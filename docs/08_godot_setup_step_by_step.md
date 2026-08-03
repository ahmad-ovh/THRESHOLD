# THRESHOLD — Godot 4 Step-by-Step Dummy-Proof Setup & Implementation Guide

This guide is a step-by-step, zero-guesswork tutorial for building the entire **THRESHOLD** game client in **Godot 4**. Follow these instructions in exact numerical order. Every project setting, node hierarchy, folder structure, and script is provided so you can copy, paste, and test visually at each step.

---

## Part 1: Project Creation & Godot Engine Settings

### Step 1.1: Create New Project
1. Open **Godot 4.x**.
2. Click **New Project**.
3. **Project Name**: `THRESHOLD_Client`
4. **Renderer**: Select **Compatibility** *(recommended for Web / HTML5 exports)* or **Forward+**.
5. Click **Create & Edit**.

### Step 1.2: Configure Input Map (Controls)
1. Go to **Project -> Project Settings -> Input Map**.
2. Type `interact` in the *Add New Action* box and press **Add**.
   - Click the **+** icon next to `interact`, press key **E**, and click **OK**.
3. Type `toggle_journal` in the *Add New Action* box and press **Add**.
   - Click the **+** icon next to `toggle_journal`, press key **J**, and click **OK**.
4. Click **Close**.

### Step 1.3: Configure Window & Stretch Mode
1. Go to **Project -> Project Settings -> General -> Display -> Window**.
2. **Viewport Width**: `1280`
3. **Viewport Height**: `720`
4. Scroll down to **Stretch**:
   - **Mode**: `canvas_items`
   - **Aspect**: `expand`
5. Click **Close**.

### Step 1.4: Create Folder Structure
In the **FileSystem** dock (bottom-left panel in Godot), right-click `res://` and create the following directory tree:

```
res://
├── singletons/
├── resources/
│   ├── npc_data/
│   └── mood_emojis/
├── scenes/
│   ├── main_menu/
│   ├── rooms/
│   ├── templates/
│   ├── player/
│   └── ui/
```

---

## Part 2: Step-by-Step Scene Assembly & Code Implementation

---

### STEP 1: Player Character & First Test Room (`Player3D.tscn` & `Room_Start.tscn`)

#### 1.1 Create `Player3D.tscn` Scene
1. Click **Scene -> New Scene**.
2. Select **3D Scene** (Root node: `Node3D`). Rename root node to `Player3D` and change its node type to `CharacterBody3D` (Right-click node -> *Change Type* -> `CharacterBody3D`).
3. Add child nodes to `Player3D`:
   - `MeshInstance3D` (In Inspector -> Mesh -> New CapsuleMesh).
   - `CollisionShape3D` (In Inspector -> Shape -> New CapsuleShape3D).
   - `Camera3D` (Position: `Transform -> Position -> X: 0, Y: 1.5, Z: 3`).
   - `Area3D` (Rename to `InteractionDetector`).
     - Add child `CollisionShape3D` to `InteractionDetector` (In Inspector -> Shape -> New SphereShape3D, Radius: `2.0`).
4. Save scene as `res://scenes/player/Player3D.tscn`.

#### 1.2 Attach `Player3D.gd` Script
Right-click `Player3D` root node -> **Attach Script** -> Save as `res://scenes/player/Player3D.gd`. Paste this code:

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

func _physics_process(_delta: float) -> void:
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

#### 1.3 Create `Room_Start.tscn` Scene
1. Click **Scene -> New Scene** -> **3D Scene** (Rename root node to `Room_Start`).
2. Add child nodes to `Room_Start`:
   - `CSGBox3D` (Rename to `Floor`, Size: `X: 20, Y: 0.2, Z: 20`, Position: `Y: -0.1`).
   - `DirectionalLight3D` (Rotation: `X: -45, Y: 45, Z: 0`).
   - `WorldEnvironment` (Inspector -> Environment -> New Environment -> Background Mode -> Sky).
3. Drag `res://scenes/player/Player3D.tscn` from FileSystem into the `Room_Start` node hierarchy.
4. Save scene as `res://scenes/rooms/Room_Start.tscn`.
5. **TEST IT**: Press **F6** (Run Current Scene). Walk around using WASD / Arrow keys!

---

### STEP 2: Doors & Room Transitions (`SceneManager.gd` & `Door3D.tscn`)

#### 2.1 Create `SceneManager.gd` Autoload
1. Click **File -> New -> Script**.
2. **Path**: `res://singletons/SceneManager.gd`
3. **Inherits**: `CanvasLayer`
4. Create script and paste this code:

```gdscript
# res://singletons/SceneManager.gd
extends CanvasLayer

var color_rect: ColorRect
var target_spawn_id: String = ""

func _ready() -> void:
	layer = 100 # Keep on top of UI
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

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

5. Register Autoload: Go to **Project -> Project Settings -> Autoload**.
   - Path: Select `res://singletons/SceneManager.gd`
   - Node Name: `SceneManager`
   - Click **Add** -> Click **Close**.

#### 2.2 Create `Door3D.tscn` Scene
1. Click **Scene -> New Scene** -> **3D Scene** (Rename root node to `Door3D`).
2. Add child nodes to `Door3D`:
   - `CSGBox3D` (Size: `X: 1.5, Y: 2.5, Z: 0.2`, Position: `Y: 1.25`).
   - `Area3D` (Rename to `TriggerArea`).
     - Add child `CollisionShape3D` (Shape: New BoxShape3D, Size: `X: 2, Y: 2.5, Z: 2`).
   - `Label3D` (Rename to `PromptLabel3D`, Text: `"Press [E] to Enter"`, Position: `Y: 2.8`).
3. Attach script `res://scenes/rooms/Door3D.gd` to `Door3D` root:

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
4. Save scene as `res://scenes/rooms/Door3D.tscn`.

#### 2.3 Create `Room_Office.tscn` & Test Room Transition
1. Open `Room_Start.tscn`.
2. Drag `Door3D.tscn` into `Room_Start.tscn`. Position it at `Z: -8`.
3. In Inspector for `Door3D`: Set `Target Room Scene` -> Select `res://scenes/rooms/Room_Office.tscn` (or duplicate `Room_Start.tscn` as `Room_Office.tscn` first).
4. Add a `Marker3D` node to `Room_Office.tscn`, rename it `default`, and add it to group `spawn_markers` (Node tab -> Groups -> Add `spawn_markers`).
5. **TEST IT**: Press **F6** in `Room_Start.tscn`. Walk up to the door, press 'E', and watch the smooth fade transition into `Room_Office.tscn`!

---

### STEP 3: NPC Template & Floating Billboard Mood Emoji (`NPCData.gd` & `NPC.tscn`)

#### 3.1 Create `NPCData.gd` Custom Resource Script
Create script `res://resources/npc_data/NPCData.gd`:

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

#### 3.2 Create `NPC.tscn` Scene
1. Click **Scene -> New Scene** -> **3D Scene** (Rename root node to `NPC`, change type to `CharacterBody3D`).
2. Add child nodes:
   - `CollisionShape3D` (Shape: New CapsuleShape3D).
   - `Node3D` (Rename to `MeshContainer`).
     - Add a child `CSGMesh3D` (Mesh: CapsuleMesh) inside `MeshContainer` so there is a 3D avatar placeholder.
   - `Marker3D` (Rename to `HeadMarker`, Position: `Y: 2.2`).
     - Add child `Sprite3D` to `HeadMarker` (Rename to `MoodSprite3D`, Billboard Mode: `Y-Billboard`, Pixel Size: `0.005`).
     - Add child `Label3D` to `HeadMarker` (Rename to `PromptLabel3D`, Text: `"Press [E] to talk"`, Position: `Y: 0.5`).
   - `Area3D` (Rename to `InteractionArea`).
     - Add child `CollisionShape3D` (Shape: SphereShape3D, Radius: `2.5`).
3. Attach script `res://scenes/templates/NPC.gd` to `NPC` root:

```gdscript
# res://scenes/templates/NPC.gd
extends CharacterBody3D

@export var npc_id: String = ""
@export var npc_data_registry: Dictionary = {}

@onready var mesh_container: Node3D = $MeshContainer
@onready var mood_sprite: Sprite3D = $HeadMarker/MoodSprite3D
@onready var prompt_label: Label3D = $HeadMarker/PromptLabel3D

var active_data: NPCData

func _ready() -> void:
	if npc_data_registry.has(npc_id):
		active_data = npc_data_registry[npc_id]
		_setup_visuals()
	else:
		# Fallback placeholder if data resource isn't assigned yet
		prompt_label.text = "Press [E] to talk to " + npc_id.capitalize()
		prompt_label.visible = false

func _setup_visuals() -> void:
	if active_data.mesh_scene:
		for child in mesh_container.get_children():
			child.queue_free()
		mesh_container.add_child(active_data.mesh_scene.instantiate())
		
	prompt_label.text = "Press [E] to talk to " + active_data.display_name
	prompt_label.visible = false
	set_mood_emoji(active_data.default_expression)

func set_mood_emoji(expression: String) -> void:
	if active_data and active_data.mood_emojis.has(expression):
		mood_sprite.texture = active_data.mood_emojis[expression]
		_animate_mood_popin()

func _animate_mood_popin() -> void:
	mood_sprite.scale = Vector3.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mood_sprite, "scale", Vector3.ONE * 0.8, 0.35)

func show_prompt(visible_state: bool) -> void:
	prompt_label.visible = visible_state

func interact() -> void:
	EncounterManager.start_encounter(npc_id)
```
4. Save scene as `res://scenes/templates/NPC.tscn`.

---

### STEP 4: Dialogue UI & Typewriter Presentation (`DialogueUI.tscn`)

#### 4.1 Create `DialogueUI.tscn` Scene
1. Click **Scene -> New Scene** -> **User Interface** (Root node: `Control`, change type to `CanvasLayer`).
2. Add node structure:
   - `PanelContainer` (Rename to `DialogueBox`, Anchors: Bottom Wide, Height: `220`).
     - `VBoxContainer`
       - `Label` (Rename to `SpeakerLabel`, Text: `"NPC Name"`).
       - `RichTextLabel` (Rename to `DialogueText`, Text: `"Dialogue lines..."`, Custom Minimum Height: `100`).
       - `HBoxContainer` (Rename to `InputContainer`).
         - `LineEdit` (Rename to `MessageInput`, Placeholder: `"Type your message here..."`, Expand Fill).
         - `Button` (Rename to `SendButton`, Text: `"Send"`).
3. Attach script `res://scenes/ui/DialogueUI.gd` to `CanvasLayer` root:

```gdscript
# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var speaker_label: Label = $DialogueBox/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $DialogueBox/VBoxContainer/DialogueText
@onready var message_input: LineEdit = $DialogueBox/VBoxContainer/InputContainer/MessageInput
@onready var send_button: Button = $DialogueBox/VBoxContainer/InputContainer/SendButton

signal message_submitted(text: String)

func _ready() -> void:
	visible = false
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(func(_text): _on_send_pressed())

func open_dialogue(npc_name: String, opening_line: String) -> void:
	speaker_label.text = npc_name
	visible = true
	message_input.editable = true
	send_button.disabled = false
	display_reply(opening_line)

func display_reply(text: String) -> void:
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, 1.2)
	message_input.editable = true
	send_button.disabled = false

func set_submitting_state() -> void:
	message_input.editable = false
	send_button.disabled = true

func close_dialogue() -> void:
	visible = false

func _on_send_pressed() -> void:
	var txt = message_input.text.strip_edges()
	if txt != "":
		message_input.text = ""
		set_submitting_state()
		message_submitted.emit(txt)
```
4. Save scene as `res://scenes/ui/DialogueUI.tscn`.

---

### STEP 5: Backend API Integration & Encounter State Manager (`ApiClient.gd` & `EncounterManager.gd`)

#### 5.1 Create `PlayerStore.gd` Autoload
Create `res://singletons/PlayerStore.gd`:

```gdscript
# res://singletons/PlayerStore.gd
extends Node

var player_id: String = "player_01"
var level: int = 1
var xp_progress: float = 0.0
var daily_streak: int = 0
var skill_vector: Dictionary = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}

func update_from_status(data: Dictionary) -> void:
	level = data.get("level", level)
	xp_progress = data.get("xp_progress", xp_progress)
	daily_streak = data.get("daily_streak", daily_streak)
	skill_vector = data.get("skill_vector", skill_vector)
```

#### 5.2 Create `ApiClient.gd` Autoload
Create `res://singletons/ApiClient.gd`:

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

#### 5.3 Create `EncounterManager.gd` Autoload
Create `res://singletons/EncounterManager.gd`:

```gdscript
# res://singletons/EncounterManager.gd
extends Node

enum State { LOBBY, ACTIVE, RESOLVING }

var current_state: State = State.LOBBY
var active_npc_id: String = ""
var dialogue_ui_ref: CanvasLayer = null

func start_encounter(npc_id: String) -> void:
	active_npc_id = npc_id
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		
	var res = await ApiClient.start_interaction(PlayerStore.player_id, npc_id)
	if res.has("error"):
		if player: player.set_physics_process(true)
		return
		
	current_state = State.ACTIVE
	
	# Open Dialogue UI
	if not dialogue_ui_ref:
		var ui_scene = preload("res://scenes/ui/DialogueUI.tscn")
		dialogue_ui_ref = ui_scene.instantiate()
		get_tree().root.add_child(dialogue_ui_ref)
		dialogue_ui_ref.message_submitted.connect(_on_player_message_submitted)
		
	dialogue_ui_ref.open_dialogue(res.get("npc_name", npc_id), res.get("opening_line", ""))

func _on_player_message_submitted(text: String) -> void:
	var res = await ApiClient.send_message(PlayerStore.player_id, active_npc_id, text)
	if res.has("error"):
		return
		
	dialogue_ui_ref.display_reply(res.get("npc_reply", ""))
	
	# Update mood emoji on active NPC
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.get("npc_id") == active_npc_id and npc.has_method("set_mood_emoji"):
			npc.set_mood_emoji(res.get("npc_expression", "neutral"))
			
	if res.get("encounter_over", false):
		_finalize_encounter()

func _finalize_encounter() -> void:
	current_state = State.RESOLVING
	var res = await ApiClient.end_interaction(PlayerStore.player_id, active_npc_id)
	
	# Hide dialogue & unfreeze player
	if dialogue_ui_ref:
		dialogue_ui_ref.close_dialogue()
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		
	current_state = State.LOBBY
```

5. Register Autoloads: Add `PlayerStore.gd`, `ApiClient.gd`, and `EncounterManager.gd` to **Project Settings -> Autoload**.

---

### STEP 6: Main Menu, HUD & Journal Profile Overlay

#### 6.1 Create `MainMenu.tscn`
1. Create CanvasLayer scene `res://scenes/main_menu/MainMenu.tscn`.
2. Add a `VBoxContainer` with a `LineEdit` (Username input) and a `Button` ("Start Game").
3. On "Start Game" pressed:
   - `PlayerStore.player_id = line_edit.text.strip_edges()`
   - `SceneManager.change_room("res://scenes/rooms/Room_Start.tscn")`
4. Set `MainMenu.tscn` as the Main Scene (**Project -> Project Settings -> Application -> Run -> Main Scene**).

#### 6.2 Create `HUD.tscn`
1. Create CanvasLayer scene `res://scenes/ui/HUD.tscn`.
2. Add top bar with Labels for Level, XP Progress Bar, Streak Counter, and a "Journal [J]" Button.
3. Attach code to update HUD values from `PlayerStore.gd` and toggle `JournalUI.tscn` on 'J' key or button click!

---

## Part 3: Godot Web (HTML5) Export Instructions

1. Open Godot 4.
2. Go to **Editor -> Manage Export Templates -> Download & Install**.
3. Go to **Project -> Export -> Add... -> Web**.
4. Set **Export Path**: `build/web/index.html`.
5. Click **Export Project** -> Save.
6. Open your terminal in the `build/web` folder and run:
   ```powershell
   python -m http.server 8060
   ```
7. Open `http://localhost:8060` in your web browser and play your game!
