"""
Tests for the deterministic Relationship Service.
"""
import pytest
from src.content import NpcTemplate, MetricDef, MetricUpdateDef, StateRule
from src.services.relationship_service import compute_metric_updates, resolve_tier


def _make_sara_template() -> NpcTemplate:
    return NpcTemplate(
        id="sara",
        archetype_role="friend",
        name="Sara",
        base_personality="",
        communication_style="",
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
        state_rules=[StateRule(condition="default", state="neutral")],
    )


class TestMetricUpdates:
    def test_trust_increases_with_high_empathy_clarity(self):
        template = _make_sara_template()
        metrics = {"trust": 0.5, "patience": 0.5, "openness": 0.4}
        turn_scores = {"clarity": 0.9, "empathy": 0.9, "politeness": 0.5, "expression": 0.5}
        new_metrics = compute_metric_updates(template, metrics, turn_scores)
        assert new_metrics["trust"] > metrics["trust"]

    def test_trust_decreases_with_low_scores(self):
        template = _make_sara_template()
        metrics = {"trust": 0.5, "patience": 0.5, "openness": 0.4}
        # Scores of 0 should not increase trust
        turn_scores = {"clarity": 0.0, "empathy": 0.0, "politeness": 0.0, "expression": 0.0}
        new_metrics = compute_metric_updates(template, metrics, turn_scores)
        assert new_metrics["trust"] <= metrics["trust"]

    def test_patience_decays_each_turn(self):
        """patience has turn_decay = 0.05, so it decreases even at zero turn scores."""
        template = _make_sara_template()
        metrics = {"trust": 0.5, "patience": 0.5, "openness": 0.4}
        turn_scores = {"clarity": 0.0, "empathy": 0.0, "politeness": 0.0, "expression": 0.0}
        new_metrics = compute_metric_updates(template, metrics, turn_scores)
        assert new_metrics["patience"] < metrics["patience"]

    def test_metrics_clamped_at_max(self):
        template = _make_sara_template()
        metrics = {"trust": 0.99, "patience": 0.99, "openness": 0.99}
        turn_scores = {"clarity": 1.0, "empathy": 1.0, "politeness": 1.0, "expression": 1.0}
        new_metrics = compute_metric_updates(template, metrics, turn_scores)
        for v in new_metrics.values():
            assert v <= 1.0

    def test_metrics_clamped_at_min(self):
        template = _make_sara_template()
        metrics = {"trust": 0.01, "patience": 0.01, "openness": 0.01}
        turn_scores = {"clarity": 0.0, "empathy": 0.0, "politeness": 0.0, "expression": 0.0}
        new_metrics = compute_metric_updates(template, metrics, turn_scores)
        for v in new_metrics.values():
            assert v >= 0.0

    def test_determinism(self):
        """Same inputs must always produce the same outputs."""
        template = _make_sara_template()
        metrics = {"trust": 0.6, "patience": 0.5, "openness": 0.4}
        scores = {"clarity": 0.7, "empathy": 0.6, "politeness": 0.8, "expression": 0.5}
        r1 = compute_metric_updates(template, metrics, scores)
        r2 = compute_metric_updates(template, metrics, scores)
        assert r1 == r2


class TestRelationshipTier:
    @classmethod
    def setup_class(cls):
        from src.content import registry
        registry.load()

    def test_friend_tiers(self):
        """Test all five friend tier thresholds."""
        from src.content import registry
        template = registry.get_template("sara")
        assert template is not None

        # trust = 0.0 -> Stranger
        assert resolve_tier(template, {"trust": 0.0}) == "Stranger"
        # trust = 0.25 -> Acquaintance
        assert resolve_tier(template, {"trust": 0.25}) == "Acquaintance"
        # trust = 0.45 -> Comfortable
        assert resolve_tier(template, {"trust": 0.45}) == "Comfortable"
        # trust = 0.65 -> Trusted
        assert resolve_tier(template, {"trust": 0.65}) == "Trusted"
        # trust = 0.85 -> Close Friend
        assert resolve_tier(template, {"trust": 0.85}) == "Close Friend"

    def test_teacher_tiers(self):
        from src.content import registry
        template = registry.get_template("mr_teo")
        assert template is not None
        assert resolve_tier(template, {"trust": 0.0}) == "Unfamiliar"
        assert resolve_tier(template, {"trust": 0.85}) == "Regarded Highly"
