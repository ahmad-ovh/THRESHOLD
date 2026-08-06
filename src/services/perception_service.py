"""
Perception Service — Social Perception Layer & Onboarding Projection.

Projects existing game state (NPC template, player world state, relationship tier,
and discovered facts) into a structured perception layer payload for pre-dialogue onboarding.
"""
from __future__ import annotations

import json
import logging
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from src.content import NpcTemplate, ScenarioSeed
    from src.models import NpcInstance, Player

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.models import NpcInstance

logger = logging.getLogger(__name__)

# Map of room locations based on role / scenario ID
LOCATION_MAP = {
    "barista": "Downtown Café",
    "daria": "Downtown Café (Window Booth)",
    "felix": "Downtown Café (Center Table)",
    "priya": "Downtown Café",
    "prof_adler": "Prof. Adler's Study",
    "teacher": "Campus Seminar Room",
    "ms_okoro": "Ms. Okoro's Classroom",
    "mr_vance": "Campus Hallway",
    "parent": "Apartment Living Room",
    "sibling": "Apartment Balcony",
    "nadia": "Office Lobby",
    "tomas": "Office Lobby",
    "seren": "Office Lobby",
    "ms_hartwell": "Executive Suite",
    "recurring_stranger": "Main Street Bench",
}


def get_location_name(npc_id: str, archetype_role: str, category: str = "") -> str:
    """Derive a friendly location name from existing NPC identity or scenario category."""
    if npc_id in LOCATION_MAP:
        return LOCATION_MAP[npc_id]
    if archetype_role in LOCATION_MAP:
        return LOCATION_MAP[archetype_role]
    if category == "workplace":
        return "Office Building"
    if category == "high_pressure":
        return "Executive Office Suite"
    return "Main Street Neighborhood"


# Tier sets mapped from relationship_tiers config
FIRST_MEETING_TIERS = {"", "Stranger", "Unfamiliar", "Unknown", "Estranged", "Unnoticed"}
EARLY_RELATIONSHIP_TIERS = {"Acquaintance", "Peer", "Noted", "Coworker", "Skeptical", "Distant", "Noticed"}


def calculate_presentation_mode(
    relationship_tier: str,
    seed_context: dict[str, Any] | None = None,
    is_major_event: bool = False,
    has_relationship_changed: bool = False,
    has_new_location: bool = False,
) -> tuple[str, bool]:
    """
    Calculate (presentation_mode, show_modal).

    Modes:
      - 'full': Detailed onboarding modal with full background context.
      - 'compact': Concise reminder card.
      - 'minimal': Quick banner or skipped modal for familiar/close relationships.

    Overrides:
      - seed.context.requires_context = True or is_major_event -> upgrades to 'full'
      - relationship level shift or new location -> upgrades mode to 'full' or 'compact'
    """
    tier = (relationship_tier or "").strip()
    context = seed_context or {}
    requires_context = context.get("requires_context", False) or is_major_event

    # 1. Base Default by Relationship Tier (Always show modal by default for clear player context)
    if tier in FIRST_MEETING_TIERS:
        base_mode = "full"
        show_modal = True
    else:
        # Early, Established, or Close Relationships: compact perception card
        base_mode = "compact"
        show_modal = True

    # 2. Overrides
    if requires_context or is_major_event:
        return "full", True
    if has_relationship_changed:
        return "full", True

    return base_mode, show_modal


async def get_player_journal_entries(db: AsyncSession, player_id: str) -> list[dict[str, Any]]:
    """Assemble Journal notebook pages for met NPCs ONLY (Section 8.1)."""
    stmt = select(NpcInstance).where(
        NpcInstance.player_id == player_id,
        NpcInstance.met_in_person == True,
    )
    res = await db.execute(stmt)
    instances = res.scalars().all()

    journal_entries = []
    from src.content import registry
    for inst in instances:
        tmpl = registry.get_template(inst.template_id)
        if not tmpl:
            continue

        r_title = tmpl.archetype_role.capitalize()
        if tmpl.id == "barista":
            r_title = "Barista"

        loc = get_location_name(tmpl.id, tmpl.archetype_role, "everyday_social")
        facts = json.loads(inst.discovered_facts_json) if getattr(inst, "discovered_facts_json", None) else []
        connections = json.loads(inst.discovered_connections_json) if getattr(inst, "discovered_connections_json", None) else []

        journal_entries.append({
            "npc_id": tmpl.id,
            "name": tmpl.name,
            "role": r_title,
            "usual_location": loc,
            "relationship_tier": inst.relationship_tier or "Noticed",
            "known_through": f"First met at {loc}",
            "connections": connections,
            "personality_notes": getattr(tmpl, "base_personality", ""),
            "discovered_facts": facts,
        })
    return journal_entries


async def build_perception_layer(
    template: NpcTemplate,
    instance: NpcInstance,
    player: Player,
    seed: ScenarioSeed,
    db: AsyncSession,
    is_major_event: bool = False,
) -> dict[str, Any]:
    """
    Build a structured perception layer dictionary from existing state.

    Determinism Rules:
      - First meeting ('Stranger'): 100% derived from template + world seed. Zero LLM hallucination.
      - Subsequent meetings: Uses stored discovered_facts + relationship tier + last summary projection.
    """
    tier = instance.relationship_tier or "Stranger"
    location_name = get_location_name(template.id, template.archetype_role, seed.category)
    from dataclasses import asdict
    seed_ctx = asdict(seed.context) if hasattr(seed.context, "__dataclass_fields__") else vars(seed.context)

    presentation_mode, show_modal = calculate_presentation_mode(
        relationship_tier=tier,
        seed_context=seed_ctx,
        is_major_event=is_major_event,
    )

    # Situation / Premise from scenario seed
    situation = seed.context.premise

    # Encounter Focus (formerly 'player goal') — describes natural purpose/context
    encounter_focus = seed.context.stakes if seed.context.stakes else f"Talking with {template.name}."

    # Known Facts (deterministic for first meeting, stored for subsequent)
    known_facts: list[str] = []
    if tier in ("", "Stranger"):
        # First meeting: Derived deterministically from template + role
        known_facts = [
            f"{template.name} is a {template.archetype_role.capitalize()} at {location_name}."
        ]
        if seed.context.npc_goal:
            known_facts.append(f"Seems focused on: {seed.context.npc_goal}")
    else:
        # Subsequent meeting: Use stored discovered facts
        known_facts = instance.discovered_facts
        if not known_facts:
            known_facts = [f"You have spoken with {template.name} before."]

    npc_role_title = template.archetype_role.capitalize()
    if template.id == "barista":
        npc_role_title = "Barista"

    journal_entries = await get_player_journal_entries(db, player.player_id)

    return {
        "show_modal": show_modal,
        "presentation_mode": presentation_mode,
        "location_name": location_name,
        "npc_name": template.name,
        "npc_role": npc_role_title,
        "relationship_tier": tier,
        "situation": situation,
        "encounter_focus": encounter_focus,
        "known_facts": known_facts,
        "journal_entries": journal_entries,
    }


async def process_encounter_end_perception(
    instance: NpcInstance,
    transcript: list[dict[str, str]],
    encounter_result: dict[str, Any],
) -> None:
    """
    Background pipeline run after POST /interaction/end:
      1. Extract candidate facts from transcript.
      2. Store valid discovered facts in instance.discovered_facts.
      3. Extract cross-NPC connections mentioned in dialogue.
      4. Regenerate perception_summary_json if meaningful changes happened.
    """
    if not transcript:
        return

    existing_facts = set(instance.discovered_facts)
    new_facts = list(existing_facts)

    # Deterministic fact extraction based on outcome and dialogue presence
    turn_count = len([t for t in transcript if t.get("role") == "player"])
    outcome = encounter_result.get("performance_outcome", "neutral")
    if outcome == "good" and f"Had a productive discussion ({turn_count} turns)" not in existing_facts:
        new_facts.append(f"Had a productive discussion ({turn_count} turns)")

    instance.discovered_facts = new_facts

    # Extract cross-NPC mentions into discovered_connections_json
    full_dialogue = " ".join([t.get("content", "") for t in transcript]).lower()
    connections = json.loads(instance.discovered_connections_json) if getattr(instance, "discovered_connections_json", None) else []
    conn_set = set(connections)

    npc_mention_map = {
        "adler": "→ Prof. Adler (Academic Advisor)",
        "okoro": "→ Ms. Okoro (Academy Teacher)",
        "vance": "→ Mr. Vance (Campus Staff)",
        "daria": "→ Daria (Classmate / Friend)",
        "felix": "→ Felix (Classmate / Friend)",
        "priya": "→ Priya (Friend)",
        "tomas": "→ Tomas (Workplace Colleague)",
        "nadia": "→ Nadia (Colleague)",
        "seren": "→ Seren (Colleague)",
        "hartwell": "→ Ms. Hartwell (Executive Client)",
        "barista": "→ The Barista (Downtown Café)",
    }

    for key, conn_label in npc_mention_map.items():
        if key in full_dialogue and key != instance.template_id:
            conn_set.add(conn_label)

    instance.discovered_connections_json = json.dumps(list(conn_set))

    instance.perception_summary_json = json.dumps({
        "last_outcome": outcome,
        "total_turns": turn_count,
        "facts_count": len(instance.discovered_facts),
    })
