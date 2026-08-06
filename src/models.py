"""
SQLAlchemy ORM models.

Tables:
  players            — Player record
  npc_instances      — Per-player NPC instance (persistent relationship state)
  memory_entries     — Per-instance memory entries
  interaction_sessions — Active encounter session (transient, discarded at end)
  encounter_history  — Completed encounter summaries used by Progression / Report
"""
import json
from datetime import datetime, timezone
from sqlalchemy import (
    String, Float, Integer, Boolean, DateTime, ForeignKey, Text
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Player(Base):
    __tablename__ = "players"

    player_id: Mapped[str] = mapped_column(String, primary_key=True)
    level: Mapped[int] = mapped_column(Integer, default=1)
    # skill_vector stored as JSON string
    skill_vector_json: Mapped[str] = mapped_column(
        Text,
        default='{"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}',
    )
    xp_progress: Mapped[float] = mapped_column(Float, default=0.0)
    daily_streak: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    last_active_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    npc_instances: Mapped[list["NpcInstance"]] = relationship(
        "NpcInstance", back_populates="player", cascade="all, delete-orphan"
    )
    encounter_history: Mapped[list["EncounterHistory"]] = relationship(
        "EncounterHistory", back_populates="player", cascade="all, delete-orphan"
    )

    @property
    def skill_vector(self) -> dict:
        return json.loads(self.skill_vector_json)

    @skill_vector.setter
    def skill_vector(self, value: dict) -> None:
        self.skill_vector_json = json.dumps(value)


class NpcInstance(Base):
    __tablename__ = "npc_instances"

    npc_instance_id: Mapped[str] = mapped_column(String, primary_key=True)
    player_id: Mapped[str] = mapped_column(String, ForeignKey("players.player_id"))
    template_id: Mapped[str] = mapped_column(String)
    # metrics stored as JSON string
    metrics_json: Mapped[str] = mapped_column(Text, default="{}")
    current_state: Mapped[str] = mapped_column(String, default="neutral")
    relationship_tier: Mapped[str] = mapped_column(String, default="")
    discovered_facts_json: Mapped[str] = mapped_column(Text, default="[]")
    perception_summary_json: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    player: Mapped["Player"] = relationship("Player", back_populates="npc_instances")
    memory_entries: Mapped[list["MemoryEntry"]] = relationship(
        "MemoryEntry", back_populates="npc_instance", cascade="all, delete-orphan"
    )
    session: Mapped["InteractionSession | None"] = relationship(
        "InteractionSession", back_populates="npc_instance", cascade="all, delete-orphan", uselist=False
    )

    @property
    def metrics(self) -> dict:
        return json.loads(self.metrics_json)

    @metrics.setter
    def metrics(self, value: dict) -> None:
        self.metrics_json = json.dumps(value)

    @property
    def discovered_facts(self) -> list[str]:
        try:
            return json.loads(self.discovered_facts_json)
        except Exception:
            return []

    @discovered_facts.setter
    def discovered_facts(self, value: list[str]) -> None:
        self.discovered_facts_json = json.dumps(value)


class MemoryEntry(Base):
    __tablename__ = "memory_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    npc_instance_id: Mapped[str] = mapped_column(String, ForeignKey("npc_instances.npc_instance_id"))
    event: Mapped[str] = mapped_column(String)
    interpretation: Mapped[str] = mapped_column(String)
    turn: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    npc_instance: Mapped["NpcInstance"] = relationship("NpcInstance", back_populates="memory_entries")


class InteractionSession(Base):
    __tablename__ = "interaction_sessions"

    npc_instance_id: Mapped[str] = mapped_column(
        String, ForeignKey("npc_instances.npc_instance_id"), primary_key=True
    )
    scenario_id: Mapped[str] = mapped_column(String)
    turn_count: Mapped[int] = mapped_column(Integer, default=0)
    # conversation_history stored as JSON array
    conversation_history_json: Mapped[str] = mapped_column(Text, default="[]")
    # encounter_modifiers stored as JSON
    encounter_modifiers_json: Mapped[str] = mapped_column(Text, default="{}")
    # effective_metrics: running metrics for this encounter (not persisted to instance until end)
    effective_metrics_json: Mapped[str] = mapped_column(Text, default="{}")
    encounter_over: Mapped[bool] = mapped_column(Boolean, default=False)
    # accumulated turn scores for progression at encounter end
    accumulated_scores_json: Mapped[str] = mapped_column(Text, default="[]")
    # narrative outcome selected by Character Voice LLM (null until triggered)
    narrative_outcome: Mapped[str | None] = mapped_column(String, nullable=True, default=None)
    # performance outcome calculated deterministically (null until evaluated)
    performance_outcome: Mapped[str | None] = mapped_column(String, nullable=True, default=None)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    npc_instance: Mapped["NpcInstance"] = relationship("NpcInstance", back_populates="session")

    @property
    def conversation_history(self) -> list:
        return json.loads(self.conversation_history_json)

    @conversation_history.setter
    def conversation_history(self, value: list) -> None:
        self.conversation_history_json = json.dumps(value)

    @property
    def encounter_modifiers(self) -> dict:
        return json.loads(self.encounter_modifiers_json)

    @encounter_modifiers.setter
    def encounter_modifiers(self, value: dict) -> None:
        self.encounter_modifiers_json = json.dumps(value)

    @property
    def effective_metrics(self) -> dict:
        return json.loads(self.effective_metrics_json)

    @effective_metrics.setter
    def effective_metrics(self, value: dict) -> None:
        self.effective_metrics_json = json.dumps(value)

    @property
    def accumulated_scores(self) -> list:
        return json.loads(self.accumulated_scores_json)

    @accumulated_scores.setter
    def accumulated_scores(self, value: list) -> None:
        self.accumulated_scores_json = json.dumps(value)


class EncounterHistory(Base):
    __tablename__ = "encounter_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[str] = mapped_column(String, ForeignKey("players.player_id"))
    npc_template_id: Mapped[str] = mapped_column(String)
    scenario_id: Mapped[str] = mapped_column(String)
    performance_outcome: Mapped[str] = mapped_column(String, default="")  # "good" | "neutral" | "poor"
    narrative_outcome: Mapped[str | None] = mapped_column(String, nullable=True, default=None)
    # average scores for this encounter
    avg_scores_json: Mapped[str] = mapped_column(Text, default="{}")
    xp_gained: Mapped[float] = mapped_column(Float, default=0.0)
    completed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    player: Mapped["Player"] = relationship("Player", back_populates="encounter_history")

    @property
    def outcome(self) -> str:
        return self.performance_outcome

    @outcome.setter
    def outcome(self, value: str) -> None:
        self.performance_outcome = value

    @property
    def avg_scores(self) -> dict:
        return json.loads(self.avg_scores_json)

    @avg_scores.setter
    def avg_scores(self, value: dict) -> None:
        self.avg_scores_json = json.dumps(value)

