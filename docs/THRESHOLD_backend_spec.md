# THRESHOLD — Backend Specification

**Audience:** backend developer, AI coding agent
**Scope:** this document defines the complete backend. The backend is authoritative. The frontend only renders backend responses.

The backend is the game engine. It must be fully playable, testable, and demonstrable without any graphical frontend — every gameplay decision (what situation the player encounters, how a character feels, what they say, what changed, what the player is told) is made here. Any client capable of sending HTTP requests and displaying text — Godot, a web client, a mobile client, or a command-line client — can drive the entire game against this backend unmodified.

---

## 1. Architecture

### 1.1 Services and responsibilities

| Service | Owns | Does not own |
|---|---|---|
| **Player Service** | player identity, session/skill vector, level, streak state | NPC data, scenario content |
| **NPC Service** | NPC registry (identity, personality, metric definitions, state rules) | conversation content, live memory |
| **Memory Service** | per-NPC memory entries, interpretation vocabulary, memory retrieval for context assembly | scoring math, dialogue generation |
| **Scenario Service** | seed bank, weighted category selection, seed filtering/exclusion logic | NPC identity, LLM calls |
| **Scoring Service** | invokes the Memory Formation AI module, returns four-dimension scores + interpretation label | metric math, dialogue |
| **Relationship Service** | metric values, metric update math, relationship tier resolution | scoring, dialogue |
| **State Engine** | deterministic NPC state resolution (constrained-grammar rule evaluation) | LLM calls of any kind |
| **Observer Service** | pattern trigger detection (same-NPC repeated interpretation), invokes Observer phrasing call | scoring, state, memory writing |
| **Progression Service** | skill vector aggregation, XP/level calculation, distribution band lookup | scoring math itself |
| **LLM Service** | all model calls (Memory Formation, Character Voice, Scenario Personalization, Observer Phrasing, Report Generation), structured-output enforcement | any game-state decision |

### 1.2 Request flow (representative — a single player message)

```
Client → POST /interaction/message
   ↓
Player Service: load player_id session + skill vector
   ↓
Memory Service: load this NPC's memory + conversation history
   ↓
Scoring Service → LLM Service (Memory Formation call)
   ↓ returns { clarity, empathy, politeness, expression, interpretation }
   ↓
Relationship Service: apply metric_updates using scores → new metric values
   ↓
State Engine: evaluate state_rules against new metrics → resolved state
   ↓
Relationship Service: resolve relationship_tier from trust + archetype_role
   ↓
Memory Service: write new memory entry (event + interpretation + turn)
   ↓
Observer Service: check trigger condition against this NPC's memory (not fired on every turn — see Section 7)
   ↓
Character Voice call → LLM Service, given resolved state + memory + scenario context
   ↓ returns npc_reply + npc_expression
   ↓
Progression Service: update skill_vector, XP
   ↓
Response assembled per API Contract (Section 8) → returned to client
```

**Authority rule, stated explicitly:** the frontend never computes a score, a metric, a state, a relationship tier, or an Observer trigger. Every one of those values is computed server-side and handed to the client as a finished result.

---

## 2. Data Models

### 2.1 Player

```json
{
  "player_id": "12345",
  "level": 23,
  "skill_vector": { "clarity": 0.65, "empathy": 0.72, "politeness": 0.58, "expression": 0.61 },
  "xp_progress": 0.42,
  "daily_streak": 4,
  "created_at": "2026-08-01T09:00:00Z"
}
```

State is permanent per `player_id`. There is no authentication layer — a given ID is trusted as-is. A fresh `player_id` always starts with default values and no relationship history with any NPC.

### 2.2 NPC (static registry entry)

```json
{
  "id": "sara",
  "archetype_role": "friend",
  "name": "Sara",
  "base_personality": "Direct but caring, reads as blunt if you don't know her.",
  "communication_style": "Casual, expressive, texts in fragments.",
  "metrics": {
    "trust": { "start": 0.7, "min": 0, "max": 1 },
    "patience": { "start": 0.6, "min": 0, "max": 1 },
    "openness": { "start": 0.4, "min": 0, "max": 1 }
  },
  "metric_updates": {
    "trust": { "influenced_by": { "empathy": 0.6, "clarity": 0.4 }, "turn_decay": 0.0 },
    "patience": { "influenced_by": { "politeness": 1.0 }, "turn_decay": 0.05 },
    "openness": { "influenced_by": { "expression": 0.7, "empathy": 0.3 }, "turn_decay": 0.0 }
  },
  "state_rules": [
    { "condition": "trust < 0.3", "state": "guarded" },
    { "condition": "trust >= 0.3 and patience < 0.3", "state": "irritated" },
    { "condition": "trust >= 0.6 and openness >= 0.6", "state": "warm" },
    { "condition": "default", "state": "neutral" }
  ]
}
```

NPCs are defined entirely as static configuration (YAML or JSON, loaded at startup or from a content store). Adding a new NPC — new identity, new metric set, new state rules — requires no code change, only a new registry entry.

### 2.3 NPC metrics (live, per player × per NPC)

```json
{
  "player_id": "12345",
  "npc_id": "sara",
  "metrics": { "trust": 0.58, "patience": 0.55, "openness": 0.32 },
  "current_state": "irritated",
  "relationship_tier": "Comfortable"
}
```

### 2.4 Relationship state (derived, not separately stored)

`relationship_tier` is computed from `metrics.trust` and `archetype_role` at read time (or cached alongside metrics for convenience) — see Section 5.3 for the tier table. It is never itself the source of truth; `trust` is.

### 2.5 Memory entries

```json
{
  "player_id": "12345",
  "npc_id": "sara",
  "entries": [
    { "event": "player_declined_help", "interpretation": "avoided_emotional_acknowledgment", "turn": 4 },
    { "event": "dismissed_feeling_ignored", "interpretation": "avoided_emotional_acknowledgment", "turn": 9 }
  ]
}
```

Memory is scoped per `(player_id, npc_id)` pair. `interpretation` values are drawn only from the fixed vocabulary defined by the active scenario seed's `failure_signal` / `success_signal` fields (Section 6) — never freely generated text. Full memory for an NPC is loaded and passed as context on every subsequent LLM call involving that NPC.

### 2.6 Scenario seeds

```yaml
- id: felt_ignored_lately
  compatible_roles: [friend]
  category: friendship
  tier: 2
  title: "The Distance"
  npc_context:
    metric_overrides: { openness: 0.3 }
  context:
    premise: "They've noticed you've been distant lately and want to talk about it."
    stakes: "The relationship itself, not a task outcome."
    opening_line_seed: "Hey... can I ask why you've been off lately?"
    npc_goal: "Wants to feel heard, not fixed."
  scoring_focus: { primary: empathy, secondary: expression }
  success_signal: "Acknowledges their feelings before explaining yourself."
  failure_signal: "avoided_emotional_acknowledgment"
  possible_outcomes:
    good: "They feel heard; trust rises."
    neutral: "Conversation resolves but stays guarded."
    poor: "They shut down; trust drops."
```

Full seed bank content, all six MVP seeds, is defined in Section 6.

### 2.7 Interaction sessions (transient, per active encounter)

```json
{
  "player_id": "12345",
  "npc_id": "sara",
  "scenario_id": "felt_ignored_lately",
  "turn_count": 3,
  "conversation_history": [
    { "role": "npc", "text": "Hey... can I ask why you've been off lately?" },
    { "role": "player", "text": "I've just been busy." },
    { "role": "npc", "text": "I understand, but I wish you'd told me." }
  ],
  "encounter_over": false
}
```

Session state exists only for the duration of an active encounter; on completion it is finalized into memory (Section 2.5) and discarded as a live session.

### 2.8 Skill vectors

```json
{ "clarity": 0.65, "empathy": 0.72, "politeness": 0.58, "expression": 0.61 }
```

Stored on the Player record (Section 2.1), updated after every completed encounter using that encounter's scores, weighted toward the active seed's `scoring_focus`.

### 2.9 Reports

```json
{
  "current_level": 23,
  "skill_vector": { "clarity": 0.65, "empathy": 0.72, "politeness": 0.58, "expression": 0.61 },
  "strongest_skill": "empathy",
  "improving_area": "conflict_resolution",
  "recent_pattern_summary": "You explain your ideas clearly, but often skip acknowledging other people's concerns.",
  "recommended_practice": "Team disagreement scenarios"
}
```

Generated on demand at `/interaction/report`, not stored — computed fresh from the player's skill vector and recent session history each time.

---

## 3. NPC System

NPC-specific metrics, personality, communication style, and archetype role are all defined per Section 2.2. Each NPC's metric *set* is independent — one NPC is not required to track the same emotional axes as another (Sara tracks trust/patience/openness; Mr. Teo tracks trust/respect). This is intentional: it is what makes archetypes feel structurally distinct rather than palette-swapped copies of a single generic "mood."

**Adding a new NPC** requires only a new registry entry containing: identity fields, a metric set with start/min/max per metric, a `metric_updates` block mapping the four scored dimensions to that NPC's metrics with weights, and a `state_rules` list. No service code changes.

**Archetype roles are fixed** to `teacher`, `friend`, `colleague`, `client` — matching the hackathon brief's named character categories directly. This value is used by the Scenario Service to filter compatible seeds (Section 6) and by the Relationship Service to select the correct tier label set (Section 5.3).

---

## 4. AI Pipeline

The LLM is used in five distinct calls, each with a narrow, explicit job. No call is permitted to make a game-state decision outside its designated scope.

### 4.1 Memory Formation AI

**Input:** the player's message, the active scenario's fixed context (premise, stakes, npc_goal, scoring_focus), the NPC's conversation history so far.

**Output (structured):**
```json
{
  "clarity": 0.8, "empathy": 0.4, "politeness": 0.7, "expression": 0.6,
  "interpretation": "avoided_emotional_acknowledgment"
}
```

**Responsible for:** scoring the player's message across the four fixed communication dimensions, and selecting one `interpretation` label from the vocabulary defined by the active seed's `success_signal` / `failure_signal` fields (Section 6) — never a freely-generated label.

**Not responsible for:** updating any metric, deciding any NPC state, writing any dialogue.

### 4.2 Character Voice AI

**Input:** the NPC's resolved `state` (from the deterministic State Engine, Section 5), the NPC's memory entries, the active scenario's fixed context, conversation history.

**Output (structured):**
```json
{ "npc_reply": "I understand, but I wish you'd told me.", "npc_expression": "hurt" }
```

**Responsible for:** generating what the character says and which expression enum best fits it, constrained to be consistent with the state and memory it is given.

**Not responsible for:** deciding what state the character is in, updating any metric, inventing new scenario content.

### 4.3 Scenario Personalization AI

**Input:** the selected seed (full object), the NPC's identity, the NPC's resolved starting metrics for this encounter, the player's profile.

**Output (structured):**
```json
{ "opening_line": "Hey... can I ask why you've been off lately?", "npc_expression": "concerned" }
```

**Responsible for:** personalizing tone and wording of the opening line to this NPC's communication style and this player's history.

**Explicitly instructed not to alter:** `premise`, `stakes`, `npc_goal`, or `possible_outcomes` — these are fixed inputs, never generation targets. This is the mechanism that guarantees the LLM never invents a new scenario premise at runtime.

### 4.4 Observer Phrasing AI

**Input:** the two (or more) matching memory entries that triggered the Observer condition (Section 7).

**Output (structured):**
```json
{ "message": "Twice now, with the same person, you've moved past what they were feeling before addressing it." }
```

**Responsible for:** phrasing the reveal line in a grounded, factual register.

**Not responsible for:** deciding whether the Observer fires — that is a deterministic count check performed before this call is ever made (Section 7).

### 4.5 Report Generation AI

**Input:** the player's skill vector, recent completed encounter summaries.

**Output (structured):** the report fields defined in Section 2.9.

### 4.6 Explicit LLM boundaries

Across all five calls, the LLM does **not**:
- decide an NPC's emotional state (the State Engine does, Section 5)
- update any metric value (the Relationship Service does, using deterministic math, Section 5.1)
- detect Observer patterns (a deterministic count check does, Section 7)
- select which scenario/seed is used (the Scenario Service's weighted-random selection does, Section 6.2)
- modify any stored game state directly — every LLM call returns data; only service code writes to state.

---

## 5. Deterministic State Engine

### 5.1 Metric updates

Given the four scores from a Memory Formation call, each NPC's `metric_updates` config (Section 2.2) determines how each of that NPC's own metrics changes:

```
new_value = clamp(
  old_value
  + sum(score[dimension] * weight for dimension, weight in influenced_by.items())
  - turn_decay,
  min, max
)
```

Example (Sara, `trust`, given `empathy: 0.4, clarity: 0.8`, `influenced_by: {empathy: 0.6, clarity: 0.4}`):
```
delta = (0.4 * 0.6) + (0.8 * 0.4) = 0.24 + 0.32 = 0.56
```
This delta is combined with the existing trust value using a tunable update rule (e.g. a weighted move toward the delta, not a raw add) — exact blending formula is an implementation detail to tune during build, but the inputs and their weights are fixed by this config, not by the LLM.

### 5.2 State resolution

`state_rules` are evaluated in order, first match wins. The grammar is intentionally restricted: `<metric_name> <operator> <number>`, chained only with `and` / `or`, plus a required `default` fallback rule. No arbitrary expression evaluation — this keeps rule evaluation safe, testable in isolation, and trivial to extend via configuration alone.

```yaml
sara:
  state_rules:
    - condition: "trust < 0.3"
      state: guarded
    - condition: "trust >= 0.3 and patience < 0.3"
      state: irritated
    - condition: "trust >= 0.6 and openness >= 0.6"
      state: warm
    - condition: "default"
      state: neutral
```

The resolved `state` value is passed to the Character Voice call (Section 4.2) as a fixed instruction, along with a short behavior fragment associated with that state (tone, terseness, whether the character references memory) — the LLM writes inside this state, it does not choose it.

### 5.3 Relationship tiers

`trust` is not exposed to the client as a raw float. It is resolved to a named tier via fixed thresholds, with tier *labels* selected by `archetype_role` so language stays appropriate to the relationship type:

```yaml
relationship_tiers:
  thresholds: [0.0, 0.25, 0.45, 0.65, 0.85]   # lower bound of each tier

  labels:
    friend:    [Stranger, Acquaintance, Comfortable, Trusted, Close Friend]
    teacher:   [Unfamiliar, Noted, Respected, Trusted, Regarded Highly]
    colleague: [Unfamiliar, Coworker, Dependable, Trusted, Strong Ally]
    client:    [Unknown, Skeptical, Professional, Reliable, Trusted Partner]
```

`relationship_tier` is computed server-side and included directly in API responses (Section 8) as a ready-to-render string — the client performs no threshold logic of its own.

---

## 6. Scenario System

### 6.1 Seed bank (MVP — six seeds)

```yaml
seeds:
  - id: missed_deadline_explain
    compatible_roles: [teacher, colleague]
    category: workplace
    tier: 2
    title: "The Late Submission"
    npc_context: { metric_overrides: {} }
    context:
      premise: "You missed a deadline by two days and need to explain yourself."
      stakes: "Consequence is real but negotiable depending on how you handle it."
      opening_line_seed: "So — tell me what happened."
      npc_goal: "Wants ownership before deciding leniency."
    scoring_focus: { primary: clarity, secondary: politeness }
    success_signal: "Owns the mistake plainly, proposes a fix or accepts consequence gracefully."
    failure_signal: "avoided_emotional_acknowledgment"
    possible_outcomes:
      good: "Leniency granted; relationship unaffected or slightly improved."
      neutral: "Consequence applies; professional tone maintained."
      poor: "Consequence applies; trust drops."

  - id: felt_ignored_lately
    compatible_roles: [friend]
    category: friendship
    tier: 2
    title: "The Distance"
    npc_context: { metric_overrides: { openness: 0.3 } }
    context:
      premise: "They've noticed you've been distant lately and want to talk about it."
      stakes: "The relationship itself, not a task outcome."
      opening_line_seed: "Hey... can I ask why you've been off lately?"
      npc_goal: "Wants to feel heard, not fixed."
    scoring_focus: { primary: empathy, secondary: expression }
    success_signal: "Acknowledges their feelings before explaining yourself."
    failure_signal: "avoided_emotional_acknowledgment"
    possible_outcomes:
      good: "They feel heard; trust rises."
      neutral: "Conversation resolves but stays guarded."
      poor: "They shut down; trust drops."

  - id: unhappy_with_deliverable
    compatible_roles: [client, colleague]
    category: high_pressure
    tier: 3
    title: "The Pushback"
    npc_context: { metric_overrides: {} }
    context:
      premise: "They're unhappy with what you delivered and think it missed the mark."
      stakes: "Professional credibility, possibly the relationship itself."
      opening_line_seed: "This isn't really what we discussed."
      npc_goal: "Wants to know you understand the gap before trusting a fix."
    scoring_focus: { primary: clarity, secondary: empathy }
    success_signal: "Validates the concern specifically before proposing next steps."
    failure_signal: "avoided_emotional_acknowledgment"
    possible_outcomes:
      good: "They agree to a revised plan; tension eases."
      neutral: "They accept a fix but stay cool."
      poor: "Trust drops significantly; they escalate or disengage."

  - id: first_meeting_small_talk
    compatible_roles: [friend, colleague]
    category: everyday_social
    tier: 1
    title: "Breaking the Ice"
    npc_context: { metric_overrides: { trust: 0.4 } }
    context:
      premise: "A casual, low-stakes first conversation — getting to know each other."
      stakes: "Low. Sets the tone for the relationship going forward."
      opening_line_seed: "Hey, I don't think we've properly met — how's your week going?"
      npc_goal: "Wants a genuine, comfortable exchange, nothing more."
    scoring_focus: { primary: expression, secondary: politeness }
    success_signal: "Responds warmly and asks something back, keeps the exchange two-way."
    failure_signal: "closed_off_exchange"
    possible_outcomes:
      good: "Comfortable rapport established; trust rises."
      neutral: "Polite but forgettable exchange."
      poor: "Feels awkward or one-sided; trust stagnates."

  - id: asking_for_extension
    compatible_roles: [teacher]
    category: everyday_social
    tier: 1
    title: "The Ask"
    npc_context: { metric_overrides: {} }
    context:
      premise: "You need to ask for an extension on an assignment, and you know it's a big ask."
      stakes: "Low-to-moderate — a reasonable request, badly delivered, can still go wrong."
      opening_line_seed: "You wanted to see me about the assignment?"
      npc_goal: "Wants a clear, honest reason, not excessive justification."
    scoring_focus: { primary: clarity, secondary: politeness }
    success_signal: "States the request plainly and briefly, respects her time."
    failure_signal: "rambled_unclear_ask"
    possible_outcomes:
      good: "Extension granted, professional tone maintained."
      neutral: "Partial extension or conditions attached."
      poor: "Denied; trust drops due to poor communication, not the request itself."

  - id: teammate_not_pulling_weight
    compatible_roles: [colleague]
    category: high_pressure
    tier: 3
    title: "The Confrontation"
    npc_context: { metric_overrides: { guardedness: 0.6 } }
    context:
      premise: "You need to address that they haven't been contributing to shared work, without damaging the relationship irreparably."
      stakes: "High — an emotionally loaded confrontation with someone conflict-avoidant."
      opening_line_seed: "You wanted to talk to me about something?"
      npc_goal: "Is bracing for blame and will shut down if attacked directly."
    scoring_focus: { primary: empathy, secondary: clarity }
    success_signal: "Names the issue directly but frames it collaboratively, not as an accusation."
    failure_signal: "blamed_outright"
    possible_outcomes:
      good: "They open up about why they've been checked out; issue starts resolving."
      neutral: "They agree to do better but stay defensive."
      poor: "They shut down entirely; trust drops significantly."
```

`failure_signal` (and `success_signal`, where used) values double as the fixed `interpretation` vocabulary for memory writing (Section 2.5) and Observer matching (Section 7) — one controlled vocabulary, not two separate lists to keep in sync.

Seeds are pure content. Adding a new seed, or a new `category`, requires only a new YAML entry — no service code change, since selection logic (6.2) reads whatever categories exist rather than a hardcoded list.

### 6.2 Weighted selection

```yaml
distribution_bands:
  - level_range: [1, 30]
    weights: { everyday_social: 60, friendship: 25, workplace: 10, high_pressure: 5 }
  - level_range: [31, 70]
    weights: { everyday_social: 20, friendship: 30, workplace: 35, high_pressure: 15 }
  - level_range: [71, 100]
    weights: { everyday_social: 5, friendship: 20, workplace: 35, high_pressure: 40 }
```

**Algorithm:**
```
1. Read npc.archetype_role for the approached NPC.
2. Determine the player's distribution_band from their level.
3. Weighted-random pick a category from that band's weights.
4. Filter seed_bank WHERE compatible_roles CONTAINS archetype_role
                    AND category == picked category.
5. If the filtered pool is empty, fall back to the nearest available
   category that has seeds for this NPC (graceful degradation —
   never error).
6. Exclude any seed_id already used with this NPC this session;
   pick randomly among what remains.
7. Resolve the NPC's effective starting metrics: use the NPC's
   currently saved state if it has prior history this session,
   otherwise layer the seed's metric_overrides on top of the NPC's
   registry defaults.
8. Invoke the Scenario Personalization AI (Section 4.3) with the
   selected seed, NPC identity, and resolved metrics.
```

### 6.3 Personalization boundaries

The LLM personalizes delivery — wording, tone — within an authored scenario. It never invents a new scenario. `premise`, `stakes`, `npc_goal`, and `possible_outcomes` are fixed inputs to every LLM call that touches this seed and are never treated as generation targets by any prompt in this system.

---

## 7. Observer System

**Scope:** single-NPC only. The Observer never aggregates or compares across different characters — it detects repetition only within one NPC's own memory.

**Trigger (deterministic, computed in service code — never by the LLM):**
```
count(entry.interpretation == X for entry in npc_memory) >= 2  →  fire
```

This is a plain filter/count over memory entries that already exist for scoring purposes (Section 2.5) — no separate evidence store, no confidence scoring.

**Generation rule:** once the trigger condition is met, the two (or more) matching memory entries are passed to the Observer Phrasing AI (Section 4.4), which generates the reveal line. The AI phrases; it does not decide whether to fire.

**Firing point:** checked once, at the close of an encounter (`/interaction/end`), not after every message. `observer_event.fired` is `false` on the large majority of encounters.

**Scope limitation, stated explicitly:** there is no mechanism, planned or implemented, by which the Observer compares memory across two different NPCs. This is a deliberate architectural boundary, not a current gap — implementing cross-NPC correlation is out of scope for this build.

---

## 8. API Contract

### `POST /interaction/start`

Request:
```json
{ "player_id": "12345", "npc_id": "sara" }
```

Response:
```json
{
  "npc_name": "Sara",
  "npc_expression": "concerned",
  "opening_line": "Hey... can I ask why you've been distant lately?",
  "interaction_id": "felt_ignored_lately",
  "encounter_over": false
}
```

Errors: `404` if `npc_id` is not in the registry. `200` always returned for a valid, unknown-to-backend `player_id` — a new player record is created on first contact.

### `POST /interaction/message`

Request:
```json
{ "player_id": "12345", "npc_id": "sara", "message": "I've just been busy." }
```

Response:
```json
{
  "npc_expression": "hurt",
  "npc_reply": "I understand, but I wish you'd told me. I thought I did something wrong.",
  "coach_hint": { "shown": true, "line": "She's mentioned feeling ignored twice now." },
  "stat_deltas": { "clarity": 0.80, "empathy": 0.35, "politeness": 0.70, "expression": 0.60 },
  "npc_metrics": { "trust": 0.58, "patience": 0.55, "openness": 0.32 },
  "relationship_tier": "Comfortable",
  "npc_state": "irritated",
  "feedback": {
    "strength": "You explained your situation clearly.",
    "improvement": "You responded to the reason, but not the feeling behind it."
  },
  "encounter_over": false
}
```

**Coach hint rule:** the `coach_hint.line` must state a noticed fact about the conversation, never a suggested response — enforced in the system prompt for the call that generates it. A prescriptive hint (telling the player what to say) is treated as a defect, not a style choice.

**Coach hint timing:** the hint returned in a given response is meant to inform the player's *next* message — ambient situational awareness, not retrospective grading.

Errors: `404` if no active session exists for this `(player_id, npc_id)` pair — client must call `/interaction/start` first. `400` if `message` is empty.

### `POST /interaction/end`

Fires when the active scenario's encounter concludes (determined server-side, based on turn count and/or scored outcome relative to the seed's `possible_outcomes`).

Response:
```json
{
  "observer_event": {
    "fired": true,
    "npc_id": "sara",
    "message": "Twice now, with the same person, you've moved past what they were feeling before addressing it."
  },
  "encounter_summary": { "outcome": "neutral" }
}
```

`observer_event.fired` is `false` on most encounters — the Observer speaks only when the Section 7 trigger condition is met that turn.

### `POST /interaction/report`

Called once, at the true end of a session (not after every encounter).

Response:
```json
{
  "current_level": 23,
  "skill_vector": { "clarity": 0.65, "empathy": 0.72, "politeness": 0.58, "expression": 0.61 },
  "strongest_skill": "empathy",
  "improving_area": "conflict_resolution",
  "recent_pattern_summary": "You explain your ideas clearly, but often skip acknowledging other people's concerns.",
  "recommended_practice": "Team disagreement scenarios"
}
```

### `GET /interaction/daily`

Response:
```json
{ "seed_id": "first_meeting_small_talk", "npc_id": "jun", "focus": "Expression + Confidence", "streak_count": 4 }
```

Returns a real, state-backed featured scenario and the player's current streak — not a static value.

### `POST /player/reset`

Utility endpoint for demo and testing convenience. Given a `player_id`, clears all associated state (skill vector, level, all NPC metrics/memory/relationship tiers for that ID) back to defaults, without requiring a new ID to be issued.

Request:
```json
{ "player_id": "12345" }
```

Response:
```json
{ "player_id": "12345", "reset": true }
```

This does not change the underlying design principle that state is permanent per `player_id` — it simply gives an explicit, intentional way to return a specific ID to a clean state on demand, which is operationally useful for repeatable demo recording.

### 8.1 General contract rules

Every response field is one of exactly three kinds:
- an **enum** (e.g. `npc_expression`, `npc_state`) — the client maps it directly to a pre-built asset, never interprets it,
- a **number** (e.g. `stat_deltas`, `npc_metrics` values) — the client renders/tweens it directly,
- **plain text** (e.g. `npc_reply`, `feedback.improvement`, `observer_event.message`) — the client displays it directly.

No response requires the client to perform any conditional logic to determine meaning.

---

## 9. Backend Non-Goals

This specification explicitly excludes and forbids:

- any frontend implementation detail (rendering, UI layout, animation, input handling)
- any Godot-specific code, scene structure, or asset reference
- any assumption about a specific client technology — this backend must be equally usable by a Godot client, a web client, a mobile client, or a command-line test harness
- client-side game logic of any kind — the backend must remain the sole source of truth for every gameplay decision described in this document