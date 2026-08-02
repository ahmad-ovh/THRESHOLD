"""
Content registry — loads and validates NPC templates and scenario seeds at startup.
All runtime code accesses content through this module; YAML files are never read again after init.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml


CONTENT_DIR = Path(__file__).parent.parent / "content"


@dataclass
class MetricDef:
    start: float
    min: float
    max: float


@dataclass
class MetricUpdateDef:
    influenced_by: dict[str, float]
    turn_decay: float


@dataclass
class StateRule:
    condition: str  # e.g. "trust < 0.3" | "default"
    state: str


@dataclass
class NpcTemplate:
    id: str
    archetype_role: str  # friend | teacher | colleague | client
    name: str
    base_personality: str
    communication_style: str
    metrics: dict[str, MetricDef]
    metric_updates: dict[str, MetricUpdateDef]
    state_rules: list[StateRule]


@dataclass
class ScenarioContext:
    premise: str
    stakes: str
    opening_line_seed: str
    npc_goal: str


@dataclass
class ScoringFocus:
    primary: str
    secondary: str


@dataclass
class PossibleOutcomes:
    good: str
    neutral: str
    poor: str


@dataclass
class ScenarioSeed:
    id: str
    compatible_roles: list[str]
    category: str
    tier: int
    title: str
    npc_context_metric_overrides: dict[str, float]
    context: ScenarioContext
    scoring_focus: ScoringFocus
    success_signal: str
    failure_signal: str
    possible_outcomes: PossibleOutcomes

    @property
    def interpretation_vocabulary(self) -> set[str]:
        return {self.success_signal, self.failure_signal}


@dataclass
class DistributionBand:
    level_range: tuple[int, int]
    weights: dict[str, int]


@dataclass
class RelationshipTierConfig:
    thresholds: list[float]
    labels: dict[str, list[str]]

    def resolve(self, trust: float, archetype_role: str) -> str:
        labels = self.labels.get(archetype_role, self.labels.get("friend", ["Unknown"]))
        tier_index = 0
        for i, threshold in enumerate(self.thresholds):
            if trust >= threshold:
                tier_index = i
        return labels[tier_index]


class ContentRegistry:
    """Singleton — populated once at startup."""

    def __init__(self) -> None:
        self._templates: dict[str, NpcTemplate] = {}
        self._seeds: dict[str, ScenarioSeed] = {}
        self._distribution_bands: list[DistributionBand] = []
        self._tier_config: RelationshipTierConfig | None = None

    def load(self) -> None:
        self._load_templates()
        self._load_seeds()

    # ------------------------------------------------------------------ #
    #  Loaders
    # ------------------------------------------------------------------ #

    def _load_templates(self) -> None:
        path = CONTENT_DIR / "npc_templates.yaml"
        with open(path, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        for raw in data["npcs"]:
            t = NpcTemplate(
                id=raw["id"],
                archetype_role=raw["archetype_role"],
                name=raw["name"],
                base_personality=raw["base_personality"],
                communication_style=raw["communication_style"],
                metrics={
                    k: MetricDef(**v) for k, v in raw["metrics"].items()
                },
                metric_updates={
                    k: MetricUpdateDef(
                        influenced_by=v["influenced_by"],
                        turn_decay=v["turn_decay"],
                    )
                    for k, v in raw["metric_updates"].items()
                },
                state_rules=[
                    StateRule(condition=r["condition"], state=r["state"])
                    for r in raw["state_rules"]
                ],
            )
            self._templates[t.id] = t

    def _load_seeds(self) -> None:
        path = CONTENT_DIR / "scenario_seeds.yaml"
        with open(path, encoding="utf-8") as f:
            data = yaml.safe_load(f)

        for raw in data["seeds"]:
            seed = ScenarioSeed(
                id=raw["id"],
                compatible_roles=raw["compatible_roles"],
                category=raw["category"],
                tier=raw["tier"],
                title=raw["title"],
                npc_context_metric_overrides=raw.get("npc_context", {}).get("metric_overrides", {}),
                context=ScenarioContext(**raw["context"]),
                scoring_focus=ScoringFocus(**raw["scoring_focus"]),
                success_signal=raw["success_signal"],
                failure_signal=raw["failure_signal"],
                possible_outcomes=PossibleOutcomes(**raw["possible_outcomes"]),
            )
            self._seeds[seed.id] = seed

        self._distribution_bands = [
            DistributionBand(
                level_range=(b["level_range"][0], b["level_range"][1]),
                weights=b["weights"],
            )
            for b in data["distribution_bands"]
        ]

        rt = data["relationship_tiers"]
        self._tier_config = RelationshipTierConfig(
            thresholds=rt["thresholds"],
            labels=rt["labels"],
        )

        self._validate_seeds()

    def _validate_seeds(self) -> None:
        """
        Validate that metric_overrides in seeds reference defined metrics on the
        appropriate NPC templates (Section 6.3).
        """
        for seed in self._seeds.values():
            if not seed.npc_context_metric_overrides:
                continue
            for role in seed.compatible_roles:
                templates_for_role = [
                    t for t in self._templates.values() if t.archetype_role == role
                ]
                for template in templates_for_role:
                    for metric_key in seed.npc_context_metric_overrides:
                        if metric_key not in template.metrics:
                            raise ValueError(
                                f"Seed '{seed.id}' references undefined metric "
                                f"'{metric_key}' on template '{template.id}' "
                                f"(role: {role})."
                            )

    # ------------------------------------------------------------------ #
    #  Public accessors
    # ------------------------------------------------------------------ #

    def get_template(self, npc_id: str) -> NpcTemplate | None:
        return self._templates.get(npc_id)

    def get_seed(self, seed_id: str) -> ScenarioSeed | None:
        return self._seeds.get(seed_id)

    def all_templates(self) -> list[NpcTemplate]:
        return list(self._templates.values())

    def all_seeds(self) -> list[ScenarioSeed]:
        return list(self._seeds.values())

    def seeds_for_role(self, archetype_role: str) -> list[ScenarioSeed]:
        return [s for s in self._seeds.values() if archetype_role in s.compatible_roles]

    def distribution_bands(self) -> list[DistributionBand]:
        return self._distribution_bands

    def tier_config(self) -> RelationshipTierConfig:
        if self._tier_config is None:
            raise RuntimeError("Content not loaded")
        return self._tier_config


# Module-level singleton
registry = ContentRegistry()
