# THRESHOLD — Game Overview

## What Is THRESHOLD

THRESHOLD is a social simulation game in which the player navigates real-feeling conversations with persistent non-player characters (NPCs). The core premise is not combat, resource management, or puzzle-solving — it is communication. Every encounter is a conversation that matters and leaves traces.

The player is given a scenario — a social situation with real stakes — and must respond to an NPC in a way that is clear, empathetic, polite, and emotionally honest. The NPC responds authentically in its own voice. After the conversation ends, the player's communication patterns are evaluated, relationship metrics are updated, and a record is written to the NPC's memory. That memory persists into future encounters.

THRESHOLD is built on a single design principle: **the quality of what you say changes who you are to this person.**

---

## Core Gameplay Loop

```
DAILY CHALLENGE / NPC SELECTION
         │
         ▼
   START ENCOUNTER
   ─ scenario selected by level + role
   ─ NPC opens in their voice, personalized to history
         │
         ▼
  PLAYER SENDS MESSAGE  (up to 8 turns)
   ─ scored on clarity, empathy, politeness, expression
   ─ NPC replies in character with current emotional state
   ─ coach hint surfaces a factual observation
   ─ feedback identifies strength + area for growth
   ─ relationship metrics update after each turn
         │
         ▼
   ENCOUNTER ENDS (turn 8 or explicit /end call)
   ─ outcome determined: good / neutral / poor
   ─ encounter memory written to NPC instance
   ─ observer checks for repeated patterns across memory
   ─ XP awarded, skill vector updated, level checked
         │
         ▼
   REPORT (on demand)
   ─ LLM synthesizes skill vector + recent encounters
   ─ returns interpretive personal summary
```

One full loop takes roughly 6 player messages. The encounter ends automatically at turn 6.

---

## Player Experience

The player receives real-time feedback after every message:

- **NPC reply** — an authentic response written in the NPC's voice, shaped by their personality, current emotional state, and the history of the relationship
- **NPC expression** — an emotional expression enum surfaced to the frontend (`warm`, `guarded`, `irritated`, `neutral`, etc.)
- **Turn scores** — four numeric scores (0.0–1.0) for clarity, empathy, politeness, and expression
- **Relationship tier** — a human-readable label reflecting the current relationship status (e.g., `Trusted`, `Close Friend`)
- **NPC state** — the NPC's current emotional state, derived deterministically from their metrics
- **Coach hint** — a single factual observation about the conversation (never prescriptive)
- **Feedback** — a strength (best dimension) and an improvement area (worst dimension)

At encounter end the player sees:
- **Outcome** (`good`, `neutral`, or `poor`)
- **Observer event** — if a conversational pattern has repeated across this NPC's memory, the Observer names it without coaching
- **Level-up notification** if XP crosses the threshold

On demand, the player can request a **report**: an AI-generated personal summary derived from their skill vector and recent encounter history.

---

## Characters and Relationships

There are four NPCs. Each has a distinct archetype role, personality, communication style, and set of relationship metrics.

| ID | Name | Role | Personality | Communication Style |
|---|---|---|---|---|
| `sara` | Sara | friend | Direct but caring, reads as blunt if you don't know her | Casual, expressive, texts in fragments |
| `mr_teo` | Mr. Teo | teacher | Patient but direct. Expects ownership and brevity | Formal, measured, economy of words |
| `jun` | Jun | colleague | Conflict-avoidant but quietly watches how people treat others | Measured, professional, occasionally dry |
| `ms_reyes` | Ms. Reyes | client | Professional, results-driven, does not hide dissatisfaction | Terse, precise, expects the same |

Each NPC exists as a **persistent instance** per player. Their metrics carry over between encounters. The player's relationship with Sara from encounter 1 is the same Sara in encounter 4 — she remembers how she was treated.

### Relationship Tiers

Tiers are derived from the `trust` metric against global thresholds. Each archetype has its own tier labels.

| Trust Threshold | friend | teacher | colleague | client |
|---|---|---|---|---|
| 0.0 | Stranger | Unfamiliar | Unfamiliar | Unknown |
| 0.25 | Acquaintance | Noted | Coworker | Skeptical |
| 0.45 | Comfortable | Respected | Dependable | Professional |
| 0.65 | Trusted | Trusted | Trusted | Reliable |
| 0.85 | Close Friend | Regarded Highly | Strong Ally | Trusted Partner |

---

## Major Gameplay Systems

### Scoring System

Every player message is scored on four dimensions by the LLM (Memory Formation pipeline):

- **clarity** — how clearly and directly the player communicated their meaning
- **empathy** — whether the player acknowledged or validated the other person's feelings or perspective
- **politeness** — whether the tone was respectful and considerate
- **expression** — whether the player communicated with emotional honesty and personal engagement

Each dimension returns a float `0.0–1.0`. These scores drive everything downstream: NPC metric updates, XP calculation, skill vector updates, and outcome determination.

### Relationship / Metric System

Each NPC has 2–3 relationship metrics. These are updated deterministically after every turn based on the turn scores and the NPC's configured `metric_updates` rules. Metrics drive the NPC's state via the State Engine.

**Sara** — `trust`, `patience`, `openness`  
**Mr. Teo** — `trust`, `respect`  
**Jun** — `trust`, `comfort_level`  
**Ms. Reyes** — `trust`, `satisfaction`

### State Engine

The NPC's current state is computed deterministically from their metrics. The rules are evaluated in order; the first matching rule wins. All NPCs have a `default` rule as the final fallback. States are fed to the LLM Character Voice pipeline, shaping the NPC's reply.

**Sara's states:** `guarded`, `irritated`, `warm`, `neutral`  
**Mr. Teo's states:** `disappointed`, `dismissive`, `approving`, `neutral`  
**Jun's states:** `withdrawn`, `defensive`, `collaborative`, `neutral`  
**Ms. Reyes' states:** `hostile`, `frustrated`, `satisfied`, `neutral`

### Memory System

Every turn writes a memory entry to the NPC instance:
- **event** — a truncated string of the player message
- **interpretation** — a scenario-specific signal label (e.g., `owned_mistake_plainly`, `avoided_emotional_acknowledgment`)
- **turn** — the turn number

At encounter end an additional summary entry is written. The most recent 10 memory entries are included in the LLM context for NPC replies, giving the NPC a sense of conversational history.

### Observer System

The Observer watches for repeated patterns in an NPC instance's full memory. If any interpretation label appears 2 or more times, the Observer fires. It calls the LLM Observer Phrasing pipeline to name the pattern factually — not as coaching, but as a mirror. The Observer fires at encounter end and its message is included in the `/interaction/end` response.

### Scenario System

A **scenario seed** defines the premise, stakes, NPC goal, scoring focus, success/failure signals, and possible outcomes. Seeds are selected at encounter start based on the NPC's archetype role and the player's level. Category distribution shifts with level:

| Level Band | everyday_social | friendship | workplace | high_pressure |
|---|---|---|---|---|
| 1–30 | 60% | 25% | 10% | 5% |
| 31–70 | 20% | 30% | 35% | 15% |
| 71–100 | 5% | 20% | 35% | 40% |

### Progression System

**XP** is awarded deterministically at encounter end. The formula weights the seed's primary scoring focus dimension (50%), secondary (30%), and the remaining two dimensions (10% each), multiplied by an outcome factor (`good`=1.0, `neutral`=0.6, `poor`=0.3), and dampened slightly by player level (higher level = marginally less XP per encounter). XP is normalized 0.0–1.0 within a level. Each level requires 1.0 XP to advance.

**Skill vector** — a player-level aggregate of the four scoring dimensions, updated after each encounter by blending encounter averages toward the current values, weighted by the seed's scoring focus.

---

## Progression

- Player starts at level 1 with all skill dimensions at 0.5
- Max level: 100 (configurable)
- Each level requires 1.0 XP (configurable: `xp_per_level`)
- Scenario difficulty distribution shifts as the player levels up
- Skill vector reflects genuine communication tendencies over time

---

## Memory and Consequences

Memory is the mechanism by which the game keeps accounts. The NPC does not forget.

- Every turn writes a memory entry with the LLM's interpretation of what happened
- The interpretation vocabulary is defined per scenario: two labels (success signal and failure signal)
- These entries are fed back to the LLM on subsequent turns and encounters, giving the NPC contextual awareness
- When a pattern repeats (same interpretation appearing twice or more), the Observer names it
- At encounter end the final effective metrics are written back to the persisted NPC instance, changing the starting point for the next encounter

The consequence of playing poorly is not a game over — it is a relationship that starts more guarded next time.

---

## AI Role in the Experience

THRESHOLD uses an LLM for five specific purposes, all of which are strictly bounded:

| Pipeline | Purpose | Inputs | Output |
|---|---|---|---|
| Memory Formation | Score the player's message and pick an interpretation label | Player message, scenario context, conversation history, vocabulary | Scores + interpretation label |
| Character Voice | Generate the NPC's reply, expression, and coach hint | NPC identity, state, memory context, conversation, scenario | NPC reply + expression + coach hint |
| Scenario Personalization | Personalize the scenario opening line to the character and history | Seed data, NPC identity, starting metrics, player history summary | Opening line + expression |
| Observer Phrasing | Phrase the Observer's pattern reveal from memory data | Matching memory entries | Observer message |
| Report Generation | Synthesize a personal communication summary | Skill vector, level, recent encounter history | Report object |

**The LLM makes no game-state decisions.** It does not set metrics, determine outcomes, fire the Observer trigger, calculate XP, or choose scenarios. Every game-state mutation is performed by deterministic service code after the LLM call returns. The LLM is purely a rendering and assessment layer.

---

## Intentional Limitations and Scope

THRESHOLD is a backend. There is no frontend in this repository. All game logic is server-side.

**What is implemented:**
- Full encounter lifecycle (start → message loop → end)
- Four NPCs with persistent relationship state
- Six scenario seeds across four categories
- All five LLM pipelines
- Deterministic scoring, metric update, state resolution, outcome, XP, and skill vector formulas
- Observer pattern detection
- On-demand report generation
- Daily challenge feed
- Player progression (level, XP, skill vector)

**What is not implemented (by design):**
- Frontend or UI of any kind
- Multiplayer or social features
- NPC-to-NPC relationships
- Player inventory, achievements, or unlockables
- Branching narrative arcs
- Audio or visual assets
- Authentication or user account management (player ID is caller-supplied)
- Streak tracking logic (field exists, not incremented by current code)
