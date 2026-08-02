"""
Memory Service — owns per-instance memory entries and memory retrieval.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models import MemoryEntry, NpcInstance


async def get_memory_entries(
    db: AsyncSession, npc_instance_id: str
) -> list[MemoryEntry]:
    result = await db.execute(
        select(MemoryEntry)
        .where(MemoryEntry.npc_instance_id == npc_instance_id)
        .order_by(MemoryEntry.id)
    )
    return list(result.scalars().all())


async def write_memory_entry(
    db: AsyncSession,
    npc_instance_id: str,
    event: str,
    interpretation: str,
    turn: int,
) -> MemoryEntry:
    """Write a new memory entry to the NPC instance."""
    entry = MemoryEntry(
        npc_instance_id=npc_instance_id,
        event=event,
        interpretation=interpretation,
        turn=turn,
    )
    db.add(entry)
    await db.flush()
    return entry


async def write_encounter_memory(
    db: AsyncSession,
    npc_instance_id: str,
    conversation_history: list[dict],
    interpretation: str,
    final_turn: int,
) -> None:
    """
    Write a summarizing memory entry for a completed encounter.
    Called during encounter finalization (POST /interaction/end).
    """
    # Derive a compact event description from the last player message
    player_turns = [m for m in conversation_history if m.get("role") == "player"]
    if player_turns:
        last_player_msg = player_turns[-1].get("text", "")[:80]
        event = f"encounter_ended: {last_player_msg}"
    else:
        event = "encounter_ended"

    await write_memory_entry(
        db=db,
        npc_instance_id=npc_instance_id,
        event=event,
        interpretation=interpretation,
        turn=final_turn,
    )


def format_memory_for_context(entries: list[MemoryEntry]) -> str:
    """Return a compact string representation of memory entries for LLM context."""
    if not entries:
        return "No prior memory with this character."
    lines = [
        f"- Turn {e.turn}: {e.event} (interpretation: {e.interpretation})"
        for e in entries[-10:]  # limit to 10 most recent entries for context window
    ]
    return "\n".join(lines)
