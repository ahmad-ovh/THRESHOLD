# THRESHOLD — Godot 4 Web & Frontend Integration Guide

This document is a comprehensive, developer-facing game implementation guide for **THRESHOLD** built exclusively for **Godot 4 (Web / HTML5 & Desktop)**. It defines how to connect backend REST APIs to Godot 4 game systems: 3D modular room architecture, player auth/entry, reusable NPC templates, floating mood emoji bubbles, dialogue UI, HUD, and the profile journal.

---

## 1. Game Architecture & Godot Web Optimization

THRESHOLD uses a client-server architecture:
- **Backend**: Stateless FastAPI REST API with SQLite storage handling all state evaluation, relationship metrics, progression, and LLM dialogue generation.
- **Frontend Engine**: **Godot 4** (GDScript), compiled to HTML5/WebAssembly for browser deployment.

To ensure minimal WebAssembly bundle size, fast initial loading, and zero room-transition lag on the web:
1. **Modular Room Scenes**: Each room is a lightweight standalone `.tscn` file (e.g., `Room_Start.tscn`, `Room_Office.tscn`).
2. **Single Active Room in Memory**: Only one room scene is loaded at a time. Transitions are managed by a global `SceneManager` Autoload using `get_tree().change_scene_to_file()` accompanied by a smooth fade-to-black transition.
3. **Spawn Markers**: Each room defines `SpawnMarker3D` nodes for entry points (matching door IDs) so the player spawns at the correct spatial coordinates after loading.

```
                                  ┌────────────────────────┐
                                  │      Godot Engine      │
                                  └───────────┬────────────┘
                                              │
     ┌───────────────────┬────────────────────┼───────────────────┬──────────────────┐
     │                   │                    │                   │                  │
     ▼                   ▼                    ▼                   ▼                  ▼
┌──────────┐     ┌──────────────┐     ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Scene   │     │  ApiClient   │     │  Encounter   │    │ PlayerStore  │    │  User Interface│
│ Manager  │     │  (HTTP REST) │     │   Manager    │    │ (Profile/XP) │    │  (HUD/Journal) │
└──────────┘     └──────────────┘     └──────────────┘    └──────────────┘    └──────────────┘
```

---

## 2. Core Game Loop & User Flow

```
                               ┌──────────────────────────────┐
                               │   Main Menu (MainMenu.tscn)  │
                               │  Player enters Username/ID   │
                               │     Click "Start Game"       │
                               └──────────────┬───────────────┘
                                              │
                                   change_scene_to_file()
                                              │
                                              ▼
                               ┌──────────────────────────────┐
                               │ 3D Room Scene (Room_*.tscn)  │
                               │  Free 3D Player Movement     │
                               │  HUD Visible (Level, XP, J)  │
                               └──────┬────────────────┬──────┘
                                      │                │
             Walk to Door & Press 'E' │                │ Walk to NPC & Press 'E'
                                      ▼                ▼
                 ┌──────────────────────────┐    ┌──────────────────────────┐
                 │ SceneManager Transition  │    │ Encounter Dialogue Loop  │
                 │   Fade Black ──► Load    │    │  Freeze 3D Movement      │
                 │   Spawn at Marker3D      │    │  Camera Cuts to NPC      │
                 └──────────────────────────┘    │  POST /interaction/start │
                                                 └────────────┬─────────────┘
                                                              │
                                                Turn Loop: POST /message (×N)
                                                Mood Emoji Pop-in above Head
                                                              │
                                                encounter_over == true ──► POST /end
                                                              │
                                                              ▼
                                                 ┌──────────────────────────┐
                                                 │ Overview Settlement Modal│
                                                 │ Performance, XP, Observer│
                                                 └────────────┬─────────────┘
                                                              │
                                                   Close & Unfreeze Movement
                                                              │
                                                              ▼
                                                 Back to Free Exploration
```

---

## 3. Godot 4 Autoload Architecture (Singletons)

The client relies on four core Autoload singletons configured in `Project Settings -> Autoload`:

```
res://
├── singletons/
│   ├── ApiClient.gd          # Handles HTTP REST requests, JSON parsing, & error toasts
│   ├── SceneManager.gd       # Scene transitions, screen fades, & spawn point positioning
│   ├── PlayerStore.gd        # Stores current player_id, level, XP progress, & skill vector
│   └── EncounterManager.gd   # Governs encounter state machine & emits gameplay signals
├── resources/
│   ├── npc_data/             # Custom NPCData Resource files (.tres) per NPC template
│   └── mood_emojis/          # Texture2D emoji icons for expressions
├── scenes/
│   ├── main_menu/
│   │   └── MainMenu.tscn     # Initial login screen
│   ├── rooms/
│   │   ├── Room_Start.tscn   # Entry lobby room
│   │   └── Room_Office.tscn  # Secondary room
│   ├── templates/
│   │   └── NPC.tscn          # Reusable 3D NPC template scene
│   ├── player/
│   │   └── Player3D.tscn     # 3D Player character controller & interaction raycast
│   └── ui/
│       ├── HUD.tscn          # Always-on player status header & Journal button
│       ├── DialogueUI.tscn   # Chat stream, typewriter effect, text input box
│       ├── MoodBubble.tscn   # Billboard Sprite3D floating mood emoji
│       ├── JournalUI.tscn    # Tabbed modal: Profile, Radar Chart, & Growth Report
│       └── OverviewModal.tscn# End-of-encounter performance & Observer summary
```

---

## 4. Reusable NPC System & Visual Resource Registry

To eliminate code duplication, every NPC in the game world is an instance of a single reusable scene: `res://scenes/templates/NPC.tscn`.

### 4.1 Visual Configuration via `NPCData` Custom Resource

Instead of hardcoding character meshes in GDScript, each NPC is configured via a custom Godot `Resource` (`NPCData.gd`):

```gdscript
# res://resources/npc_data/NPCData.gd
class_name NPCData
extends Resource

@export var npc_id: String = ""
@export var display_name: String = ""
@export var mesh_scene: PackedScene
@export var default_expression: String = "neutral"
@export var mood_emojis: Dictionary = {} # Key: expression enum string -> Value: Texture2D
```

### 4.2 Reusable `NPC.tscn` Script (`NPC.gd`)

```gdscript
# res://scenes/templates/NPC.gd
extends CharacterBody3D

@export var npc_id: String = ""
@export var npc_data_registry: Dictionary = {
	"daria": preload("res://resources/npc_data/daria_data.tres"),
	"prof_adler": preload("res://resources/npc_data/prof_adler_data.tres"),
	"barista": preload("res://resources/npc_data/barista_data.tres")
}

@onready var mesh_container: Node3D = $MeshContainer
@onready var mood_sprite: Sprite3D = $HeadMarker/MoodSprite3D
@onready var interaction_area: Area3D = $InteractionArea
@onready var prompt_label: Label3D = $HeadMarker/PromptLabel3D

var active_data: NPCData

func _ready() -> void:
	if npc_data_registry.has(npc_id):
		active_data = npc_data_registry[npc_id]
		_setup_visuals()
	else:
		push_error("NPC ID '%s' not found in data registry!" % npc_id)

func _setup_visuals() -> void:
	# Instance 3D character mesh
	if active_data.mesh_scene:
		var mesh_instance = active_data.mesh_scene.instantiate()
		mesh_container.add_child(mesh_instance)
		
	# Configure interaction prompt
	prompt_label.text = "Press [E] to talk to " + active_data.display_name
	prompt_label.visible = false
	
	# Set initial mood emoji
	set_mood_emoji(active_data.default_expression)

func set_mood_emoji(expression: String) -> void:
	if active_data and active_data.mood_emojis.has(expression):
		mood_sprite.texture = active_data.mood_emojis[expression]
		_animate_mood_popin()
	else:
		mood_sprite.texture = null

func _animate_mood_popin() -> void:
	mood_sprite.scale = Vector3.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mood_sprite, "scale", Vector3.ONE * 0.8, 0.35)

func show_prompt(visible_state: bool) -> void:
	prompt_label.visible = visible_state
```

---

## 5. Floating Mood Bubble (Emoji) System

Backend REST calls return `npc_expression` in `/start` and `/message` responses. In 3D space, this expression is rendered as a floating billboard emoji above the NPC's head.

```
       ┌────────────────────────┐
       │   [ 😠 Mood Emoji ]   │  ◄── Sprite3D (Billboard Y-Axis)
       │    (Floating Icon)     │
       └───────────┬────────────┘
                   │
            [ HeadMarker3D ]
                   │
           ┌──────────────┐
           │ 3D NPC Mesh  │
           └──────────────┘
```

### Expression to Emoji Icon Mapping

| Backend `npc_expression` Enum | Recommended Emoji Icon | Visual Animation Effect |
|---|---|---|
| `neutral` | 😐 Neutral Face | Subtle scale pulse |
| `warm` | 😊 Warm Smile / Soft Hearts | Warm bounce up |
| `hurt` | 💔 Broken Heart / Hurt Face | Drop down & fade |
| `guarded` | 🛡️ Shield / Cold Face | Shake side-to-side |
| `irritated` | 💢 Anger Vein / Irritated | Sharp pop scale |
| `concerned` | 😟 Concerned Face | Gentle hover |
| `disappointed` | 😞 Disappointed Face | Slow tilt down |
| `approving` | 👍 Thumbs Up / Star | Sparkle bounce |
| `dismissive` | ✋ Hand Wave / Rolling Eyes | Flip rotation |
| `satisfied` | 😌 Satisfied Smile | Float up & glow |
| `frustrated` | 😤 Frustrated Steam | Rapid shake |
| `hostile` | 🤬 Hostile / Fire | Red pulse tint |
| `defensive` | 🖐️ Open Hand / Caution | Push back scale |
| `withdrawn` | 😶 Blank / Recessed | Shrink opacity |
| `collaborative` | 🤝 Handshake / Sparkle | Dual bounce |

---

## 6. Detailed API Specification & Godot Gameplay Mapping

Base URL: `http://<host>:<port>` (default dev: `http://127.0.0.1:8000`)

---

### 6.1 GET /health
- **When Called**: During `MainMenu.tscn` `_ready()` to check backend connection status.
- **Request**: None.
- **Response**: `{"status": "ok", "service": "THRESHOLD Backend"}`
- **Godot Mapping**: Enables/disables the "Start Game" button and shows connection status text.

---

### 6.2 GET /player/status
- **When Called**: Main menu login & after encounter resolution.
- **Query Params**: `player_id=string`
- **Response**:
  ```json
  {
    "player_id": "player_01",
    "level": 1,
    "skill_vector": {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5},
    "xp_progress": 0.308,
    "daily_streak": 2,
    "created_at": "2026-08-02T19:22:32.821583"
  }
  ```
- **Godot Mapping**:
  - Updates `PlayerStore.gd` Autoload data.
  - Updates `HUD.tscn` top bar: Level badge, XP bar fill (`xp_progress * 100%`), Daily streak flame icon.

---

### 6.3 POST /player/reset
- **When Called**: Settings menu "Reset Profile" button.
- **JSON Body**: `{"player_id": "player_01"}`
- **Response**: `{"player_id": "player_01", "reset": true}`
- **Godot Mapping**: Resets `PlayerStore.gd`, clears cached data, reloads `MainMenu.tscn`.

---

### 6.4 GET /interaction/daily
- **When Called**: Main menu load to display the Daily Featured Challenge card.
- **Query Params**: `player_id=string`
- **Response**: `{"seed_id": "asking_for_extension", "npc_id": "mr_teo", "focus": "Clarity + Politeness", "streak_count": 2}`
- **Godot Mapping**: Pre-populates the "Daily Challenge" card on `MainMenu.tscn` with NPC name and focus tags.

---

### 6.5 POST /interaction/start
- **When Called**: Player approaches NPC in 3D world and presses 'E'.
- **JSON Body**: `{"player_id": "player_01", "npc_id": "daria"}`
- **Response**:
  ```json
  {
    "npc_name": "Daria",
    "npc_expression": "neutral",
    "opening_line": "Hey, so we've never really talked, right? How's your week going?",
    "interaction_id": "first_meeting_small_talk",
    "encounter_over": false
  }
  ```
- **Godot Mapping**:
  1. Freezes player 3D movement (`player.set_physics_process(false)`).
  2. Swivels 3D camera to frame the NPC.
  3. Opens `DialogueUI.tscn` overlay.
  4. Calls `set_mood_emoji("neutral")` on target NPC to pop up the billboard icon.
  5. Plays typewriter effect for `opening_line`.

---

### 6.6 POST /interaction/message
- **When Called**: Player types text into `DialogueUI.tscn` input box and presses Enter / Send.
- **JSON Body**: `{"player_id": "player_01", "npc_id": "daria", "message": "I've been super busy with work, sorry."}`
- **Response**:
  ```json
  {
    "npc_expression": "neutral",
    "npc_reply": "No worries, work's been eating me alive too. What do you do?",
    "coach_hint": {"shown": true, "line": "Daria acknowledged your excuse and is shifting topics."},
    "turn_scores": {"clarity": 0.90, "empathy": 0.30, "politeness": 0.70, "expression": 0.40},
    "relationship_tier": "Comfortable",
    "npc_state": "neutral",
    "feedback": {
      "strength": "You communicated your point clearly.",
      "improvement": "You responded to the words, but not the feeling behind them."
    },
    "encounter_over": false,
    "narrative_outcome": null,
    "performance_outcome": "neutral"
  }
  ```
- **Godot Mapping**:
  1. Appends player message to `DialogueUI.tscn` stream.
  2. Updates NPC mood emoji (`set_mood_emoji(npc_expression)`).
  3. Plays typewriter effect for `npc_reply`.
  4. Updates turn score bars & strength/improvement cards on `FeedbackPanel.tscn`.
  5. If `coach_hint.shown == true`, animates floating coach hint banner into view.
  6. Updates status pills (`relationship_tier`, `npc_state`) in `StatusHeader.tscn`.
  7. If `encounter_over == true`, locks text input and shows "Complete Encounter" CTA.

---

### 6.7 POST /interaction/end
- **When Called**: Player clicks "Complete Encounter" after `encounter_over == true` (or exits early).
- **JSON Body**: `{"player_id": "player_01", "npc_id": "daria"}`
- **Response**:
  ```json
  {
    "observer_event": {
      "fired": true,
      "npc_id": "daria",
      "message": "Across these exchanges, a pattern of deflecting emotional acknowledgment recurred..."
    },
    "encounter_summary": {
      "narrative_outcome": "neutral",
      "performance_outcome": "good"
    },
    "level_up": {
      "new_level": 2
    }
  }
  ```
- **Godot Mapping**:
  1. Opens `OverviewModal.tscn`.
  2. Renders performance outcome badge (`GOOD`, `NEUTRAL`, `POOR`) and XP gained.
  3. If `observer_event.fired == true`, displays special "Observer Insight" card with `message`.
  4. If `level_up` is present, triggers Level-Up splash particle animation.
  5. On modal close: hides `DialogueUI.tscn`, unfreezes 3D player movement (`player.set_physics_process(true)`), restores 3D follow camera. Player is free to continue exploring.

---

### 6.8 POST /interaction/report
- **When Called**: Player opens the Journal / Profile Book (`J` key or HUD button) and clicks the "Communication Growth Report" tab.
- **JSON Body**: `{"player_id": "player_01"}`
- **Response**:
  ```json
  {
    "current_level": 2,
    "skill_vector": {"clarity": 0.55, "empathy": 0.48, "politeness": 0.52, "expression": 0.49},
    "strongest_skill": "clarity",
    "improving_area": "emotional_acknowledgment",
    "recent_pattern_summary": "Your conversations are clear and direct, but you often miss emotional cues.",
    "recommended_practice": "Try a friendship scenario and focus on validating feelings."
  }
  ```
- **Godot Mapping**:
  - Renders tabbed `JournalUI.tscn` modal displaying skill vector progress meters, AI pattern summary card, and recommended practice button.

---

## 7. Complete GDScript Script Implementations

### 7.1 `SceneManager.gd` (Autoload Singleton)

```gdscript
# res://singletons/SceneManager.gd
extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var target_spawn_id: String = ""

func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_room(scene_path: String, spawn_id: String = "default") -> void:
	target_spawn_id = spawn_id
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to Black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.4)
	await tween.finished
	
	# Change Scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Position Player at SpawnMarker3D
	_position_player()
	
	# Fade from Black
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.4)
	await fade_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _position_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var spawn_markers = get_tree().get_nodes_in_group("spawn_markers")
	for marker in spawn_markers:
		if marker.name == target_spawn_id or marker.get("spawn_id") == target_spawn_id:
			player.global_transform = marker.global_transform
			return
```

---

### 7.2 `ApiClient.gd` (Autoload Singleton)

```gdscript
# res://singletons/ApiClient.gd
extends Node

signal request_failed(detail: String)

const BASE_URL := "http://127.0.0.1:8000"

func get_player_status(player_id: String) -> Dictionary:
	return await _http_get("/player/status?player_id=" + player_id.uri_encode())

func start_interaction(player_id: String, npc_id: String) -> Dictionary:
	return await _http_post("/interaction/start", {"player_id": player_id, "npc_id": npc_id})

func send_message(player_id: String, npc_id: String, message: String) -> Dictionary:
	return await _http_post("/interaction/message", {"player_id": player_id, "npc_id": npc_id, "message": message})

func end_interaction(player_id: String, npc_id: String) -> Dictionary:
	return await _http_post("/interaction/end", {"player_id": player_id, "npc_id": npc_id})

func get_report(player_id: String) -> Dictionary:
	return await _http_post("/interaction/report", {"player_id": player_id})

func _http_get(path: String) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	var err = http.request(BASE_URL + path)
	if err != OK:
		http.queue_free()
		return {"error": true}
	var res = await http.request_completed
	http.queue_free()
	return JSON.parse_string(res[3].get_string_from_utf8())

func _http_post(path: String, body: Dictionary) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	var json_str = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = http.request(BASE_URL + path, headers, HTTPClient.METHOD_POST, json_str)
	if err != OK:
		http.queue_free()
		return {"error": true}
	var res = await http.request_completed
	http.queue_free()
	
	var code: int = res[1]
	var parsed = JSON.parse_string(res[3].get_string_from_utf8())
	if code >= 400:
		var detail = parsed.get("detail", "HTTP Error %d" % code) if parsed else "Error"
		request_failed.emit(detail)
		return {"error": true, "code": code, "detail": detail}
	return parsed
```

---

### 7.3 `Player3D.gd` (3D Player Character)

```gdscript
# res://scenes/player/Player3D.gd
extends CharacterBody3D

const SPEED = 4.5

@onready var interaction_detector: Area3D = $InteractionDetector

var current_target: Node3D = null

func _ready() -> void:
	add_to_group("player")
	interaction_detector.area_entered.connect(_on_area_entered)
	interaction_detector.area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target:
		if current_target.has_method("interact"):
			current_target.interact()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent.has_method("show_prompt"):
		current_target = parent
		parent.show_prompt(true)

func _on_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent == current_target:
		if parent.has_method("show_prompt"):
			parent.show_prompt(false)
		current_target = null
```

---

### 7.4 `Door3D.gd` (Door Interaction Node)

```gdscript
# res://scenes/rooms/Door3D.gd
extends Node3D

@export_file("*.tscn") var target_room_scene: String
@export var target_spawn_id: String = "default"

@onready var prompt_label: Label3D = $PromptLabel3D

func _ready() -> void:
	prompt_label.visible = false

func show_prompt(visible_state: bool) -> void:
	prompt_label.visible = visible_state

func interact() -> void:
	if target_room_scene:
		SceneManager.change_room(target_room_scene, target_spawn_id)
```

---

## 8. Development Build Order & Roadmap

Follow this 5-phase build sequence to construct the Godot 4 web client:

```
  PHASE 1: Player Auth & Singletons
  ├── Build MainMenu.tscn (Username line edit -> PlayerStore.player_id)
  └── Implement ApiClient.gd & SceneManager.gd Autoloads

  PHASE 2: Modular Rooms & Player Controller
  ├── Create Player3D.tscn (movement + Area3D interaction raycast)
  ├── Create Door3D.gd & Room_Start.tscn / Room_Office.tscn
  └── Test room transitions via E key using SceneManager.change_room()

  PHASE 3: NPC Template & Floating Mood Emoji
  ├── Build NPCData custom resource registry & NPC.tscn template
  └── Implement HeadMarker/MoodSprite3D billboard emoji pop-in tweens

  PHASE 4: Dialogue UI & Turn Loop
  ├── Build DialogueUI.tscn (typewriter effect, input box, turn scores)
  └── Wire EncounterManager.gd to handle POST /start, /message, & /end

  PHASE 5: HUD, Journal Book & Overview Settlement
  ├── Build HUD.tscn (Level, XP progress bar, Daily streak, Journal button)
  ├── Build JournalUI.tscn tabbed profile modal (Skill vector & /report)
  └── Build OverviewModal.tscn for end-of-encounter results & Observer reveal
```

---

## 9. Existing Architecture Gaps & TODOs

The following features or metrics are required for complete frontend rendering but are currently missing or unexposed in the existing backend architecture:

- **TODO (Raw Metrics Exposure)**: Individual underlying metric float values (`trust`, `respect`, `closeness`, etc.) are processed server-side but are **not exposed** in REST responses (only `npc_state` and `relationship_tier` string labels are returned). If the game client needs numeric metric progress bars, the backend must expose `effective_metrics` in `/start` and `/message` responses.
- **TODO (Memory Journal API)**: Memory entries are stored in backend SQLite tables, but there is no GET endpoint for retrieving an NPC's full memory history list for an in-game "Memory Log / Relationship Journal" UI.
- **TODO (Daily Streak Tracking Logic)**: `daily_streak` is returned in status APIs, but automatic calendar day streak incrementation logic is not implemented on the backend.
- **TODO (Streaming LLM Token Support)**: `/interaction/message` is a blocking REST call. Adding WebSockets or Server-Sent Events (SSE) for streaming dialogue text would allow real-time typewriter playback as LLM tokens generate.
- **TODO (Client Authentication)**: `player_id` is an unauthenticated client string. Production deployment requires session authentication tokens.
