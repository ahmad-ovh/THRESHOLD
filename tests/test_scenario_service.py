"""
Tests for the deterministic Scenario Service.
"""
import pytest
from src.content import registry
from src.services.scenario_service import select_seed, compute_effective_metrics


class TestScenarioSelection:
    @classmethod
    def setup_class(cls):
        registry.load()

    def test_select_seed_for_friend(self):
        seed = select_seed("friend", player_level=5)
        assert "friend" in seed.compatible_roles

    def test_select_seed_for_teacher(self):
        seed = select_seed("teacher", player_level=5)
        assert "teacher" in seed.compatible_roles

    def test_select_seed_for_colleague(self):
        seed = select_seed("colleague", player_level=5)
        assert "colleague" in seed.compatible_roles

    def test_select_seed_for_client(self):
        seed = select_seed("client", player_level=5)
        assert "client" in seed.compatible_roles

    def test_exclusion_list_respected(self):
        """Excluded seeds should not be returned when alternatives exist."""
        # Get all seeds for friend
        from src.content import registry as r
        friend_seeds = r.seeds_for_role("friend")
        all_ids = [s.id for s in friend_seeds]
        # Exclude all but one
        excluded = all_ids[:-1]
        seed = select_seed("friend", player_level=5, excluded_seed_ids=excluded)
        assert seed.id == all_ids[-1]

    def test_unknown_role_raises(self):
        with pytest.raises(ValueError):
            select_seed("wizard", player_level=5)

    def test_level_1_30_prefers_everyday(self):
        """At low level, everyday_social should come up more often than high_pressure."""
        import random
        random.seed(42)
        categories = [select_seed("colleague", player_level=5).category for _ in range(50)]
        everyday_count = categories.count("everyday_social")
        high_pressure_count = categories.count("high_pressure")
        assert everyday_count > high_pressure_count


class TestEffectiveMetrics:
    def test_overrides_applied(self):
        persisted = {"trust": 0.7, "openness": 0.5}
        overrides = {"openness": 0.3}
        effective = compute_effective_metrics(persisted, overrides)
        assert effective["openness"] == 0.3
        assert effective["trust"] == 0.7

    def test_no_overrides_unchanged(self):
        persisted = {"trust": 0.7, "openness": 0.5}
        effective = compute_effective_metrics(persisted, {})
        assert effective == persisted

    def test_persisted_not_mutated(self):
        persisted = {"trust": 0.7, "openness": 0.5}
        compute_effective_metrics(persisted, {"openness": 0.1})
        assert persisted["openness"] == 0.5  # original unchanged
