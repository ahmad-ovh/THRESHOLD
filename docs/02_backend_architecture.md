# THRESHOLD — Backend Architecture

## Overall Structure

THRESHOLD is a **FastAPI application** backed by an **async SQLite database** (via SQLAlchemy + aiosqlite). All game logic runs server-side. There is no frontend in this repository.

```
THRESHOLD/
├── content/                   # Game content (YAML — read-only at runtime)
│   ├── npc_templates.yaml
│   └── scenario_seeds.yaml
├── src/
│   ├── main.py                # FastAPI application factory + startup
│   ├── config.py              # Settings (pydantic-settings, .env)
│   ├── database.py            # Async SQLAlchemy engine + session factory
│   ├── models.py              # ORM table definitions
│   ├── content.py             # Content registry (loaded once at startup)
│   ├── state_engine.py        # Deterministic NPC state rule evaluator
│   ├── routers/
│   │   ├── interaction.py     # /interaction/* — all game logic endpoints
│   │   └── player.py          # /player/* — player management
│   └── services/
│       ├── llm_service.py     # All LLM calls (5 pipelines)
│       ├── memory_service.py  # Memory entry CRUD
│       ├── npc_service.py     # NPC instance resolution/creation
│       ├── observer_service.py # Observer trigger check + phrasing
│       ├── player_service.py  # Player CRUD + reset
│       ├── progression_service.py # XP, level, skill vector
│       ├── relationship_service.py # Metric update formula + tier resolution
│       ├── scenario_service.py # Seed selection + effective metrics
│       └── scoring_service.py # Message scoring (wraps LLM memory formation)
├── tests/                     # pytest unit tests (deterministic services only)
├── demo_flow.py               # End-to-end demo script
├── requirements.txt
└── pytest.ini
```

---

## Technology Stack

| Component | Library | Version |
|---|---|---|
| Web framework | FastAPI | >=0.111.0 |
| ASGI server | uvicorn[standard] | >=0.29.0 |
| ORM | SQLAlchemy (async) | >=2.0.30 |
| Database driver | aiosqlite | >=0.19.0 |
| Settings | pydantic-settings | >=2.3.0 |
| Validation | pydantic | >=2.7.0 |
| LLM client | openai (SDK) | >=1.30.0 |
| Content | pyyaml | >=6.0.1 |
| HTTP client (tests/demo) | requests, httpx | >=0.27.0 |
| Testing | pytest, pytest-asyncio, anyio | >=8.0.0 |

---

## Application Startup Sequence

1. `config.py` loads settings from `.env` (or environment variables)
2. `main.py` creates the FastAPI `app` instance and attaches CORS middleware
3. On `startup` event:
   a. `registry.load()` reads and validates `content/npc_templates.yaml` and `content/scenario_seeds.yaml`; validates metric override keys against template metrics
   b. `init_db()` creates the SQLAlchemy async engine and calls `Base.metadata.create_all` — all tables are created if they do not exist
4. Routers are registered: `/interaction/*` and `/player/*`

After startup, content is immutable in memory. YAML files are never re-read.

---

## Request Flow — POST /interaction/message (typical turn)

This is the hottest path. The sequence for a single player turn:

```
HTTP POST /interaction/message
  │
  ├─ Validate request body (pydantic)
  ├─ Load NPC template from registry (sync, in-memory)
  ├─ Load NpcInstance from DB (or 404)
  ├─ Load InteractionSession from DB (or 404)
  ├─ Load Player from DB
  ├─ Load ScenarioSeed from registry (sync, in-memory)
  ├─ Guard: session.encounter_over → 400
  │
  ├─ Append player message to conversation_history
  │
  ├─ SCORING SERVICE
  │   └─ LLM: Memory Formation pipeline
  │       Input:  player message, scenario context, conversation history, vocab
  │       Output: clarity, empathy, politeness, expression, interpretation
  │
  ├─ RELATIONSHIP SERVICE
  │   └─ compute_metric_updates() [deterministic]
  │       Input:  template metric_updates config, current effective_metrics, turn_scores
  │       Output: new_effective_metrics
  │   └─ resolve_state() [deterministic state engine]
  │   └─ resolve_tier() [deterministic]
  │
  ├─ Update session.effective_metrics, instance.current_state, instance.relationship_tier
  │
  ├─ MEMORY SERVICE
  │   └─ write_memory_entry() → DB insert
  │
  ├─ Accumulate turn_scores in session.accumulated_scores
  │
  ├─ Load memory entries → format for LLM context
  │
  ├─ CHARACTER VOICE SERVICE
  │   └─ LLM: Character Voice pipeline
  │       Input:  NPC identity+state, memory context, conversation history, scenario,
  │               possible_outcomes, turn_count, min_turns_before_end
  │       Output: npc_reply, npc_expression, coach_hint,
  │               outcome_triggered (null|"good"|"neutral"|"poor"), end_encounter (bool)
  │
  ├─ Append NPC reply to conversation_history
  ├─ Check: LLM end_encounter flag OR turn_count >= max_turns_safety_limit → set encounter_over
  ├─ Store narrative_outcome if LLM triggered one
  ├─ Build feedback (deterministic, from turn_scores)
  │
  ├─ DB commit
  │
  └─ Return response JSON
```

Two LLM calls occur per turn: Memory Formation (scoring) and Character Voice (dialogue).

---

## Request Flow — POST /interaction/end

Called explicitly by the client after the encounter is over.

```
HTTP POST /interaction/end
  │
  ├─ Load instance, session, player, seed
  ├─ Compute avg_scores from accumulated_scores
  │
  ├─ PROGRESSION SERVICE
  │   └─ determine_outcome() [deterministic — always computed from avg_scores]
  │   (narrative_outcome read from session — set by Character Voice LLM during /message)
  │
  ├─ MEMORY SERVICE
  │   └─ write_encounter_memory() — summarizing entry with dominant interpretation
  │
  ├─ Load all memory entries for this NPC instance
  │
  ├─ OBSERVER SERVICE
  │   ├─ _check_trigger() [deterministic: count interpretations]
  │   └─ if fired: LLM Observer Phrasing pipeline
  │
  ├─ PROGRESSION SERVICE (all deterministic)
  │   ├─ compute_xp_gain()
  │   ├─ compute_skill_vector_update()
  │   └─ apply_xp_and_level()
  │
  ├─ Commit final effective_metrics → instance.metrics (persistent)
  ├─ Resolve and commit final state + tier → instance
  │
  ├─ Write EncounterHistory record
  ├─ Delete InteractionSession (transient — discarded at end)
  │
  ├─ DB commit
  │
  └─ Return response JSON (observer_event, encounter_summary, optional level_up)
```

At most one LLM call occurs during end (Observer Phrasing, only if triggered).

---

## Request Flow — POST /interaction/start

```
HTTP POST /interaction/start
  │
  ├─ Load/create Player, resolve/create NpcInstance
  ├─ Delete any stale InteractionSession
  │
  ├─ SCENARIO SERVICE
  │   ├─ select_seed() [weighted random, level-based distribution]
  │   └─ compute_effective_metrics() [persisted metrics + seed overrides]
  │
  ├─ Create new InteractionSession in DB
  │
  ├─ Load memory entries → format for LLM
  │
  ├─ LLM: Scenario Personalization pipeline
  │   Input:  seed data, NPC identity, starting metrics, player history summary
  │   Output: opening_line, npc_expression
  │
  ├─ Append NPC opening to conversation_history
  ├─ DB commit
  │
  └─ Return response JSON
```

One LLM call occurs during start (Scenario Personalization).

---

## Modules and Responsibilities

### `src/config.py`

Reads environment variables and `.env`. Exposes `get_settings()` (cached via `lru_cache`). All configurable knobs live here.

### `src/database.py`

Creates the async SQLAlchemy engine and session factory lazily on first use (or at startup). Uses `NullPool` to prevent connection sharing across event loops. Exposes `get_db()` as a FastAPI dependency (async generator) and `init_db()` for table creation.

### `src/models.py`

Five ORM tables (see [Persistence](#persistence) section).

### `src/content.py`

Content registry singleton. Loaded once at startup from YAML files. Provides typed access to NPC templates, scenario seeds, distribution bands, and relationship tier config. Never mutated after load. Validates seed metric overrides against template definitions at load time.

### `src/state_engine.py`

Parses and evaluates NPC state rule conditions. Supports: comparison operators (`>`, `<`, `>=`, `<=`, `==`, `!=`), `and`/`or` chaining, and the special `default` keyword. Uses no `eval` — tokens are parsed explicitly with regex. Called by `relationship_service` after every metric update.

### `src/routers/interaction.py`

Orchestration layer for all game logic. Contains the four interaction endpoints. Calls into services; never owns data directly. All business logic that spans multiple services lives here.

### `src/routers/player.py`

Thin player management endpoints: status and reset.

### `src/services/player_service.py`

Owns `Player` record lifecycle: `get_or_create_player`, `get_player`, `reset_player`. Reset cascades to NPC instances (and their memory/sessions) and encounter history.

### `src/services/npc_service.py`

Owns NPC instance resolution. Instance IDs are deterministic: `inst_{player_id}_{template_id}`. Creates a new instance from template start values on first contact. Sets initial relationship tier.

### `src/services/memory_service.py`

Owns memory entry reads and writes. Formats memory as a compact string for LLM context (last 10 entries). Does not trigger or interpret memory — only stores and retrieves.

### `src/services/scoring_service.py`

Thin wrapper. Assembles the context needed for the Memory Formation LLM call and delegates to `llm_service.memory_formation`. Returns the four scores and interpretation label.

### `src/services/relationship_service.py`

Owns the metric update formula and tier resolution. Stateless: takes current metrics and turn scores, returns new metrics. Calls `state_engine.resolve_state` internally. The blend factor (`_DELTA_BLEND_FACTOR = 0.15`) dampens score impact on metrics.

### `src/services/scenario_service.py`

Owns seed selection (weighted random by category, level-based distribution) and effective metric computation (overlay seed overrides on persisted metrics). Does not read from DB.

### `src/services/progression_service.py`

Owns all XP, level, outcome, and skill vector calculations. Fully deterministic. Never calls the LLM. The LLM has zero influence over any progression value.

### `src/services/observer_service.py`

Owns the Observer trigger check (deterministic: count interpretation occurrences across all memory entries for an NPC instance; fire if any reaches 2). If triggered, calls `llm_service.observer_phrasing`. Does not own memory — receives entries as input.

### `src/services/llm_service.py`

Owns all LLM calls. Five pipelines, each with a fixed system prompt, structured JSON output schema, and post-processing (clamping, vocabulary enforcement, defaults). Uses the OpenAI SDK with `response_format: json_object`. Temperature varies by pipeline (0.3 for scoring, 0.8 for character voice). Raises on API failure.

The **Character Voice pipeline** is the only one that can end encounters: it receives `possible_outcomes` and the current `turn_count`/`min_turns_before_end` guard, and returns `outcome_triggered` + `end_encounter` in addition to the usual dialogue fields. The progression service (`determine_outcome`) is always run independently of the LLM and computes `performance_outcome` from avg_scores.

---

## Data Ownership

| Data | Owned By | Persisted |
|---|---|---|
| Player record | `player_service` | Yes — `players` table |
| NPC instance (metrics, state, tier) | `npc_service` (creation), `interaction.py` (mutation) | Yes — `npc_instances` |
| Memory entries | `memory_service` | Yes — `memory_entries` |
| Interaction session (in-flight state) | `interaction.py` | Transient — deleted at `/end` |
| Encounter history | `interaction.py` | Yes — `encounter_history` |
| NPC templates + scenario seeds | `content.py` registry | In-memory (loaded from YAML) |
| Skill vector | `player_service` (reset), `interaction.py` (update via progression_service) | Yes — `players.skill_vector_json` |

---

## Persistence

Database: SQLite, file `threshold.db` (configurable via `DB_URL` env var).  
ORM: SQLAlchemy async, all table operations async.  
The `InteractionSession` table is transient state: it is created at `/start` and deleted at `/end`. Between those calls it holds the in-flight encounter: conversation history, effective metrics, accumulated scores, turn count.

All JSON-valued columns (metrics, skill vector, conversation history, etc.) are stored as serialized JSON strings in `Text` columns and exposed as typed Python properties via `@property` setters/getters.

See [API and Data Models](./03_api_reference.md) for the full schema.

---

## Important Runtime Notes

- **CORS**: Fully open (`allow_origins=["*"]`). Restrict for production.
- **Session factory**: Created lazily, bound to the running event loop. `NullPool` ensures no shared connections across requests.
- **Content registry**: Module-level singleton, populated once. All runtime content access is through `registry`, never direct YAML reads.
- **LLM client**: A new `AsyncOpenAI` client is instantiated per call. No connection pooling at the client level.
- **Transaction scope**: Each request uses a single `AsyncSession`. The session is committed once per request (at the end). Intermediate `flush()` calls are used to make inserts visible within the same session before commit.
- **Encounter-end logic**: The encounter ends (`encounter_over=True`) under two conditions: (a) the Character Voice LLM sets `end_encounter=True` in its response after `min_turns_before_end` turns (default: 3), signaling a natural narrative closure; or (b) `turn_count >= max_turns_safety_limit` (default: 8), a hard cap preventing runaway sessions. `max_turns_per_encounter` remains in config for legacy compatibility but is not used in the turn-end check.
- **`narrative_outcome`**: Written to `InteractionSession.narrative_outcome` on the turn where the LLM triggers closure. Returned in `/end`'s `encounter_summary.narrative_outcome`. `null` if the encounter ended by safety limit.
