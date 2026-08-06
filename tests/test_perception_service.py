"""
Unit tests for perception_service.py — Social Perception Layer & Onboarding Projection.
"""
from __future__ import annotations

import pytest
from src.content import NpcTemplate, ScenarioContext, ScenarioSeed
from src.models import NpcInstance, Player
from src.services import perception_service


@pytest.fixture
def mock_template() -> NpcTemplate:
    from src.content import registry
    registry.load()
    tmpl = registry.get_template("barista")
    if tmpl:
        return tmpl
    return NpcTemplate(
        id="barista",
        archetype_role="barista",
        name="Lina",
        base_personality="Friendly and fast-paced",
        communication_style="Direct",
        metrics={},
        metric_updates={},
        state_rules=[],
        tier_definitions=[],
    )


@pytest.fixture
def mock_seed() -> ScenarioSeed:
    from src.content import registry
    registry.load()
    seeds = registry.all_seeds()
    if seeds:
        return seeds[0]
    return ScenarioSeed(
        id="cafe_order_01",
        title="Morning Rush Order",
        compatible_roles=["barista"],
        category="everyday",
        tier=1,
        npc_context_metric_overrides={},
        context=ScenarioContext(
            premise="You enter a busy café during the morning rush. Customers are queuing.",
            stakes="Ordering a drink and getting a feel for the local atmosphere.",
            opening_line_seed="Morning. First time here?",
            npc_goal="Wants to take orders efficiently without long delays.",
        ),
        scoring_focus=ScoringFocus(primary="clarity", secondary="politeness"),
        success_signal="ordered_succinctly",
        failure_signal="wandered_indecisively",
        possible_outcomes=PossibleOutcomes(
            good=OutcomeDetail(trigger="t1", closing_seed="c1"),
            neutral=OutcomeDetail(trigger="t2", closing_seed="c2"),
            poor=OutcomeDetail(trigger="t3", closing_seed="c3"),
        ),
    )


@pytest.fixture
def mock_player() -> Player:
    return Player(player_id="test_player", level=1)


@pytest.fixture
def mock_instance() -> NpcInstance:
    return NpcInstance(
        npc_instance_id="inst_barista",
        player_id="test_player",
        template_id="barista",
        relationship_tier="Stranger",
        metrics_json='{"trust": 0.5}',
    )


def test_calculate_presentation_mode_stranger():
    mode, show_modal = perception_service.calculate_presentation_mode(relationship_tier="Stranger")
    assert mode == "full"
    assert show_modal is True


def test_calculate_presentation_mode_acquaintance():
    mode, show_modal = perception_service.calculate_presentation_mode(relationship_tier="Acquaintance")
    assert mode == "compact"
    assert show_modal is True


def test_calculate_presentation_mode_friend():
    mode, show_modal = perception_service.calculate_presentation_mode(relationship_tier="Friend")
    assert mode == "minimal"
    assert show_modal is False


def test_calculate_presentation_mode_friend_major_event_override():
    # Friend tier + requires_context/is_major_event override
    mode, show_modal = perception_service.calculate_presentation_mode(
        relationship_tier="Friend",
        seed_context={"requires_context": True},
        is_major_event=True,
    )
    assert mode == "full"
    assert show_modal is True


def test_build_perception_layer_first_meeting(mock_template, mock_instance, mock_player, mock_seed):
    layer = perception_service.build_perception_layer(
        template=mock_template,
        instance=mock_instance,
        player=mock_player,
        seed=mock_seed,
    )
    assert layer["show_modal"] is True
    assert layer["presentation_mode"] == "full"
    assert layer["npc_name"] == mock_template.name
    assert layer["npc_role"] == mock_template.archetype_role.capitalize()
    assert layer["location_name"] == "Downtown Café"
    assert layer["relationship_tier"] == "Stranger"
    assert layer["situation"] == mock_seed.context.premise
    assert len(layer["known_facts"]) >= 1
    assert mock_template.name in layer["known_facts"][0]


@pytest.mark.asyncio
async def test_process_encounter_end_perception(mock_instance):
    mock_instance.discovered_facts = ["Lina works at Downtown Café."]
    transcript = [
        {"role": "npc", "text": "Morning!"},
        {"role": "player", "text": "Hi, I'd like an iced latte please."},
    ]
    await perception_service.process_encounter_end_perception(
        instance=mock_instance,
        transcript=transcript,
        encounter_result={"performance_outcome": "good"},
    )

    assert len(mock_instance.discovered_facts) >= 2
    assert "Built rapport with Barista" in mock_instance.discovered_facts[-1]
