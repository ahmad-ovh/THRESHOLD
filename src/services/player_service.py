"""
Player Service — owns player identity and record lifecycle.
"""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models import Player


async def get_or_create_player(db: AsyncSession, player_id: str) -> Player:
    """Load an existing player or create a new one with default values."""
    result = await db.execute(select(Player).where(Player.player_id == player_id))
    player = result.scalar_one_or_none()
    if player is None:
        player = Player(
            player_id=player_id,
            level=1,
            skill_vector={
                "clarity": 0.5,
                "empathy": 0.5,
                "politeness": 0.5,
                "expression": 0.5,
            },
            xp_progress=0.0,
            daily_streak=0,
        )
        db.add(player)
        await db.flush()
    return player


async def get_player(db: AsyncSession, player_id: str) -> Player | None:
    result = await db.execute(select(Player).where(Player.player_id == player_id))
    return result.scalar_one_or_none()


async def reset_player(db: AsyncSession, player_id: str) -> Player:
    """Reset a player back to defaults, removing all NPC instances and history."""
    from src.models import NpcInstance, EncounterHistory
    from sqlalchemy import delete

    # Delete cascade handles NPC instances → memory entries and sessions
    await db.execute(delete(NpcInstance).where(NpcInstance.player_id == player_id))
    await db.execute(delete(EncounterHistory).where(EncounterHistory.player_id == player_id))

    result = await db.execute(select(Player).where(Player.player_id == player_id))
    player = result.scalar_one_or_none()
    if player is None:
        player = Player(player_id=player_id)
        db.add(player)
    else:
        player.level = 1
        player.skill_vector = {
            "clarity": 0.5,
            "empathy": 0.5,
            "politeness": 0.5,
            "expression": 0.5,
        }
        player.xp_progress = 0.0
        player.daily_streak = 0

    await db.flush()
    return player
