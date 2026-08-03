# THRESHOLD — Product Specification

**Hackathon:** Tencent Cloud × UTM Hackathon 2026 — Game Track, "Relational Intelligence Engine"
**Audience:** game designers, judges, team members, future collaborators
**Purpose:** explain what THRESHOLD is and why it exists — not how it is built

---

## 1. Overview

**Name:** THRESHOLD

**One-line pitch:** *"A social simulation where every conversation is real, every character remembers how you treated them, and an Observer occasionally reveals the pattern behind it."*

**Problem being solved:** communication skill is not something people improve by reading theory or picking multiple-choice answers. It is developed through repeated, consequence-bearing practice — the kind normally only available by risking a real relationship. THRESHOLD gives players a space to have real, freely-worded conversations with people who react like people, remember like people, and where nothing resets when it goes badly.

**Player fantasy:** you are someone navigating the ordinary relationships of a life stage everyone recognizes — a teacher you need something from, a friend who's noticed your distance, a colleague you have to hold accountable, a client who's unhappy with your work. You are not solving puzzles or picking the "correct" line. You are being someone, in conversations that matter, to people who don't forget how you treated them.

---

## 2. Core Experience

The player journey, as it is felt during play:

```
Explore
  ↓
Encounter a character
  ↓
Make choices through real conversation
  ↓
The relationship changes
  ↓
The world remembers
  ↓
Future encounters are different because of it
```

The player moves freely through a small, grounded environment. There is no menu that says "start scenario." A character is simply present, in a space, and approaching them begins a real conversation. The player types their own words — there are no dialogue options to choose between. What they say is evaluated for how they communicated, not whether they picked a scripted "right answer." The character's internal disposition toward the player shifts as a result, and that shift persists: the next time the player meets that character, the conversation starts from wherever the relationship was left, not from a clean slate.

This is the entire game. There is no separate "combat," "puzzle," or "minigame" layer bolted on top. The conversation *is* the gameplay, and the relationship *is* the progression.

---

## 3. Design Philosophy

**Why conversations are the gameplay.** The hackathon challenge asks for a game that trains real communication skill in a way that transfers to real life. A game built around picking from pre-written dialogue options trains pattern recognition, not communication — it teaches players to find the "correct" button, which is the opposite of the skill being trained. THRESHOLD's core mechanic is the player typing their own sentences, because that is the only mechanic that actually exercises the skill the game claims to build.

**Why there are no dialogue options.** Any fixed dialogue tree implies there is a single correct sentence for a given moment, which is false of real conversation and actively undermines the "authentic social situations" requirement of the challenge. Removing dialogue trees is not a difficulty increase — it is the difference between a game that resembles communication and a game that requires it.

**Why consequences persist.** Real conversations do not have a retry button. A relationship a player damages by being dismissive does not reset the next time they see that person — it opens more guarded, and may reference what happened. This is the single strongest way the game demonstrates that it is simulating something real rather than scoring a quiz: the proof is visible, not claimed. A player (or a judge watching a recording) can see a poorly-handled encounter change how a character behaves the next time they meet, with no retry available to undo it.

**Why the Observer exists.** A player experiencing their own conversations one at a time may not notice that they handle a certain kind of moment the same way, with different people, every time. The Observer is a second, quieter layer that surfaces exactly that: a pattern the player could not see from inside a single conversation, made visible only when it has genuinely repeated. It never coaches the player mid-conversation and never tells them what to say — it only reveals something true about what has already happened, after the fact, in its own distinct voice, separate from any character in the world.

**Why the game avoids feeling like a test.** A game that shows a raw numeric score after every message reads as an evaluation tool, not a simulation — and undermines the sense that the player is relating to a person rather than being graded by a system. THRESHOLD deliberately favors legible, human language over raw numbers wherever a player-facing choice exists: a relationship is shown as a named stage ("Comfortable," "Trusted Partner"), not a decimal; feedback names what happened in plain language, not a rubric; the Observer speaks in a natural, grounded voice, not a diagnostic report. The intelligence behind the game is real and rigorous — the presentation of it is deliberately human.

---

## 4. Characters

Four archetypes, matched directly to the relationship categories the hackathon challenge names explicitly: teacher, friend, colleague, and client. Each represents a distinct register of social risk and a distinct kind of stakes.

**Teacher.** Represents interactions with authority and asymmetric power — asking for something you may not fully deserve, being evaluated by someone whose judgment has real consequences for you. Tests a player's ability to be clear and appropriately deferential without being either obsequious or evasive.

**Friend.** Represents interpersonal, emotionally intimate relationships with no power imbalance and no professional stakes — the hardest register in some ways, because there is no formal script to hide behind. Tests empathy and emotional honesty directly.

**Colleague.** Represents peer-level collaboration and conflict — situations where the player has to hold someone accountable, or be held accountable, without either party having formal authority over the other. Tests the ability to name a problem without attacking the person.

**Client.** Represents professional, transactional relationships where trust must be earned through competence and clarity rather than warmth. Tests the ability to communicate under stakes where the relationship itself is conditional on performance.

Together, these four cover the interpersonal, workplace-collaboration, and conflict-resolution categories the hackathon brief names, without collapsing into a single "workplace" framing that would leave the "friend" and "teacher" categories unrepresented.

---

## 5. AI Philosophy

THRESHOLD's characters are not scripted, and they are not stateless chatbots either. Two distinct kinds of intelligence are at work, and the game is designed so their roles never blur into each other.

**Characters interpret, and remember, what happened to them.** Every conversation a character has with the player is turned into a compact memory of *what it meant*, not a transcript of exact words — the way a real person remembers being dismissed, not the literal sentence that dismissed them. That memory persists and shapes how the character behaves the next time the player sees them.

**Characters speak from inside a state, not from a blank slate.** A character's tone, warmth, and willingness to open up in any given conversation is shaped by everything that has happened between them and the player so far — not generated fresh and disconnected each time. A character who has been dismissed twice does not warm up instantly because the player says one nice thing; a character who has been consistently heard opens up more easily.

**Personalization happens inside boundaries, not without them.** The premise of any given conversation — what is actually happening, what is at stake, what the character wants from the exchange — is fixed and authored in advance. What adapts to the individual player is the delivery: tone, phrasing, and how the character's personality expresses itself given the player's history with them. The game never improvises a new situation on the fly; it personalizes a known one.

**A second layer watches the pattern, not the moment.** Beyond any single conversation, something in the system is capable of noticing when the same kind of miss happens more than once with the same person — and naming it, plainly, without judgment or coaching, only after it has genuinely repeated.

---

## 6. Gameplay Systems Overview

**Relationship progression.** Each character the player knows has their own evolving disposition toward the player, expressed as a named relationship stage appropriate to that kind of relationship (a friend can become a "Close Friend"; a client becomes a "Trusted Partner"). This is the primary, most legible form of progress in the game — not a level number, a way another person feels about you.

**Communication scoring.** Every message the player sends is assessed across four dimensions of how well they communicated: clarity, empathy, politeness, and expression. This is not a pass/fail judgment — it is ongoing, dimension-specific feedback the player can use to understand their own patterns.

**Levels.** The player has an overall level reflecting communication growth across all their relationships. Rather than unlocking new content, level controls the *kind* of situations the player is more likely to encounter — lower levels lean toward lower-stakes, everyday interactions; higher levels weight toward more emotionally complex and higher-pressure ones. Every kind of interaction is available from the very first session; level shapes likelihood, not access.

**Daily challenges.** A featured situation is highlighted each day to encourage consistent practice, tied to a simple streak so returning players have a reason to keep coming back.

**Reports.** At the close of a session, the player receives a personal summary of their communication growth — their strengths, the area they're improving in, a pattern noticed across their recent conversations, and a concrete suggestion for what to practice next.

---

## 7. Scope Boundaries

The following are deliberate exclusions, not omissions — each protects the game's core identity or its feasibility within the hackathon timeline:

- **No combat, health bars, or "patience meters" as a game-mechanical stat.** Consequences in THRESHOLD are conversational — a colder reply, a change in how someone treats you — never a game-mechanical loss condition. Turning relationship stakes into combat stakes would undermine the realism the hackathon challenge explicitly requires.
- **No fantasy or metaphor layer of any kind.** Every character, situation, and consequence in THRESHOLD is presented as plainly realistic. No visual metaphor stands in for an emotional state.
- **No dialogue trees, no pre-written "correct" responses.** The player always types their own words.
- **No retry, reload, or "perfect answer" loop.** Consequences are permanent within a playthrough.
- **No scenario invented on the fly.** Every situation is authored in advance and reviewed; only its delivery adapts live.
- **No cross-character pattern detection.** The Observer only notices repetition within a single relationship, never correlates across different people.
- **No parent or teacher-facing dashboard**, and **no voice or spoken audio.** Both are explicitly out of scope for this build.
- **No visible "training" or "coaching" framing inside the game itself.** The player is never told they are being evaluated; that framing exists only in materials presented to judges, never in the played experience.
