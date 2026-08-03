# THRESHOLD — API Reference

Base URL: `http://<host>:<port>` (default dev: `http://127.0.0.1:8000`)

All request bodies are JSON. All responses are JSON. HTTP errors return `{"detail": "<message>"}`.

---

## GET /health

Health check.

**Request:** None  
**Response:**
```json
{
  "status": "ok",
  "service": "THRESHOLD Backend"
}
```

---

## Interaction Endpoints

All game lifecycle calls. All require a `player_id` and (except `/report`) an `npc_id`.

---

### POST /interaction/start

Begin a new encounter between a player and an NPC. Selects a scenario, computes starting metrics, generates the NPC's opening line via LLM, and creates an `InteractionSession`.

If an active session already exists for this player+NPC pair it is silently discarded and replaced.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier. Auto-creates the player if not found. |
| `npc_id` | string | Yes | NPC template ID. Must be a known NPC. |

**Example request:**
```json
{
  "player_id": "player_01",
  "npc_id": "sara"
}
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `npc_name` | string | Display name of the NPC |
| `npc_expression` | string (enum) | NPC's opening emotional expression |
| `opening_line` | string | The NPC's first line of dialogue, personalized by LLM |
| `interaction_id` | string | The scenario seed ID that was selected |
| `encounter_over` | boolean | Always `false` on start |

**npc_expression enum values:** `neutral`, `warm`, `hurt`, `guarded`, `irritated`, `concerned`, `disappointed`, `approving`, `dismissive`, `satisfied`, `frustrated`, `hostile`, `defensive`, `withdrawn`, `collaborative`

**Example response:**
```json
{
  "npc_name": "Sara",
  "npc_expression": "neutral",
  "opening_line": "Hey, so we've never really talked, right? How's your week going?",
  "interaction_id": "first_meeting_small_talk",
  "encounter_over": false
}
```

**Errors:**

| Code | Condition |
|---|---|
| 404 | `npc_id` not found in template registry |

---

### POST /interaction/message

Send one player message and receive the NPC's reply, scores, feedback, and updated relationship state.

This endpoint drives the conversation loop. Call it once per player turn. The encounter ends when `encounter_over` becomes `true` — either because the Character Voice LLM triggered a narrative outcome, or because `turn_count` reached the safety limit (`max_turns_safety_limit`, default 8).

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier |
| `npc_id` | string | Yes | NPC template ID |
| `message` | string | Yes | The player's message. Must not be empty or whitespace-only. |

**Example request:**
```json
{
  "player_id": "player_01",
  "npc_id": "sara",
  "message": "I've just been really busy with work, sorry."
}
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `npc_expression` | string (enum) | NPC's emotional expression for this reply |
| `npc_reply` | string | The NPC's reply in their authentic voice |
| `coach_hint` | object | See below |
| `turn_scores` | object | See below |
| `relationship_tier` | string | Current relationship tier label |
| `npc_state` | string | Current NPC state (deterministic, from metric rules) |
| `feedback` | object | See below |
| `encounter_over` | boolean | `true` when the LLM triggers a narrative outcome OR turn_count >= max_turns_safety_limit |
| `narrative_outcome` | string or null | `"good"`, `"neutral"`, `"poor"` if a narrative outcome was triggered this turn; `null` otherwise |

**`coach_hint` object:**

| Field | Type | Description |
|---|---|---|
| `shown` | boolean | Whether there is a hint to display |
| `line` | string | The hint text (one factual observation; empty if `shown` is false) |

**`turn_scores` object:**

| Field | Type | Description |
|---|---|---|
| `clarity` | float (0.0–1.0) | How clearly the player communicated |
| `empathy` | float (0.0–1.0) | Whether the player acknowledged the other's feelings |
| `politeness` | float (0.0–1.0) | Whether the tone was respectful |
| `expression` | float (0.0–1.0) | Whether the player communicated with emotional honesty |

**`feedback` object:**

| Field | Type | Description |
|---|---|---|
| `strength` | string | Human-language label for the highest-scoring dimension |
| `improvement` | string | Human-language label for the lowest-scoring dimension |

**Possible `strength` values:**
- `"You communicated your point clearly."` (clarity)
- `"You showed genuine understanding of the other person."` (empathy)
- `"Your tone was respectful and considerate."` (politeness)
- `"You expressed yourself with personal honesty."` (expression)

**Possible `improvement` values:**
- `"Your message could have been more direct."` (clarity)
- `"You responded to the words, but not the feeling behind them."` (empathy)
- `"The tone came across as slightly abrupt."` (politeness)
- `"You kept things factual but didn't share your own perspective."` (expression)

**Example response:**
```json
{
  "npc_expression": "neutral",
  "npc_reply": "No worries, work's been eating me alive too. What do you do?",
  "coach_hint": {
    "shown": true,
    "line": "Sara acknowledged your excuse and is trying to shift to lighter topics."
  },
  "turn_scores": {
    "clarity": 0.90,
    "empathy": 0.30,
    "politeness": 0.70,
    "expression": 0.40
  },
  "relationship_tier": "Comfortable",
  "npc_state": "neutral",
  "feedback": {
    "strength": "You communicated your point clearly.",
    "improvement": "You responded to the words, but not the feeling behind them."
  },
  "encounter_over": false,
  "narrative_outcome": null
}
```

**Errors:**

| Code | Condition |
|---|---|
| 404 | `npc_id` not found |
| 404 | No active session (call `/start` first) |
| 400 | Encounter is already over (call `/end`) |
| 422 | `message` is empty or whitespace |
| 500 | Scenario seed not found (data integrity error) |

---

### POST /interaction/end

Finalize the encounter. Must be called after the encounter loop ends (when `encounter_over` is `true` or whenever the client chooses to end early).

Performs: outcome determination, encounter memory write, Observer pattern check, XP + skill vector update, level check, NPC metric persistence, encounter history record, session deletion.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier |
| `npc_id` | string | Yes | NPC template ID |

**Example request:**
```json
{
  "player_id": "player_01",
  "npc_id": "sara"
}
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `observer_event` | object | See below |
| `encounter_summary` | object | See below |
| `level_up` | object (optional) | Present only if the player leveled up; see below |

**`observer_event` object:**

| Field | Type | Description |
|---|---|---|
| `fired` | boolean | Whether the Observer pattern trigger fired |
| `npc_id` | string | The NPC this Observer event is about |
| `message` | string or null | LLM-generated factual pattern description; null if not fired |

**`encounter_summary` object:**

| Field | Type | Description |
|---|---|---|
| `narrative_outcome` | string or null | `"good"`, `"neutral"`, or `"poor"` if the LLM triggered a narrative closure; `null` if the encounter ended by safety limit |
| `performance_outcome` | string (enum) | `"good"`, `"neutral"`, or `"poor"` — always computed from weighted average of avg_scores |

**`level_up` object** (only present when `leveled_up == true`):

| Field | Type | Description |
|---|---|---|
| `new_level` | integer | The player's new level |

**Outcome determination:**

`narrative_outcome` — set by the Character Voice LLM when it decides the scenario has reached a natural conclusion. Only possible after `min_turns_before_end` turns (default: 3).

`performance_outcome` — always computed from weighted average of avg_scores:
- Primary scoring focus dimension × 0.6
- Secondary scoring focus dimension × 0.3
- Remaining two dimensions × 0.05 each

Thresholds: weighted score ≥ 0.65 → `"good"`, ≥ 0.40 → `"neutral"`, < 0.40 → `"poor"`

**Example response (Observer fired, no level-up):**
```json
{
  "observer_event": {
    "fired": true,
    "npc_id": "sara",
    "message": "Across these exchanges, the pattern of deflecting emotional acknowledgment recurred..."
  },
  "encounter_summary": {
    "narrative_outcome": "neutral",
    "performance_outcome": "neutral"
  }
}
```

**Example response (no Observer, level-up, ended by safety limit):**
```json
{
  "observer_event": {
    "fired": false,
    "npc_id": "sara",
    "message": null
  },
  "encounter_summary": {
    "narrative_outcome": null,
    "performance_outcome": "good"
  },
  "level_up": {
    "new_level": 2
  }
}
```

**Errors:**

| Code | Condition |
|---|---|
| 404 | `npc_id` not found |
| 404 | No active session |
| 500 | Scenario seed not found (data integrity error) |

---

### POST /interaction/report

Generate a personal communication report for a player. Computed fresh on each call from the player's current skill vector and up to 5 most recent encounter history records. Not stored.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier |

**Example request:**
```json
{
  "player_id": "player_01"
}
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `current_level` | integer | Player's current level |
| `skill_vector` | object | Current skill vector (four dimensions, 0.0–1.0) |
| `strongest_skill` | string | One of: `clarity`, `empathy`, `politeness`, `expression` |
| `improving_area` | string | Interpretive label for the area with most room to grow (e.g., `emotional_acknowledgment`, `conflict_resolution`) |
| `recent_pattern_summary` | string | One or two sentences describing a communication pattern |
| `recommended_practice` | string | One concrete practice suggestion referencing a scenario type |

**Example response:**
```json
{
  "current_level": 1,
  "skill_vector": {
    "clarity": 0.5135,
    "empathy": 0.4957,
    "politeness": 0.5018,
    "expression": 0.4740
  },
  "strongest_skill": "clarity",
  "improving_area": "emotional_acknowledgment",
  "recent_pattern_summary": "Your conversations are clear and well-structured, but you often miss opportunities to connect emotionally.",
  "recommended_practice": "In your next small talk encounter, try to actively reflect back the other person's feelings."
}
```

**Errors:**

| Code | Condition |
|---|---|
| 404 | Player not found |

---

### GET /interaction/daily

Returns a featured scenario and NPC matched to the player's level, plus the current daily streak count.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier. Auto-creates if not found. |

**Example request:**
```
GET /interaction/daily?player_id=player_01
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `seed_id` | string | The selected scenario seed ID |
| `npc_id` | string | The selected NPC ID (compatible with the seed's roles) |
| `focus` | string | Human-readable scoring focus label (e.g., `"Clarity + Politeness"`) |
| `streak_count` | integer | Player's current daily streak |

**Seed tier selection by level:**
- Level ≤ 30: only tier 1 seeds
- Level ≤ 70: tier 1 or 2 seeds
- Level > 70: any tier

**Example response:**
```json
{
  "seed_id": "asking_for_extension",
  "npc_id": "mr_teo",
  "focus": "Clarity + Politeness",
  "streak_count": 0
}
```

**Errors:** None. Player is auto-created if not found.

---

## Player Endpoints

---

### GET /player/status

Return a player's current state. Convenience endpoint for testing and frontend display.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier |

**Example request:**
```
GET /player/status?player_id=player_01
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `player_id` | string | Player identifier |
| `level` | integer | Current level (1–100) |
| `skill_vector` | object | Four dimensions (clarity, empathy, politeness, expression), each 0.0–1.0 |
| `xp_progress` | float | XP within current level (0.0–1.0) |
| `daily_streak` | integer | Current daily streak count |
| `created_at` | string (ISO 8601) | Account creation timestamp |

**Example response:**
```json
{
  "player_id": "player_01",
  "level": 1,
  "skill_vector": {
    "clarity": 0.5063,
    "empathy": 0.4990,
    "politeness": 0.5040,
    "expression": 0.4933
  },
  "xp_progress": 0.308,
  "daily_streak": 0,
  "created_at": "2026-08-02T19:22:32.821583"
}
```

**Errors:**

| Code | Condition |
|---|---|
| 404 | Player not found |

---

### POST /player/reset

Reset a player back to defaults. Clears all NPC instances, memory entries, sessions, and encounter history. Resets level to 1, XP to 0.0, skill vector to all 0.5, daily streak to 0. Creates the player if not found.

Intended for development, testing, and demo use.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `player_id` | string | Yes | Player identifier |

**Example request:**
```json
{
  "player_id": "player_01"
}
```

**Response:**

| Field | Type | Description |
|---|---|---|
| `player_id` | string | The reset player's ID |
| `reset` | boolean | Always `true` |

**Example response:**
```json
{
  "player_id": "player_01",
  "reset": true
}
```

**Errors:** None. Player is created if not found.

---

## Data Models (ORM Tables)

### `players`

| Column | Type | Notes |
|---|---|---|
| `player_id` | String (PK) | Caller-supplied identifier |
| `level` | Integer | Default: 1 |
| `skill_vector_json` | Text | JSON: `{"clarity":float, "empathy":float, "politeness":float, "expression":float}` |
| `xp_progress` | Float | 0.0–1.0 within current level. Default: 0.0 |
| `daily_streak` | Integer | Default: 0 |
| `created_at` | DateTime (UTC) | Auto-set |
| `last_active_at` | DateTime (UTC) | Auto-set on create; not currently updated |

### `npc_instances`

| Column | Type | Notes |
|---|---|---|
| `npc_instance_id` | String (PK) | Format: `inst_{player_id}_{template_id}` |
| `player_id` | String (FK → players) | |
| `template_id` | String | NPC template ID |
| `metrics_json` | Text | JSON: NPC's persisted metric dict |
| `current_state` | String | Last resolved state label |
| `relationship_tier` | String | Last resolved tier label |
| `created_at` | DateTime (UTC) | |
| `updated_at` | DateTime (UTC) | Not auto-updated; set at creation |

### `memory_entries`

| Column | Type | Notes |
|---|---|---|
| `id` | Integer (PK, autoincrement) | |
| `npc_instance_id` | String (FK → npc_instances) | |
| `event` | String | Truncated event description |
| `interpretation` | String | One of the seed's interpretation vocabulary labels |
| `turn` | Integer | Turn number within the encounter |
| `created_at` | DateTime (UTC) | |

### `interaction_sessions`

Transient. Created at `/start`, deleted at `/end`.

| Column | Type | Notes |
|---|---|---|
| `npc_instance_id` | String (PK, FK → npc_instances) | One session per NPC instance at a time |
| `scenario_id` | String | The active scenario seed ID |
| `turn_count` | Integer | Current turn number |
| `conversation_history_json` | Text | JSON array of `{"role": "npc"|"player", "text": string}` |
| `encounter_modifiers_json` | Text | JSON: seed's metric overrides applied at start |
| `effective_metrics_json` | Text | JSON: running metrics for this encounter (not persisted to instance until end) |
| `encounter_over` | Boolean | Default: false |
| `accumulated_scores_json` | Text | JSON array of per-turn score dicts |
| `narrative_outcome` | String or null | LLM-generated narrative interpretation when set by narrative closure; null until then |
| `performance_outcome` | String or null | Deterministic outcome rating (`"good"`, `"neutral"`, `"poor"`) calculated from turn scores |
| `created_at` | DateTime (UTC) | |

### `encounter_history`

| Column | Type | Notes |
|---|---|---|
| `id` | Integer (PK, autoincrement) | |
| `player_id` | String (FK → players) | |
| `npc_template_id` | String | NPC template ID |
| `scenario_id` | String | Scenario seed ID |
| `performance_outcome` | String | `"good"`, `"neutral"`, or `"poor"` — strictly deterministic, drives XP and skill progression |
| `narrative_outcome` | String or null | AI-generated narrative interpretation (or outcome ID) retained from encounter closure |
| `avg_scores_json` | Text | JSON: average turn scores dict |
| `xp_gained` | Float | XP awarded for this encounter |
| `completed_at` | DateTime (UTC) | |

