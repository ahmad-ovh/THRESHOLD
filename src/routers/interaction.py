"""
Interaction router — /interaction/* endpoints.

All game logic is here, orchestrating the services per the spec's request flows.
"""
from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config import get_settings
from src.content import registry
from src.database import get_db
from src.models import EncounterHistory, InteractionSession, NpcInstance
from src.services import (
    llm_service,
    memory_service,
    npc_service,
    observer_service,
    player_service,
    progression_service,
    scenario_service,
    scoring_service,
)
from src.services.relationship_service import update_npc_instance_metrics
from src.state_engine import resolve_state

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/interaction", tags=["interaction"])
settings = get_settings()

# ─────────────────────────────────────────────────────────────────────────────
# Request / Response schemas
# ─────────────────────────────────────────────────────────────────────────────


class StartRequest(BaseModel):
    player_id: str
    npc_id: str


class MessageRequest(BaseModel):
    player_id: str
    npc_id: str
    message: str

    @field_validator("message")
    @classmethod
    def message_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("message must not be empty")
        return v


class EndRequest(BaseModel):
    player_id: str
    npc_id: str


class ReportRequest(BaseModel):
    player_id: str


# ─────────────────────────────────────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────────────────────────────────────


async def _load_session(
    db: AsyncSession, npc_instance_id: str
) -> InteractionSession | None:
    """Load the InteractionSession for an NPC instance directly by PK (no lazy load)."""
    result = await db.execute(
        select(InteractionSession).where(
            InteractionSession.npc_instance_id == npc_instance_id
        )
    )
    return result.scalar_one_or_none()


async def _get_active_session(
    db: AsyncSession, player_id: str, npc_id: str
) -> tuple[NpcInstance, InteractionSession]:
    """Load the active session or raise 404."""
    template = registry.get_template(npc_id)
    if template is None:
        raise HTTPException(status_code=404, detail=f"NPC '{npc_id}' not found.")

    instance = await npc_service.resolve_instance(db, player_id, npc_id)
    session = await _load_session(db, instance.npc_instance_id)

    if session is None:
        raise HTTPException(
            status_code=404,
            detail="No active session. Call /interaction/start first.",
        )

    return instance, session


# ─────────────────────────────────────────────────────────────────────────────
# POST /interaction/start
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/start")
async def start_interaction(
    body: StartRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """
    Section 1.3.1 — encounter start flow.
    """
    template = registry.get_template(body.npc_id)
    if template is None:
        raise HTTPException(status_code=404, detail=f"NPC '{body.npc_id}' not found.")

    # Load/create player and NPC instance
    player = await player_service.get_or_create_player(db, body.player_id)
    instance = await npc_service.resolve_instance(db, body.player_id, body.npc_id)

    # Close any stale session (query directly — no lazy attribute access)
    stale_session = await _load_session(db, instance.npc_instance_id)
    if stale_session is not None:
        await db.delete(stale_session)
        await db.flush()

    # Scenario selection (Section 6.2)
    seed = scenario_service.select_seed(
        archetype_role=template.archetype_role,
        player_level=player.level,
    )

    # Effective starting metrics (Section 6.3)
    effective_metrics = scenario_service.compute_effective_metrics(
        persisted_metrics=instance.metrics,
        encounter_modifiers=seed.npc_context_metric_overrides,
    )

    # Create session
    session = InteractionSession(
        npc_instance_id=instance.npc_instance_id,
        scenario_id=seed.id,
        turn_count=0,
        encounter_modifiers=seed.npc_context_metric_overrides,
        effective_metrics=effective_metrics,
        encounter_over=False,
        accumulated_scores=[],
    )
    db.add(session)
    await db.flush()
    await db.refresh(instance)

    # Memory for context
    memory_entries = await memory_service.get_memory_entries(db, instance.npc_instance_id)
    memory_ctx = memory_service.format_memory_for_context(memory_entries)

    # Player history summary (brief)
    history_summary = f"Level {player.level} player. Recent encounters: {len(memory_entries)} recorded memories."

    # Scenario Personalization AI (Section 4.3)
    seed_data = {
        "title": seed.title,
        "premise": seed.context.premise,
        "stakes": seed.context.stakes,
        "opening_line_seed": seed.context.opening_line_seed,
        "npc_goal": seed.context.npc_goal,
    }
    npc_identity = {
        "name": template.name,
        "base_personality": template.base_personality,
        "communication_style": template.communication_style,
    }

    personalized = await llm_service.scenario_personalization(
        seed_data=seed_data,
        npc_identity=npc_identity,
        encounter_starting_metrics=effective_metrics,
        player_history_summary=history_summary,
    )

    opening_line = personalized.get("opening_line", seed.context.opening_line_seed)
    npc_expression = personalized.get("npc_expression", "neutral")

    # Append NPC opening to conversation history
    session.conversation_history = [{"role": "npc", "text": opening_line}]
    await db.commit()

    return {
        "npc_name": template.name,
        "npc_expression": npc_expression,
        "opening_line": opening_line,
        "interaction_id": seed.id,
        "encounter_over": False,
    }


# ─────────────────────────────────────────────────────────────────────────────
# POST /interaction/message
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/message")
async def send_message(
    body: MessageRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """
    Section 1.3 — single player message flow.
    """
    template = registry.get_template(body.npc_id)
    if template is None:
        raise HTTPException(status_code=404, detail=f"NPC '{body.npc_id}' not found.")

    instance, session = await _get_active_session(db, body.player_id, body.npc_id)
    player = await player_service.get_or_create_player(db, body.player_id)
    seed = registry.get_seed(session.scenario_id)

    if seed is None:
        raise HTTPException(status_code=500, detail=f"Seed '{session.scenario_id}' not found.")

    if session.encounter_over:
        raise HTTPException(
            status_code=400,
            detail="Encounter is already over. Call /interaction/end.",
        )

    # Append player message to conversation history
    history = session.conversation_history
    history.append({"role": "player", "text": body.message})
    session.conversation_history = history

    # 1. Scoring Service → Memory Formation (Section 1.3)
    scores = await scoring_service.score_message(
        player_message=body.message,
        seed=seed,
        conversation_history=history,
    )

    turn_scores = {k: scores[k] for k in ("clarity", "empathy", "politeness", "expression")}
    interpretation = scores["interpretation"]

    # 2. Relationship Service: metric update on effective_metrics
    current_effective = session.effective_metrics
    new_effective, new_state, new_tier = update_npc_instance_metrics(
        template=template,
        instance_metrics=current_effective,
        turn_scores=turn_scores,
    )
    session.effective_metrics = new_effective

    # Update instance state cache
    instance.current_state = new_state
    instance.relationship_tier = new_tier

    # 3. Memory: write turn entry to NPC instance memory
    session.turn_count += 1
    await memory_service.write_memory_entry(
        db=db,
        npc_instance_id=instance.npc_instance_id,
        event=f"player_turn_{session.turn_count}: {body.message[:80]}",
        interpretation=interpretation,
        turn=session.turn_count,
    )

    # Accumulate turn scores for progression at encounter end
    acc = session.accumulated_scores
    acc.append(turn_scores)
    session.accumulated_scores = acc

    # 4. Character Voice AI
    memory_entries = await memory_service.get_memory_entries(db, instance.npc_instance_id)
    memory_ctx = memory_service.format_memory_for_context(memory_entries)

    scenario_context = {
        "premise": seed.context.premise,
        "stakes": seed.context.stakes,
        "npc_goal": seed.context.npc_goal,
    }

    voice_result = await llm_service.character_voice(
        npc_name=template.name,
        npc_personality=template.base_personality,
        npc_communication_style=template.communication_style,
        npc_state=new_state,
        memory_context=memory_ctx,
        conversation_history=history,
        scenario_context=scenario_context,
    )

    npc_reply = voice_result.get("npc_reply", "")
    npc_expression = voice_result.get("npc_expression", new_state)
    coach_hint_text = voice_result.get("coach_hint", "")

    # Append NPC reply to conversation history
    history = session.conversation_history
    history.append({"role": "npc", "text": npc_reply})
    session.conversation_history = history

    # 5. Encounter termination check
    encounter_over = session.turn_count >= settings.max_turns_per_encounter
    session.encounter_over = encounter_over

    # 6. Build feedback (strength + improvement from scores)
    feedback = _build_feedback(turn_scores, seed)

    await db.commit()

    return {
        "npc_expression": npc_expression,
        "npc_reply": npc_reply,
        "coach_hint": {"shown": bool(coach_hint_text), "line": coach_hint_text},
        "turn_scores": turn_scores,
        "relationship_tier": new_tier,
        "npc_state": new_state,
        "feedback": feedback,
        "encounter_over": encounter_over,
    }


def _build_feedback(turn_scores: dict, seed: "Any") -> dict:
    """
    Derive human-language feedback from turn scores.
    Strength = highest dimension; improvement = lowest or seed's secondary focus.
    """
    dims = ["clarity", "empathy", "politeness", "expression"]
    best_dim = max(dims, key=lambda d: turn_scores.get(d, 0.0))
    worst_dim = min(dims, key=lambda d: turn_scores.get(d, 0.0))

    strength_labels = {
        "clarity":    "You communicated your point clearly.",
        "empathy":    "You showed genuine understanding of the other person.",
        "politeness": "Your tone was respectful and considerate.",
        "expression": "You expressed yourself with personal honesty.",
    }
    improvement_labels = {
        "clarity":    "Your message could have been more direct.",
        "empathy":    "You responded to the words, but not the feeling behind them.",
        "politeness": "The tone came across as slightly abrupt.",
        "expression": "You kept things factual but didn't share your own perspective.",
    }

    return {
        "strength":    strength_labels.get(best_dim, ""),
        "improvement": improvement_labels.get(worst_dim, ""),
    }


# ─────────────────────────────────────────────────────────────────────────────
# POST /interaction/end
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/end")
async def end_interaction(
    body: EndRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """
    Section 1.3.1 — encounter end flow.
    """
    template = registry.get_template(body.npc_id)
    if template is None:
        raise HTTPException(status_code=404, detail=f"NPC '{body.npc_id}' not found.")

    instance, session = await _get_active_session(db, body.player_id, body.npc_id)
    player = await player_service.get_or_create_player(db, body.player_id)
    seed = registry.get_seed(session.scenario_id)

    if seed is None:
        raise HTTPException(status_code=500, detail=f"Seed '{session.scenario_id}' not found.")

    accumulated = session.accumulated_scores
    final_effective = session.effective_metrics
    conversation_history = session.conversation_history

    # 1. Determine outcome
    if accumulated:
        avg_scores = {
            dim: sum(s.get(dim, 0.5) for s in accumulated) / len(accumulated)
            for dim in ("clarity", "empathy", "politeness", "expression")
        }
    else:
        avg_scores = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}

    outcome = progression_service.determine_outcome(avg_scores, seed)

    # 2. Write encounter-summary memory entry
    # Determine the dominant interpretation from accumulated turns
    if accumulated:
        from collections import Counter
        from sqlalchemy import select as sa_select
        entries = await memory_service.get_memory_entries(db, instance.npc_instance_id)
        session_entries = [e for e in entries if e.turn <= session.turn_count]
        if session_entries:
            dominant_interpretation = Counter(
                e.interpretation for e in session_entries
            ).most_common(1)[0][0]
        else:
            dominant_interpretation = seed.failure_signal
    else:
        dominant_interpretation = seed.failure_signal

    await memory_service.write_encounter_memory(
        db=db,
        npc_instance_id=instance.npc_instance_id,
        conversation_history=conversation_history,
        interpretation=dominant_interpretation,
        final_turn=session.turn_count,
    )

    # 3. Observer Service
    all_entries = await memory_service.get_memory_entries(db, instance.npc_instance_id)
    observer_result = await observer_service.run_observer(all_entries)

    # 4. Progression: XP + skill vector
    xp_gain = progression_service.compute_xp_gain(
        turn_scores_list=accumulated,
        seed=seed,
        outcome=outcome,
        player_level=player.level,
    )
    new_skill_vector = progression_service.compute_skill_vector_update(
        current_vector=player.skill_vector,
        turn_scores_list=accumulated,
        seed=seed,
    )
    new_xp, new_level, leveled_up = progression_service.apply_xp_and_level(
        player_xp_progress=player.xp_progress,
        player_level=player.level,
        xp_gain=xp_gain,
    )

    player.skill_vector = new_skill_vector
    player.xp_progress = new_xp
    player.level = new_level

    # 5. Commit final effective metrics back to the NPC instance (Section 6.3)
    instance.metrics = final_effective
    new_state, new_tier = resolve_state(template, final_effective), ""
    from src.services.relationship_service import resolve_tier
    new_tier = resolve_tier(template, final_effective)
    instance.current_state = new_state
    instance.relationship_tier = new_tier

    # 6. Record encounter history for reporting
    history_record = EncounterHistory(
        player_id=body.player_id,
        npc_template_id=body.npc_id,
        scenario_id=session.scenario_id,
        outcome=outcome,
        xp_gained=xp_gain,
    )
    history_record.avg_scores = avg_scores
    db.add(history_record)

    # 7. Discard session
    await db.delete(session)
    await db.flush()

    await db.commit()

    response: dict = {
        "observer_event": {
            "fired": observer_result["fired"],
            "npc_id": body.npc_id,
            "message": observer_result.get("message"),
        },
        "encounter_summary": {"outcome": outcome},
    }
    if leveled_up:
        response["level_up"] = {"new_level": new_level}

    return response


# ─────────────────────────────────────────────────────────────────────────────
# POST /interaction/report
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/report")
async def get_report(
    body: ReportRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """
    Generate and return a player report on demand.
    Not stored — computed fresh each time.
    """
    player = await player_service.get_player(db, body.player_id)
    if player is None:
        raise HTTPException(status_code=404, detail="Player not found.")

    result = await db.execute(
        select(EncounterHistory)
        .where(EncounterHistory.player_id == body.player_id)
        .order_by(EncounterHistory.id.desc())
        .limit(5)
    )
    recent_encounters = [
        {
            "scenario_id": eh.scenario_id,
            "npc_template_id": eh.npc_template_id,
            "outcome": eh.outcome,
            "avg_scores": eh.avg_scores,
        }
        for eh in result.scalars().all()
    ]

    report = await llm_service.report_generation(
        skill_vector=player.skill_vector,
        player_level=player.level,
        recent_encounters=recent_encounters,
    )

    return {
        "current_level": player.level,
        "skill_vector": player.skill_vector,
        "strongest_skill":        report.get("strongest_skill"),
        "improving_area":         report.get("improving_area"),
        "recent_pattern_summary": report.get("recent_pattern_summary"),
        "recommended_practice":   report.get("recommended_practice"),
    }


# ─────────────────────────────────────────────────────────────────────────────
# GET /interaction/daily
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/daily")
async def get_daily(player_id: str, db: AsyncSession = Depends(get_db)) -> dict:
    """
    Return a featured scenario and current streak.
    """
    player = await player_service.get_or_create_player(db, player_id)

    # Pick a featured seed — choose one appropriate to the player's level
    # Prefer tier 1 for lower levels, any for higher
    all_seeds = registry.all_seeds()
    if player.level <= 30:
        candidate_seeds = [s for s in all_seeds if s.tier == 1] or all_seeds
    elif player.level <= 70:
        candidate_seeds = [s for s in all_seeds if s.tier <= 2] or all_seeds
    else:
        candidate_seeds = all_seeds

    import random
    featured = random.choice(candidate_seeds)

    # Pick an NPC that matches
    matching_templates = [
        t for t in registry.all_templates() if t.archetype_role in featured.compatible_roles
    ]
    npc = random.choice(matching_templates) if matching_templates else registry.all_templates()[0]

    focus_parts = [featured.scoring_focus.primary.capitalize()]
    if featured.scoring_focus.secondary:
        focus_parts.append(featured.scoring_focus.secondary.capitalize())
    focus_str = " + ".join(focus_parts)

    await db.commit()

    return {
        "seed_id": featured.id,
        "npc_id": npc.id,
        "focus": focus_str,
        "streak_count": player.daily_streak,
    }
