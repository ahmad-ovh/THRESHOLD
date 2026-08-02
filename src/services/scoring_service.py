"""
Scoring Service — coordinates the Memory Formation pipeline.

Owns: calling LLM Service with player message + session context,
      receiving and returning the four-dimension scores + interpretation label.
Does not own: metric math, dialogue generation, LLM execution internals.
"""
from __future__ import annotations

from src.content import ScenarioSeed
from src.services import llm_service


async def score_message(
    player_message: str,
    seed: ScenarioSeed,
    conversation_history: list[dict],
) -> dict:
    """
    Call the Memory Formation pipeline and return scores + interpretation.

    Returns:
      {
        "clarity": float,
        "empathy": float,
        "politeness": float,
        "expression": float,
        "interpretation": str  — from seed's success/failure vocabulary
      }
    """
    scenario_context = {
        "premise": seed.context.premise,
        "stakes": seed.context.stakes,
        "npc_goal": seed.context.npc_goal,
        "scoring_focus_primary": seed.scoring_focus.primary,
        "scoring_focus_secondary": seed.scoring_focus.secondary,
    }

    vocab = [seed.success_signal, seed.failure_signal]

    result = await llm_service.memory_formation(
        player_message=player_message,
        scenario_context=scenario_context,
        conversation_history=conversation_history,
        interpretation_vocabulary=vocab,
    )

    return {
        "clarity":        result["clarity"],
        "empathy":        result["empathy"],
        "politeness":     result["politeness"],
        "expression":     result["expression"],
        "interpretation": result["interpretation"],
    }
