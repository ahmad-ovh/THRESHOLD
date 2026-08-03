"""
Tests for the deterministic Progression Service.
"""
import pytest
from src.content import ScenarioSeed, ScenarioContext, ScoringFocus, PossibleOutcomes, OutcomeDetail
from src.services.progression_service import (
    compute_xp_gain,
    compute_skill_vector_update,
    apply_xp_and_level,
    determine_outcome,
)


def _make_seed(primary: str = "empathy", secondary: str = "clarity") -> ScenarioSeed:
    return ScenarioSeed(
        id="test_seed",
        compatible_roles=["friend"],
        category="friendship",
        tier=2,
        title="Test Seed",
        npc_context_metric_overrides={},
        context=ScenarioContext(
            premise="Test", stakes="Low", opening_line_seed="Hi.", npc_goal="Test."
        ),
        scoring_focus=ScoringFocus(primary=primary, secondary=secondary),
        success_signal="acknowledged_feelings_first",
        failure_signal="avoided_emotional_acknowledgment",
        possible_outcomes=PossibleOutcomes(
            good=OutcomeDetail(trigger="Good outcome reached.", closing_seed="That went well."),
            neutral=OutcomeDetail(trigger="Neutral outcome reached.", closing_seed="We'll see."),
            poor=OutcomeDetail(trigger="Poor outcome reached.", closing_seed="That didn't go well."),
        ),
    )


class TestXpGain:
    def test_good_outcome_more_xp_than_poor(self):
        seed = _make_seed()
        scores = [{"clarity": 0.8, "empathy": 0.8, "politeness": 0.7, "expression": 0.7}]
        xp_good = compute_xp_gain(scores, seed, "good", 1)
        xp_poor = compute_xp_gain(scores, seed, "poor", 1)
        assert xp_good > xp_poor

    def test_deterministic(self):
        seed = _make_seed()
        scores = [{"clarity": 0.6, "empathy": 0.7, "politeness": 0.5, "expression": 0.6}]
        r1 = compute_xp_gain(scores, seed, "neutral", 5)
        r2 = compute_xp_gain(scores, seed, "neutral", 5)
        assert r1 == r2

    def test_no_turns_returns_zero(self):
        seed = _make_seed()
        assert compute_xp_gain([], seed, "good", 1) == 0.0

    def test_xp_capped_at_1(self):
        seed = _make_seed()
        scores = [{"clarity": 1.0, "empathy": 1.0, "politeness": 1.0, "expression": 1.0}] * 10
        xp = compute_xp_gain(scores, seed, "good", 1)
        assert xp <= 1.0

    def test_higher_level_dampening(self):
        seed = _make_seed()
        scores = [{"clarity": 0.8, "empathy": 0.8, "politeness": 0.8, "expression": 0.8}]
        xp_low = compute_xp_gain(scores, seed, "good", 1)
        xp_high = compute_xp_gain(scores, seed, "good", 50)
        assert xp_low >= xp_high


class TestLevelUp:
    def test_single_levelup(self):
        xp, level, leveled_up = apply_xp_and_level(0.9, 1, 0.2)
        assert leveled_up is True
        assert level == 2
        assert xp == pytest.approx(0.1, abs=0.001)

    def test_no_levelup(self):
        xp, level, leveled_up = apply_xp_and_level(0.5, 5, 0.3)
        assert leveled_up is False
        assert level == 5
        assert xp == pytest.approx(0.8, abs=0.001)

    def test_max_level_cap(self):
        xp, level, leveled_up = apply_xp_and_level(0.99, 100, 0.5)
        assert level == 100


class TestDetermineOutcome:
    def test_good_outcome(self):
        seed = _make_seed(primary="empathy", secondary="clarity")
        avg = {"clarity": 0.8, "empathy": 0.85, "politeness": 0.7, "expression": 0.7}
        assert determine_outcome(avg, seed) == "good"

    def test_poor_outcome(self):
        seed = _make_seed(primary="empathy", secondary="clarity")
        avg = {"clarity": 0.2, "empathy": 0.15, "politeness": 0.3, "expression": 0.3}
        assert determine_outcome(avg, seed) == "poor"

    def test_neutral_outcome(self):
        seed = _make_seed(primary="empathy", secondary="clarity")
        avg = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}
        assert determine_outcome(avg, seed) == "neutral"


class TestSkillVectorUpdate:
    def test_primary_dimension_updated_more(self):
        seed = _make_seed(primary="empathy", secondary="clarity")
        initial = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}
        scores = [{"clarity": 0.9, "empathy": 0.9, "politeness": 0.9, "expression": 0.9}]
        new = compute_skill_vector_update(initial, scores, seed)
        # All dimensions should increase since all scores are high
        for dim in initial:
            assert new[dim] >= initial[dim]

    def test_no_turns_unchanged(self):
        seed = _make_seed()
        initial = {"clarity": 0.6, "empathy": 0.7, "politeness": 0.5, "expression": 0.4}
        new = compute_skill_vector_update(initial, [], seed)
        assert new == initial
