# THRESHOLD — Game Design Document & Systems Specification

**Document Version**: 2.0.0  
**Status**: Approved Master Specification  
**Lead Designer**: GameDesigner  
**Target Platform**: Browser (Godot 4 GL Compatibility / WebGL)  
**Backend Reference**: Relational Intelligence Engine API (Python / FastAPI / SQLite)  

---

## 📜 Revision History & Changelog

| Version | Date | Author | Description of Changes |
|---|---|---|---|
| 1.0.0 | 2026-08-04 | GameDesigner | Initial High-Level Concept & Sector Outline. |
| 1.5.0 | 2026-08-05 | GameDesigner | Integrated Hackathon Alignment & Diorama Room Specifications. |
| **2.0.0** | **2026-08-05** | **GameDesigner** | **Full GDD Overhaul: Detailed Mechanic Specifications, Economy Spreadsheet, Onboarding Flow, Behavioral Economics, and Street Connector Systems.** |

---

## 🎯 1. Design Pillars

Every system, mechanic, and UI element in THRESHOLD must pass against these three non-negotiable design pillars:

1. **Emotional Affordance over E-Learning**:  
   *What the player feels*: "I am in a real conversation with a human who has feelings and boundaries."  
   *Design Mandate*: Choices never feel like a quiz. Dialogue is open-ended text input evaluated in real-time by the AI Relational Intelligence Engine.

2. **Spatial & Visual Metaphor**:  
   *What the player feels*: "My environment reflects my emotional safety."  
   *Design Mandate*: Room interiors, lighting, and camera positioning visually respond to relationship metrics (slate blue when guarded, warm golden cream when trusted).

3. **Emergent Social Practice**:  
   *What the player feels*: "I am discovering my own communication habits and growing without being preached to."  
   *Design Mandate*: The game tracks repeating behavioral tendencies via the Observer Pattern engine and presents actionable self-reflection without judgment.

---

## 🔄 2. Core Gameplay Loop Document

```
+-----------------------------------------------------------------------------------+
|                                CORE GAMEPLAY LOOPS                                |
+-----------------------------------------------------------------------------------+
| MOMENT-TO-MOMENT (0-30s)                                                          |
| Explore Street / Room -> Spot NPC -> Engage (E) -> Glided Side-by-Side Position   |
| -> Type Response -> Immediate Sentiment & Multi-Dimensional Feedback (Scores/Badges) |
|                                                                                   |
| SESSION LOOP (5-30m)                                                              |
| Accept Daily Missions -> Navigate 2-3 Sector Encounters -> Manage NPC Mood/Trust  |
| -> Trigger Conversation Reflection -> Gain XP & Daily Streak Increment            |
|                                                                                   |
| LONG-TERM LOOP (Hours-Weeks)                                                      |
| Advance Level Bands (Lv. 1-100) -> Unlock Deep NPC Tiers -> Uncover Observer      |
| Pattern Insights -> Master 4D Skill Vectors -> Expand Street Access               |
+-----------------------------------------------------------------------------------+
```

### ⚡ Moment-to-Moment Loop (0–30 Seconds)
- **Action**: Player walks up to an NPC in a 3D Diorama Room Box or Outdoor Street and presses `E` (`interact`).
- **Feedback**:
  - Control locks instantly; `Walking over to <NPC>...` speech bubble appears over the NPC head.
  - Player character glides to a parallel side-by-side standing spot (`2.4m` distance, facing profile).
  - Camera smoothly interpolates to an asymmetric left-framed dialogue view (`+1.8m` X offset).
  - Audio tick sounds as typewriter text streams into a warm cream Tomodachi speech bubble.
- **Reward**: Instant sentiment animation on 3D NPC, live progress bar fills, score delta indicators (`+15% ↑`), and mood badge updates.

### 🔄 Session Loop (5–30 Minutes)
- **Goal**: Complete 2–3 dialogue encounters across different sectors (School, Café, Apartment, Office) to complete daily missions and earn XP.
- **Tension**: Managing NPC emotional metrics (`patience` decay, `trust` thresholds, `state` shifts like `guarded` or `irritated`).
- **Resolution**: Encounter completion triggers the *Conversation Reflection* (`OverviewModal`), updating the player's 4D skill vector, relationship tier, and daily streak.

### 🌐 Long-Term Loop (Hours–Weeks)
- **Progression**: Advance through 3 Level Bands (Lv. 1–30 Foundations, Lv. 31–70 Relational Nuance, Lv. 71–100 High-Stakes Crisis).
- **Retention Hook**: Unlocking maximum Relationship Tiers (`Close Friend`, `Regarded Highly`, `Trusted Partner`), discovering deep *Observer Pattern Insights* in the Journal (`JournalUI`), and expanding street access.

---

## 🛠️ 3. Comprehensive Mechanic Specifications

### 💬 Mechanic 1: 2.5D Screen-Projected Speech Bubbles
- **Purpose**: Render clear, vector-crisp dialogue text over character heads in 3D space without texture blurring.
- **Player Fantasy**: Reading real-time thoughts and spoken lines in a charming, expressive comic/simulation style.
- **Input**: Backend `ApiClient` response payload (`npc_reply`, `npc_expression`).
- **Output**: 2D `CanvasLayer` speech bubble node positioned via `camera.unproject_position(world_pos)`.
- **Success Condition**: Speech bubble spawns over character head, scales up with a bounce (`Tween.TRANS_BACK`), plays typewriter audio ticks, and auto-expands vertically without scrollbars.
- **Failure State**: If character is behind camera frustum, `visible` sets to `false` to avoid off-screen artifacts.
- **Edge Cases**:
  - *Extremely long text*: `fit_content = true` on `RichTextLabel` forces vertical expansion downward while maintaining maximum viewport width (`340px`).
  - *Overlapping characters*: Player bubble offsets `-0.7m` left; NPC bubble offsets `+0.7m` right.
- **Tuning Levers**:
  - `typewriter_speed`: `0.7s` `[PLACEHOLDER]`
  - `bounce_duration`: `0.3s` `[PLACEHOLDER]`
  - `bubble_max_width`: `340px` `[PLACEHOLDER]`
- **Dependencies**: `DialogueUI.gd`, `Camera3D`, `AudioManager.gd`.

---

### 🚶‍♂️ Mechanic 2: Parallel Sideways Dialogue Positioning
- **Purpose**: Ensure characters stand at a natural, non-crowded distance facing each other in profile during dialogue.
- **Player Fantasy**: Standing side-by-side with another person in a cozy 2.5D dollhouse scene.
- **Input**: Player presses `E` while inside `InteractionDetector` area of an NPC.
- **Output**: 
  - Player control locks (`set_physics_process(false)`).
  - Player glides to `target_npc.global_position + Vector3(-2.4, 0, 0)`.
  - Player mesh rotates `90°` (facing right); NPC mesh rotates `-90°` (facing left).
- **Success Condition**: Player stops smoothly at `2.4m` distance on the X-axis facing the NPC.
- **Failure State**: If standing spot is blocked by geometry, target defaults to nearest open NavMesh point.
- **Edge Cases**:
  - *Player standing on top of NPC*: Distance calculation defaults to `Vector3(-2.4, 0, 0)` relative to NPC.
- **Tuning Levers**:
  - `dialogue_standing_distance`: `2.4m` `[PLACEHOLDER]`
  - `glide_duration`: `0.4s` `[PLACEHOLDER]`
- **Dependencies**: `EncounterManager.gd`, `Player3D.gd`, `NPC.gd`.

---

### 📷 Mechanic 3: Asymmetric Left-Framed Camera Zoom
- **Purpose**: Frame the 3D conversation in the open mid-left area of the screen so the right performance UI panel remains 100% unobscured.
- **Player Fantasy**: Cinematic framing that focuses on the characters while keeping performance stats clear.
- **Input**: Dialogue state changes to `ACTIVE`.
- **Output**: Camera pivot moves to `Vector3((player.x + npc.x)/2 + 1.8, 2.4, mid.z + 4.2)` with `spring_length = 2.6m`.
- **Success Condition**: Characters and speech bubbles sit in `X = 25%–55%` screen width; right 300px HUD panel is completely clear.
- **Failure State**: Camera clips into back wall; spring arm collision prevents clipping.
- **Edge Cases**:
  - *Small rooms*: Clamped within room boundary limits.
- **Tuning Levers**:
  - `camera_left_offset`: `+1.8m` `[PLACEHOLDER]`
  - `dialogue_zoom_distance`: `2.6m` `[PLACEHOLDER]`
- **Dependencies**: `Player3D.gd`, `SpringArm3D`.

---

### 📊 Mechanic 4: Real-Time Communication Reflection Panel
- **Purpose**: Provide immediate feedback on the player's performance across 4D skill dimensions.
- **Player Fantasy**: Seeing emotional intelligence and communication clarity measured in real time.
- **Input**: `turn_scores` payload from `ApiClient.send_message()`.
- **Output**: 4 progress bars (`Clarity`, `Empathy`, `Politeness`, `Expression`), composite overall score, and animated delta labels (`+15% ↑`).
- **Success Condition**: Progress bars animate smoothly (`Tween.tween_property`) with green/red delta badges.
- **Failure State**: No turn scores returned; panel displays baseline scores (`50%`).
- **Edge Cases**:
  - *First turn of encounter*: Delta displays `[=]` baseline until turn 2.
- **Tuning Levers**:
  - `bar_animation_speed`: `0.4s` `[PLACEHOLDER]`
  - `good_status_threshold`: `70%` `[PLACEHOLDER]`
- **Dependencies**: `DialogueUI.gd`, `scoring_service.py`.

---

### 🔍 Mechanic 5: Observer Pattern Insight System
- **Purpose**: Identify and present subconscious repeating behavioral habits.
- **Player Fantasy**: Gaining deep psychological self-awareness about personal communication blind spots.
- **Input**: Encounter completion event sent to backend `observer_service`.
- **Output**: If `count(memory.interpretation == X) >= 2`, returns a purple-accented *Observer Pattern Insight* card inside `OverviewModal`.
- **Success Condition**: Modal displays tailored LLM reflection phrasing when a pattern repeats.
- **Failure State**: No pattern detected; insight card remains hidden.
- **Edge Cases**:
  - *Single turn encounters*: Memory entries recorded but observer trigger requires at least 2 occurrences.
- **Tuning Levers**:
  - `pattern_trigger_threshold`: `2 occurrences` `[PLACEHOLDER]`
- **Dependencies**: `observer_service.py`, `OverviewModal.gd`.

---

## 📊 4. Economy & Skill Tuning Balance Spreadsheet

All values represent the tuning levers and thresholds governing progression and rendering:

```
Variable / Metric           | Base Value | Min   | Max   | Tuning Rationale & Notes
----------------------------|------------|-------|-------|--------------------------------------------------
Player Starting Level       | 1          | 1     | 100   | Linear level scaling up to max cap
XP Per Level                | 100 XP     | 100   | 100   | Normalization base for level progression
XP Gain (Good Outcome)      | 35 XP      | 25    | 50    | [PLACEHOLDER] - 3 good encounters = 1 level up
XP Gain (Neutral Outcome)   | 15 XP      | 10    | 25    | [PLACEHOLDER] - Steady baseline progress
XP Gain (Poor Outcome)      | 5 XP       | 0     | 10    | Consolation XP so failure still feels useful
Skill Vector Default        | 0.50 (50%) | 0.00  | 1.00  | Neutral baseline for Clarity/Empathy/Polite/Expr
Skill Update Weight (Pri)   | +0.08      | +0.02 | +0.15 | Primary dimension updates faster on good turns
Skill Update Weight (Sec)   | +0.04      | +0.01 | +0.08 | Secondary dimension updates moderately
Dialogue Gap Distance       | 2.4m       | 1.8m  | 3.0m  | Parallel standing offset for side-by-side view
Camera Left Shift           | +1.8m      | 1.0m  | 2.5m  | Unblocks right 300px performance panel
Typewriter Text Speed       | 0.7s       | 0.3s  | 1.2s  | Playback duration per dialogue line
Patience Decay Per Turn     | 0.02       | 0.00  | 0.05  | Gradual time pressure per conversation turn
Trust Tier: Acquaintance    | 0.25       | 0.20  | 0.30  | Threshold for first tier upgrade
Trust Tier: Comfortable     | 0.45       | 0.40  | 0.50  | Mid-tier relationship unlock
Trust Tier: Trusted         | 0.65       | 0.60  | 0.70  | High-trust scenario unlock
Trust Tier: Close / Partner | 0.85       | 0.80  | 0.90  | Maximum relationship tier cap
```

---

## 🏁 5. Player Onboarding Flow & First Session Checklist

```
## Onboarding Checklist
- [x] Core verb (Interaction E) introduced within 10 seconds of first control
- [x] First success guaranteed — opening line from Daria provides immediate warm dialogue prompt
- [x] First encounter introduced in a safe, low-stakes context (Campus Entry / Room_Start)
- [x] Player discovers Journal [J] through key prompt or HUD button click
- [x] First session ends on a hook — Level Up unlock, streak increment (+1), and street access
```

### Detailed Step-by-Step Onboarding Journey:
1. **Beat 1 (0–30s)**: Player spawns in `Room_Start`. Ground ring highlights NPC Daria. Prompt reads `[E] Talk to Daria`.
2. **Beat 2 (30s–2m)**: Player presses `E`. Control locks, character glides side-by-side (`2.4m`), camera frames left (`+1.8m`), and Daria says her opening line in a cream speech bubble.
3. **Beat 3 (2m–4m)**: Player types a response in the text box. Real-time scores fill the right panel, showing instant `+15% ↑` feedback.
4. **Beat 4 (4m–5m)**: Dialogue completes. `OverviewModal` appears showing `PERFORMANCE: GOOD`, `+35 XP`, and `Level 1 -> Level 2` progress.
5. **Beat 5 (5m+)**: Player steps out through the door onto `StreetConnector.tscn` to explore the open world!

---

## 🏛️ 6. World Architecture & Street Connector Systems

### 🏙️ 1. Outdoor Street Connector (`StreetConnector.tscn`)
- **Visual Style**: 2.5D side-scrolling street featuring low-poly buildings (blue house, dark office), mailboxes, fences, streetlamps, trees, and sidewalks.
- **Camera Mechanics**: Smooth horizontal tracking camera (`lerp` with `5.0 * delta`) that follows the player along the sidewalk, clamped to street end boundaries.
- **Building Doors**: Approaching a building door displays a ground interaction ring (`[E] Enter`). Pressing `E` triggers a seamless scene transition into the target Diorama Room.

### 📦 2. Indoor Diorama Room Box (`RoomTemplate.tscn`)
- **Structure**: 3-walled diorama room box (16m W × 10m D × 5m H) with an open front wall.
- **Camera Mechanics**: Fixed stationary camera anchor (`Vector3(0, 3.2, 7.5)`, `-14°` pitch) framing 100% of the room interior at all times.
- **Scene Inheritance**: All game rooms (`Room_Start.tscn`, `Room_Office.tscn`) inherit from `RoomTemplate.tscn`. New rooms are created by duplicating `RoomTemplate.tscn` and adding custom 3D props.

---

## 🧠 7. Behavioral Economics & Progression Design

1. **Endowment Effect**:
   - The player builds and personalizes their communication profile in `JournalUI`. Earning custom relationship badges (`Trusted Partner`, `Regarded Highly`) creates personal investment in maintaining high relationship scores.

2. **Commitment & Streak Devices**:
   - `daily_streak` tracks consecutive days of social practice. Daily mission rewards incentivize regular engagement and prevent skill decay.

3. **Loss Aversion Mitigation**:
   - Poor dialogue turns reduce effective encounter metrics but **never penalize overall player XP**. Failing an encounter still awards `+5 XP` as consolation for learning, ensuring players never fear practicing difficult scenarios.

---

## 📍 8. Technical Deliverables Summary

| File Path | Description |
|---|---|
| [docs/world_lore_and_narrative_blueprint.md](file:///c:/Users/User/Documents/THRESHOLD/docs/world_lore_and_narrative_blueprint.md) | **Master Game Design Document (GDD)** containing all pillars, mechanics, economy spreadsheets, onboarding flows, and street connector specs. |
| [diorama_room_system_spec.md](file:///c:/Users/User/Documents/THRESHOLD/docs/diorama_room_system_spec.md) | Non-technical architectural guide for diorama rooms and camera offsets. |
| [world_progression_story_arc.md](file:///c:/Users/User/Documents/THRESHOLD/docs/world_progression_story_arc.md) | 15 NPC storyline tracks across 4 sectors and 3 Level Bands. |

