"""
Observer Service — pattern trigger detection at encounter close.

Section 7:
  - Trigger: count(entry.interpretation == X) >= 2 within ONE NPC instance's memory.
  - Deterministic check. The LLM is only called for phrasing after the trigger fires.
  - Does not own memory. Does not write memory.
"""
from __future__ import annotations

from collections import Counter

from src.models import MemoryEntry
from src.services import llm_service


def _check_trigger(entries: list[MemoryEntry]) -> tuple[bool, str, list[MemoryEntry]]:
    """
    Deterministic count check.
    Returns (fired, matched_interpretation, matching_entries).
    """
    counts = Counter(e.interpretation for e in entries)
    for interpretation, count in counts.items():
        if count >= 2:
            matching = [e for e in entries if e.interpretation == interpretation]
            return True, interpretation, matching
    return False, "", []


async def run_observer(entries: list[MemoryEntry]) -> dict:
    """
    Check whether the Observer trigger fires and, if so, call Observer Phrasing.

    Returns:
      { "fired": bool, "message": str | None }
    """
    fired, _, matching_entries = _check_trigger(entries)

    if not fired:
        return {"fired": False, "message": None}

    # Convert to plain dicts for the LLM call
    entry_dicts = [
        {"turn": e.turn, "event": e.event, "interpretation": e.interpretation}
        for e in matching_entries
    ]

    phrasing = await llm_service.observer_phrasing(entry_dicts)
    return {"fired": True, "message": phrasing.get("message", "")}
