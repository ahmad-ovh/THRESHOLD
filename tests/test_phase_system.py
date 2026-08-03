"""
Unit tests for the Deterministic Encounter Phase System and outcome decoupling.
"""
import pytest
from unittest.mock import AsyncMock, patch
from src.services import llm_service
from src.services.progression_service import compute_xp_gain
from src.content import ScenarioSeed, ScenarioContext, ScoringFocus, PossibleOutcomes, OutcomeDetail


def _make_seed() -> ScenarioSeed:
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
        scoring_focus=ScoringFocus(primary="empathy", secondary="clarity"),
        success_signal="acknowledged_feelings_first",
        failure_signal="avoided_emotional_acknowledgment",
        possible_outcomes=PossibleOutcomes(
            good=OutcomeDetail(trigger="Good outcome reached.", closing_seed="That went well."),
            neutral=OutcomeDetail(trigger="Neutral outcome reached.", closing_seed="We'll see."),
            poor=OutcomeDetail(trigger="Poor outcome reached.", closing_seed="That didn't go well."),
        ),
    )


class TestPhaseSystemEnforcement:
    @pytest.mark.asyncio
    @patch("src.services.llm_service._call")
    async def test_development_phase_forces_continuation(self, mock_call):
        """In Development Phase (min_turns_reached=False), early outcomes and early end are suppressed."""
        mock_call.return_value = '{"npc_reply": "Goodbye!", "npc_expression": "warm", "coach_hint": "", "outcome_triggered": "good", "narrative_outcome": "Early success", "end_encounter": true}'

        result = await llm_service.character_voice(
            npc_name="Alex",
            npc_personality="Warm",
            npc_communication_style="Direct",
            npc_state="warm",
            memory_context="",
            conversation_history=[{"role": "player", "text": "Hi"}],
            scenario_context={"premise": "Test", "stakes": "Low", "npc_goal": "Goal"},
            possible_outcomes={"good_trigger": "win", "good_closing_seed": "bye"},
            min_turns_reached=False,  # Development Phase
        )

        assert result["end_encounter"] is False
        assert result["outcome_triggered"] is None
        assert result["narrative_outcome"] is None

    @pytest.mark.asyncio
    @patch("src.services.llm_service._call")
    async def test_resolution_phase_allows_outcome(self, mock_call):
        """In Resolution Phase (min_turns_reached=True), outcomes and encounter end are allowed."""
        mock_call.return_value = '{"npc_reply": "Thanks for talking!", "npc_expression": "satisfied", "coach_hint": "", "outcome_triggered": "good", "narrative_outcome": "Resolved well", "end_encounter": true}'

        result = await llm_service.character_voice(
            npc_name="Alex",
            npc_personality="Warm",
            npc_communication_style="Direct",
            npc_state="warm",
            memory_context="",
            conversation_history=[{"role": "player", "text": "Hi"}],
            scenario_context={"premise": "Test", "stakes": "Low", "npc_goal": "Goal"},
            possible_outcomes={"good_trigger": "win", "good_closing_seed": "bye"},
            min_turns_reached=True,  # Resolution Phase
        )

        assert result["end_encounter"] is True
        assert result["outcome_triggered"] == "good"
        assert result["narrative_outcome"] == "Resolved well"


class TestOutcomeDecoupling:
    def test_xp_uses_performance_outcome_strictly(self):
        """Verify XP calculation relies strictly on the outcome passed to compute_xp_gain (performance_outcome)."""
        seed = _make_seed()
        scores = [{"clarity": 0.8, "empathy": 0.8, "politeness": 0.7, "expression": 0.7}]
        
        xp_good = compute_xp_gain(scores, seed, outcome="good", player_level=1)
        xp_poor = compute_xp_gain(scores, seed, outcome="poor", player_level=1)
        
        assert xp_good > xp_poor
