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

### Seed Schema

Each seed has the following top-level fields:

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `title` | string | Human-readable name |
| `compatible_roles` | list | NPC archetype roles this seed works with |
| `category` | string | `everyday_social`, `friendship`, `workplace`, `high_pressure` |
| `tier` | int | 1–3; maps loosely to encounter difficulty |
| `context.premise` | string | Scene setup |
| `context.stakes` | string | What is at stake |
| `context.opening_line_seed` | string | Seed phrase for Scenario Personalization LLM |
| `context.npc_goal` | string | NPC's internal objective for this encounter |
| `scoring_focus` | dict | `primary` and `secondary` scoring dimensions |
| `success_signal` | string | Memory interpretation label on good performance |
| `failure_signal` | string | Memory interpretation label on poor performance |
| `possible_outcomes` | dict | `good`, `neutral`, `poor` — each with `trigger` (narrative condition for LLM) and `closing_seed` (NPC's closing line seed) |
| `npc_context.metric_overrides` | dict | Per-metric value overrides applied at encounter start |

**`possible_outcomes` detail:** The `trigger` field is passed to the Character Voice LLM as prose describing the narrative state that would constitute that outcome. The LLM selects one and signals `end_encounter=True` when the trigger condition is met (after `min_turns_before_end` turns). The `closing_seed` is the seed phrase used to personalize the NPC's final line.

---

### All Seeds (Summary)

| ID | Title | Roles | Category | Tier | Primary | Secondary |
|---|---|---|---|---|---|---|
| `final_paper_feedback` | Notes on the Draft | teacher | workplace | 2 | clarity | expression |
| `extension_request_end_of_semester` | Asking for More Time | teacher | workplace | 2 | clarity | politeness |
| `grade_dispute_quiet` | Disputing a Grade | teacher | high_pressure | 3 | clarity | empathy |
| `office_hours_genuine_question` | Office Hours | teacher | everyday_social | 1 | expression | clarity |
| `you_cancelled_again` | Cancelled Again | friend | friendship | 2 | empathy | expression |
| `they_got_news_you_didnt_ask_about` | News You Should Have Known | friend | friendship | 2 | empathy | expression |
| `honest_opinion_asked` | Asked for Your Opinion | friend | friendship | 2 | expression | empathy |
| `friend_venting_no_fix_wanted` | Not Looking for Advice | friend | everyday_social | 1 | empathy | politeness |
| `credit_not_given` | Left Off the Presentation | colleague | workplace | 3 | clarity | empathy |
| `covering_for_absence` | Brushed Past | colleague | workplace | 2 | clarity | politeness |
| `shared_task_different_standards` | Different Approach | colleague | workplace | 2 | clarity | empathy |
| `colleague_small_gesture` | Quieter Than Usual | colleague | everyday_social | 1 | empathy | expression |
| `deliverable_missed_scope` | Work That Missed the Brief | client | high_pressure | 3 | clarity | empathy |
| `client_asking_for_more` | One More Thing | client | workplace | 2 | clarity | politeness |
| `client_first_impression` | First Call | client | everyday_social | 1 | expression | clarity |
| `client_bad_news_early` | Telling Them First | client | high_pressure | 3 | clarity | empathy |
| `parent_asking_about_the_plan` | What's the Plan | family | everyday_social | 2 | expression | clarity |
| `old_argument_resurfacing` | Something That Still Sits There | family | high_pressure | 3 | empathy | expression |
| `sibling_asking_for_something` | A Favor | family | everyday_social | 2 | clarity | empathy |
| `ordering_under_pressure` | Rush Order | stranger | everyday_social | 1 | politeness | clarity |
| `stranger_spills_something` | Small Collision | stranger | everyday_social | 1 | politeness | empathy |
| `recommendation_letter_ask` | Asking for a Reference | teacher | workplace | 2 | expression | clarity |
| `taking_on_too_much` | Overcommitted | colleague | workplace | 2 | clarity | expression |
| `client_timeline_slipping` | Timeline Update | client | high_pressure | 3 | clarity | empathy |
| `client_scope_clarification` | What's Included | client | workplace | 2 | clarity | politeness |
| `parent_noticed_something_off` | You Seem Off | family | everyday_social | 2 | expression | empathy |
| `sibling_pushing_back` | Called Out | family | high_pressure | 3 | empathy | clarity |
| `recurring_stranger_remembers_you` | I've Seen You Here Before | stranger | everyday_social | 2 | expression | politeness |

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
| `final_paper_feedback` | `named_own_shortfall_honestly` | `deflected_onto_circumstances` |
| `extension_request_end_of_semester` | `stated_request_plainly` | `deflected_onto_circumstances` |
| `grade_dispute_quiet` | `made_case_without_entitlement` | `framed_disagreement_as_accusation` |
| `office_hours_genuine_question` | `engaged_substantively` | `performed_interest_insincerely` |
| `you_cancelled_again` | `acknowledged_pattern_not_just_instance` | `gave_excuse_without_acknowledgment` |
| `they_got_news_you_didnt_ask_about` | `created_space_to_be_heard` | `redirected_to_own_experience` |
| `honest_opinion_asked` | `gave_honest_view_with_care` | `gave_hollow_validation` |
| `friend_venting_no_fix_wanted` | `stayed_present_without_fixing` | `redirected_to_own_experience` |
| `credit_not_given` | `named_issue_without_accusation` | `framed_disagreement_as_accusation` |
| `covering_for_absence` | `addressed_imbalance_directly` | `absorbed_resentment_silently` |
| `shared_task_different_standards` | `proposed_alignment_not_dominance` | `framed_disagreement_as_accusation` |
| `colleague_small_gesture` | `noticed_without_overstepping` | `gave_hollow_validation` |
| `deliverable_missed_scope` | `named_own_shortfall_honestly` | `deflected_onto_circumstances` |
| `client_asking_for_more` | `held_boundary_with_warmth` | `absorbed_resentment_silently` |
| `client_first_impression` | `projected_genuine_competence` | `performed_interest_insincerely` |
| `client_bad_news_early` | `delivered_bad_news_directly` | `softened_truth_into_vagueness` |
| `parent_asking_about_the_plan` | `shared_uncertainty_without_deflecting` | `gave_hollow_validation` |
| `old_argument_resurfacing` | `acknowledged_history_without_minimizing` | `deflected_onto_circumstances` |
| `sibling_asking_for_something` | `gave_honest_answer_with_care` | `gave_excuse_without_acknowledgment` |
| `ordering_under_pressure` | `treated_service_worker_with_basic_decency` | `took_frustration_out_sideways` |
| `stranger_spills_something` | `resolved_small_moment_gracefully` | `took_frustration_out_sideways` |
| `recommendation_letter_ask` | `made_case_without_entitlement` | `performed_interest_insincerely` |
| `taking_on_too_much` | `named_own_shortfall_honestly` | `gave_hollow_validation` |
| `client_timeline_slipping` | `delivered_bad_news_directly` | `softened_truth_into_vagueness` |
| `client_scope_clarification` | `held_boundary_with_warmth` | `softened_truth_into_vagueness` |
| `parent_noticed_something_off` | `shared_uncertainty_without_deflecting` | `gave_hollow_validation` |
| `sibling_pushing_back` | `acknowledged_pattern_not_just_instance` | `deflected_onto_circumstances` |
| `recurring_stranger_remembers_you` | `engaged_authentically_with_being_remembered` | `performed_interest_insincerely` |

Note: Several seeds share common signal IDs (e.g., `deflected_onto_circumstances`, `gave_hollow_validation`, `framed_disagreement_as_accusation`). Pattern detection across these seeds using the same NPC will aggregate on the shared signal label.

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
