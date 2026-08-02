"""
Relationship Service — metric update calculations and relationship tier resolution.

Owns:
  - the metric update formula (Section 5.1)
  - relationship tier resolution (Section 5.3)

Does not own: the NPC Instance data entity itself, scoring, or dialogue.
"""
from __future__ import annotations

from src.content import NpcTemplate, registry
from src.state_engine import resolve_state

# Blending factor — how aggressively the new delta moves the current value.
# Tunable implementation detail (Section 5.1). Set to direct add with dampening.
_DELTA_BLEND_FACTOR = 0.15


def compute_metric_updates(
    template: NpcTemplate,
    current_metrics: dict[str, float],
    turn_scores: dict[str, float],
) -> dict[str, float]:
    """
    Given the four turn scores and the NPC template's metric_updates config,
    compute the new metric values.

    Formula (Section 5.1):
      raw_delta = sum(score[dim] * weight for dim, weight in influenced_by)
      delta = raw_delta * BLEND_FACTOR  (tunable dampening)
      new_value = clamp(old_value + delta - turn_decay, min, max)
    """
    new_metrics = dict(current_metrics)

    for metric_name, update_def in template.metric_updates.items():
        old_value = current_metrics.get(metric_name, 0.0)
        metric_def = template.metrics.get(metric_name)
        if metric_def is None:
            continue

        # Weighted contribution from scored dimensions
        raw_delta = sum(
            turn_scores.get(dim, 0.0) * weight
            for dim, weight in update_def.influenced_by.items()
        )
        # Blend toward the raw delta rather than adding it directly
        delta = raw_delta * _DELTA_BLEND_FACTOR

        new_value = old_value + delta - update_def.turn_decay
        new_value = max(metric_def.min, min(metric_def.max, new_value))
        new_metrics[metric_name] = round(new_value, 4)

    return new_metrics


def resolve_tier(template: NpcTemplate, metrics: dict[str, float]) -> str:
    """Derive the relationship tier label from trust and archetype_role."""
    trust = metrics.get("trust", 0.5)
    tier_cfg = registry.tier_config()
    return tier_cfg.resolve(trust, template.archetype_role)


def update_npc_instance_metrics(
    template: NpcTemplate,
    instance_metrics: dict[str, float],
    turn_scores: dict[str, float],
) -> tuple[dict[str, float], str, str]:
    """
    High-level call: compute new metrics → resolve state → resolve tier.
    Returns (new_metrics, new_state, new_tier).
    """
    new_metrics = compute_metric_updates(template, instance_metrics, turn_scores)
    new_state = resolve_state(template, new_metrics)
    new_tier = resolve_tier(template, new_metrics)
    return new_metrics, new_state, new_tier
