"""
Player router — /player/* endpoints.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.services import player_service

router = APIRouter(prefix="/player", tags=["player"])


class ResetRequest(BaseModel):
    player_id: str


@router.post("/reset")
async def reset_player(
    body: ResetRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """
    Reset a player back to defaults — clears all NPC instances, memory,
    and resets skill vector/level/XP. Demo and test utility endpoint.
    """
    await player_service.reset_player(db, body.player_id)
    await db.commit()
    return {"player_id": body.player_id, "reset": True}


@router.get("/status")
async def player_status(
    player_id: str, db: AsyncSession = Depends(get_db)
) -> dict:
    """Return the player's current state (convenience endpoint for testing)."""
    player = await player_service.get_player(db, player_id)
    if player is None:
        raise HTTPException(status_code=404, detail="Player not found.")

    return {
        "player_id": player.player_id,
        "level": player.level,
        "skill_vector": player.skill_vector,
        "xp_progress": player.xp_progress,
        "daily_streak": player.daily_streak,
        "created_at": player.created_at.isoformat(),
    }
