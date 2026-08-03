# THRESHOLD — Setup, Environment, and Operations

## Environment Variables

All configuration is read from a `.env` file in the project root (or from environment variables directly). The file is read by `pydantic-settings` at startup.

| Variable | Default | Description |
|---|---|---|
| `LLM_KEY` | `""` | API key for the LLM provider. Required for any LLM pipeline to function. |
| `LLM_BASE_URL` | `https://api.deepseek.com` | Base URL for the OpenAI-compatible API endpoint. |
| `LLM_MODEL` | `deepseek-chat` | Model name to pass to the API. |
| `DB_URL` | `sqlite+aiosqlite:///./threshold.db` | SQLAlchemy async database URL. |
| `XP_PER_LEVEL` | `100` | XP required per level. Present in settings; the level-up formula currently uses `>= 1.0` as the normalized threshold. |
| `MAX_LEVEL` | `100` | Maximum player level. |
| `MAX_TURNS_PER_ENCOUNTER` | `6` | Legacy field; present in settings but not used by encounter-end logic. |
| `MAX_TURNS_SAFETY_LIMIT` | `8` | Hard cap on player turns. Encounter is force-ended if turn_count reaches this limit regardless of narrative state. |
| `MIN_TURNS_BEFORE_END` | `3` | Minimum player turns that must occur before the Character Voice LLM is permitted to trigger a narrative outcome. |

**Minimal `.env` for local development:**
```env
LLM_KEY=your_api_key_here
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
```

All other values use defaults. The database file `threshold.db` is created automatically in the project root on first run.

**Using a different LLM provider:**

Any OpenAI-compatible API can be used. Example for OpenAI:
```env
LLM_KEY=sk-...
LLM_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o
```

---

## Local Setup

### Prerequisites

- Python 3.11 or later (async SQLAlchemy + aiosqlite requirements)
- pip

### Installation

```powershell
cd C:\Users\User\Documents\THRESHOLD
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### Create `.env`

```powershell
copy .env.example .env   # if it exists, otherwise create manually
# Then edit .env and set LLM_KEY
```

Or create `.env` directly:
```
LLM_KEY=your_api_key_here
```

### Run the server

```powershell
uvicorn src.main:app --reload --host 127.0.0.1 --port 8000
```

The server will:
1. Load content from `content/npc_templates.yaml` and `content/scenario_seeds.yaml`
2. Create `threshold.db` (SQLite) in the project root if it does not exist
3. Create all tables via SQLAlchemy `create_all`
4. Start accepting requests

**API documentation (auto-generated):**
- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`
- Health check: `http://127.0.0.1:8000/health`

---

## Running Tests

Tests cover all deterministic services. No LLM calls are made in the test suite (LLM calls are mocked where the observer is tested end-to-end).

```powershell
pytest tests/ -v
```

Or via the helper script:
```powershell
python run_tests.py
```

**Test configuration (`pytest.ini`):**
```ini
[pytest]
asyncio_mode = auto
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

### Test Coverage

| Test File | Covers |
|---|---|
| `test_state_engine.py` | State rule parsing, compound conditions (and/or), all Sara states, edge cases, missing default rule |
| `test_relationship_service.py` | Metric update formula, trust increase/decrease, patience decay, clamp at min/max, determinism, tier resolution for all roles |
| `test_scenario_service.py` | Seed selection by role, exclusion list, unknown role error, level distribution (low level prefers everyday_social), effective metric override |
| `test_progression_service.py` | XP formula (good > poor, determinism, empty turns, cap at 1.0, level dampening), level-up (single, no levelup, max level cap), outcome thresholds, skill vector update |
| `test_observer_service.py` | Trigger at 2 occurrences, no trigger at 1, trigger at 3, empty entries, multiple repeating labels, LLM called when triggered, LLM NOT called when not triggered |

---

## Running the Demo

The demo script runs the full encounter lifecycle against a live server and prints results to stdout. It uses the `sara` NPC and a set of 6 predefined messages designed to trigger the Observer pattern.

```powershell
python demo_flow.py
```

The script:
1. Starts a uvicorn server on `127.0.0.1:18765` in a background thread
2. Resets `demo_player_01` to defaults
3. Starts an encounter with Sara
4. Sends 6 messages, printing scores, state, tier, and coach hints per turn
5. Ends the encounter, prints Observer result and outcome
6. Shows player status (level, XP, skill vector)
7. Starts a second encounter with Sara, sends 3 messages, ends it
8. Requests a report
9. Fetches the daily challenge

Expected output is captured in `demo_out.txt`.

**Requirements:** A valid `LLM_KEY` in `.env`. The demo makes real LLM calls.

---

## Database Files

| File | Purpose |
|---|---|
| `threshold.db` | Main database. Created automatically on first run. |
| `test_green.db` | SQLite artifact from test runs (if tests use a separate DB). |

The default `DB_URL` points to `./threshold.db` in the working directory. For tests, this may be overridden or tests may use a separate configuration.

---

## Project Dependencies

Full `requirements.txt`:

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
sqlalchemy>=2.0.30
aiosqlite>=0.19.0
pydantic>=2.7.0
pydantic-settings>=2.3.0
httpx>=0.27.0
pyyaml>=6.0.1
python-dotenv>=1.0.1
openai>=1.30.0
pytest>=8.0.0
pytest-asyncio>=0.23.0
anyio>=4.0.0
requests>=2.31.0
```

---

## Deployment Notes

THRESHOLD is a standard ASGI application. Any ASGI-compatible host works (Railway, Render, Fly.io, etc.).

**Key considerations:**

1. **LLM API key** must be provided via environment variable (`LLM_KEY`). Never commit to source control.

2. **Database:** The default SQLite configuration is suitable for single-instance deployment. For multi-instance or production use, change `DB_URL` to a PostgreSQL async URL (`postgresql+asyncpg://...`) and add `asyncpg` to dependencies. The SQLAlchemy ORM layer is compatible with both.

3. **CORS:** Currently configured as fully open (`allow_origins=["*"]`). Restrict to your frontend origin for production.

4. **NullPool:** The engine uses `NullPool`, which opens one connection per request. This is safe for async but not optimal for high-throughput production use. For production, switch to `AsyncAdaptedQueuePool` and tune pool size.

5. **Startup:** Tables are created via `create_all` on every startup. This is safe for SQLite (idempotent). For managed production databases, use Alembic migrations instead.

6. **Port:** Default uvicorn port is 8000. Override with `--port` flag or a `PORT` environment variable (depending on hosting platform).

**Minimal production start command:**
```bash
uvicorn src.main:app --host 0.0.0.0 --port 8000 --workers 1
```

Use `--workers 1` with SQLite (multiple workers would write to the same file concurrently). For PostgreSQL, multiple workers are safe.

---

## Content Extension

To add new NPCs or scenarios without changing any Python code:

**Add an NPC:** Add an entry to `content/npc_templates.yaml` following the existing structure. The NPC will be available at the next server startup.

**Add a scenario seed:** Add an entry to `content/scenario_seeds.yaml`. Ensure:
- `id` is unique
- `compatible_roles` contains valid archetype role strings
- `category` is one of: `everyday_social`, `friendship`, `workplace`, `high_pressure` (or add new category weights to `distribution_bands`)
- Any `metric_overrides` keys exist as metric names on all templates with the listed compatible roles (validated at startup)
- `scoring_focus.primary` and `scoring_focus.secondary` are one of: `clarity`, `empathy`, `politeness`, `expression`

Startup validation will raise a `ValueError` if metric override keys don't match template definitions.
