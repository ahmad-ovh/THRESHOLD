"""
Scenario Service — seed bank, weighted category selection, seed filtering, encounter setup.

Section 6.2 algorithm implemented verbatim.
"""
from __future__ import annotations

import random
from typing import TYPE_CHECKING

from src.content import ScenarioSeed, registry

if TYPE_CHECKING:
    pass


def _get_distribution_band(level: int) -> dict[str, int]:
    """Return the category weights for the player's level."""
    for band in registry.distribution_bands():
        lo, hi = band.level_range
        if lo <= level <= hi:
            return band.weights
    # Fallback: last band
    return registry.distribution_bands()[-1].weights


def _weighted_choice(weights: dict[str, int]) -> str:
    """Weighted random category pick."""
    total = sum(weights.values())
    r = random.uniform(0, total)
    cumulative = 0
    for category, weight in weights.items():
        cumulative += weight
        if r <= cumulative:
            return category
    return list(weights.keys())[-1]


def select_seed(
    archetype_role: str,
    player_level: int,
    excluded_seed_ids: list[str] | None = None,
    npc_id: str | None = None,
    is_first_interaction: bool = False,
) -> ScenarioSeed:
    """
    Weighted seed selection (Section 6.2 steps 1–6).

    1. Read archetype_role & optional npc_id.
    2. Determine distribution_band from player level.
    3. Weighted-random pick a category.
    4. Filter seeds: compatible_roles contains npc_id/role AND category matches.
    5. Fall back to nearest available category if pool is empty.
    6. Exclude already-used seed_ids; pick randomly from what remains.
    """
    if is_first_interaction and npc_id == "barista":
        onboarding_seed = registry.get_seed("first_time_around_here")
        if onboarding_seed:
            return onboarding_seed

    excluded = set(excluded_seed_ids or [])

    weights = _get_distribution_band(player_level)
    all_role_seeds = registry.seeds_for_npc(npc_id=npc_id, archetype_role=archetype_role)

    if not all_role_seeds:
        raise ValueError(f"No seeds found for npc_id='{npc_id}', archetype_role='{archetype_role}'")

    # Step 3–4: try weighted category pick
    available_categories = {s.category for s in all_role_seeds}
    category_weights = {c: w for c, w in weights.items() if c in available_categories}

    if category_weights:
        picked_category = _weighted_choice(category_weights)
    else:
        # Fall back to a uniform pick among available categories
        picked_category = random.choice(list(available_categories))

    pool = [
        s for s in all_role_seeds
        if s.category == picked_category and s.id not in excluded
    ]

    # Step 5: graceful degradation — try other categories
    if not pool:
        for cat in sorted(available_categories):
            if cat == picked_category:
                continue
            pool = [s for s in all_role_seeds if s.category == cat and s.id not in excluded]
            if pool:
                break

    # If everything is excluded, allow any (reset exclusion)
    if not pool:
        pool = all_role_seeds

    return random.choice(pool)


def compute_effective_metrics(
    persisted_metrics: dict[str, float],
    encounter_modifiers: dict[str, float],
) -> dict[str, float]:
    """
    Section 6.3: overlay encounter modifiers on top of persisted metrics.
    encounter_modifiers keys override; all other metrics stay as persisted.
    """
    effective = dict(persisted_metrics)
    effective.update(encounter_modifiers)
    return effective
