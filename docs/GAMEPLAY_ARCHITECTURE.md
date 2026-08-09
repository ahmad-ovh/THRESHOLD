# THRESHOLD — Gameplay Architecture & Backend Specification

> **System Status**: `IMPLEMENTED`  
> **Authoritative Code Location**: `src/` (FastAPI backend, SQLAlchemy models, services, content registry)

---

## 1. Overview & Data Ownership

THRESHOLD follows a **backend-authoritative gameplay architecture**. The Godot client is responsible purely for visual presentation, input handling, spatial positioning, audio, and UI layout. The Python FastAPI backend owns all game logic, persistence, relationship state machines, deterministic scoring formulas, observer triggers, and LLM orchestration.

```text
Godot 4 Client (HTTP / REST)
        ↓
FastAPI Routers (src/routers/interaction.py, player.py)
        ↓
Core Services (scoring, relationship, progression, perception, memory, observer, llm)
        ↓
SQLite Database (threshold.db via Async SQLAlchemy)
```

---

## 2. Database Schema & Data Models (`src/models.py`)

Game state is persisted across five primary database tables:

### 2.1 `players` Table
Stores overall player profile, progression, and skill proficiency.
- `player_id` (`String`, Primary Key)
- `level` (`Integer`, Default: `1`, Range: 1–100)
- `skill_vector_json` (`Text`, JSON string for `{"clarity": float, "empathy": float, "politeness": float, "expression": float}`)
- `xp_progress` (`Float`, Default: `0.0`, Range: 0.0–1.0 within current level)
- `daily_streak` (`Integer`, Default: `0`)
- `created_at`, `last_active_at` (`DateTime(timezone=True)`)

### 2.2 `npc_instances` Table
Per-player runtime state for each NPC encountered.
- `npc_instance_id` (`String`, Primary Key)
- `player_id` (`String`, Foreign Key → `players.player_id`)
- `template_id` (`String`, e.g., `"prof_adler"`, `"barista"`)
- `metrics_json` (`Text`, JSON string tracking metric values, e.g. `{"respect": 0.55, "confidence": 0.45}`)
- `current_state` (`String`, Default: `"neutral"`, resolved by state engine)
- `relationship_tier` (`String`, e.g., `"Acquaintance"`, `"Trusted"`)
- `met_in_person` (`Boolean`, Default: `False`)
- `discovered_facts_json` (`Text`, JSON array of string facts)
- `discovered_connections_json` (`Text`, JSON array of cross-NPC connection strings)
- `perception_summary_json` (`Text`, JSON object summarizing recent encounter outcomes)

### 2.3 `memory_entries` Table
Per-instance memory records accumulated across turns and encounters.
- `id` (`Integer`, Primary Key, Autoincrement)
- `npc_instance_id` (`String`, Foreign Key → `npc_instances.npc_instance_id`)
- `event` (`String`, description of player action / turn text snippet)
- `interpretation` (`String`, mapped interpretation signal, e.g. `"named_own_shortfall_honestly"`)
- `turn` (`Integer`, turn counter)
- `created_at` (`DateTime(timezone=True)`)

### 2.4 `interaction_sessions` Table
Transient active encounter session (discarded upon encounter close).
- `npc_instance_id` (`String`, Primary Key, Foreign Key → `npc_instances.npc_instance_id`)
- `scenario_id` (`String`, e.g., `"final_paper_feedback"`)
- `turn_count` (`Integer`, Default: `0`)
- `conversation_history_json` (`Text`, JSON array of `{"role": "npc"|"player", "text": "..."}`)
- `encounter_modifiers_json` (`Text`, JSON metric overrides for scenario)
- `effective_metrics_json` (`Text`, running metrics during encounter)
- `encounter_over` (`Boolean`, Default: `False`)
- `accumulated_scores_json` (`Text`, array of per-turn dimension scores)
- `narrative_outcome` (`String`, optional outcome selected by LLM)
- `performance_outcome` (`String`, deterministic outcome `"good"` | `"neutral"` | `"poor"`)

### 2.5 `encounter_history` Table
Historical archive of completed encounters used for report generation.
- `id` (`Integer`, Primary Key, Autoincrement)
- `player_id` (`String`, Foreign Key → `players.player_id`)
- `npc_template_id` (`String`)
- `scenario_id` (`String`)
- `performance_outcome` (`String`, `"good"` | `"neutral"` | `"poor"`)
- `narrative_outcome` (`String | None`)
- `avg_scores_json` (`Text`, average scores across encounter)
- `xp_gained` (`Float`)
- `completed_at` (`DateTime(timezone=True)`)

---

## 3. Core Subsystems & Logic Flow

### 3.1 Content Registry (`src/content.py`)
Loads `content/npc_templates.yaml` and `content/scenario_seeds.yaml` once at application startup.
- **16 NPC Templates**: Defines base personality, communication style, initial metric values/min/max, metric update weights, and conditional state rules.
- **25 Scenario Seeds**: Defines category (`everyday_social`, `friendship`, `workplace`, `high_pressure`), tier (1–3), context (premise, stakes, opening line, NPC goal), scoring focus (`primary`, `secondary`), signals (`success_signal`, `failure_signal`), and outcome triggers.
- **Distribution Bands**: Maps player levels (1–30, 31–70, 71–100) to weighted scenario category pools.

### 3.2 State Engine (`src/state_engine.py`)
Deterministic evaluation of NPC `state_rules` against current metric values.
- Supported condition syntax: `<metric> <operator> <number>` chained with `and` / `or` (e.g., `respect >= 0.70 and confidence >= 0.65`).
- Safe execution: Evaluated via custom regex and comparison dicts (zero `eval()` or dynamic execution).

### 3.3 Relationship Service (`src/services/relationship_service.py`)
Computes metric updates after each dialogue turn.
- **Formula**:
  $$\text{raw\_delta} = \sum (\text{turn\_score}[\text{dim}] \times \text{weight})$$
  $$\text{delta} = \text{raw\_delta} \times \text{blend\_factor}\;(0.15)$$
  $$\text{new\_value} = \text{clamp}(\text{old\_value} + \text{delta} - \text{turn\_decay},\;\text{min},\;\text{max})$$
- Resolves new emotional state via `state_engine.py` and relationship tier label via `RelationshipTierConfig`.

### 3.4 Progression Service (`src/services/progression_service.py`)
Calculates XP, level advancement, and skill vector progression.
- **Deterministic XP Formula**:
  Base XP is computed from average turn scores weighted toward the scenario's primary and secondary `scoring_focus`, multiplied by outcome weight (`good`: 1.0, `neutral`: 0.6, `poor`: 0.3) and level dampening.
- **Skill Vector Update**:
  Blends the player's current skill vector (`clarity`, `empathy`, `politeness`, `expression`) slightly toward encounter average scores.
- **Level Up**:
  XP is normalized 0.0–1.0 within each level. Reaching 1.0 increments level (up to max level 100).

### 3.5 Perception Service (`src/services/perception_service.py`)
Builds the Social Perception Layer modal data and maintains the player's Journal entries.
- Calculates presentation mode (`full`, `compact`, `minimal`) based on relationship tier and scenario requirements.
- Performs background extraction of discovered facts and cross-NPC connection mentions upon encounter completion.

### 3.6 Observer Service (`src/services/observer_service.py`)
Monitors behavioral patterns across an NPC's memory entries.
- **Deterministic Trigger**: Fires when count of any single `interpretation` signal $\ge 2$ within an NPC instance's memory.
- When triggered, invokes `llm_service.observer_phrasing()` to generate an insightful reflection line for the player's settlement modal.

---

## 4. Deterministic vs. AI Boundary Matrix

To maintain game balance, predictability, and safety, AI generation is strictly isolated from core game mechanics:

| Subsystem | Deterministic (Authoritative Code) | Generative LLM (AI Pipeline) |
|---|---|---|
| **Turn Scoring** | Dimensional score calculation from signals | Scoring LLM evaluates message against scenario focus |
| **Metric Shifts** | Mathematical update & decay formula | Zero influence |
| **NPC State Engine** | `state_rules` condition evaluation | Zero influence |
| **Relationship Tier** | Metric threshold resolution | Zero influence |
| **Scenario Selection** | Level-banded weighted category pick | Scenario personalization tailors opening line |
| **Dialogue Reply** | Safety turn counters & phase limits | Character voice LLM crafts NPC response text |
| **XP & Level Up** | Exact formula based on performance | Zero influence |
| **Observer Trigger** | Memory entry frequency check ($\ge 2$) | Generates reflection text after trigger fires |
| **Player Journal** | Fact & connection extraction | Synthesizes periodic summary reports |
