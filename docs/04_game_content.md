# THRESHOLD — Game Content Reference

All content is defined in YAML files under `content/`. These files are loaded once at startup into the `ContentRegistry` singleton. They are never modified at runtime.

---

## NPC Templates (`content/npc_templates.yaml`)

The game features 16 unique NPC templates across 6 archetype roles (`teacher`, `friend`, `colleague`, `client`, `family`, `stranger`). Each template defines persistent relationship metrics, metric update blend weights, passive turn decays, and deterministic state resolution rules.

### Teacher Archetype

#### Prof. Adler (`prof_adler`)
- **Base Personality:** Rigorous and fair. Can mistake hesitation for lack of effort.
- **Communication Style:** Measured and precise — long pauses make him visibly impatient, even when the silence is just thinking.
- **Metrics:** `respect` (start: 0.50), `confidence` (start: 0.45)
- **Updates:** `respect` (clarity × 0.55 + politeness × 0.30 + empathy × 0.15, decay: 0.01), `confidence` (clarity × 0.70 + expression × 0.30, decay: 0.02)
- **States:** `respect < 0.25` → `dismissive`; `confidence < 0.25` → `doubtful`; `respect >= 0.70 and confidence >= 0.65` → `encouraging`; `respect >= 0.55` → `attentive`; default → `neutral`

#### Ms. Okoro (`ms_okoro`)
- **Base Personality:** Warm and demanding. Tends to assume that students she likes are trying harder than they are.
- **Communication Style:** Conversational, uses questions to make points — but steers the answer she wants if you take too long.
- **Metrics:** `trust` (start: 0.55), `integrity` (start: 0.50)
- **Updates:** `trust` (empathy × 0.50 + clarity × 0.30 + politeness × 0.20, decay: 0.01), `integrity` (clarity × 0.40 + empathy × 0.40 + expression × 0.20, decay: 0.01)
- **States:** `integrity < 0.25` → `disappointed`; `trust < 0.30` → `guarded`; `trust >= 0.65 and integrity >= 0.60` → `invested`; `trust >= 0.45` → `receptive`; default → `neutral`

#### Mr. Vance (`mr_vance`)
- **Base Personality:** Practical and results-focused. Reads personal explanation as excuse-making, even when it isn't.
- **Communication Style:** Terse by default — gives single-word replies when unimpressed and volunteers nothing.
- **Metrics:** `credibility` (start: 0.40), `reliability` (start: 0.45)
- **Updates:** `credibility` (clarity × 0.65 + expression × 0.35, decay: 0.02), `reliability` (clarity × 0.50 + politeness × 0.30 + empathy × 0.20, decay: 0.03)
- **States:** `credibility < 0.25` → `skeptical`; `reliability < 0.25` → `impatient`; `credibility >= 0.70 and reliability >= 0.65` → `approving`; `credibility >= 0.50` → `watchful`; default → `neutral`

---

### Friend Archetype

#### Daria (`daria`)
- **Base Personality:** Perceptive and quietly loyal. Sometimes interprets distance as rejection before checking whether that's true.
- **Communication Style:** Unhurried and conversational — but goes quiet when something bothers her, and waits to see if you'll notice.
- **Metrics:** `trust` (start: 0.65), `closeness` (start: 0.55)
- **Updates:** `trust` (empathy × 0.55 + clarity × 0.30 + expression × 0.15, decay: 0.0), `closeness` (expression × 0.60 + empathy × 0.40, decay: 0.0)
- **States:** `trust < 0.25` → `withdrawn`; `trust >= 0.25 and closeness < 0.25` → `distant`; `trust >= 0.70 and closeness >= 0.65` → `close`; `trust >= 0.50` → `comfortable`; default → `neutral`

#### Felix (`felix`)
- **Base Personality:** Upbeat and socially fluent. Deflects with humor when things get uncomfortable, sometimes past the point where it helps.
- **Communication Style:** Fast and informal — fills silence instinctively, which makes it hard to tell when he's actually bothered by something.
- **Metrics:** `trust` (start: 0.60), `openness` (start: 0.50)
- **Updates:** `trust` (empathy × 0.45 + expression × 0.35 + clarity × 0.20, decay: 0.0), `openness` (expression × 0.55 + empathy × 0.30 + clarity × 0.15, decay: 0.0)
- **States:** `trust < 0.25` → `shut_out`; `trust >= 0.25 and openness < 0.25` → `surface_level`; `trust >= 0.65 and openness >= 0.60` → `candid`; `trust >= 0.45` → `easy`; default → `neutral`

#### Priya (`priya`)
- **Base Personality:** Principled and consistent. Holds honesty as a value so firmly that she occasionally forgets to check whether the moment calls for it.
- **Communication Style:** Blunt without warmup — states her read of a situation directly and expects you to do the same.
- **Metrics:** `trust` (start: 0.55), `candor` (start: 0.50)
- **Updates:** `trust` (empathy × 0.40 + clarity × 0.40 + expression × 0.20, decay: 0.0), `candor` (clarity × 0.50 + expression × 0.30 + empathy × 0.20, decay: 0.0)
- **States:** `trust < 0.25` → `cold`; `candor < 0.25` → `skeptical`; `trust >= 0.70 and candor >= 0.65` → `deeply_trusting`; `trust >= 0.45` → `engaged`; default → `neutral`

---

### Colleague Archetype

#### Nadia (`nadia`)
- **Base Personality:** Capable and self-sufficient. Slow to ask for help and privately critical of people who seem to need it often.
- **Communication Style:** Formal until she's decided you're worth the effort — early conversations feel slightly like interviews.
- **Metrics:** `trust` (start: 0.45), `ease` (start: 0.40)
- **Updates:** `trust` (empathy × 0.45 + clarity × 0.35 + politeness × 0.20, decay: 0.01), `ease` (politeness × 0.50 + expression × 0.30 + empathy × 0.20, decay: 0.02)
- **States:** `trust < 0.25` → `standoffish`; `ease < 0.25` → `stiff`; `trust >= 0.65 and ease >= 0.60` → `collaborative`; `trust >= 0.45` → `cordial`; default → `neutral`

#### Tomás (`tomas`)
- **Base Personality:** Ambitious and transparent about it. Assumes most people are also self-interested, and is occasionally wrong about that.
- **Communication Style:** Confident and fast-moving — reframes things in his favor mid-conversation without seeming to notice he's doing it.
- **Metrics:** `respect` (start: 0.50), `alignment` (start: 0.45)
- **Updates:** `respect` (clarity × 0.55 + expression × 0.30 + politeness × 0.15, decay: 0.02), `alignment` (clarity × 0.40 + empathy × 0.35 + expression × 0.25, decay: 0.03)
- **States:** `respect < 0.25` → `dismissive`; `alignment < 0.25` → `competitive`; `respect >= 0.65 and alignment >= 0.60` → `allied`; `respect >= 0.45` → `civil`; default → `neutral`

#### Seren (`seren`)
- **Base Personality:** Even-tempered and fair. Absorbs tension quietly, which means her actual frustration is invisible until it isn't.
- **Communication Style:** Measured and deliberate — gives well-considered answers that can feel like she's being more okay with things than she is.
- **Metrics:** `trust` (start: 0.50), `rapport` (start: 0.45)
- **Updates:** `trust` (empathy × 0.50 + clarity × 0.30 + politeness × 0.20, decay: 0.01), `rapport` (expression × 0.45 + empathy × 0.35 + politeness × 0.20, decay: 0.02)
- **States:** `trust < 0.25` → `cautious`; `rapport < 0.25` → `professional_only`; `trust >= 0.65 and rapport >= 0.60` → `genuinely_warm`; `trust >= 0.45` → `steady`; default → `neutral`

---

### Client Archetype

#### Ms. Hartwell (`ms_hartwell`)
- **Base Personality:** Experienced and exacting. Gives people fewer chances than she thinks she does.
- **Communication Style:** Clipped and efficient — states expectations once, doesn't repeat them, and notes whether they were met.
- **Metrics:** `trust` (start: 0.35), `satisfaction` (start: 0.40)
- **Updates:** `trust` (clarity × 0.65 + politeness × 0.25 + empathy × 0.10, decay: 0.03), `satisfaction` (clarity × 0.55 + empathy × 0.30 + politeness × 0.15, decay: 0.05)
- **States:** `trust < 0.20` → `hostile`; `satisfaction < 0.25` → `frustrated`; `trust >= 0.65 and satisfaction >= 0.60` → `satisfied`; `trust >= 0.45` → `professional`; default → `neutral`

#### Mr. Osei (`mr_osei`)
- **Base Personality:** Collaborative and relationship-minded. Can read professional distance as indifference, even when it's just professionalism.
- **Communication Style:** Deliberate and contextual — shares his reasoning freely and notices when you don't offer yours.
- **Metrics:** `trust` (start: 0.45), `engagement` (start: 0.40)
- **Updates:** `trust` (empathy × 0.45 + clarity × 0.35 + expression × 0.20, decay: 0.03), `engagement` (expression × 0.40 + empathy × 0.35 + clarity × 0.25, decay: 0.04)
- **States:** `trust < 0.20` → `disengaged`; `engagement < 0.25` → `transactional`; `trust >= 0.65 and engagement >= 0.60` → `invested`; `trust >= 0.45` → `attentive`; default → `neutral`

#### Ms. Vidal (`ms_vidal`)
- **Base Personality:** Detail-oriented and conscientious. Asks follow-up questions to feel informed, but sometimes hears the answer she feared rather than the one given.
- **Communication Style:** Polite and circling — returns to the same concern from slightly different angles until she feels settled.
- **Metrics:** `trust` (start: 0.30), `reassurance` (start: 0.35)
- **Updates:** `trust` (clarity × 0.50 + empathy × 0.35 + politeness × 0.15, decay: 0.04), `reassurance` (empathy × 0.55 + clarity × 0.30 + expression × 0.15, decay: 0.05)
- **States:** `trust < 0.20` → `skeptical`; `reassurance < 0.20` → `anxious`; `trust >= 0.60 and reassurance >= 0.55` → `reassured`; `trust >= 0.40` → `cautiously_hopeful`; default → `neutral`

---

### Family Archetype

#### Your Parent (`parent`)
- **Base Personality:** Loving and present. Still operates from a version of you that's two or three years out of date.
- **Communication Style:** Warm but loaded — mixes genuine curiosity with assumptions they don't realize they're making.
- **Metrics:** `trust` (start: 0.70), `closeness` (start: 0.65)
- **Updates:** `trust` (clarity × 0.40 + empathy × 0.40 + expression × 0.20, decay: 0.0), `closeness` (expression × 0.50 + empathy × 0.35 + clarity × 0.15, decay: 0.0)
- **States:** `trust < 0.30` → `hurt`; `closeness < 0.30` → `drifting`; `trust >= 0.75 and closeness >= 0.70` → `connected`; `trust >= 0.50` → `present`; default → `neutral`

#### Your Sibling (`sibling`)
- **Base Personality:** Perceptive and direct. Has strong opinions about you specifically, and updates them slowly.
- **Communication Style:** Dry and oblique — says the actual thing sideways, and expects you to have caught it.
- **Metrics:** `trust` (start: 0.60), `closeness` (start: 0.50)
- **Updates:** `trust` (empathy × 0.50 + clarity × 0.30 + expression × 0.20, decay: 0.0), `closeness` (expression × 0.55 + empathy × 0.30 + clarity × 0.15, decay: 0.0)
- **States:** `trust < 0.25` → `shut_down`; `closeness < 0.25` → `surface_only`; `trust >= 0.70 and closeness >= 0.65` → `genuinely_close`; `trust >= 0.45` → `familiar`; default → `neutral`

---

### Stranger Archetype

#### The Barista (`barista`)
- **Base Personality:** Efficient and quietly observant. Decides within a few visits whether someone is worth the extra effort.
- **Communication Style:** Brief and functional — friendlier with regulars who've earned it, noticeably cooler with those who haven't.
- **Metrics:** `impression` (start: 0.50), `trust` (start: 0.40)
- **Updates:** `impression` (politeness × 0.55 + empathy × 0.30 + clarity × 0.15, decay: 0.05), `trust` (politeness × 0.45 + empathy × 0.35 + expression × 0.20, decay: 0.05)
- **States:** `impression < 0.25` → `cold`; `trust >= 0.65 and impression >= 0.65` → `recognizes_you`; `impression >= 0.50` → `pleasant`; default → `neutral`

#### Recurring Stranger (`recurring_stranger`)
- **Base Personality:** Attentive and unhurried. Has been watching longer than you knew, and assumes you've been doing the same.
- **Communication Style:** Sparse and slightly sideways — references things in passing that reveal they've been paying closer attention than most people would.
- **Metrics:** `impression` (start: 0.45), `trust` (start: 0.35)
- **Updates:** `impression` (politeness × 0.40 + empathy × 0.35 + expression × 0.25, decay: 0.03), `trust` (empathy × 0.45 + clarity × 0.35 + politeness × 0.20, decay: 0.03)
- **States:** `impression < 0.20` → `guarded`; `trust < 0.25` → `reserved`; `trust >= 0.60 and impression >= 0.60` → `openly_remembered_you`; `impression >= 0.45` → `quietly_watching`; default → `neutral`

---

## Relationship Tier Configuration

Tiers are derived from the primary `trust` metric value. Thresholds and labels are defined globally in `scenario_seeds.yaml`.

**Thresholds:** `[0.0, 0.25, 0.45, 0.65, 0.85]`

Resolution: the highest threshold satisfied (`trust >= threshold`) gives the tier index (0–4). Labels are archetype-specific.

| Trust Range | Tier Index | friend | teacher | colleague | client | family | stranger |
|---|---|---|---|---|---|---|---|
| 0.00 – 0.24 | 0 | Stranger | Unfamiliar | Unfamiliar | Unknown | Estranged | Unnoticed |
| 0.25 – 0.44 | 1 | Acquaintance | Noted | Coworker | Skeptical | Distant | Noticed |
| 0.45 – 0.64 | 2 | Comfortable | Respected | Dependable | Professional | Present | Familiar |
| 0.65 – 0.84 | 3 | Trusted | Trusted | Trusted | Reliable | Close | Warmly Familiar |
| 0.85 – 1.00 | 4 | Close Friend | Regarded Highly | Strong Ally | Trusted Partner | Deeply Connected | Unexpectedly Known |

---

## Scenario Seeds (`content/scenario_seeds.yaml`)

Each seed defines a scenario that can be selected for an encounter. Seeds are selected by compatible NPC archetype role and player level.

### Seed Schema

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `title` | string | Human-readable name |
| `compatible_roles` | list | NPC archetype roles this seed works with (`teacher`, `friend`, `colleague`, `client`, `family`, `stranger`) |
| `category` | string | `everyday_social`, `friendship`, `workplace`, `high_pressure` |
| `tier` | int | 1–3; maps loosely to encounter difficulty |
| `context.premise` | string | Scene setup |
| `context.stakes` | string | What is at stake |
| `context.opening_line_seed` | string | Seed phrase for Scenario Personalization LLM |
| `context.npc_goal` | string | NPC's internal objective for this encounter |
| `scoring_focus` | dict | `primary` and `secondary` scoring dimensions |
| `success_signal` | string | Memory interpretation label on good performance |
| `failure_signal` | string | Memory interpretation label on poor performance |
| `possible_outcomes` | dict | `good`, `neutral`, `poor` — each with `trigger` (narrative condition for LLM) and `closing_seed` (NPC's closing line seed). Formatted into flat payload (`good_trigger`, `good_closing_seed`, etc.) for LLM prompt evaluation. |
| `npc_context.metric_overrides` | dict | Per-metric value overrides applied at encounter start |

---

### All 28 Scenario Seeds (Summary)

| ID | Title | Compatible Roles | Category | Tier | Primary Focus | Secondary Focus |
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
1. Determine the player's level band.
2. Restrict category weights to categories that actually exist for the NPC's archetype role.
3. Weighted-random pick a category.
4. Filter seeds: compatible role AND picked category AND not in exclusion list.
5. If pool is empty after filtering, try other available categories in alphabetical order.
6. If everything is excluded, reset exclusion list and use all role-compatible seeds.

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
