"""
Tests for the deterministic State Engine.
"""
import pytest
from src.content import NpcTemplate, MetricDef, MetricUpdateDef, StateRule
from src.state_engine import resolve_state, _evaluate_condition


def _make_sara_template() -> NpcTemplate:
    return NpcTemplate(
        id="sara",
        archetype_role="friend",
        name="Sara",
        base_personality="Direct but caring.",
        communication_style="Casual.",
        metrics={
            "trust":    MetricDef(start=0.7, min=0.0, max=1.0),
            "patience": MetricDef(start=0.6, min=0.0, max=1.0),
            "openness": MetricDef(start=0.4, min=0.0, max=1.0),
        },
        metric_updates={
            "trust":    MetricUpdateDef(influenced_by={"empathy": 0.6, "clarity": 0.4}, turn_decay=0.0),
            "patience": MetricUpdateDef(influenced_by={"politeness": 1.0}, turn_decay=0.05),
            "openness": MetricUpdateDef(influenced_by={"expression": 0.7, "empathy": 0.3}, turn_decay=0.0),
        },
        state_rules=[
            StateRule(condition="trust < 0.3", state="guarded"),
            StateRule(condition="trust >= 0.3 and patience < 0.3", state="irritated"),
            StateRule(condition="trust >= 0.6 and openness >= 0.6", state="warm"),
            StateRule(condition="default", state="neutral"),
        ],
    )


class TestStateEngine:
    def test_guarded_state(self):
        template = _make_sara_template()
        metrics = {"trust": 0.2, "patience": 0.8, "openness": 0.5}
        assert resolve_state(template, metrics) == "guarded"

    def test_irritated_state(self):
        template = _make_sara_template()
        metrics = {"trust": 0.5, "patience": 0.2, "openness": 0.5}
        assert resolve_state(template, metrics) == "irritated"

    def test_warm_state(self):
        template = _make_sara_template()
        metrics = {"trust": 0.75, "patience": 0.6, "openness": 0.7}
        assert resolve_state(template, metrics) == "warm"

    def test_neutral_state_default(self):
        template = _make_sara_template()
        metrics = {"trust": 0.5, "patience": 0.5, "openness": 0.3}
        assert resolve_state(template, metrics) == "neutral"

    def test_guarded_takes_priority_over_warm(self):
        """trust < 0.3 should fire before trust >= 0.6 and openness >= 0.6"""
        template = _make_sara_template()
        # This is a logically inconsistent state but tests rule ordering
        metrics = {"trust": 0.25, "patience": 0.8, "openness": 0.9}
        assert resolve_state(template, metrics) == "guarded"

    def test_boundary_trust_exactly_0_3(self):
        """trust = 0.3 should NOT trigger 'guarded' (condition: trust < 0.3)"""
        template = _make_sara_template()
        metrics = {"trust": 0.3, "patience": 0.5, "openness": 0.3}
        state = resolve_state(template, metrics)
        assert state != "guarded"

    def test_condition_parser_or(self):
        metrics = {"trust": 0.2, "patience": 0.8}
        assert _evaluate_condition("trust < 0.3 or patience < 0.5", metrics) is True

    def test_condition_parser_and(self):
        metrics = {"trust": 0.5, "patience": 0.2}
        assert _evaluate_condition("trust >= 0.3 and patience < 0.3", metrics) is True

    def test_condition_default(self):
        assert _evaluate_condition("default", {}) is True

    def test_missing_metric_raises(self):
        with pytest.raises(ValueError):
            _evaluate_condition("nonexistent > 0.5", {"trust": 0.5})


class TestStateEngineEdgeCases:
    def test_no_default_rule_raises(self):
        """If no rule matches and there is no 'default', a RuntimeError is raised."""
        template = NpcTemplate(
            id="t",
            archetype_role="friend",
            name="T",
            base_personality="",
            communication_style="",
            metrics={"trust": MetricDef(start=0.5, min=0.0, max=1.0)},
            metric_updates={},
            state_rules=[
                StateRule(condition="trust < 0.0", state="impossible"),
            ],
        )
        with pytest.raises(RuntimeError):
            resolve_state(template, {"trust": 0.5})
