"""
Tests for the deterministic Observer trigger check.
"""
import pytest
from unittest.mock import AsyncMock, patch

from src.services.observer_service import _check_trigger


class FakeEntry:
    def __init__(self, interpretation: str, turn: int = 1, event: str = "test"):
        self.interpretation = interpretation
        self.turn = turn
        self.event = event


class TestObserverTrigger:
    def test_no_trigger_with_one_occurrence(self):
        entries = [
            FakeEntry("avoided_emotional_acknowledgment"),
            FakeEntry("owned_mistake_plainly"),
        ]
        fired, interp, matching = _check_trigger(entries)
        assert fired is False

    def test_trigger_fires_at_two_occurrences(self):
        entries = [
            FakeEntry("avoided_emotional_acknowledgment"),
            FakeEntry("owned_mistake_plainly"),
            FakeEntry("avoided_emotional_acknowledgment"),
        ]
        fired, interp, matching = _check_trigger(entries)
        assert fired is True
        assert interp == "avoided_emotional_acknowledgment"
        assert len(matching) == 2

    def test_trigger_fires_with_three_occurrences(self):
        entries = [
            FakeEntry("avoided_emotional_acknowledgment"),
            FakeEntry("avoided_emotional_acknowledgment"),
            FakeEntry("avoided_emotional_acknowledgment"),
        ]
        fired, interp, matching = _check_trigger(entries)
        assert fired is True
        assert len(matching) == 3

    def test_no_trigger_with_empty_entries(self):
        fired, interp, matching = _check_trigger([])
        assert fired is False

    def test_picks_first_interpretation_that_meets_threshold(self):
        """When multiple interpretations repeat, one must trigger (any matching)."""
        entries = [
            FakeEntry("label_A"),
            FakeEntry("label_B"),
            FakeEntry("label_A"),
            FakeEntry("label_B"),
        ]
        fired, interp, matching = _check_trigger(entries)
        assert fired is True
        assert interp in {"label_A", "label_B"}

    @pytest.mark.asyncio
    async def test_run_observer_calls_llm_when_triggered(self):
        entries = [
            FakeEntry("avoided_emotional_acknowledgment", turn=1),
            FakeEntry("avoided_emotional_acknowledgment", turn=3),
        ]
        with patch(
            "src.services.observer_service.llm_service.observer_phrasing",
            new_callable=AsyncMock,
            return_value={"message": "A pattern repeated."},
        ):
            from src.services.observer_service import run_observer
            result = await run_observer(entries)
            assert result["fired"] is True
            assert result["message"] == "A pattern repeated."

    @pytest.mark.asyncio
    async def test_run_observer_no_llm_when_not_triggered(self):
        entries = [FakeEntry("avoided_emotional_acknowledgment", turn=1)]
        with patch(
            "src.services.observer_service.llm_service.observer_phrasing",
            new_callable=AsyncMock,
        ) as mock_llm:
            from src.services.observer_service import run_observer
            result = await run_observer(entries)
            assert result["fired"] is False
            mock_llm.assert_not_called()
