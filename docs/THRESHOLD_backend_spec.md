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
| **NPC Service** | NPC templates (identity, personality, metric definitions, state rules); NPC instance creation from templates | player-specific memories, relationship metric values, live NPC instance state |
| **Memory Service** | per-instance memory entries, interpretation vocabulary, memory retrieval for context assembly | scoring math, dialogue generation |
| **Scenario Service** | seed bank, weighted category selection, seed filtering/exclusion logic | NPC identity, LLM calls |
| **Scoring Service** | coordinates the Memory Formation pipeline: calls LLM Service with the player message and session context, receives and returns the four-dimension scores + interpretation label | metric math, dialogue, LLM execution |
| **Relationship Service** | metric update calculations, relationship tier resolution | scoring, dialogue; does not own the NPC instance data entity itself |
| **State Engine** | deterministic NPC state resolution (constrained-grammar rule evaluation) | LLM calls of any kind |
| **Observer Service** | pattern trigger detection (same-NPC-instance repeated interpretation) at encounter close; calls LLM Service (Observer Phrasing pipeline) when trigger fires | scoring, state, memory writing; does not own memory; does not execute LLM calls directly |
| **Progression Service** | skill vector aggregation, XP/level calculation, distribution band lookup; owns the XP gain and level threshold formulas | scoring math itself |
| **LLM Service** | all model calls (Memory Formation, Character Voice, Scenario Personalization, Observer Phrasing, Report Generation), structured-output enforcement | any game-state decision |

### 1.2 Core data ownership model

NPCs are represented at two distinct levels that must never be merged:

**NPC Template** — a global static definition. Shared across all players. Contains identity, personality, communication style, archetype role, metric definitions, metric update rules, and state rules. Templates are immutable at runtime.

**NPC Instance** — a player-owned persistent entity. Created the first time a player interacts with a given NPC. Contains the player's live relationship state with that NPC: current metric values, accumulated memories, derived state cache, and relationship tier. One NPC Instance exists per (player, NPC template) pair.

The ownership hierarchy is:

```
Player
 └── NPC Instances
        ├── template_id          (reference to NPC Template)
        ├── metrics              (live per-player metric values)
        ├── memory               (persistent relationship knowledge)
        ├── current_state        (cache — derived from metrics via State Engine)
        └── active_session       (transient — exists only during an encounter)
```

All player-specific NPC data is owned by and accessed through the NPC Instance. There is no floating `(player_id, npc_id)` ownership model — player identity is established by the instance itself.

### 1.3 Request flow (representative — a single player message)

```
Client → POST /interaction/message
   ↓
Player Service: load player_id session + skill vector
   ↓
NPC Service: resolve player_id + npc_id → NPC instance
   ↓
Memory Service: load instance memory + active session conversation history
   ↓
Scoring Service → LLM Service (Memory Formation pipeline)
   ↓ returns { clarity, empathy, politeness, expression, interpretation }
   ↓
Relationship Service: apply metric_updates using scores → new metric values on instance
   ↓
State Engine: evaluate state_rules against new metrics → resolved state (written to instance cache)
   ↓
Relationship Service: resolve relationship_tier from instance.metrics.trust + template.archetype_role
   ↓
Memory Service: write new memory entry to NPC instance (event + interpretation + turn)
   ↓
LLM Service (Character Voice pipeline): given resolved state + instance memory + conversation history + scenario context
   ↓ returns { npc_reply, npc_expression, coach_hint }
   ↓
Progression Service: update skill_vector, XP
   ↓
Response assembled per API Contract (Section 8) → returned to client
```

The Observer Service is **not** invoked during message processing. It runs once at encounter close (`POST /interaction/end`). See Section 1.3.1 and Section 7.

**Authority rule, stated explicitly:** the frontend never computes a score, a metric, a state, a relationship tier, or an Observer trigger. Every one of those values is computed server-side and handed to the client as a finished result.

### 1.3.1 Request flows — encounter start and encounter end

**`POST /interaction/start` — internal flow:**
```
Player Service: load or create player record
   ↓
NPC Service: resolve player_id + npc_id → NPC Instance (create if first contact)
   ↓
Scenario Service: select seed (Section 6.2 steps 1–7)
   ↓ returns selected seed + effective encounter starting metrics
   ↓
Session created on NPC Instance: scenario_id, encounter_modifiers, empty conversation_history
   ↓
LLM Service (Scenario Personalization pipeline): given seed + NPC template identity + encounter starting metrics
   ↓ returns { opening_line, npc_expression }
   ↓
Response assembled per API Contract (Section 8) → returned to client
```

**`POST /interaction/end` — internal flow:**
```
Memory Service: finalize encounter — scored outcomes written as new memory entries to NPC Instance
   ↓
Observer Service: read NPC Instance memory; apply deterministic count check (Section 7)
   ↓ if trigger fires → LLM Service (Observer Phrasing pipeline) → returns { message }
   ↓
Progression Service: compute XP gain + skill_vector update from encounter scores
   ↓
Session record discarded from NPC Instance
   ↓
Response assembled per API Contract (Section 8) → returned to client
```

The `encounter_over` flag returned by `POST /interaction/message` signals to the client that the encounter is complete and the client should call `POST /interaction/end` to finalize. Finalization logic (Observer check, Progression update, session discard) runs only in the `/interaction/end` handler, not in the message handler.

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

State is permanent per `player_id`. There is no authentication layer — a given ID is trusted as-is. A fresh `player_id` always starts with default values and no NPC instances.

### 2.2 NPC Template (static, global)

```json
{
  "id": "sara",
  "archetype_role": "friend",
  "name": "Sara",
  "base_personality": "Direct but caring, reads as blunt if you don't know her.",
  "communication_style": "Casual, expressive, texts in fragments.",
  "metrics": {
    "trust":    { "start": 0.7, "min": 0, "max": 1 },
    "patience": { "start": 0.6, "min": 0, "max": 1 },
    "openness": { "start": 0.4, "min": 0, "max": 1 }
  },
  "metric_updates": {
    "trust":    { "influenced_by": { "empathy": 0.6, "clarity": 0.4 }, "turn_decay": 0.0 },
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

NPC Templates are defined entirely as static configuration (YAML or JSON, loaded at startup or from a content store). Adding a new NPC — new identity, new metric set, new state rules — requires no code change, only a new template entry. Templates are never mutated at runtime. They define the character; they do not hold any player-specific state.

### 2.3 NPC Instance (player-owned, persistent)

```json
{
  "npc_instance_id": "inst_12345_sara",
  "player_id": "12345",
  "template_id": "sara",
  "metrics": { "trust": 0.58, "patience": 0.55, "openness": 0.32 },
  "current_state": "irritated",
  "relationship_tier": "Comfortable"
}
```

An NPC Instance is created the first time `player_id` initiates an interaction with a given `template_id`. Initial metric values are copied from the template's `metrics.start` values. The `player_id` and `template_id` fields establish full ownership — they are not duplicated on child entities (memory, session) that already belong to this instance.

**`current_state` is a cache.** It is not the source of truth. The authoritative derivation is:

```
instance.metrics → State Engine → current_state
```

`current_state` is updated after every metric update and stored for read convenience. If the cache is absent or stale, the State Engine re-derives it from `metrics` on demand. No code path should treat `current_state` as authoritative over a fresh State Engine evaluation.

**`relationship_tier` is derived.** It is computed from `instance.metrics.trust` and `template.archetype_role` (Section 5.3) and included on the instance record as a convenience cache. The source of truth is `trust`; `relationship_tier` is never itself the input to any calculation.

### 2.4 Memory (belongs to NPC Instance)

```json
{
  "npc_instance_id": "inst_12345_sara",
  "entries": [
    { "event": "player_declined_help",    "interpretation": "avoided_emotional_acknowledgment", "turn": 4 },
    { "event": "dismissed_feeling_ignored", "interpretation": "avoided_emotional_acknowledgment", "turn": 9 }
  ]
}
```

Memory belongs to the NPC Instance. Ownership is established by `npc_instance_id` — no separate `player_id` or `npc_id` fields are needed or stored here. `interpretation` values are drawn only from the fixed vocabulary defined by the active scenario seed's `failure_signal` / `success_signal` fields (Section 6) — never freely generated text.

Memory is **long-term relationship knowledge.** It persists across encounters and is loaded as context for every subsequent LLM call involving this NPC instance (Section 4). It is distinct from conversation history (Section 2.5).

### 2.5 Interaction Session (transient, belongs to NPC Instance)

```json
{
  "npc_instance_id": "inst_12345_sara",
  "scenario_id": "felt_ignored_lately",
  "turn_count": 3,
  "conversation_history": [
    { "role": "npc",    "text": "Hey... can I ask why you've been off lately?" },
    { "role": "player", "text": "I've just been busy." },
    { "role": "npc",    "text": "I understand, but I wish you'd told me." }
  ],
  "encounter_modifiers": { "openness": 0.3 },
  "encounter_over": false
}
```

The session belongs to the NPC Instance and exists only for the duration of an active encounter. `conversation_history` is **short-term interaction context** — it is active session only and is discarded when the encounter ends. It is not the same as memory (Section 2.4) and must not be confused with it.

`encounter_modifiers` captures any scenario seed `metric_overrides` that apply for this encounter's starting conditions. These are **temporary encounter context only** — they affect how the encounter begins but do not permanently mutate the NPC instance's metric values (see Section 6.3 for the full boundary).

On encounter completion, the session is finalized: scored outcomes are written to the NPC Instance's memory (Section 2.4) as new memory entries, and the session record is discarded.

**Character Voice AI may receive:** relevant memory entries from the NPC Instance (long-term) and the current conversation history from the active session (short-term). These are separate inputs serving distinct purposes and must not be collapsed into a single context field.

### 2.6 Scenario Seeds

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

`npc_context.metric_overrides` defines **encounter-only starting conditions** for this scenario. They are applied as temporary modifiers to establish the emotional starting point of the encounter; they do not permanently overwrite the NPC instance's persisted metric values. See Section 6.3.

### 2.7 Skill Vectors

```json
{ "clarity": 0.65, "empathy": 0.72, "politeness": 0.58, "expression": 0.61 }
```

Stored on the Player record (Section 2.1), updated after every completed encounter using that encounter's scores, weighted toward the active seed's `scoring_focus`.

### 2.8 Reports

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

Generated on demand at `/interaction/report`, not stored — computed fresh from the player's skill vector and recent session history each time. The Report Generation AI interprets the four-dimension skill vector and recent encounter history to produce its output. It does not invent new player statistics. Fields such as `improving_area` that reference interpretive labels like `conflict_resolution` are interpretation labels generated by the Report Generation AI from the existing skill vector and recent encounter history — they are not separately tracked player statistics. The report generator cannot produce a field that does not derive from the skill vector or encounter data it is given.

---

## 3. NPC System

### 3.1 Templates and instances

NPC Templates define the character: identity, personality, communication style, archetype role, the metric set with per-metric definitions, metric update rules, and state rules. Templates are global static definitions — they are never player-specific and never mutated at runtime.

NPC Instances hold the player's relationship with that character. The first time a player initiates an interaction with an NPC, the backend creates an NPC Instance for that (player, template) pair, copying the template's metric start values as the initial metric state. All subsequent interaction reads from and writes to the instance, not the template.

Each NPC template's metric set is independent — one NPC is not required to track the same emotional axes as another (Sara tracks trust/patience/openness; Mr. Teo tracks trust/respect). This is intentional: it is what makes archetypes feel structurally distinct rather than palette-swapped copies of a single generic "mood."

**Adding a new NPC** requires only a new template entry containing: identity fields, a metric set with start/min/max per metric, a `metric_updates` block mapping the four scored dimensions to that NPC's metrics with weights, and a `state_rules` list. No service code changes.

### 3.2 NPC Service responsibility boundary

The NPC Service owns:
- NPC templates (loading, validation, registry)
- NPC instance creation from templates
- resolution of `player_id` + `npc_id` → NPC Instance

The NPC Service does **not** own:
- player-specific memory entries (Memory Service)
- relationship metric values (live on the NPC Instance; updated by Relationship Service calculations)
- live NPC state resolution (State Engine)

### 3.3 Archetype roles

Archetype roles are fixed to `teacher`, `friend`, `colleague`, `client` — matching the hackathon brief's named character categories directly. This value is used by the Scenario Service to filter compatible seeds (Section 6) and by the Relationship Service to select the correct tier label set (Section 5.3).

---

## 4. AI Pipeline

The LLM is used in five distinct pipelines, each with a narrow, explicit job. No pipeline is permitted to make a game-state decision outside its designated scope.

**Infrastructure vs. pipeline distinction:** these five (Memory Formation, Character Voice, Scenario Personalization, Observer Phrasing, Report Generation) are logical pipeline definitions — each with its own fixed input set, output schema, and system-prompt constraints. They are all executed by the LLM Service (Section 1.1), which owns model selection, structured-output enforcement, retry logic, and prompt assembly. They are not separately deployable services. Adding a new pipeline requires a new LLM Service call definition and system prompt, not a new service.

### 4.1 Memory Formation AI

**Input:** the player's message, the active scenario's fixed context (premise, stakes, npc_goal, scoring_focus), the NPC instance's conversation history for this session.

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

**Input:** the NPC instance's resolved `state` (from the deterministic State Engine, Section 5), the NPC instance's memory entries (long-term, from Memory Service), the active session's conversation history (short-term), the active scenario's fixed context.

**Output (structured):**
```json
{ "npc_reply": "I understand, but I wish you'd told me.", "npc_expression": "hurt" }
```

**Responsible for:** generating what the character says, which expression enum best fits it, and the `coach_hint` (a noticed fact about the current conversation — never a prescribed response). All three are constrained to be consistent with the state and memory provided.

**Not responsible for:** deciding what state the character is in, updating any metric, inventing new scenario content.

The `coach_hint` is a secondary structured output of this pipeline. It has access to the NPC state, memory, and conversation history — the same inputs used to generate the NPC reply — making this the correct pipeline to produce ambient situational awareness for the player. Its system prompt enforces: state a noticed fact, never tell the player what to say.

### 4.3 Scenario Personalization AI

**Input:** the selected seed (full object), the NPC template's identity fields, the NPC instance's resolved starting metrics for this encounter, the player's profile.

**Output (structured):**
```json
{ "opening_line": "Hey... can I ask why you've been off lately?", "npc_expression": "concerned" }
```

**Responsible for:** personalizing tone and wording of the opening line to this NPC's communication style and this player's history.

**Explicitly instructed not to alter:** `premise`, `stakes`, `npc_goal`, or `possible_outcomes` — these are fixed inputs, never generation targets. This is the mechanism that guarantees the LLM never invents a new scenario premise at runtime.

### 4.4 Observer Phrasing AI

**Input:** the two (or more) matching memory entries from the NPC instance that triggered the Observer condition (Section 7).

**Output (structured):**
```json
{ "message": "Twice now, with the same person, you've moved past what they were feeling before addressing it." }
```

**Responsible for:** phrasing the reveal line in a grounded, factual register.

**Not responsible for:** deciding whether the Observer fires — that is a deterministic count check performed before this call is ever made (Section 7).

### 4.5 Report Generation AI

**Input:** the player's skill vector, recent completed encounter summaries.

**Output (structured):** the report fields defined in Section 2.8.

The Report Generation AI interprets and phrases; it does not change metrics, choose scenarios, resolve state, trigger observers, or modify any stored state. It operates under the same LLM boundary rules as all other AI calls.

### 4.6 Explicit LLM boundaries

Across all five calls, the LLM does **not**:
- decide an NPC's emotional state (the State Engine does, Section 5)
- update any metric value (the Relationship Service does, using deterministic math, Section 5.1)
- detect Observer patterns (a deterministic count check does, Section 7)
- select which scenario/seed is used (the Scenario Service's weighted-random selection does, Section 6.2)
- modify any stored game state directly — every LLM call returns data; only service code writes to state

---

## 5. Deterministic State Engine

### 5.1 Metric updates

Given the four scores from a Memory Formation call, the NPC template's `metric_updates` config (Section 2.2) determines how each metric on the NPC Instance changes:

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
This delta is combined with the existing trust value on the NPC Instance using a tunable update rule (e.g. a weighted move toward the delta, not a raw add). What is fixed vs. tunable is explicit:

- **Fixed (template-defined, not tunable at runtime):** the four input scores (from Memory Formation AI), the `influenced_by` dimension weights per metric, and the `turn_decay` value — all defined in the NPC Template.
- **Fixed (system behaviour):** the LLM has zero influence over any metric calculation. It provides scores; arithmetic does the rest.
- **Tunable (implementation detail):** the specific blending/accumulation function (e.g., how aggressively the new delta moves the current value) — this is the one knob available during build. It does not change which inputs are used or who owns the calculation.

The Relationship Service performs this calculation. The updated metric values are written back to the NPC Instance by the service layer. The Relationship Service does not own the NPC Instance data entity; it computes the new values and instructs the write.

### 5.2 State resolution

`state_rules` from the NPC Template are evaluated in order against the NPC Instance's current metrics, first match wins. The grammar is intentionally restricted: `<metric_name> <operator> <number>`, chained only with `and` / `or`, plus a required `default` fallback rule. No arbitrary expression evaluation — this keeps rule evaluation safe, testable in isolation, and trivial to extend via configuration alone.

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

The resolved `state` value is the authoritative output of this evaluation. It is stored as the `current_state` cache on the NPC Instance (Section 2.3) and passed to the Character Voice call (Section 4.2) as a fixed instruction, along with a short behavior fragment associated with that state (tone, terseness, whether the character references memory) — the LLM writes inside this state, it does not choose it.

**Source of truth:** `instance.metrics → State Engine → current_state`. The cache is always derived; if in doubt, re-evaluate.

### 5.3 Relationship tiers

`trust` is not exposed to the client as a raw float. It is resolved to a named tier via fixed thresholds, with tier *labels* selected by `archetype_role` from the NPC Template so language stays appropriate to the relationship type:

```yaml
relationship_tiers:
  thresholds: [0.0, 0.25, 0.45, 0.65, 0.85]   # lower bound of each tier

  labels:
    friend:    [Stranger, Acquaintance, Comfortable, Trusted, Close Friend]
    teacher:   [Unfamiliar, Noted, Respected, Trusted, Regarded Highly]
    colleague: [Unfamiliar, Coworker, Dependable, Trusted, Strong Ally]
    client:    [Unknown, Skeptical, Professional, Reliable, Trusted Partner]
```

`relationship_tier` is computed server-side from the NPC Instance's `trust` metric and the template's `archetype_role`, and is included directly in API responses (Section 8) as a ready-to-render string — the client performs no threshold logic of its own. The Relationship Service owns this derivation. The derived tier is never itself the input to any subsequent calculation; `trust` remains the source of truth.

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
    npc_context: { metric_overrides: { trust: 0.35 } }  # override must reference a metric defined in the colleague NPC template
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

`failure_signal` (and `success_signal`, where used) values double as the fixed `interpretation` vocabulary for memory writing (Section 2.4) and Observer matching (Section 7) — one controlled vocabulary, not two separate lists to keep in sync.

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
1. Read template.archetype_role for the approached NPC.
2. Determine the player's distribution_band from their level.
3. Weighted-random pick a category from that band's weights.
4. Filter seed_bank WHERE compatible_roles CONTAINS archetype_role
                    AND category == picked category.
5. If the filtered pool is empty, fall back to the nearest available
   category that has seeds for this NPC (graceful degradation —
   never error).
6. Exclude any seed_id already used with this NPC instance this session;
   pick randomly among what remains.
7. Resolve the NPC instance's effective starting metrics for this
   encounter: take the instance's currently persisted metric values
   and layer the seed's metric_overrides on top as temporary encounter
   modifiers. These overrides apply to this encounter only and do not
   overwrite the instance's persisted metrics.
8. Invoke the Scenario Personalization AI (Section 4.3) with the
   selected seed, NPC template identity, and resolved encounter metrics.
```

### 6.3 Encounter modifier boundary

`npc_context.metric_overrides` in a seed defines the **temporary emotional starting conditions** for that encounter — the NPC's disposition at the opening of this particular scenario. They are applied as encounter modifiers stored on the active session (Section 2.5, `encounter_modifiers`) and used to initialize the encounter's starting state.

They do **not** permanently overwrite the NPC instance's persisted metric values. The instance's persisted metrics before the encounter remain unchanged at encounter start. The modifier only affects the starting point; it does not silently rewrite relationship history.

**How encounter_modifiers are consumed during message processing:**

At encounter start, the effective metric values are computed as:
```
effective_metric = encounter_modifier[metric] if metric in encounter_modifiers
                   else instance.persisted_metric[metric]
```
These effective values are the starting point for all State Engine evaluations and Relationship Service calculations during the encounter. Each subsequent turn's metric update (Section 5.1) applies to the running effective values for the encounter. The persisted NPC Instance metrics are **not read or written during individual message turns** — only at encounter close, when the final effective metrics are committed back to the NPC Instance.

Metric changes that occur *during* the encounter accumulate on the effective values. At encounter close (`/interaction/end`), the final accumulated metric values are written back to the NPC Instance as the new persisted state.

**Persistent NPC Instance state:** `trust`, `patience`, `openness`, and any other metrics defined in the template — these are the player's accumulated relationship history with this NPC. Written once at encounter close.

**Temporary encounter context:** `encounter_modifiers` from the seed — these set the emotional starting conditions for this scenario and exist only for the duration of the active session. Discarded with the session at encounter close.

**Constraint:** any key in `metric_overrides` must correspond to a metric defined in the NPC template being used. Seeds are validated at load time against the template registry; a seed referencing an undefined metric is rejected as a content error.

### 6.4 Personalization boundaries

The LLM personalizes delivery — wording, tone — within an authored scenario. It never invents a new scenario. `premise`, `stakes`, `npc_goal`, and `possible_outcomes` are fixed inputs to every LLM call that touches this seed and are never treated as generation targets by any prompt in this system.

---

## 7. Observer System

**Scope:** single NPC instance only. The Observer never aggregates or compares across different NPC instances or different characters — it detects repetition only within one NPC instance's own memory.

**Trigger (deterministic, computed in service code — never by the LLM):**
```
count(entry.interpretation == X for entry in npc_instance.memory.entries) >= 2  →  fire
```

This is a plain filter/count over memory entries that already exist for scoring purposes (Section 2.4) — no separate evidence store, no confidence scoring.

**Dependency:** the Observer Service reads memory from the Memory Service. The Observer Service does not own memory and does not write memory. It receives memory entries as input, applies the deterministic count check, and if the trigger fires, passes the matching entries to the Observer Phrasing AI.

**Generation rule:** once the trigger condition is met, the two (or more) matching memory entries are passed to the Observer Phrasing AI (Section 4.4), which generates the reveal line. The AI phrases; it does not decide whether to fire.

**Firing point:** checked once, at the close of an encounter (`/interaction/end`), not after every message. `observer_event.fired` is `false` on the large majority of encounters.

**Scope limitation, stated explicitly:** there is no mechanism, planned or implemented, by which the Observer compares memory across two different NPC instances or two different characters. This is a deliberate architectural boundary, not a current gap — implementing cross-NPC correlation is out of scope for this build.

---

## 8. API Contract

The frontend uses `player_id` and `npc_id` in all requests. The backend internally resolves `player_id + npc_id → NPC Instance`. Internal instance IDs are not exposed in the API. This resolution is an internal concern; the API contract does not change.

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

On first contact between this `player_id` and `npc_id`, the backend creates an NPC Instance initialized from the template's metric start values. Subsequent calls use the existing instance.

Errors: `404` if `npc_id` is not in the template registry. `200` always returned for a valid, unknown-to-backend `player_id` — a new player record is created on first contact.

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
  "turn_scores": { "clarity": 0.80, "empathy": 0.35, "politeness": 0.70, "expression": 0.60 },
  "relationship_tier": "Comfortable",
  "npc_state": "irritated",
  "feedback": {
    "strength": "You explained your situation clearly.",
    "improvement": "You responded to the reason, but not the feeling behind it."
  },
  "encounter_over": false
}
```

**Field semantics:**
- `turn_scores` — the four-dimension scores returned by the Memory Formation pipeline for this turn. These are the *per-turn raw scores* used as input to the metric update calculation (Section 5.1). They are not deltas on the player's skill vector; skill vector accumulation happens at encounter close via the Progression Service.
- `relationship_tier` — the derived relationship label for this NPC (Section 5.3). This is the client-facing representation of the NPC's trust level. Raw NPC metric float values are internal state and are not exposed in the API; `relationship_tier` is the render-ready form.
- `npc_state` — the State Engine's resolved state enum after this turn's metric update. The client maps it to a pre-built expression asset.
- `encounter_over` — when `true`, the encounter is complete. The client must call `POST /interaction/end` to finalize. Finalization (Observer check, Progression update, session discard) does not occur until `/interaction/end` is called.

**Coach hint ownership and rule:** `coach_hint` is a secondary output of the Character Voice pipeline (Section 4.2), generated alongside `npc_reply` and `npc_expression`. Its system prompt enforces: state a noticed fact about the conversation, never a prescribed response. A prescriptive hint (telling the player what to say) is a defect. The hint informs the player's *next* message — ambient situational awareness, not retrospective grading.

Errors: `404` if no active session exists for this `(player_id, npc_id)` pair — client must call `/interaction/start` first. `400` if `message` is empty.

### `POST /interaction/end`

Called by the client when it receives `encounter_over: true` in a `POST /interaction/message` response. The server determines encounter completion (based on turn count and/or scored outcome relative to the seed's `possible_outcomes`) and signals it via that flag; the client is responsible for calling this endpoint to trigger finalization.

Request:
```json
{ "player_id": "12345", "npc_id": "sara" }
```

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

Utility endpoint for demo and testing convenience. Given a `player_id`, clears all associated state (skill vector, level, all NPC instances including their metrics/memory for that ID) back to defaults, without requiring a new ID to be issued.

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
- a **number** (e.g. `turn_scores` values, `xp_progress`) — the client renders/tweens it directly,
- **plain text** (e.g. `npc_reply`, `feedback.improvement`, `observer_event.message`) — the client displays it directly.

No response requires the client to perform any conditional logic to determine meaning.

---

## 9. Progression

XP gain and level threshold calculations are owned exclusively by the Progression Service. The following constraints are non-negotiable:

- XP gain per encounter must be **deterministic** — the same encounter inputs must always produce the same XP output. The LLM does not influence XP calculation.
- Level thresholds must be **configurable** — defined in a data file or configuration, not hardcoded. The Progression Service reads them; no other service hardcodes level boundaries.
- The exact XP gain formula is an implementation placeholder to be defined during build, but it must be derived only from: the four scored dimensions, the seed's `scoring_focus`, the encounter outcome, and optionally the player's current level. No other inputs are permitted.

The Progression Service aggregates encounter scores into the skill vector update and XP update after each completed encounter. Level-up detection is a downstream result of the XP update, not a separate event system.

---

## 10. Backend Non-Goals

This specification explicitly excludes and forbids:

- any frontend implementation detail (rendering, UI layout, animation, input handling)
- any Godot-specific code, scene structure, or asset reference
- any assumption about a specific client technology — this backend must be equally usable by a Godot client, a web client, a mobile client, or a command-line test harness
- client-side game logic of any kind — the backend must remain the sole source of truth for every gameplay decision described in this document
