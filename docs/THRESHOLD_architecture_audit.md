# THRESHOLD Backend Specification — Architecture Consistency Audit
**Date:** 2026-08-03
**Scope:** `THRESHOLD_backend_spec.md` — audit only, no architectural redesign

---

## Changes Made

### Change 1 — Section 1.1: Scoring Service ownership wording
**Category:** Ownership consistency

**Problem:** The table said Scoring Service "invokes the Memory Formation AI module" in a way that could imply it owns AI execution. LLM execution is owned exclusively by LLM Service.

**Fix:** Reworded to: "coordinates the Memory Formation pipeline: calls LLM Service with the player message and session context, receives and returns the four-dimension scores + interpretation label." Added "LLM execution" to the "does not own" column.

---

### Change 2 — Section 1.1: Observer Service ownership wording
**Category:** Ownership consistency

**Problem:** Table said Observer Service "invokes Observer phrasing call" — ambiguous about whether Observer Service or LLM Service executes the call. Also missing the encounter-close timing constraint from Section 7.

**Fix:** Reworded to: "pattern trigger detection at encounter close; calls LLM Service (Observer Phrasing pipeline) when trigger fires." Added to "does not own": "does not execute LLM calls directly."

---

### Change 3 — Section 1.3: Observer removed from message processing flow
**Category:** Observer timing consistency

**Problem:** The `/interaction/message` flow diagram included an Observer Service step ("read instance memory from Memory Service; check trigger condition — not fired every turn — see Section 7"). This directly contradicted Section 7's explicit rule: "checked once, at the close of an encounter (`/interaction/end`), not after every message."

**Fix:** Removed Observer from the message flow entirely. Added an explicit note below the flow: "The Observer Service is **not** invoked during message processing. It runs once at encounter close (`POST /interaction/end`)."

---

### Change 4 — Section 1.3.1 (new): Explicit orchestration flows for `/interaction/start` and `/interaction/end`
**Category:** Lifecycle/orchestration ambiguity

**Problem:** The spec described the `/interaction/message` flow in detail (Section 1.3) but had no equivalent orchestration sequence for `/interaction/start` or `/interaction/end`. Readers had to infer these from the API section (Section 8) and the Scenario System section (Section 6.2). Encounter-close finalization order (Observer → Progression → session discard) was implied but not sequenced.

**Fix:** Added Section 1.3.1 with explicit step-by-step flows for both `/interaction/start` and `/interaction/end`. These reuse and reference existing sections (6.2, Section 7, Progression Service) — no new concepts introduced. Added a clarifying note on `encounter_over`: the flag signals completion to the client; the client calls `/interaction/end`; finalization runs only in that handler.

---

### Change 5 — Section 1.3: Character Voice pipeline produces `coach_hint`
**Category:** Ownership consistency / API contract

**Problem:** `coach_hint` appeared in the API response (Section 8) with no documented owner or origin. It could not come from Observer (fires at encounter close only). Adding a new pipeline would violate scope constraints.

**Fix:** The Character Voice pipeline already has all the inputs needed (NPC state, memory, conversation history). Added `coach_hint` as a third output of the Character Voice pipeline in the flow diagram: `returns { npc_reply, npc_expression, coach_hint }`.

---

### Change 6 — Section 4 intro: Pipelines are logical, not separate services
**Category:** LLM module wording

**Problem:** The five AI pipeline sections (4.1–4.5) used headers like "Memory Formation AI" and "Character Voice AI" without a statement clarifying that these are logical pipeline definitions executed by the LLM Service, not separately deployable services. A developer reading top-down might reasonably build five separate services.

**Fix:** Added an "Infrastructure vs. pipeline distinction" paragraph at the top of Section 4, explicitly stating: they are logical pipeline definitions, all executed by the LLM Service. Adding a new pipeline requires a new LLM Service call definition and system prompt, not a new service.

---

### Change 7 — Section 4.2: `coach_hint` ownership and rules documented
**Category:** Ownership consistency / API contract

**Problem:** `coach_hint` had no documented pipeline owner, no input description, and no constraint documentation.

**Fix:** Updated the Character Voice AI "Responsible for" description to include `coach_hint` as a secondary structured output, with its constraint (state a noticed fact, never prescribe a response) and input rationale. Moved the two loose `coach_hint` paragraphs from Section 8 into Section 4.2 where they belong architecturally.

---

### Change 8 — Section 5.1: Fixed vs. tunable formula elements made explicit
**Category:** Metric update ambiguity

**Problem:** The metric formula section said the "exact blending formula is an implementation detail to tune during build, but the inputs and their weights are fixed." The distinction was partially stated but not clearly structured — it could be read as the weights being tunable.

**Fix:** Replaced with a structured list explicitly labelling:
- **Fixed (template-defined):** input scores, `influenced_by` weights, `turn_decay` — all in the NPC Template
- **Fixed (system behaviour):** LLM has zero influence on any calculation
- **Tunable (implementation detail):** only the blending/accumulation function

---

### Change 9 — Section 6.1: Seed `metric_overrides` must reference template-defined metrics
**Category:** Ownership consistency / data integrity

**Problem:** The `teammate_not_pulling_weight` seed used `metric_overrides: { guardedness: 0.6 }`. `guardedness` is not a metric defined in any NPC template in the specification. No colleague NPC template is defined. This is an orphaned field — an override key that references a non-existent metric.

**Fix:** Replaced `guardedness: 0.6` with `trust: 0.35` (a metric all templates must define), and added a comment: "# override must reference a metric defined in the colleague NPC template." This is a content correction, not a design change.

---

### Change 10 — Section 6.3: How encounter_modifiers are consumed during message processing
**Category:** Encounter modifier handling

**Problem:** Section 6.3 clearly stated that `metric_overrides` set temporary starting conditions and don't overwrite persisted metrics at encounter start. However, nowhere in the spec was it explained *how* these modifiers are used during individual message turns. The Section 5.1 metric update rules referenced "existing metric values on the NPC Instance" — ambiguous about whether message turns read from persisted instance metrics or from the effective encounter values.

**Fix:** Added an explicit sub-section inside 6.3 explaining:
- At encounter start, effective values are computed: override value if present, otherwise persisted value
- All State Engine and Relationship Service calculations during the encounter use these effective values
- Persisted metrics are not read or written during individual message turns
- At encounter close, final accumulated effective metrics are written back as the new persisted state
- Added the constraint: any `metric_overrides` key must match a template-defined metric; seeds are validated at load time

---

### Change 11 — Section 8 `/interaction/message`: Removed `npc_metrics` from response
**Category:** API contract / duplicate source of truth

**Problem:** The API response included `"npc_metrics": { "trust": 0.58, "patience": 0.55, "openness": 0.32 }` — raw internal metric floats. Section 5.3 explicitly states: "`trust` is not exposed to the client as a raw float. It is resolved to a named tier." This was a direct contradiction. The response already contained `relationship_tier` as the correct client-facing form.

**Fix:** Removed `npc_metrics` from the response JSON. Added a field semantics block documenting that raw NPC metric floats are internal state and are not exposed in the API; `relationship_tier` is the render-ready form.

---

### Change 12 — Section 8 `/interaction/message`: Renamed `stat_deltas` to `turn_scores`
**Category:** API contract / naming contradiction

**Problem:** The field was named `stat_deltas` but its values (`"clarity": 0.80, "empathy": 0.35`) are the per-turn raw scores output by the Memory Formation pipeline — not deltas on the player's skill vector. The player's skill vector (`skill_vector` on the Player entity) is updated by the Progression Service at encounter close, not per-turn. The name `stat_deltas` implied it was the change to the accumulated skill vector, which is false.

**Fix:** Renamed to `turn_scores`. Added field semantics explaining these are the per-turn scores used as input to the metric update (Section 5.1); skill vector accumulation happens at encounter close via the Progression Service.

---

### Change 13 — Section 8 `/interaction/end`: Client initiates, not server-autonomous
**Category:** Lifecycle/orchestration ambiguity

**Problem:** The original wording said it "fires when the active scenario's encounter concludes (determined server-side)" — which implies the server autonomously fires the endpoint. The architecture uses `encounter_over: true` in the message response to signal completion, requiring the client to call `/interaction/end` explicitly. "Fires server-side" contradicts the client-driven API design.

**Fix:** Reworded: "Called by the client when it receives `encounter_over: true` in a `POST /interaction/message` response. The server determines encounter completion and signals it via that flag; the client is responsible for calling this endpoint to trigger finalization."

---

### Change 14 — Section 8.1: Number field examples updated
**Category:** API contract

**Problem:** The contract rule section listed `stat_deltas` and `npc_metrics` as examples of number fields. Both have been corrected in the actual response.

**Fix:** Updated examples to `turn_scores` and `xp_progress`.

---

## Final Consistency Check

### Core architectural principles — all preserved

| Principle | Status |
|---|---|
| Backend is the authoritative game engine | ✅ Unchanged |
| Frontend only renders backend responses — no client-side gameplay logic | ✅ Unchanged |
| NPC Template and NPC Instance are separate | ✅ Unchanged |
| NPC Instance is the boundary for player-specific NPC relationships | ✅ Unchanged |
| LLMs only generate/score/phrase within strict boundaries | ✅ Unchanged |
| Deterministic systems own game-state decisions | ✅ Unchanged |
| Scenario seeds are data-driven | ✅ Unchanged |
| Metrics → State Engine → cached state is the source of truth | ✅ Unchanged |
| Memory is long-term relationship knowledge | ✅ Unchanged |
| Conversation history is temporary encounter context | ✅ Unchanged |
| Service list unchanged | ✅ Unchanged (10 services, no additions) |
| AI pipeline count unchanged | ✅ Unchanged (5 pipelines) |
| API endpoint list unchanged | ✅ Unchanged (start, message, end, report, daily, reset) |

### What was changed

Only internal consistency was corrected:
- Ownership wording made precise (Scoring Service, Observer Service)
- One Observer timing contradiction resolved (moved out of message flow to encounter close)
- Missing orchestration flows added (start, end) — from existing content, no new design
- Five AI pipelines explicitly identified as logical (LLM Service infrastructure), not separate services
- Metric formula fixed/tunable boundary made explicit
- One seed override key corrected to reference a real metric (`guardedness` → `trust`)
- Encounter modifier consumption during message turns made explicit
- One API contradiction removed (`npc_metrics` raw floats vs Section 5.3 rule)
- One naming contradiction fixed (`stat_deltas` → `turn_scores`)
- `coach_hint` given explicit pipeline ownership (Character Voice AI secondary output)
- `/interaction/end` caller model clarified (client-initiated, not server-autonomous)

### No new architectural concepts were introduced

No new services, no new databases, no new AI agents, no new gameplay systems, no new data models, no authentication systems, no multiplayer concepts, no analytics, no frontend requirements, no unnecessary abstractions.

Every fix was a clarification, correction, or explicit statement of something already implied by the original design.
