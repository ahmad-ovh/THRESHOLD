"""
Deterministic State Engine — evaluates NPC state_rules against current metric values.

Grammar supported (per spec Section 5.2):
  <metric_name> <operator> <number>
  chained with: and / or
  special: "default"

No arbitrary eval — tokens are parsed explicitly and safely.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from src.content import NpcTemplate

_CONDITION_RE = re.compile(
    r"(?P<metric>[a-zA-Z_][a-zA-Z0-9_]*)\s*"
    r"(?P<op>>=|<=|!=|>|<|==)\s*"
    r"(?P<value>[0-9]*\.?[0-9]+)"
)

_OPERATORS = {
    ">":  lambda a, b: a > b,
    "<":  lambda a, b: a < b,
    ">=": lambda a, b: a >= b,
    "<=": lambda a, b: a <= b,
    "==": lambda a, b: a == b,
    "!=": lambda a, b: a != b,
}


def _evaluate_atom(atom: str, metrics: dict[str, float]) -> bool:
    """Evaluate a single comparison atom."""
    m = _CONDITION_RE.fullmatch(atom.strip())
    if not m:
        raise ValueError(f"Unrecognised condition atom: {atom!r}")
    metric_name = m.group("metric")
    op_str = m.group("op")
    threshold = float(m.group("value"))
    current = metrics.get(metric_name)
    if current is None:
        raise ValueError(f"Metric '{metric_name}' not found in instance metrics.")
    return _OPERATORS[op_str](current, threshold)


def _evaluate_condition(condition: str, metrics: dict[str, float]) -> bool:
    """Evaluate a compound condition (e.g. 'trust >= 0.3 and patience < 0.3')."""
    condition = condition.strip()
    if condition.lower() == "default":
        return True

    # Split on ' or ' first (lower precedence), then ' and '
    or_parts = re.split(r"\bor\b", condition, flags=re.IGNORECASE)
    for or_part in or_parts:
        and_parts = re.split(r"\band\b", or_part, flags=re.IGNORECASE)
        if all(_evaluate_atom(atom, metrics) for atom in and_parts):
            return True
    return False


def resolve_state(template: "NpcTemplate", metrics: dict[str, float]) -> str:
    """
    Evaluate the NPC template's state_rules against the provided metrics.
    Returns the first matching state value. 'default' always matches.
    Raises RuntimeError if no rule matches (should never happen if 'default' is last).
    """
    for rule in template.state_rules:
        if _evaluate_condition(rule.condition, metrics):
            return rule.state
    raise RuntimeError(
        f"No state rule matched for template '{template.id}' — "
        "ensure a 'default' rule is present."
    )
