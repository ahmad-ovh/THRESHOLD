"""
Progression Service — skill vector aggregation, XP/level calculation.

Section 9 constraints:
  - XP gain is deterministic: same encounter inputs → same XP output.
  - Level thresholds are config-driven (not hardcoded).
  - XP formula inputs: four scored dimensions, seed's scoring_focus,
    encounter outcome, optionally player's current level.
  - The LLM has zero influence over XP calculation.
"""
from __future__ import annotations

from src.config import get_settings
from src.content import ScenarioSeed

settings = get_settings()

# XP weights per outcome
_OUTCOME_XP_MULTIPLIER = {"good": 1.0, "neutral": 0.6, "poor": 0.3}

# Skill vector update weight — weighted toward seed's scoring_focus
_PRIMARY_WEIGHT = 0.5
_SECONDARY_WEIGHT = 0.3
_REMAINING_WEIGHT = 0.1  # each remaining dimension


def compute_xp_gain(
    turn_scores_list: list[dict],
    seed: ScenarioSeed,
    outcome: str,
    player_level: int,
) -> float:
    """
    Deterministic XP formula.

    Base XP = weighted average of primary + secondary scoring_focus dimensions,
              across all turns.
    Final XP = base_xp * outcome_multiplier * level_dampening
    """
    if not turn_scores_list:
        return 0.0

    primary_dim = seed.scoring_focus.primary
    secondary_dim = seed.scoring_focus.secondary

    # Average per-dimension scores across all turns
    n = len(turn_scores_list)
    avg_scores = {
        dim: sum(s.get(dim, 0.5) for s in turn_scores_list) / n
        for dim in ("clarity", "empathy", "politeness", "expression")
    }

    base_xp = avg_scores[primary_dim] * _PRIMARY_WEIGHT + avg_scores[secondary_dim] * _SECONDARY_WEIGHT
    # Add remaining two dimensions at lower weight
    remaining = [d for d in ("clarity", "empathy", "politeness", "expression")
                 if d not in (primary_dim, secondary_dim)]
    for dim in remaining:
        base_xp += avg_scores[dim] * _REMAINING_WEIGHT

    # Outcome multiplier
    multiplier = _OUTCOME_XP_MULTIPLIER.get(outcome, 0.5)
    base_xp *= multiplier

    # Mild level dampening — higher levels gain slightly less XP per encounter
    dampening = max(0.5, 1.0 - (player_level - 1) * 0.005)
    xp_gain = base_xp * dampening

    return round(min(xp_gain, 1.0), 4)  # cap at 1.0 XP per encounter


def compute_skill_vector_update(
    current_vector: dict[str, float],
    turn_scores_list: list[dict],
    seed: ScenarioSeed,
) -> dict[str, float]:
    """
    Update the player's skill vector from this encounter's scores.
    Weighted toward the active seed's scoring_focus.
    """
    if not turn_scores_list:
        return current_vector

    primary_dim = seed.scoring_focus.primary
    secondary_dim = seed.scoring_focus.secondary

    # Average scores
    n = len(turn_scores_list)
    avg = {
        dim: sum(s.get(dim, 0.5) for s in turn_scores_list) / n
        for dim in ("clarity", "empathy", "politeness", "expression")
    }

    # Weights per dimension
    dim_weights = {d: _REMAINING_WEIGHT for d in avg}
    dim_weights[primary_dim] = _PRIMARY_WEIGHT
    dim_weights[secondary_dim] = _SECONDARY_WEIGHT

    new_vector = {}
    for dim in avg:
        w = dim_weights[dim]
        # Blend: move current value slightly toward the encounter average
        new_val = current_vector.get(dim, 0.5) * (1 - w * 0.2) + avg[dim] * (w * 0.2)
        new_vector[dim] = round(max(0.0, min(1.0, new_val)), 4)

    return new_vector


def apply_xp_and_level(
    player_xp_progress: float,
    player_level: int,
    xp_gain: float,
) -> tuple[float, int, bool]:
    """
    Add XP and check for level-up.
    Returns (new_xp_progress, new_level, leveled_up).
    XP is normalised 0.0–1.0 within the current level.
    """
    new_xp = player_xp_progress + xp_gain
    leveled_up = False

    while new_xp >= 1.0 and player_level < settings.max_level:
        new_xp -= 1.0
        player_level += 1
        leveled_up = True

    new_xp = min(new_xp, 1.0)
    return round(new_xp, 4), player_level, leveled_up


def determine_outcome(
    avg_scores: dict[str, float],
    seed: ScenarioSeed,
) -> str:
    """
    Determine encounter outcome (good / neutral / poor) from average scores
    weighted by seed's scoring focus.
    """
    primary_dim = seed.scoring_focus.primary
    secondary_dim = seed.scoring_focus.secondary

    weighted = (
        avg_scores.get(primary_dim, 0.5) * 0.6
        + avg_scores.get(secondary_dim, 0.5) * 0.3
        + sum(
            avg_scores.get(d, 0.5) * 0.05
            for d in ("clarity", "empathy", "politeness", "expression")
            if d not in (primary_dim, secondary_dim)
        )
    )

    if weighted >= 0.65:
        return "good"
    elif weighted >= 0.40:
        return "neutral"
    else:
        return "poor"
