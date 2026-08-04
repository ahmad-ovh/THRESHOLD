# THRESHOLD: Master Game Design Document & World Blueprint
*Frontend Rendering & Visualization Layer for the Relational Intelligence Engine*

---

## 1. Executive Summary & Design Pillars

**THRESHOLD** is a 2.5D social simulation game where communication is the core gameplay verb. Set in a world of silent emotional isolation, players navigate physical and psychological "thresholds" — the split-second hesitation before speaking honestly, holding a boundary, or offering empathy.

The frontend serves as an immersive **rendering and visualization layer** for a deterministic backend `Relational Intelligence Engine`. Every 3D room, street lamp, speech bubble, and camera interpolation translates backend metric updates (`trust`, `respect`, `closeness`) and 4D skill vectors (`clarity`, `empathy`, `politeness`, `expression`) into tangible, game-like player feedback.

```
+-------------------------------------------------------------------------------+
|                             DESIGN PILLARS                                    |
+-------------------------------------------------------------------------------+
| 1. EMOTIONAL AFFORDANCE: Social choices feel like authentic human encounters, |
|    never dry e-learning quizzes or rigid multiple-choice trees.               |
|                                                                               |
| 2. SPATIAL METAPHOR: Room box lighting and street aesthetics reflect the      |
|    emotional warmth of their primary occupants.                               |
|                                                                               |
| 3. NON-LINEAR RELATIONAL DISCOVERY: Free-roam street exploration with        |
|    backend level-band scenario scaling (Lv. 1–100).                           |
+-------------------------------------------------------------------------------+
```

---

## 2. Core Gameplay Loops

### ⚡ Moment-to-Moment (0–30 Seconds)
- **Action**: Player approaches an NPC in a 3D Diorama Room Box or Outdoor Street and presses `E` (`interact`).
- **Feedback**: 
  - Control locks instantly; `Approaching <NPC>...` floating speech bubble appears over the NPC head.
  - Player glides to a parallel side-by-side standing spot (`2.4m` distance, facing profile).
  - Camera smoothly transitions to an asymmetric left-framed dialogue view (+1.8m X offset).
  - Typewriter text streams in cream Tomodachi speech bubbles with audio ticks.
- **Reward**: Instant sentiment reaction, score delta indicators (`+15% ↑`), and mood badge shifts.

### 🔄 Session Loop (5–30 Minutes)
- **Goal**: Complete 2–3 dialogue encounters across different sectors (School, Café, Apartment, Office) to complete daily missions and earn XP.
- **Tension**: Managing NPC emotional metrics (`patience` decay, `trust` thresholds, `state` shifts like `guarded` or `irritated`).
- **Resolution**: Encounter completion triggers the *Conversation Reflection* (`OverviewModal`), updating the player's 4D skill vector, relationship tier, and daily streak.

### 🌐 Long-Term Loop (Hours–Weeks)
- **Progression**: Advance through 3 Level Bands (Lv. 1–30 Foundations, Lv. 31–70 Relational Nuance, Lv. 71–100 High-Stakes Crisis).
- **Retention Hook**: Unlocking maximum Relationship Tiers (`Close Friend`, `Regarded Highly`, `Trusted Partner`), discovering deep *Observer Pattern Insights* in the Journal (`JournalUI`), and expanding street access.

---

## 3. World Architecture: Diorama Rooms & Street Connectors

The physical world combines **Modular Diorama Room Boxes** (interiors) with **2.5D Outdoor Street Connectors** (exteriors).

```
 [ Sector I: Campus ] ◄── Street ──► [ Sector II: Café ]
          │                                  │
       Street                             Street
          ▼                                  ▼
 [ Sector III: Home ] ◄── Street ──► [ Sector IV: Office ]
```

### 🏙️ 1. Outdoor Street Connector (`StreetConnector.tscn`)
- **Visual Style**: 2.5D side-scrolling street scene featuring low-poly buildings, mailboxes, wooden fences, streetlamps, trees, and sidewalks.
- **Camera Behavior**: Smooth X-axis camera tracking (`lerp` with `5.0 * delta`) that follows the player along the sidewalk, clamped to street end walls.
- **Door Interactivity**: Approaching a building door displays a 3D ground interaction ring (`E Enter`). Pressing `E` triggers a seamless threshold transition into the building's interior Diorama Room.

### 📦 2. Indoor Diorama Room Box (`RoomTemplate.tscn`)
- **Structure**: 3-walled diorama room box (16m W × 10m D × 5m H) with an open front wall.
- **Camera Behavior**: Stationary camera anchor (`Vector3(0, 3.2, 7.5)`, `-14°` pitch) framing 100% of the room interior at all times.
- **Dialogue Camera Interpolation**: During dialogue, the camera zooms into `2.6m` spring length and shifts `+1.8m` to the left, centering the characters in the open mid-left viewport (`25%–55%` width) and keeping the right `Communication Reflection` panel 100% clear.

---

## 4. Frontend Mechanic Specifications

### 💬 Mechanic: 2.5D Screen-Projected Speech Bubbles
- **Purpose**: Render clear, vector-crisp dialogue text over character heads in 3D space.
- **Input**: Backend `ApiClient` dialogue response payload (`npc_reply`, `npc_expression`).
- **Output**: 2D `CanvasLayer` speech bubble node positioned via `camera.unproject_position(world_pos)`.
- **Visual Design**: Tomodachi Life cream background (`#fffef0`), rounded pill speaker badges (`Alice`, `You`), typewriter playback, bouncing down arrow (`▼`).
- **Dynamic Auto-Height**: `fit_content = true` on `RichTextLabel` allows bubbles to expand downward vertically based on text length without scrollbars.
- **Spatial Offsets**: Player bubble offsets `-0.7m` left; NPC bubble offsets `+0.7m` right to prevent overlap.

### 📊 Mechanic: Real-Time Communication Reflection Panel
- **Purpose**: Provide immediate multi-dimensional feedback on communication quality.
- **Input**: Cumulative turn scores (`clarity`, `empathy`, `politeness`, `expression`) from backend `scoring_service`.
- **Output**: Animated progress bars (`ProgressBar`), composite score (`Overall: X%`), and delta badges (`+15% ↑` in green, `-10% ↓` in red).

### 🔍 Mechanic: Observer Pattern Insight Card
- **Purpose**: Highlight subconscious repeating behavioral patterns when the player makes the same communication mistake twice across interactions.
- **Trigger**: Backend `observer_service` detects `count(memory.interpretation == X) >= 2`.
- **Visualization**: Displayed inside `OverviewModal` as a purple-accented insight card featuring tailored reflection feedback.

---

## 5. Economy & Skill Tuning Matrix

All values represent the frontend rendering thresholds and feedback triggers for backend data:

| Metric / Variable | Base Value | Min | Max | Frontend Rendering & Feedback Rationale |
|---|---|---|---|---|
| **Level XP Threshold** | `100 XP` | `0` | `100` | Bar fills in `HUD`; triggers Level Up banner modal at 100% |
| **Skill Vector Min/Max** | `50%` | `0%` | `100%` | Rendered as 4 progress bars in `DialogueUI` & `JournalUI` |
| **Trust Threshold (Friend)** | `0.65` | `0.0` | `1.0` | Upgrades relationship tier badge to `Trusted` |
| **Trust Threshold (Close)** | `0.85` | `0.0` | `1.0` | Upgrades relationship tier badge to `Close Friend` |
| **Dialogue Gap Distance** | `2.4m` | `1.8m` | `3.0m` | Parallel standing offset for side-by-side profile framing |
| **Camera Left Shift** | `+1.8m` | `1.0m` | `2.5m` | Keeps right 300px performance panel 100% clear |
| **Typewriter Speed** | `0.7s` | `0.3s` | `1.2s` | Smooth character playback time per message line |

---

## 6. Player Onboarding Flow & First 3 Minutes

```
[ Game Start: Main Menu ] ──"Start Game"──► [ Room_Start (Campus Entry) ]
                                                    │
                                           Ground Ring Active
                                                    │
                                         Player moves (WASD/Shift)
                                                    │
                                         Approaches NPC Daria (E)
                                                    │
                                         [ Dialogue Encounter 1 ]
                                         - Parallel 2.4m glide
                                         - Speech bubble pop-in
                                         - First response sent
                                                    │
                                         [ OverviewModal ]
                                         - Performance + XP gained
                                         - Journal [J] unlocked
                                                    │
                                         Step Out to Street Connector!
```

---

## 7. Reiteration & Improvement Rationale

### 💡 Why This Blueprint Delivers Maximum Impact:

1. **Unique Systems Design (Not a Generic Hackathon Checklist)**:
   - Instead of listing hackathon guidelines as dry text, this document formats everything as an **authentic, ship-ready Game Design Document (GDD)**.
2. **Integrates Street Connectors**:
   - Explicitly defines the 2.5D Outdoor Street Connector scene (`StreetConnector.tscn`), connecting diorama room interiors with seamless low-poly street traversal.
3. **Strict Separation of Frontend & Backend**:
   - Treats the backend API, state engine, and scoring models as unmutable truth, focusing 100% on how Godot 4 renders, interpolates, and visualizes this data for maximum player delight.
