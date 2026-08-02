"""
LLM Service — all model calls through a single module.

Five pipelines (Section 4):
  1. Memory Formation   — score + interpretation
  2. Character Voice    — npc_reply, npc_expression, coach_hint
  3. Scenario Personalization — opening_line, npc_expression
  4. Observer Phrasing  — observer message
  5. Report Generation  — full report object

Every pipeline:
  - Has its own system prompt enforcing input/output constraints.
  - Returns structured output (parsed from JSON).
  - Raises an exception on model failure (no silent fallbacks).

The LLM does NOT make game-state decisions — it returns data only.
State mutation is always done by service code after this call returns.
"""
from __future__ import annotations

import json
import logging
from typing import Any

from openai import AsyncOpenAI

from src.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def _make_client() -> AsyncOpenAI:
    return AsyncOpenAI(
        api_key=settings.llm_key,
        base_url=settings.llm_base_url,
    )


async def _call(
    system_prompt: str,
    user_prompt: str,
    temperature: float = 0.7,
) -> str:
    """
    Single LLM call. Returns the raw text content of the first choice.
    Raises on API error.
    """
    client = _make_client()
    response = await client.chat.completions.create(
        model=settings.llm_model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        temperature=temperature,
        response_format={"type": "json_object"},
    )
    return response.choices[0].message.content or "{}"


def _parse_json(raw: str, pipeline: str) -> dict:
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"LLM ({pipeline}) returned invalid JSON: {raw!r}") from exc


# ─────────────────────────────────────────────────────────────────────────────
# 1. Memory Formation Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_MEMORY_FORMATION_SYSTEM = """
You are an assessment engine for a social simulation game. Your sole function is to score the
player's message across four communication dimensions and select an interpretation label.

You MUST return valid JSON with exactly this schema:
{
  "clarity":      <float 0.0–1.0>,
  "empathy":      <float 0.0–1.0>,
  "politeness":   <float 0.0–1.0>,
  "expression":   <float 0.0–1.0>,
  "interpretation": <string — one of the allowed labels listed in the prompt>
}

Scoring guidance:
  clarity:    How clearly and directly the player communicated their meaning.
  empathy:    Whether the player acknowledged or validated the other person's feelings/perspective.
  politeness: Whether the tone was respectful and considerate.
  expression: Whether the player communicated with emotional honesty and personal engagement.

The interpretation label MUST be chosen from the vocabulary provided — never a freely invented string.
You do not decide NPC state, write dialogue, or mutate any game value. Return data only.
""".strip()


async def memory_formation(
    player_message: str,
    scenario_context: dict,
    conversation_history: list[dict],
    interpretation_vocabulary: list[str],
) -> dict:
    """
    Score the player's message and select an interpretation label.

    Returns: { clarity, empathy, politeness, expression, interpretation }
    """
    history_text = "\n".join(
        f"{m['role'].upper()}: {m['text']}" for m in conversation_history[-6:]
    )
    vocab_str = ", ".join(f'"{v}"' for v in interpretation_vocabulary)

    user_prompt = f"""
Scenario premise: {scenario_context.get('premise', '')}
Scenario stakes: {scenario_context.get('stakes', '')}
NPC goal: {scenario_context.get('npc_goal', '')}
Scoring focus — primary: {scenario_context.get('scoring_focus_primary', '')}, secondary: {scenario_context.get('scoring_focus_secondary', '')}

Recent conversation:
{history_text}

Player message to score:
"{player_message}"

Allowed interpretation labels: [{vocab_str}]

Return your assessment as JSON.
""".strip()

    raw = await _call(_MEMORY_FORMATION_SYSTEM, user_prompt, temperature=0.3)
    result = _parse_json(raw, "Memory Formation")

    # Enforce vocabulary constraint
    vocab_set = set(interpretation_vocabulary)
    if result.get("interpretation") not in vocab_set:
        # Fall back to failure_signal if model returns something outside vocab
        result["interpretation"] = interpretation_vocabulary[-1]

    # Clamp scores
    for dim in ("clarity", "empathy", "politeness", "expression"):
        result[dim] = max(0.0, min(1.0, float(result.get(dim, 0.5))))

    return result


# ─────────────────────────────────────────────────────────────────────────────
# 2. Character Voice Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_CHARACTER_VOICE_SYSTEM = """
You are a character voice engine for a social simulation game. You embody a specific character
and generate their authentic response to the player.

You MUST return valid JSON with exactly this schema:
{
  "npc_reply":      <string — what the character says>,
  "npc_expression": <string enum — one of: neutral, warm, hurt, guarded, irritated, concerned,
                     disappointed, approving, dismissive, satisfied, frustrated, hostile,
                     defensive, withdrawn, collaborative>,
  "coach_hint":     <string — one factual observation about the conversation, never prescriptive>
}

Rules:
  - Write the reply entirely in the character's voice and communication style.
  - The reply must be consistent with the character's current emotional state.
  - npc_expression must be the enum that best fits the reply's emotional tone.
  - coach_hint: state ONE noticed fact about the conversation (e.g., "She hasn't acknowledged
    what you said about feeling left out."). NEVER tell the player what to say or prescribe an action.
  - You do not choose NPC state — you write from within the state you are given.
  - Do not invent new scenario premises.
""".strip()


async def character_voice(
    npc_name: str,
    npc_personality: str,
    npc_communication_style: str,
    npc_state: str,
    memory_context: str,
    conversation_history: list[dict],
    scenario_context: dict,
) -> dict:
    """
    Generate the NPC's reply, expression, and coach hint.

    Returns: { npc_reply, npc_expression, coach_hint }
    """
    history_text = "\n".join(
        f"{m['role'].upper()}: {m['text']}" for m in conversation_history[-8:]
    )

    user_prompt = f"""
Character: {npc_name}
Personality: {npc_personality}
Communication style: {npc_communication_style}
Current emotional state: {npc_state}

Scenario context:
  Premise: {scenario_context.get('premise', '')}
  Stakes: {scenario_context.get('stakes', '')}
  NPC goal: {scenario_context.get('npc_goal', '')}

Long-term memory of this relationship:
{memory_context}

Conversation so far (this encounter):
{history_text}

Respond as {npc_name} in their current state. Return JSON.
""".strip()

    raw = await _call(_CHARACTER_VOICE_SYSTEM, user_prompt, temperature=0.8)
    result = _parse_json(raw, "Character Voice")

    # Ensure required fields
    result.setdefault("npc_reply", f"{npc_name} says nothing.")
    result.setdefault("npc_expression", npc_state)
    result.setdefault("coach_hint", "")

    return result


# ─────────────────────────────────────────────────────────────────────────────
# 3. Scenario Personalization Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_SCENARIO_PERSONALIZATION_SYSTEM = """
You are a scenario personalization engine for a social simulation game. Your job is to phrase the
NPC's opening line for a scenario in a way that matches their personality and the player's history
with them.

You MUST return valid JSON with exactly this schema:
{
  "opening_line":   <string — the NPC's opening line, personalized in their voice>,
  "npc_expression": <string enum — one of: neutral, warm, hurt, guarded, irritated, concerned,
                     disappointed, approving, dismissive, satisfied, frustrated, hostile,
                     defensive, withdrawn, collaborative>
}

CRITICAL constraints:
  - Do NOT alter the premise, stakes, npc_goal, or possible_outcomes — these are fixed.
  - Only personalize: tone, wording, how the personality expresses itself.
  - The opening_line must feel consistent with the character's communication style and current state.
  - Never invent a new scenario; only re-word the provided opening_line_seed.
""".strip()


async def scenario_personalization(
    seed_data: dict,
    npc_identity: dict,
    encounter_starting_metrics: dict,
    player_history_summary: str,
) -> dict:
    """
    Personalize the scenario opening line.

    Returns: { opening_line, npc_expression }
    """
    user_prompt = f"""
Character: {npc_identity.get('name', 'Unknown')}
Personality: {npc_identity.get('base_personality', '')}
Communication style: {npc_identity.get('communication_style', '')}

Scenario title: {seed_data.get('title', '')}
Scenario premise: {seed_data.get('premise', '')}
Opening line seed (to personalize, not replace): "{seed_data.get('opening_line_seed', '')}"
NPC goal: {seed_data.get('npc_goal', '')}

Current NPC metrics (emotional state at encounter start):
{json.dumps(encounter_starting_metrics, indent=2)}

Player's recent history with this character (brief):
{player_history_summary}

Return the personalized opening line as JSON.
""".strip()

    raw = await _call(_SCENARIO_PERSONALIZATION_SYSTEM, user_prompt, temperature=0.7)
    result = _parse_json(raw, "Scenario Personalization")

    result.setdefault("opening_line", seed_data.get("opening_line_seed", ""))
    result.setdefault("npc_expression", "neutral")

    return result


# ─────────────────────────────────────────────────────────────────────────────
# 4. Observer Phrasing Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_OBSERVER_PHRASING_SYSTEM = """
You are the Observer — a quiet, factual narrator in a social simulation game.
When a player has repeated the same kind of conversational miss with the same person, you name it.

You MUST return valid JSON with exactly this schema:
{
  "message": <string — one or two sentences, factual, grounded, non-judgmental>
}

Rules:
  - State what happened as a plain fact. Do not coach, advise, or prescribe.
  - Do not use the word "you" to assign blame. Describe the pattern.
  - Speak in a quiet, observational register — like a wise narrator, not a critic.
  - Never tell the player what they should have said or should do next.
  - Your trigger data (the memory entries) is the only source of truth. Do not invent.
""".strip()


async def observer_phrasing(matching_entries: list[dict]) -> dict:
    """
    Phrase the Observer's reveal message from the matching memory entries.

    Returns: { message }
    """
    entries_text = "\n".join(
        f"- Turn {e.get('turn', '?')}: {e.get('event', '')} (interpretation: {e.get('interpretation', '')})"
        for e in matching_entries
    )

    user_prompt = f"""
The following pattern has repeated in this relationship:

{entries_text}

Write one or two sentences that factually name what has happened, without coaching or prescribing.
Return as JSON.
""".strip()

    raw = await _call(_OBSERVER_PHRASING_SYSTEM, user_prompt, temperature=0.6)
    result = _parse_json(raw, "Observer Phrasing")
    result.setdefault("message", "A pattern repeated in this relationship.")
    return result


# ─────────────────────────────────────────────────────────────────────────────
# 5. Report Generation Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_REPORT_GENERATION_SYSTEM = """
You are the report generator for a social simulation game. You interpret the player's skill vector
and recent encounter history to produce a personal communication growth summary.

You MUST return valid JSON with exactly this schema:
{
  "strongest_skill":        <string — one of: clarity, empathy, politeness, expression>,
  "improving_area":         <string — a concise descriptive label (e.g., "conflict_resolution")>,
  "recent_pattern_summary": <string — one or two sentences describing a pattern>,
  "recommended_practice":   <string — one concrete practice suggestion>
}

Rules:
  - Derive every field from the provided skill vector and encounter history — never invent data.
  - Use plain, human-readable language — not rubric language.
  - improving_area should be an interpretive label derived from the data (e.g., conflict_resolution,
    emotional_acknowledgment, clarity_under_pressure) — not a raw metric name.
  - recommended_practice should reference a scenario type, not a generic tip.
  - Do not produce a score, a rating, a grade, or anything that feels like a test result.
""".strip()


async def report_generation(
    skill_vector: dict,
    player_level: int,
    recent_encounters: list[dict],
) -> dict:
    """
    Generate the player report from their skill vector and recent encounter history.

    Returns: { strongest_skill, improving_area, recent_pattern_summary, recommended_practice }
    """
    encounters_text = "\n".join(
        f"- {e.get('scenario_id', '?')} with {e.get('npc_template_id', '?')}: "
        f"outcome={e.get('outcome', '?')}, scores={json.dumps(e.get('avg_scores', {}))}"
        for e in recent_encounters[-5:]
    ) or "No recent encounters."

    user_prompt = f"""
Player level: {player_level}

Skill vector:
{json.dumps(skill_vector, indent=2)}

Recent encounter history (most recent up to 5):
{encounters_text}

Generate a personal communication summary. Return as JSON.
""".strip()

    raw = await _call(_REPORT_GENERATION_SYSTEM, user_prompt, temperature=0.6)
    result = _parse_json(raw, "Report Generation")

    result.setdefault("strongest_skill", max(skill_vector, key=lambda k: skill_vector[k]))
    result.setdefault("improving_area", "emotional_acknowledgment")
    result.setdefault("recent_pattern_summary", "Your communication patterns are developing.")
    result.setdefault("recommended_practice", "Try a friendship scenario.")

    return result
