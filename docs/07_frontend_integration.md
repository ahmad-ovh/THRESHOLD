# THRESHOLD — Frontend Integration & Game Engine Guide

This document is a comprehensive, developer-facing guide for building a game client and frontend for **THRESHOLD**. It defines how to integrate backend REST APIs with game engine systems (such as **Godot 4.x**, Unity, or Unreal Engine), mapping server responses into 3D world behavior, character animations, cinematic camera cuts, UI overlays, and game state transitions.

---

## 1. Architecture Overview & Data Flow

THRESHOLD uses a hybrid architecture: a **stateless FastAPI REST backend** handling all state evaluation, metric updates, progression, and LLM dialogue generation; and a **3D game engine client** responsible for spatial interaction, character rendering, camera control, visual effects, and UI presentation.

```
+-----------------------------------------------------------------------------------------------+
|                                      GAME CLIENT ENGINE                                       |
|                                                                                               |
|   ┌─────────────────────┐       ┌───────────────────────┐       ┌─────────────────────────┐   |
|   │ Spatial Triggers    │ ────► │ EncounterManager      │ ────► │ ApiClient (HTTP REST)   │   |
|   │ (Area3D Interaction)│       │ (State Machine)       │       │ (Async Network Calls)   │   |
|   └─────────────────────┘       └───────────┬───────────┘       └────────────┬────────────┘   |
|                                             │                                │                |
|                                             ▼                                │                |
|   ┌──────────────────────────────────────────────────────────────────┐       │                |
|   │                      3D World & UI Presenters                    │       │                |
|   │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐  │       │                |
|   │  │ CameraSystem │  │ NpcController│  │ Dialogue & Feedback UI │  │       │                |
|   │  └──────────────┘  └──────────────┘  └────────────────────────┘  │       │                |
|   └──────────────────────────────────────────────────────────────────┘       │                |
+------------------------------------------------------------------------------┼----------------+
                                                                               │ HTTP Requests
                                                                               ▼
+-----------------------------------------------------------------------------------------------+
|                                       THRESHOLD BACKEND                                       |
|   FastAPI REST API ──► State Engine ──► Relationship Service ──► OpenAI SDK (LLM Pipelines)   |
+-----------------------------------------------------------------------------------------------+
```

---

### Turn Loop Sequence (Player Action → 3D World & UI Reaction)

```
   PLAYER ACTION (3D World / UI)
         │
         ├───► 1. Player presses "Send" in Dialogue UI
         │
   GAME CLIENT ENGINE
         │
         ├───► 2. Lock UI Input (Disable text field, set is_submitting = true)
         ├───► 3. Trigger NPC "Thinking" Animation (Head tilt, subtle idle shift)
         ├───► 4. ApiClient fires POST /interaction/message async
         │
   FASTAPI BACKEND
         │
         ├───► 5. Scoring LLM evaluates turn scores & interpretation signal
         ├───► 6. Metric update formula updates effective metrics & evaluates NPC state
         ├───► 7. Character Voice LLM generates reply, expression enum, coach hint & outcome
         │
   GAME CLIENT ENGINE (Response Processing)
         │
         ├───► 8. ApiClient receives MessageResponse JSON
         ├───► 9. NpcController transitions animation tree & blendshapes to npc_expression
         ├───► 10. CameraDirector triggers cinematic shot cut based on turn_scores & npc_state
         ├───► 11. LightingController updates color grading/vignette accent
         ├───► 12. DialogueUI presents npc_reply via typewriter text effect
         ├───► 13. FeedbackUI animates score radar chart, strength/improvement cards, & hints
         ├───► 14. StatusUI updates relationship_tier and npc_state badge chips
         │
         └───► 15. IF encounter_over == true:
                     - Lock input permanently
                     - Trigger CameraDirector "Encounter Resolution Shot"
                     - Show "Complete Encounter" CTA
                   ELSE:
                     - Unlock input field for next turn
```

---

## 2. Recommended Game Client Architecture

To maintain clean separation of concerns, the game client should split responsibilities into distinct singletons (Autoloads), controllers, and presenters.

```
res://
├── singletons/
│   ├── ApiClient.gd          # Handles HTTP REST requests, DTO parsing, & network errors
│   ├── EncounterManager.gd   # Global state machine governing encounter lifecycle
│   └── PlayerStore.gd        # Stores persistent player profile (level, skill vector, XP)
├── controllers/
│   ├── NpcController.gd      # Controls 3D NPC model, animation tree, IK look-at, & blendshapes
│   ├── CameraDirector.gd     # Manages 3D cameras, shot cuts, FOV transitions, & camera shake
│   └── EnvironmentDirector.gd# Manages lighting, color grading, post-processing, & audio cues
├── ui/
│   ├── DialogueOverlay.tscn  # Speech bubbles, typewriter effect, text input box
│   ├── FeedbackPanel.tscn    # Turn score meters, radar chart, strength/improvement cards
│   ├── CoachHintBanner.tscn  # Floating hint banner
│   ├── StatusHeader.tscn     # Tier badge, mood badge, level progress bar
│   └── SettlementModal.tscn  # End-of-encounter results, Observer insight, level-up splash
└── scenes/
    ├── MainLobby.tscn        # Main menu / daily challenge selection hub
    └── EncounterScene.tscn   # 3D encounter environment with staged NPC & camera rigs
```

---

## 3. Game Subsystems Specification

### 3.1 EncounterManager (State Machine)

The `EncounterManager` is the central orchestrator of the game client. It exposes signals for scene elements to react to state changes without hard coupling.

**Client Game States (`EncounterState` Enum):**
- `LOBBY`: Navigating menus, inspecting daily challenge or player report.
- `ENCOUNTER_INITIALIZING`: Spatial interaction triggered; calling `POST /interaction/start`.
- `ENCOUNTER_ACTIVE`: Conversation loop in progress (`POST /interaction/message`).
- `ENCOUNTER_RESOLVING`: Encounter ended on backend (`encounter_over == true`); awaiting final settlement.
- `ENCOUNTER_SETTLEMENT`: Displaying results modal after `POST /interaction/end`.

**Exposed Signals:**
- `encounter_started(start_response: StartResponse)`
- `turn_submitted(message: String)`
- `turn_completed(message_response: MessageResponse)`
- `expression_changed(expression: String)`
- `scores_updated(turn_scores: Dictionary)`
- `encounter_resolution_ready(narrative_outcome: String, performance_outcome: String)`
- `encounter_ended(end_response: EndResponse)`

---

### 3.2 3D NPC Controller (`NpcController`)

The `NpcController` attaches to the 3D NPC character instance in the scene. It manages body posture, facial expressions, and head tracking.

#### Component Structure:
1. **AnimationTree (AnimationNodeStateMachine)**:
   - Base layer: Idle loops (`idle_neutral`, `idle_warm`, `idle_tense`, `idle_withdrawn`).
   - Gesture layer: One-shot upper body gestures (`nod_approving`, `shake_disappointed`, `arms_crossed`).
2. **BlendShape / Face Driver**:
   - Maps backend `npc_expression` string to facial mesh BlendShape target weights (e.g. `smile`, `brow_furrow`, `jaw_clench`, `eye_squint`).
3. **SkeletonIK3D / Head Tracker**:
   - Rotates NPC head and neck bones to track `Camera3D` or the player avatar position with smooth damping.

#### Expression Mapping Matrix:

| Backend `npc_expression` | Animation State | BlendShape Weights | Body Gesture |
|---|---|---|---|
| `neutral` | `idle_neutral` | Default | Hands at sides / relaxed stance |
| `warm` | `idle_relaxed` | `smile`: 0.6, `eye_soft`: 0.5 | Leaning slightly forward |
| `hurt` | `idle_withdrawn` | `brow_inner_up`: 0.7, `lip_tight`: 0.5 | Head tilted down, averted eyes |
| `guarded` | `idle_tense` | `brow_down`: 0.4, `eye_squint`: 0.3 | Arms crossed, stiff torso |
| `irritated` | `idle_tense` | `brow_down`: 0.8, `jaw_clench`: 0.7 | Sharp head turn, erect posture |
| `concerned` | `idle_attentive` | `brow_inner_up`: 0.8, `mouth_open`: 0.2 | Hand near chin / chest gesture |
| `disappointed` | `idle_withdrawn` | `mouth_sad`: 0.6, `brow_down`: 0.5 | Slow head shake, sigh gesture |
| `approving` | `idle_relaxed` | `smile`: 0.8, `eye_soft`: 0.7 | Firm single nod |
| `dismissive` | `idle_distant` | `eye_squint`: 0.5, `head_turn_away`: 0.6 | Wave off gesture / shoulder shrug |
| `satisfied` | `idle_relaxed` | `smile`: 0.9, `brow_relaxed`: 1.0 | Relaxed shoulders, open hands |
| `frustrated` | `idle_tense` | `brow_down`: 0.9, `lip_press`: 0.8 | Pinching bridge of nose gesture |
| `hostile` | `idle_aggressive` | `brow_down`: 1.0, `eye_wide`: 0.6, `jaw_clench`: 0.9 | Stepping forward, rigid arms |
| `defensive` | `idle_tense` | `brow_inner_up`: 0.5, `eye_wide`: 0.4 | Leaning back, palms outward |
| `withdrawn` | `idle_withdrawn` | `gaze_down`: 0.8, `mouth_flat`: 0.7 | Recessed posture, minimal motion |
| `collaborative` | `idle_attentive` | `smile`: 0.5, `eye_soft`: 0.8 | Open hand gestures, direct gaze |

---

### 3.3 Cinematic Camera Director (`CameraDirector`)

Rather than maintaining a static camera angle, conversations feel cinematic when the camera cuts between dynamic camera shots based on turn flow, scores, and emotional intensity.

```
       [CAM_OTS_PLAYER]                 [CAM_MEDIUM_NPC]                [CAM_CLOSEUP_NPC]
 (Over-The-Shoulder View)            (Standard Dialogue Shot)          (Intense Emotion Shot)
 ┌──────────────────────┐            ┌──────────────────────┐          ┌──────────────────────┐
 │ [Player Back]  [NPC] │            │     [NPC Bust]       │          │   [NPC Face Detail]  │
 └──────────────────────┘            └──────────────────────┘          └──────────────────────┘
```

#### Camera Shot Types:
- `CAM_OVER_SHOULDER`: Standard default camera angle framing the player's shoulder on the left, NPC on the right.
- `CAM_MEDIUM_NPC`: Medium shot focused on NPC upper body. Used during opening lines and normal exchanges.
- `CAM_CLOSEUP_NPC`: Tight close-up on NPC face. Triggered when `turn_scores.empathy < 0.3` or when `npc_expression` is `hurt`, `hostile`, or `frustrated`.
- `CAM_REACTION_WIDE`: Wide shot capturing both characters and environment. Used during high-performance turns (`turn_scores` average > 0.85) or encounter resolution.

#### Camera Cut Rules:
- On turn response: Smooth transition or hard cut to `CAM_MEDIUM_NPC`.
- On low score (`empathy` or `clarity` < 0.35): Cut to `CAM_CLOSEUP_NPC` with slight FOV narrowing (e.g. 75° → 60°) to heighten tension.
- On high score (`turn_scores` avg > 0.80): Cut to `CAM_OVER_SHOULDER` with warm depth-of-field.
- On `encounter_over == true`: Transition to `CAM_REACTION_WIDE` for closing narrative dialogue.

---

### 3.4 Environmental & Lighting Controller (`EnvironmentDirector`)

Lighting and post-processing accents amplify emotional resonance without altering backend data.

- **Color Grading**: Interpolate `WorldEnvironment` color adjustment properties based on `relationship_tier` and `npc_state`.
  - Positive states (`warm`, `satisfied`, `approving`): Shift ambient tint toward warm gold (+10% saturation).
  - Negative states (`hostile`, `hurt`, `withdrawn`): Shift ambient tint toward cool blue/grey (-15% saturation, +10% contrast).
- **Vignette Control**: Increase screen vignette opacity when `npc_state` is `hostile`, `defensive`, or `frustrated`.
- **Audio Stings**:
  - Soft chime on `coach_hint.shown == true`.
  - Minor key low pad on `encounter_over == true` with `narrative_outcome == "poor"`.
  - Major key warm chord on `encounter_over == true` with `narrative_outcome == "good"`.
  - Level-Up fan fare on `level_up` object received in `/end`.

---

## 4. Godot 4.x Reference Architecture

Below is a reference Godot 4.x project structure demonstrating how nodes, scripts, and signals connect to the backend.

### 4.1 Node Hierarchy Tree

```
EncounterScene (Node3D)
├── WorldEnvironment (WorldEnvironment)
├── DirectionalLight3D (DirectionalLight3D)
├── Environment3D (Node3D)
│   ├── RoomMesh (MeshInstance3D)
│   └── Furniture (Node3D)
├── CameraDirector (Node3D) [script: CameraDirector.gd]
│   ├── CamOverShoulder (Camera3D)
│   ├── CamMediumNpc (Camera3D)
│   └── CamCloseUpNpc (Camera3D)
├── PlayerStaging (Node3D)
│   └── PlayerMarker (Marker3D)
├── NPC_Character (CharacterBody3D) [script: NpcController.gd]
│   ├── Skeleton3D (Skeleton3D)
│   │   └── FaceMesh (MeshInstance3D)
│   ├── AnimationPlayer (AnimationPlayer)
│   ├── AnimationTree (AnimationTree)
│   └── SkeletonIK3D (SkeletonIK3D)
└── CanvasLayer (CanvasLayer)
    ├── DialogueUI (Control) [script: DialogueUI.gd]
    │   ├── ChatContainer (VBoxContainer)
    │   │   └── ScrollContainer (ScrollContainer)
    │   │       └── ChatStream (VBoxContainer)
    │   └── InputBar (HBoxContainer)
    │       ├── MessageInput (LineEdit)
    │       └── SendButton (Button)
    ├── FeedbackPanel (Control) [script: FeedbackPanel.gd]
    │   ├── TurnScoresBar (HBoxContainer)
    │   └── FeedbackCards (VBoxContainer)
    ├── StatusHeader (Control) [script: StatusHeader.gd]
    │   ├── TierBadge (Label)
    │   └── MoodBadge (Label)
    └── SettlementModal (Control) [script: SettlementModal.gd]
```

---

### 4.2 Core GDScript Implementation Examples

#### 1. `ApiClient.gd` (Autoload Singleton)

```gdscript
# res://singletons/ApiClient.gd
extends Node

signal request_failed(error_message: String)

const BASE_URL := "http://127.0.0.1:8000"

func start_interaction(player_id: String, npc_id: String) -> Dictionary:
	var payload := {"player_id": player_id, "npc_id": npc_id}
	return await _http_post("/interaction/start", payload)

func send_message(player_id: String, npc_id: String, message: String) -> Dictionary:
	var payload := {"player_id": player_id, "npc_id": npc_id, "message": message}
	return await _http_post("/interaction/message", payload)

func end_interaction(player_id: String, npc_id: String) -> Dictionary:
	var payload := {"player_id": player_id, "npc_id": npc_id}
	return await _http_post("/interaction/end", payload)

func _http_post(path: String, body: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	
	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]
	
	var err := http.request(BASE_URL + path, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		request_failed.emit("Failed to initiate HTTP request")
		http.queue_free()
		return {}
	
	var result: Array = await http.request_completed
	http.queue_free()
	
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]
	var parsed = JSON.parse_string(response_body.get_string_from_utf8())
	
	if response_code >= 400:
		var detail = parsed.get("detail", "HTTP Error %d" % response_code) if parsed else "Network Error"
		request_failed.emit(detail)
		return {"error": true, "code": response_code, "detail": detail}
		
	return parsed
```

---

#### 2. `EncounterManager.gd` (Autoload Singleton)

```gdscript
# res://singletons/EncounterManager.gd
extends Node

enum State { LOBBY, INITIALIZING, ACTIVE, RESOLVING, SETTLEMENT }

var current_state: State = State.LOBBY
var current_player_id: String = "player_01"
var current_npc_id: String = ""
var active_session_id: String = ""
var turn_count: int = 0
var is_over: bool = false

signal encounter_started(data: Dictionary)
signal turn_completed(data: Dictionary)
signal encounter_ended(data: Dictionary)
signal state_changed(new_state: State)

func start_encounter(npc_id: String) -> void:
	current_npc_id = npc_id
	_set_state(State.INITIALIZING)
	
	var res := await ApiClient.start_interaction(current_player_id, current_npc_id)
	if res.has("error"):
		_set_state(State.LOBBY)
		return
		
	active_session_id = res.get("interaction_id", "")
	turn_count = 0
	is_over = false
	
	_set_state(State.ACTIVE)
	encounter_started.emit(res)

func submit_player_message(message_text: String) -> void:
	if current_state != State.ACTIVE or is_over:
		return
		
	var res := await ApiClient.send_message(current_player_id, current_npc_id, message_text)
	if res.has("error"):
		return
		
	turn_count += 1
	is_over = res.get("encounter_over", false)
	
	turn_completed.emit(res)
	
	if is_over:
		_set_state(State.RESOLVING)

func finalize_encounter() -> void:
	var res := await ApiClient.end_interaction(current_player_id, current_npc_id)
	if res.has("error"):
		return
		
	_set_state(State.SETTLEMENT)
	encounter_ended.emit(res)

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
```

---

#### 3. `NpcController.gd` (3D NPC Component)

```gdscript
# res://controllers/NpcController.gd
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var face_mesh: MeshInstance3D = $Skeleton3D/FaceMesh
@onready var ik_lookat: SkeletonIK3D = $SkeletonIK3D

const EXPRESSION_BLENDSHAPES := {
	"neutral": {"smile": 0.0, "brow_down": 0.0, "brow_up": 0.0},
	"warm": {"smile": 0.7, "brow_down": 0.0, "brow_up": 0.2},
	"hurt": {"smile": 0.0, "brow_down": 0.0, "brow_up": 0.8},
	"guarded": {"smile": 0.0, "brow_down": 0.5, "brow_up": 0.0},
	"irritated": {"smile": 0.0, "brow_down": 0.9, "brow_up": 0.0},
	"approving": {"smile": 0.8, "brow_down": 0.0, "brow_up": 0.3},
	"hostile": {"smile": 0.0, "brow_down": 1.0, "brow_up": 0.0},
}

func _ready() -> void:
	EncounterManager.encounter_started.connect(_on_encounter_started)
	EncounterManager.turn_completed.connect(_on_turn_completed)
	if ik_lookat:
		ik_lookat.start()

func _on_encounter_started(data: Dictionary) -> void:
	var expr: String = data.get("npc_expression", "neutral")
	set_expression(expr)

func _on_turn_completed(data: Dictionary) -> void:
	var expr: String = data.get("npc_expression", "neutral")
	set_expression(expr)

func set_expression(expr_name: String) -> void:
	var blend_data: Dictionary = EXPRESSION_BLENDSHAPES.get(expr_name, EXPRESSION_BLENDSHAPES["neutral"])
	var mesh: ArrayMesh = face_mesh.mesh
	
	# Smoothly interpolate blendshapes
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	for shape_name in blend_data.keys():
		var idx := face_mesh.find_blend_shape_by_name(shape_name)
		if idx != -1:
			var target_weight: float = blend_data[shape_name]
			tween.tween_method(
				func(val: float): face_mesh.set_blend_shape_value(idx, val),
				face_mesh.get_blend_shape_value(idx),
				target_weight,
				0.4
			)
			
	# Update animation tree state machine
	var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
	if playback:
		playback.travel("state_" + expr_name)
```

---

## 5. AI Output vs. Deterministic Game Logic Boundary

Game developers must clearly distinguish between backend AI-generated dynamic outputs and local/backend deterministic logic to avoid unnecessary client overhead or corrupting game rules.

```
+---------------------------------------------------------------------------------------------------+
|                                     GAME SYSTEM BOUNDARY MAP                                      |
+------------------------------------+----------------------------------+---------------------------+
| System Feature                     | Authority / Driven By            | Deterministic vs. AI      |
+------------------------------------+----------------------------------+---------------------------+
| 3D Player Movement & Collision     | Client Game Engine               | Fully Deterministic       |
| Spatial Encounter Trigger Zones    | Client Game Engine               | Fully Deterministic       |
| Camera Cuts & FOV Transitions      | Client CameraDirector            | Fully Deterministic       |
| Dialogue UI Typewriter Effect      | Client DialogueUI                | Fully Deterministic       |
| Local Animation Blending & IK      | Client NpcController             | Fully Deterministic       |
+------------------------------------+----------------------------------+---------------------------+
| Metric Updates (Trust, Respect)    | Backend Relationship Service     | Fully Deterministic       |
| NPC Mood State Resolution          | Backend State Engine (Rules)     | Fully Deterministic       |
| Relationship Tier Resolution       | Backend Relationship Service     | Fully Deterministic       |
| Scenario Seed Selection            | Backend Scenario Service         | Deterministic (Weighted)  |
| Performance Outcome & XP Gain      | Backend Progression Service      | Fully Deterministic       |
| Observer Pattern Trigger Check     | Backend Observer Service         | Fully Deterministic       |
+------------------------------------+----------------------------------+---------------------------+
| Dialogue Text (`npc_reply`)        | Backend Character Voice LLM      | AI Generated              |
| Initial Line Personalization       | Backend Personalization LLM      | AI Generated              |
| Message Scoring & Interpretation   | Backend Memory Formation LLM     | AI Generated (Clamped)    |
| Emotional Expression Selection     | Backend LLM / State Fallback     | AI Selected (Enum)        |
| Coach Hint Line (`coach_hint`)     | Backend Character Voice LLM      | AI Generated              |
| Observer Pattern Summary Message   | Backend Observer Phrasing LLM    | AI Generated              |
| Player Communication Report        | Backend Report Generation LLM    | AI Generated              |
+------------------------------------+----------------------------------+---------------------------+
```

---

## 6. 3D Scene Design & Staging Guide

Every NPC encounter scenario in THRESHOLD belongs to an archetype (`teacher`, `friend`, `colleague`, `client`, `family`, `stranger`). 3D scene environments should be staged to reflect these narrative contexts.

```
┌─────────────────────────┬───────────────────────────────┬────────────────────────────────────────┐
│ Archetype / NPC         │ Recommended 3D Scene Setting  │ Staging & Camera Framing               │
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ teacher                 │ University Office / Classroom │ Desk separating player and NPC.        │
│ (prof_adler, ms_okoro)  │ Bookshelves, dim warm lamps   │ Camera angle looking slightly up at NPC.│
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ friend                  │ Coffee Shop / Apartment Couch │ Intimate seating, side-by-side angle.  │
│ (daria, felix, priya)   │ Soft natural window light     │ Shallow depth-of-field, warm grading.  │
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ colleague               │ Corporate Meeting Room        │ Clean modern conference table.         │
│ (nadia, tomas, seren)   │ Bright fluorescent/glass light│ Symmetrical eye-level camera framing.  │
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ client                  │ Executive Office Suite        │ Large corner office desk, city backdrop│
│ (ms_hartwell, mr_osei)  │ High contrast cool lighting   │ Formal over-the-shoulder wide angle.   │
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ family                  │ Kitchen Island / Living Room  │ Domestic setting, warm ambient lamp.   │
│ (parent, sibling)       │ Casual cozy props (coffee mugs)│ Close medium shots, high emotional proximity│
├─────────────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ stranger                │ Espresso Bar / Street Counter │ Outdoor/public urban counter.          │
│ (barista, recurring)    │ Ambient passerby movement     │ Dynamic wide-angle background framing. │
└─────────────────────────┴───────────────────────────────┴────────────────────────────────────────┘
```

---

## 7. Developer Implementation Roadmap (Build Order)

To construct the THRESHOLD game client efficiently, developers should follow this 5-phase implementation order:

```
  PHASE 1: Core REST Client & Headless Harness
  ├── Build ApiClient singleton & DTO parsers
  └── Create text-only UI harness to test /start, /message, /end API loops

  PHASE 2: Client State Machine & Dialogue UI
  ├── Implement EncounterManager state machine & signals
  └── Build DialogueUI (typewriter effect, input field, scroll container)

  PHASE 3: 3D Scene & Character Animation Rigs
  ├── Create 3D stage environments & light presets
  ├── Set up 3D NPC model with AnimationTree & SkeletonIK3D look-at
  └── Implement BlendShape face driver mapped to npc_expression enums

  PHASE 4: Cinematic Camera & Environmental Accents
  ├── Build CameraDirector with 3 shot types & dynamic score cuts
  └── Set up EnvironmentDirector color grading & audio sting controllers

  PHASE 5: Progression, Observer & Settlement Modals
  ├── Build SettlementModal for /end response (Observer reveal & XP bars)
  ├── Build Player Report Dashboard for /report
  └── Add final sound effects, UI particle polish, & input locking guards
```

---

## 8. API Endpoint Reference Specifications

*(Maintained from original specification for completeness)*

Base URL: `http://<host>:<port>` (default dev: `http://127.0.0.1:8000`)

---

### 8.1 GET /health
- **When Frontend Calls It**: App initialization / splash screen.
- **Request Inputs**: None.
- **Response Fields**: `status` (`"ok"`), `service` (`"THRESHOLD Backend"`).

### 8.2 GET /player/status
- **When Frontend Calls It**: Lobby screen & profile load.
- **Request Inputs**: `player_id` (`string`, Query Param).
- **Response Fields**: `player_id`, `level`, `skill_vector`, `xp_progress`, `daily_streak`, `created_at`.

### 8.3 POST /player/reset
- **When Frontend Calls It**: Settings "Reset Progress" button.
- **Request Inputs**: `player_id` (`string`).
- **Response Fields**: `player_id`, `reset` (`true`).

### 8.4 GET /interaction/daily
- **When Frontend Calls It**: Lobby screen featured card load.
- **Request Inputs**: `player_id` (`string`, Query Param).
- **Response Fields**: `seed_id`, `npc_id`, `focus`, `streak_count`.

### 8.5 POST /interaction/start
- **When Frontend Calls It**: Player triggers spatial interaction / selects scenario.
- **Request Inputs**: `player_id`, `npc_id`.
- **Response Fields**: `npc_name`, `npc_expression`, `opening_line`, `interaction_id`, `encounter_over`.

### 8.6 POST /interaction/message
- **When Frontend Calls It**: Player submits message turn.
- **Request Inputs**: `player_id`, `npc_id`, `message`.
- **Response Fields**: `npc_expression`, `npc_reply`, `coach_hint`, `turn_scores`, `relationship_tier`, `npc_state`, `feedback`, `encounter_over`, `narrative_outcome`, `performance_outcome`.

### 8.7 POST /interaction/end
- **When Frontend Calls It**: Player clicks "Complete Encounter" after `encounter_over == true`.
- **Request Inputs**: `player_id`, `npc_id`.
- **Response Fields**: `observer_event`, `encounter_summary`, `level_up` (optional).

### 8.8 POST /interaction/report
- **When Frontend Calls It**: Player views Communication Report screen.
- **Request Inputs**: `player_id`.
- **Response Fields**: `current_level`, `skill_vector`, `strongest_skill`, `improving_area`, `recent_pattern_summary`, `recommended_practice`.

---

## 9. Error, Latency & Loading Strategies in 3D Environments

### 9.1 Network Latency (1.5s - 3.5s per turn)
Because `/message` executes two sequential LLM pipeline calls (Memory Formation scoring and Character Voice dialogue generation), response latency ranges from **1.5 to 3.5 seconds**.

- **In-World Idle Animations**: During request wait time, `NpcController` should transition the NPC to an active "thinking" idle animation (`idle_attentive`, subtle head tilt, breathing motion) to prevent the character from feeling frozen.
- **UI Lock & Submitting State**: Input text field is disabled with a translucent overlay. A animated ellipsis typing bubble ("{NPC} is thinking...") appears in the chat stream.

### 9.2 Error Recovery
- **400 Bad Request (Session Over)**: Locks message input immediately; prompts player to click "Complete Encounter".
- **404 Not Found (Session Expired/Server Restart)**: Displays an in-game modal: *"Encounter state lost."* Returns player gracefully to the 3D lobby view.
- **500 Server Error**: Unlocks input field, restores drafted text, and displays a temporary warning toast: *"Connection timeout. Please retry."*

---

## 10. Existing Architecture Gaps & TODOs

The following items are missing or unexposed in the current backend and must be accounted for in client development:

- **TODO (Raw Metrics Exposure)**: Underlying metric float values (`trust`, `respect`, `closeness`, etc.) are processed server-side but are **not exposed** in REST responses (only `npc_state` and `relationship_tier` string labels are returned). If the game client needs numeric metric progress bars, the backend must expose `effective_metrics` in `/start` and `/message` responses.
- **TODO (Memory Journal API)**: Memory entries are stored in backend SQLite tables, but there is no GET endpoint for retrieving an NPC's full memory history list for an in-game "Memory Log / Relationship Journal" UI.
- **TODO (Daily Streak Tracking Logic)**: `daily_streak` is returned in status APIs, but automatic calendar day streak incrementation logic is not implemented on the backend.
- **TODO (Streaming LLM Token Support)**: `/interaction/message` is a blocking REST call. Adding WebSockets or Server-Sent Events (SSE) for streaming dialogue text would allow real-time typewriter playback as LLM tokens generate.
- **TODO (Client Authentication)**: `player_id` is an unauthenticated client string. Production deployment requires session authentication tokens.
