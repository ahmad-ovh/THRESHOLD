# THRESHOLD — Systems Reference

This document explains how each backend system works: inputs, outputs, formulas, boundaries, and what is handled by deterministic code versus the LLM.

---

## Player System

**Module:** `src/services/player_service.py`  
**Data:** `players` table

The player is identified by a caller-supplied string `player_id`. There is no authentication. Any string can be a player ID; the player record is created on first use.

**Player record fields:**
- `level` — integer, starts at 1, max 100 (configurable)
- `skill_vector` — dict of four floats, each 0.0–1.0, stored as JSON in `skill_vector_json`
- `xp_progress` — float 0.0–1.0 within the current level
- `daily_streak` — integer, not currently incremented by any running code
- `created_at`, `last_active_at` — timestamps (last_active_at is set at creation but not updated)

**Initial values on creation:**
```json
{
  "level": 1,
  "skill_vector": {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5},
  "xp_progress": 0.0,
  "daily_streak": 0
}
```

**Reset:** Deletes all NPC instances (cascades to memory entries and sessions), deletes all encounter history, resets the player record to defaults. The player record itself is retained (or created if missing).

---

## NPC System

**Module:** `src/services/npc_service.py`  
**Data:** `npc_instances` table, `content/npc_templates.yaml`

NPC templates are static content loaded once at startup. An NPC instance is a per-player, per-NPC persistent record that holds the living state of that relationship.

**Instance ID format:** `inst_{player_id}_{template_id}`

On first contact (instance does not exist), a new instance is created with:
- `metrics` — populated from template `metrics[x].start` values
- `current_state` — `"neutral"`
- `relationship_tier` — resolved from initial trust value using `registry.tier_config()`

Once created, the instance persists across all encounters. The player's relationship with each NPC is cumulative.

**What persists on the instance:**
- `metrics` — updated at encounter end (after `/interaction/end`)
- `current_state` — updated after every turn and at encounter end
- `relationship_tier` — updated after every turn and at encounter end

**What does not persist to the instance during an encounter:**
- Effective metrics (metric values during a live encounter, including any seed overrides) are tracked in `InteractionSession.effective_metrics_json` and only written back to `instance.metrics` at `/end`

---

## Memory System

**Module:** `src/services/memory_service.py`  
**Data:** `memory_entries` table

Memory is per-NPC-instance. Each player turn during an encounter writes one memory entry. Each encounter end writes one additional summarizing entry.

**Per-turn entry format:**
```
event: "player_turn_{turn_number}: {first 80 chars of player message}"
interpretation: "{success or failure signal from seed vocabulary}"
turn: {integer}
```

**Encounter-end entry format:**
```
event: "encounter_ended: {last 80 chars of final player message}"
interpretation: "{most common interpretation from this encounter's turns}"
turn: {final turn number}
```

Memory entries are never deleted (except via player reset cascade).

**LLM context:** The 10 most recent entries are formatted as a compact string and passed to the Character Voice pipeline. Format:
```
- Turn {n}: {event} (interpretation: {interpretation})
```

**Observer access:** The full set of memory entries for an NPC instance is passed to the Observer service at encounter end. The Observer does not write to memory; it only reads.

---

## Scoring System

**Module:** `src/services/scoring_service.py` → `src/services/llm_service.py` (Memory Formation pipeline)

The scoring system evaluates every player message across four dimensions. This is the only mechanism that produces scores — there is no fallback scoring logic in deterministic code.

**Input:**
- Player message (string)
- Scenario context: premise, stakes, npc_goal, scoring_focus primary/secondary
- Conversation history: last 6 turns formatted as `ROLE: text`
- Interpretation vocabulary: `[success_signal, failure_signal]` from the active seed

**Output:**
- `clarity` — float 0.0–1.0
- `empathy` — float 0.0–1.0
- `politeness` — float 0.0–1.0
- `expression` — float 0.0–1.0
- `interpretation` — one string from the vocabulary (vocabulary enforced; if model returns invalid value, falls back to `failure_signal`)

**Post-processing by deterministic code:**
- All four scores are clamped to `[0.0, 1.0]`
- Interpretation is validated against the vocabulary; invalid values are replaced with the failure signal

**Temperature:** 0.3 (low variance — consistency matters for scoring)

---

## Relationship System

**Module:** `src/services/relationship_service.py`  
**State evaluation:** `src/state_engine.py`

### Metric Update Formula

Called after every player turn with the turn's four dimension scores. Fully deterministic.

```
For each metric defined in template.metric_updates:
  raw_delta = sum(turn_score[dim] * weight for dim, weight in influenced_by)
  delta = raw_delta * DELTA_BLEND_FACTOR          # DELTA_BLEND_FACTOR = 0.15
  new_value = old_value + delta - turn_decay
  new_value = clamp(new_value, metric.min, metric.max)
  new_value = round(new_value, 4)
```

The blend factor (0.15) prevents scores from moving metrics violently. Even a perfect score (all 1.0) produces a moderate positive delta per turn.

**Example (Sara's trust, turn with empathy=0.9, clarity=0.9):**
```
raw_delta = 0.9 * 0.6 + 0.9 * 0.4 = 0.54 + 0.36 = 0.90
delta = 0.90 * 0.15 = 0.135
new_trust = old_trust + 0.135 - 0.0
```

**Example (Sara's patience, turn with politeness=0.0):**
```
raw_delta = 0.0 * 1.0 = 0.0
delta = 0.0 * 0.15 = 0.0
new_patience = old_patience + 0.0 - 0.05  # always loses 0.05 per turn
```

### Effective Metrics vs. Persisted Metrics

During an encounter, changes are tracked in `session.effective_metrics`. The NPC instance's `metrics` (persisted) are not modified until the encounter ends. This means:
- If a player abandons an encounter (does not call `/end`), no metric changes are persisted
- Encounter-start metric overrides from seed `npc_context.metric_overrides` affect the effective metrics for that encounter but do not permanently change the persisted values (unless they happen to be the final effective values committed at end)

### Tier Resolution

```python
trust = metrics.get("trust", 0.5)
thresholds = [0.0, 0.25, 0.45, 0.65, 0.85]
tier_index = 0
for i, threshold in enumerate(thresholds):
    if trust >= threshold:
        tier_index = i
return labels[archetype_role][tier_index]
```

Tier is determined solely by the `trust` metric value. Other metrics do not affect tier.

---

## State Engine

**Module:** `src/state_engine.py`

Evaluates NPC state rules against current metric values. Returns the first rule whose condition evaluates to `true`.

**Rule format:**
- Single atom: `metric_name operator value` — e.g., `trust < 0.3`
- Compound: atoms joined by `and` / `or` (case-insensitive)
- Special: `default` — always evaluates to `true`

**Operators:** `>`, `<`, `>=`, `<=`, `==`, `!=`

**Evaluation:**
- `or` has lower precedence than `and`
- Expression is split on `or`, then each part split on `and`
- An `or` group evaluates to `true` if any `and`-chain within it is all true
- Conditions are evaluated against the current effective metrics (during encounter) or persisted metrics (at end)

**Safety:** No Python `eval`. All tokens parsed explicitly via regex `_CONDITION_RE = r"(?P<metric>[a-zA-Z_][a-zA-Z0-9_]*)\s*(?P<op>>=|<=|!=|>|<|==)\s*(?P<value>[0-9]*\.?[0-9]+)"`.

**Error conditions:**
- Unrecognized condition atom → `ValueError`
- Metric name not in the provided metrics dict → `ValueError`
- No rule matches (missing `default`) → `RuntimeError`

Every NPC template must have a `default` rule as the final entry.

---

## Scenario System

**Module:** `src/services/scenario_service.py`

### Seed Selection

1. Determine the player's level band from `distribution_bands`
2. Get all seeds compatible with the NPC's archetype role
3. Intersect available seed categories with the band's category weights
4. Weighted-random pick a category (proportional to weights)
5. Filter: compatible role AND category matches AND not in exclusion list
6. Graceful degradation: if pool is empty, try other available categories alphabetically
7. If everything excluded: reset exclusion, use all role-compatible seeds
8. Random pick from final pool

**Distribution bands are read from `scenario_seeds.yaml`**, not hardcoded.

### Effective Metrics

```python
effective = dict(persisted_metrics)
effective.update(encounter_modifiers)   # seed's metric_overrides keys override
```

The seed's `npc_context.metric_overrides` can force specific metric values at encounter start without permanently altering the NPC instance. These overrides are also stored in `session.encounter_modifiers_json` for reference.

---

## Encounter-End Logic

An encounter ends (`encounter_over=True`) via one of two paths:

1. **Narrative closure (preferred):** During the **RESOLUTION phase** (`turn_count >= min_turns_before_end`, default: 3), the Character Voice LLM evaluates scene completion and may set `end_encounter=True`, returning `outcome_triggered` and a `narrative_outcome` interpretation. During the **DEVELOPMENT phase** (`turn_count < min_turns_before_end`), the prompt explicitly instructs the LLM to continue developing the scene without farewell dialogue, and the backend parser strictly suppresses any premature outcome fields (`end_encounter=False`, `outcome_triggered=null`, `narrative_outcome=null`).

2. **Safety limit:** If `turn_count >= max_turns_safety_limit` (default: 8), the encounter is force-ended regardless. In this case `narrative_outcome` remains `null`.

| Config key | Default | Description |
|---|---|---|
| `min_turns_before_end` | `3` | Minimum turns required to transition from DEVELOPMENT to RESOLUTION phase |
| `max_turns_safety_limit` | `8` | Hard turn cap (force-end) |

The `performance_outcome` (from `determine_outcome`) is calculated deterministically from average turn scores and **exclusively drives XP calculation and skill vector updates**. The `narrative_outcome` serves as an independent narrative interpretation and never alters mechanical progression.


---

## Progression System

**Module:** `src/services/progression_service.py`

Fully deterministic. The LLM has zero influence over any progression value.

### Outcome Determination

```
weighted = (
    avg_scores[primary_dim] * 0.6 +
    avg_scores[secondary_dim] * 0.3 +
    sum(avg_scores[d] * 0.05 for d in remaining_dims)
)

if weighted >= 0.65: outcome = "good"
elif weighted >= 0.40: outcome = "neutral"
else: outcome = "poor"
```

### XP Gain Formula

```
For each turn, avg_score[dim] = mean of that dim across all turns.

base_xp = (
    avg_scores[primary_dim] * PRIMARY_WEIGHT       # 0.5
  + avg_scores[secondary_dim] * SECONDARY_WEIGHT   # 0.3
  + avg_scores[remaining[0]] * REMAINING_WEIGHT    # 0.1
  + avg_scores[remaining[1]] * REMAINING_WEIGHT    # 0.1
)

outcome_multiplier = {"good": 1.0, "neutral": 0.6, "poor": 0.3}
base_xp *= outcome_multiplier[outcome]

dampening = max(0.5, 1.0 - (player_level - 1) * 0.005)
xp_gain = base_xp * dampening

xp_gain = round(min(xp_gain, 1.0), 4)   # capped at 1.0
```

Level dampening: at level 1, factor = 1.0; at level 101+ or higher, factor floors at 0.5.

### Skill Vector Update

```
For each dimension:
  w = dimension_weight  (primary=0.5, secondary=0.3, remaining=0.1 each)
  new_value = current_value * (1 - w * 0.2) + encounter_avg[dim] * (w * 0.2)
  new_value = round(clamp(new_value, 0.0, 1.0), 4)
```

This is a weighted blend: the skill vector moves toward the encounter average, with the primary scoring focus dimension moving faster. At primary weight 0.5: `new = current * 0.9 + avg * 0.1`.

### Level Threshold

```
new_xp = xp_progress + xp_gain
while new_xp >= 1.0 and level < max_level:
    new_xp -= 1.0
    level += 1
    leveled_up = True
new_xp = min(new_xp, 1.0)
```

One level = 1.0 XP. Configurable: `xp_per_level` (field exists in settings but the while loop condition uses `>= 1.0` directly; `xp_per_level` is present as a setting but not referenced in the formula).

---

## Observer System

**Module:** `src/services/observer_service.py`

The Observer watches for repeated patterns across the full memory history of a single NPC instance.

### Trigger Check (deterministic)

```python
counts = Counter(entry.interpretation for entry in all_memory_entries)
for interpretation, count in counts.items():
    if count >= 2:
        matching = [e for e in entries if e.interpretation == interpretation]
        return fired=True, interpretation, matching
return fired=False
```

Threshold: **2 or more occurrences** of the same interpretation label triggers the Observer. The first interpretation to meet the threshold is used (Counter iteration order, which in Python 3.7+ is insertion order).

### LLM Call (conditional)

If the trigger fires, the Observer calls the LLM Observer Phrasing pipeline to generate the message. If it does not fire, no LLM call is made.

### Observer Message Rules

The LLM is instructed to:
- State the pattern as a plain fact
- Use a quiet, observational register — not coaching
- Never tell the player what they should have done
- Never use "you" to assign blame
- Base the message only on the provided memory entries

The Observer message is returned in `/interaction/end` response regardless of whether the player has read any previous Observer messages.

---

## AI / LLM Integration

**Module:** `src/services/llm_service.py`

All LLM calls are routed through this single module. No other module calls the LLM directly.

**Client:** OpenAI SDK (`AsyncOpenAI`) with configurable `api_key`, `base_url`, and `model`. Default provider: DeepSeek (`https://api.deepseek.com`, model `deepseek-chat`). Any OpenAI-compatible API endpoint can be used.

**Output format:** All calls use `response_format={"type": "json_object"}`. Every pipeline returns structured JSON.

**Error handling:** `_call()` raises on API errors. `_parse_json()` raises `ValueError` on invalid JSON. No silent fallbacks — errors propagate to the router.

---

### Pipeline 1: Memory Formation

**Purpose:** Score a player message and select an interpretation label.  
**Called by:** `scoring_service.score_message` → `interaction/message`  
**Temperature:** 0.3

**Inputs to LLM:**
- Scenario premise, stakes, npc_goal
- Scoring focus primary and secondary dimensions
- Last 6 turns of conversation history
- Player message
- Allowed interpretation labels (2 values from seed vocabulary)

**LLM output schema:**
```json
{
  "clarity":        float (0.0–1.0),
  "empathy":        float (0.0–1.0),
  "politeness":     float (0.0–1.0),
  "expression":     float (0.0–1.0),
  "interpretation": string
}
```

**Post-processing by deterministic code:**
- All scores clamped to `[0.0, 1.0]`
- `interpretation` validated against vocabulary; if invalid → replaced with `failure_signal`

**What the LLM does NOT do:**
- Set NPC metrics
- Decide NPC state
- Generate dialogue
- Determine outcome

---

### Pipeline 2: Character Voice

**Purpose:** Generate the NPC's reply, emotional expression, coach hint, and optionally signal narrative encounter closure.  
**Called by:** `interaction/message` (after scoring and metric update)  
**Temperature:** 0.8

**Inputs to LLM:**
- NPC name, personality, communication style
- NPC's current state (determined by state engine, not LLM)
- Formatted memory context (last 10 entries)
- Last 8 turns of conversation history
- Scenario premise, stakes, npc_goal
- `possible_outcomes` — the seed's possible outcome labels (used to ground the narrative outcome decision)
- `turn_count` and `min_turns_before_end` — so the LLM knows when it is permitted to trigger closure

**LLM output schema:**
```json
{
  "npc_reply":        string,
  "npc_expression":   string (enum),
  "coach_hint":       string,
  "outcome_triggered": string or null,
  "end_encounter":     boolean
}
```

- `outcome_triggered` — `"good"`, `"neutral"`, or `"poor"` when the LLM decides the scenario has reached a natural conclusion; `null` otherwise. Only valid when `turn_count >= min_turns_before_end`.
- `end_encounter` — `true` when `outcome_triggered` is non-null; `false` otherwise.

**Defaults applied if fields missing:**
- `npc_reply` → `"{npc_name} says nothing."`
- `npc_expression` → current npc_state
- `coach_hint` → `""`
- `outcome_triggered` → `null`
- `end_encounter` → `false`

**What the LLM does NOT do:**
- Choose the NPC's state (it receives the state as input)
- Update metrics
- Compute the performance outcome (that is always deterministic, via `progression_service.determine_outcome`)

---

### Pipeline 3: Scenario Personalization

**Purpose:** Personalize the scenario's opening line to match NPC personality and player history.  
**Called by:** `interaction/start`  
**Temperature:** 0.7

**Inputs to LLM:**
- NPC name, personality, communication style
- Scenario title, premise, opening_line_seed, npc_goal
- Current NPC metrics at encounter start (effective metrics)
- Player history summary (brief text: level + memory count)

**LLM output schema:**
```json
{
  "opening_line":   string,
  "npc_expression": string (enum)
}
```

**Constraints enforced in system prompt:**
- Must not alter scenario premise, stakes, npc_goal, or possible outcomes
- Only personalizes wording and tone of the opening line

**Defaults if fields missing:**
- `opening_line` → seed's `opening_line_seed`
- `npc_expression` → `"neutral"`

---

### Pipeline 4: Observer Phrasing

**Purpose:** Phrase the Observer's pattern reveal message.  
**Called by:** `observer_service.run_observer` → `interaction/end` (only if trigger fired)  
**Temperature:** 0.6

**Inputs to LLM:**
- All memory entries matching the triggered interpretation, formatted as:
  `- Turn {n}: {event} (interpretation: {interpretation})`

**LLM output schema:**
```json
{
  "message": string
}
```

**Default if field missing:** `"A pattern repeated in this relationship."`

**What the LLM does NOT do:**
- Check the trigger (deterministic code does this)
- Advise or prescribe actions to the player
- Invent facts not in the provided memory entries

---

### Pipeline 5: Report Generation

**Purpose:** Generate a personal communication growth summary.  
**Called by:** `interaction/report`  
**Temperature:** 0.6

**Inputs to LLM:**
- Player level
- Current skill vector (four dimensions)
- Up to 5 most recent encounter history records (scenario_id, npc_template_id, outcome, avg_scores)

**LLM output schema:**
```json
{
  "strongest_skill":        string (one of: clarity, empathy, politeness, expression),
  "improving_area":         string (interpretive label),
  "recent_pattern_summary": string,
  "recommended_practice":   string
}
```

**Defaults:**
- `strongest_skill` → max key in skill_vector
- `improving_area` → `"emotional_acknowledgment"`
- `recent_pattern_summary` → `"Your communication patterns are developing."`
- `recommended_practice` → `"Try a friendship scenario."`

**What the LLM does NOT do:**
- Access the database directly
- Modify any player state
- See conversation transcripts (only scores and outcomes are passed)

---

## AI vs. Deterministic Boundary Summary

| Decision | Handled By |
|---|---|
| Score player message | LLM (Memory Formation) |
| Select interpretation label | LLM (Memory Formation), vocabulary enforced by code |
| Update NPC metrics | Deterministic code (relationship_service) |
| Resolve NPC state | Deterministic code (state_engine) |
| Resolve relationship tier | Deterministic code (relationship_service) |
| Generate NPC reply | LLM (Character Voice) |
| Select NPC expression | LLM (Character Voice, Scenario Personalization) |
| Generate coach hint | LLM (Character Voice) |
| Signal narrative encounter closure | LLM (Character Voice) — `outcome_triggered` + `end_encounter`; only after `min_turns_before_end` |
| Select scenario | Deterministic code (weighted random, scenario_service) |
| Personalize opening line | LLM (Scenario Personalization) |
| Detect Observer pattern | Deterministic code (counter, observer_service) |
| Phrase Observer message | LLM (Observer Phrasing) |
| Determine narrative_outcome | LLM (Character Voice) — stored in session; null if ended by safety limit |
| Determine performance_outcome | Deterministic code (progression_service) — always computed from avg_scores |
| Calculate XP | Deterministic code (progression_service) |
| Update skill vector | Deterministic code (progression_service) |
| Level-up check | Deterministic code (progression_service) |
| Generate player report | LLM (Report Generation), defaults applied by code |
