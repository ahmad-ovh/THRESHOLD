"""
NPC Service — owns NPC template registry and NPC instance creation/resolution.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.content import NpcTemplate, registry
from src.models import NpcInstance


def _instance_id(player_id: str, template_id: str) -> str:
    return f"inst_{player_id}_{template_id}"


async def resolve_instance(
    db: AsyncSession, player_id: str, npc_id: str
) -> NpcInstance:
    """
    Return the NPC Instance for (player_id, npc_id).
    Creates one from the template's start values if this is the first contact.
    Raises ValueError if npc_id is not in the registry.
    Always eager-loads the session relationship to avoid lazy-load in async context.
    """
    template = registry.get_template(npc_id)
    if template is None:
        raise ValueError(f"NPC '{npc_id}' not found in template registry.")

    instance_id = _instance_id(player_id, npc_id)
    result = await db.execute(
        select(NpcInstance).where(NpcInstance.npc_instance_id == instance_id)
    )
    instance = result.scalar_one_or_none()

    if instance is None:
        initial_metrics = {k: v.start for k, v in template.metrics.items()}
        # Compute initial tier
        tier_cfg = registry.tier_config()
        relationship_tier = tier_cfg.resolve(
            initial_metrics.get("trust", 0.5), template.archetype_role
        )
        instance = NpcInstance(
            npc_instance_id=instance_id,
            player_id=player_id,
            template_id=npc_id,
            metrics=initial_metrics,
            current_state="neutral",
            relationship_tier=relationship_tier,
        )
        db.add(instance)
        await db.flush()

    return instance


async def get_template(npc_id: str) -> NpcTemplate | None:
    return registry.get_template(npc_id)
