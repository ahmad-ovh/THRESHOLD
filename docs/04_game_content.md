# THRESHOLD — Game Content Reference

All content is defined in YAML files under `content/`. These files are loaded once at startup into the `ContentRegistry` singleton. They are never modified at runtime.

---

## NPC Templates (`content/npc_templates.yaml`)

### NPC: Sara

| Field | Value |
|---|---|
| **id** | `sara` |
| **archetype_role** | `friend` |
| **name** | Sara |
| **base_personality** | Direct but caring, reads as blunt if you don't know her. |
| **communication_style** | Casual, expressive, texts in fragments. |

**Metrics:**

| Metric | Start | Min | Max |
|---|---|---|---|
| `trust` | 0.7 | 0.0 | 1.0 |
| `patience` | 0.6 | 0.0 | 1.0 |
| `openness` | 0.4 | 0.0 | 1.0 |

**Metric Update Rules:**

| Metric | Influenced By | Turn Decay |
|---|---|---|
| `trust` | empathy × 0.6 + clarity × 0.4 | 0.0 |
| `patience` | politeness × 1.0 | 0.05 |
| `openness` | expression × 0.7 + empathy × 0.3 | 0.0 |

`patience` naturally decays by 0.05 per turn regardless of the player's score. All other metrics decay at 0.0 (no passive decay).

**State Rules (evaluated in order, first match wins):**

| Condition | State |
|---|---|
| `trust < 0.3` | `guarded` |
| `trust >= 0.3 and patience < 0.3` | `irritated` |
| `trust >= 0.6 and openness >= 0.6` | `warm` |
| `default` | `neutral` |

---

### NPC: Mr. Teo

| Field | Value |
|---|---|
| **id** | `mr_teo` |
| **archetype_role** | `teacher` |
| **name** | Mr. Teo |
| **base_personality** | Patient but direct. Expects ownership and brevity. |
| **communication_style** | Formal, measured, economy of words. |

**Metrics:**

| Metric | Start | Min | Max |
|---|---|---|---|
| `trust` | 0.5 | 0.0 | 1.0 |
| `respect` | 0.5 | 0.0 | 1.0 |

**Metric Update Rules:**

| Metric | Influenced By | Turn Decay |
|---|---|---|
| `trust` | clarity × 0.6 + politeness × 0.4 | 0.0 |
| `respect` | clarity × 0.5 + empathy × 0.3 + politeness × 0.2 | 0.02 |

`respect` decays by 0.02 per turn.

**State Rules:**

| Condition | State |
|---|---|
| `trust < 0.3` | `disappointed` |
| `respect < 0.3` | `dismissive` |
| `trust >= 0.65 and respect >= 0.65` | `approving` |
| `default` | `neutral` |

---

### NPC: Jun

| Field | Value |
|---|---|
| **id** | `jun` |
| **archetype_role** | `colleague` |
| **name** | Jun |
| **base_personality** | Conflict-avoidant but quietly watches how people treat others. |
| **communication_style** | Measured, professional, occasionally dry. |

**Metrics:**

| Metric | Start | Min | Max |
|---|---|---|---|
| `trust` | 0.5 | 0.0 | 1.0 |
| `comfort_level` | 0.5 | 0.0 | 1.0 |

**Metric Update Rules:**

| Metric | Influenced By | Turn Decay |
|---|---|---|
| `trust` | empathy × 0.5 + clarity × 0.5 | 0.0 |
| `comfort_level` | politeness × 0.6 + expression × 0.4 | 0.03 |

`comfort_level` decays by 0.03 per turn.

**State Rules:**

| Condition | State |
|---|---|
| `trust < 0.3` | `withdrawn` |
| `comfort_level < 0.3` | `defensive` |
| `trust >= 0.65 and comfort_level >= 0.6` | `collaborative` |
| `default` | `neutral` |

---

### NPC: Ms. Reyes

| Field | Value |
|---|---|
| **id** | `ms_reyes` |
| **archetype_role** | `client` |
| **name** | Ms. Reyes |
| **base_personality** | Professional, results-driven, does not hide dissatisfaction. |
| **communication_style** | Terse, precise, expects the same. |

**Metrics:**

| Metric | Start | Min | Max |
|---|---|---|---|
| `trust` | 0.4 | 0.0 | 1.0 |
| `satisfaction` | 0.4 | 0.0 | 1.0 |

**Metric Update Rules:**

| Metric | Influenced By | Turn Decay |
|---|---|---|
| `trust` | clarity × 0.7 + politeness × 0.3 | 0.0 |
| `satisfaction` | clarity × 0.5 + empathy × 0.5 | 0.04 |

`satisfaction` decays by 0.04 per turn — the fastest decay of any metric in the game.

**State Rules:**

| Condition | State |
|---|---|
| `trust < 0.25` | `hostile` |
| `satisfaction < 0.3` | `frustrated` |
| `trust >= 0.6 and satisfaction >= 0.6` | `satisfied` |
| `default` | `neutral` |

---

## Relationship Tier Configuration

Tiers are derived from the `trust` metric value. The thresholds and labels are defined globally in `scenario_seeds.yaml`.

**Thresholds:** `[0.0, 0.25, 0.45, 0.65, 0.85]`

Resolution: the highest threshold that `trust >= threshold` is satisfied gives the tier index. Labels are archetype-specific.

| Trust Value | Index | friend | teacher | colleague | client |
|---|---|---|---|---|---|
| 0.00 – 0.24 | 0 | Stranger | Unfamiliar | Unfamiliar | Unknown |
| 0.25 – 0.44 | 1 | Acquaintance | Noted | Coworker | Skeptical |
| 0.45 – 0.64 | 2 | Comfortable | Respected | Dependable | Professional |
| 0.65 – 0.84 | 3 | Trusted | Trusted | Trusted | Reliable |
| 0.85 – 1.00 | 4 | Close Friend | Regarded Highly | Strong Ally | Trusted Partner |

---

## Scenario Seeds (`content/scenario_seeds.yaml`)

Each seed defines a scenario that can be selected for an encounter. Seeds are selected by compatible NPC role and player level.

---

### Seed: `missed_deadline_explain`

| Field | Value |
|---|---|
| **Title** | The Late Submission |
| **Compatible Roles** | `teacher`, `colleague` |
| **Category** | `workplace` |
| **Tier** | 2 |
| **Scoring Focus** | Primary: `clarity`, Secondary: `politeness` |
| **Success Signal** | `owned_mistake_plainly` |
| **Failure Signal** | `avoided_emotional_acknowledgment` |

**Context:**
- **Premise:** You missed a deadline by two days and need to explain yourself.
- **Stakes:** Consequence is real but negotiable depending on how you handle it.
- **Opening Line Seed:** "So — tell me what happened."
- **NPC Goal:** Wants ownership before deciding leniency.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | Leniency granted; relationship unaffected or slightly improved. |
| neutral | Consequence applies; professional tone maintained. |
| poor | Consequence applies; trust drops. |

**Metric Overrides at Start:** None

---

### Seed: `felt_ignored_lately`

| Field | Value |
|---|---|
| **Title** | The Distance |
| **Compatible Roles** | `friend` |
| **Category** | `friendship` |
| **Tier** | 2 |
| **Scoring Focus** | Primary: `empathy`, Secondary: `expression` |
| **Success Signal** | `acknowledged_feelings_first` |
| **Failure Signal** | `avoided_emotional_acknowledgment` |

**Context:**
- **Premise:** They've noticed you've been distant lately and want to talk about it.
- **Stakes:** The relationship itself, not a task outcome.
- **Opening Line Seed:** "Hey... can I ask why you've been off lately?"
- **NPC Goal:** Wants to feel heard, not fixed.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | They feel heard; trust rises. |
| neutral | Conversation resolves but stays guarded. |
| poor | They shut down; trust drops. |

**Metric Overrides at Start:** `openness` → `0.3` (Sara starts the encounter less open)

---

### Seed: `unhappy_with_deliverable`

| Field | Value |
|---|---|
| **Title** | The Pushback |
| **Compatible Roles** | `client`, `colleague` |
| **Category** | `high_pressure` |
| **Tier** | 3 |
| **Scoring Focus** | Primary: `clarity`, Secondary: `empathy` |
| **Success Signal** | `validated_concern_specifically` |
| **Failure Signal** | `avoided_emotional_acknowledgment` |

**Context:**
- **Premise:** They're unhappy with what you delivered and think it missed the mark.
- **Stakes:** Professional credibility, possibly the relationship itself.
- **Opening Line Seed:** "This isn't really what we discussed."
- **NPC Goal:** Wants to know you understand the gap before trusting a fix.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | They agree to a revised plan; tension eases. |
| neutral | They accept a fix but stay cool. |
| poor | Trust drops significantly; they escalate or disengage. |

**Metric Overrides at Start:** None

---

### Seed: `first_meeting_small_talk`

| Field | Value |
|---|---|
| **Title** | Breaking the Ice |
| **Compatible Roles** | `friend`, `colleague` |
| **Category** | `everyday_social` |
| **Tier** | 1 |
| **Scoring Focus** | Primary: `expression`, Secondary: `politeness` |
| **Success Signal** | `warm_two_way_exchange` |
| **Failure Signal** | `closed_off_exchange` |

**Context:**
- **Premise:** A casual, low-stakes first conversation — getting to know each other.
- **Stakes:** Low. Sets the tone for the relationship going forward.
- **Opening Line Seed:** "Hey, I don't think we've properly met — how's your week going?"
- **NPC Goal:** Wants a genuine, comfortable exchange, nothing more.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | Comfortable rapport established; trust rises. |
| neutral | Polite but forgettable exchange. |
| poor | Feels awkward or one-sided; trust stagnates. |

**Metric Overrides at Start:** `trust` → `0.4` (starts from a neutral rather than initial value)

---

### Seed: `asking_for_extension`

| Field | Value |
|---|---|
| **Title** | The Ask |
| **Compatible Roles** | `teacher` |
| **Category** | `everyday_social` |
| **Tier** | 1 |
| **Scoring Focus** | Primary: `clarity`, Secondary: `politeness` |
| **Success Signal** | `stated_request_plainly` |
| **Failure Signal** | `rambled_unclear_ask` |

**Context:**
- **Premise:** You need to ask for an extension on an assignment, and you know it's a big ask.
- **Stakes:** Low-to-moderate — a reasonable request, badly delivered, can still go wrong.
- **Opening Line Seed:** "You wanted to see me about the assignment?"
- **NPC Goal:** Wants a clear, honest reason, not excessive justification.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | Extension granted, professional tone maintained. |
| neutral | Partial extension or conditions attached. |
| poor | Denied; trust drops due to poor communication, not the request itself. |

**Metric Overrides at Start:** None

---

### Seed: `teammate_not_pulling_weight`

| Field | Value |
|---|---|
| **Title** | The Confrontation |
| **Compatible Roles** | `colleague` |
| **Category** | `high_pressure` |
| **Tier** | 3 |
| **Scoring Focus** | Primary: `empathy`, Secondary: `clarity` |
| **Success Signal** | `named_issue_collaboratively` |
| **Failure Signal** | `blamed_outright` |

**Context:**
- **Premise:** You need to address that they haven't been contributing to shared work, without damaging the relationship irreparably.
- **Stakes:** High — an emotionally loaded confrontation with someone conflict-avoidant.
- **Opening Line Seed:** "You wanted to talk to me about something?"
- **NPC Goal:** Is bracing for blame and will shut down if attacked directly.

**Possible Outcomes:**

| Outcome | Description |
|---|---|
| good | They open up about why they've been checked out; issue starts resolving. |
| neutral | They agree to do better but stay defensive. |
| poor | They shut down entirely; trust drops significantly. |

**Metric Overrides at Start:** `trust` → `0.35` (Jun starts the encounter with lower trust than default)

---

## Scenario Distribution Bands

Category probability weights by player level band. Used to select scenario category before filtering by NPC role.

| Level Band | everyday_social | friendship | workplace | high_pressure |
|---|---|---|---|---|
| 1–30 | 60 | 25 | 10 | 5 |
| 31–70 | 20 | 30 | 35 | 15 |
| 71–100 | 5 | 20 | 35 | 40 |

**Selection algorithm:**
1. Determine the player's level band
2. Restrict category weights to categories that actually exist for the NPC's archetype role
3. Weighted-random pick a category
4. Filter seeds: compatible role AND picked category AND not in exclusion list
5. If pool is empty after filtering, try other available categories in alphabetical order
6. If everything is excluded, reset exclusion and use all role-compatible seeds

---

## Interpretation Vocabulary (All Values)

Each seed defines exactly two interpretation labels used by the Memory Formation pipeline:

| Seed | Success Signal | Failure Signal |
|---|---|---|
| `missed_deadline_explain` | `owned_mistake_plainly` | `avoided_emotional_acknowledgment` |
| `felt_ignored_lately` | `acknowledged_feelings_first` | `avoided_emotional_acknowledgment` |
| `unhappy_with_deliverable` | `validated_concern_specifically` | `avoided_emotional_acknowledgment` |
| `first_meeting_small_talk` | `warm_two_way_exchange` | `closed_off_exchange` |
| `asking_for_extension` | `stated_request_plainly` | `rambled_unclear_ask` |
| `teammate_not_pulling_weight` | `named_issue_collaboratively` | `blamed_outright` |

Note: three seeds (`missed_deadline_explain`, `felt_ignored_lately`, `unhappy_with_deliverable`) share `avoided_emotional_acknowledgment` as their failure signal. Pattern detection across these seeds (using the same NPC) will aggregate.

---

## NPC Expression Enum (All Values)

Used by Character Voice and Scenario Personalization LLM pipelines:

```
neutral, warm, hurt, guarded, irritated, concerned, disappointed,
approving, dismissive, satisfied, frustrated, hostile, defensive,
withdrawn, collaborative
```

---

## Scoring Dimensions (All Values)

Four dimensions, each scored 0.0–1.0 per player message:

| Dimension | What It Measures |
|---|---|
| `clarity` | How clearly and directly the player communicated their meaning |
| `empathy` | Whether the player acknowledged or validated the other person's feelings/perspective |
| `politeness` | Whether the tone was respectful and considerate |
| `expression` | Whether the player communicated with emotional honesty and personal engagement |
