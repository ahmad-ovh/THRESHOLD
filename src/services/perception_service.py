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

    # 1. Base Default by Relationship Tier
    if tier in ("", "Stranger"):
        base_mode = "full"
        show_modal = True
    elif tier in ("Acquaintance", "Peer"):
        base_mode = "compact"
        show_modal = True
    else:  # Friend, Mentor, Close
        base_mode = "minimal"
        show_modal = False

    # 2. Overrides
    if requires_context or is_major_event:
        return "full", True
    if has_relationship_changed:
        return "full", True
    if has_new_location and base_mode == "minimal":
        return "compact", True

    return base_mode, show_modal


def build_perception_layer(
    template: NpcTemplate,
    instance: NpcInstance,
    player: Player,
    seed: ScenarioSeed,
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

    return {
        "show_modal": show_modal,
        "presentation_mode": presentation_mode,
        "location_name": location_name,
        "npc_name": template.name,
        "npc_role": template.archetype_role.capitalize(),
        "relationship_tier": tier,
        "situation": situation,
        "encounter_focus": encounter_focus,
        "known_facts": known_facts,
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
      3. Regenerate perception_summary_json if meaningful changes happened.
    """
    if not transcript:
        return

    existing_facts = set(instance.discovered_facts)
    new_facts = list(existing_facts)

    # Deterministic fact extraction based on outcome and dialogue presence
    turn_count = len([t for t in transcript if t.get("role") == "player"])
    outcome = encounter_result.get("performance_outcome", "neutral")

    # Basic milestone fact logging
    if outcome == "good" and f"Had a great conversation with {instance.template_id.capitalize()}" not in existing_facts:
        new_facts.append(f"Built rapport with {instance.template_id.capitalize()} during a recent chat.")
    elif outcome == "poor" and f"Had a tense conversation with {instance.template_id.capitalize()}" not in existing_facts:
        new_facts.append(f"Had a difficult interaction with {instance.template_id.capitalize()}.")

    # Limit discovered facts list to last 10 relevant items
    instance.discovered_facts = new_facts[-10:]
    instance.perception_summary_json = json.dumps({
        "last_outcome": outcome,
        "total_turns": turn_count,
        "facts_count": len(instance.discovered_facts),
    })
