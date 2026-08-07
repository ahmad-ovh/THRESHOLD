# res://scenes/player/Player3D.gd
extends CharacterBody3D

@export_group("Movement Parameters")
@export var walk_speed: float = 4.0
@export var run_speed: float = 6.5
@export var acceleration: float = 20.0
@export var friction: float = 25.0
@export var run_speed_threshold: float = 4.5
@export var mesh_turn_speed: float = 12.0

@export_group("Camera Parameters")
@export var camera_follow_speed: float = 5.0
@export var is_fixed_diorama_room: bool = true
@export var room_camera_pos: Vector3 = Vector3(0.0, 3.2, 4)
@export var room_camera_rot: Vector3 = Vector3(-14.0, 0.0, 0.0)
@export var spring_arm_length: float = 0.0
@export var corridor_min_x: float = -12.0
@export var corridor_max_x: float = 12.0
@export var dialogue_camera_offset: Vector3 = Vector3(1.8, 2.4, 4.2)

@export_group("Procedural Fallback Animation")
@export var leg_swing_deg: float = 28.0
@export var arm_swing_deg: float = 22.0
@export var body_base_y: float = 0.76
@export var body_bob_amount: float = 0.035
@export var breathing_amplitude: float = 0.015
@export var head_tilt_deg: float = 1.5

@export_group("Development Mode")
@export var is_development_mode: bool = true

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var character_mesh: Node3D = $CharacterMesh
@onready var interaction_detector: Area3D = $InteractionDetector

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var current_target: Node3D = null

var anim_left_leg: Node3D
var anim_right_leg: Node3D
var anim_left_arm: Node3D
var anim_right_arm: Node3D
var anim_body: Node3D
var anim_head: Node3D
var walk_anim_time: float = 0.0
var camera_dev_layer: CanvasLayer = null

func _ready() -> void:
	add_to_group("player")
	interaction_detector.area_entered.connect(_on_area_entered)
	interaction_detector.area_exited.connect(_on_area_exited)
	_setup_dollhouse_camera()
	_setup_player_mesh()
	_ensure_dev_camera_input_action()
	
	if GameController:
		GameController.is_development_mode_changed.connect(func(enabled: bool):
			_update_dev_mode(enabled)
		)
		_update_dev_mode(GameController.is_development_mode)
	else:
		_update_dev_mode(is_development_mode)

func _ensure_dev_camera_input_action() -> void:
	if not InputMap.has_action("toggle_dev_camera"):
		InputMap.add_action("toggle_dev_camera")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_F1
		InputMap.action_add_event("toggle_dev_camera", ev)

func _update_dev_mode(enabled: bool) -> void:
	is_development_mode = enabled
	if enabled:
		if not camera_dev_layer:
			_setup_camera_dev_widget()
		else:
			camera_dev_layer.visible = true
			var panel = camera_dev_layer.find_child("CameraDevPanel", true, false)
			if panel:
				panel.visible = true
	elif camera_dev_layer:
		camera_dev_layer.visible = false

func _setup_camera_dev_widget() -> void:
	if camera_dev_layer:
		return

	camera_dev_layer = CanvasLayer.new()
	camera_dev_layer.name = "CameraDevWidgetLayer"
	camera_dev_layer.layer = 100
	add_child(camera_dev_layer)

	var panel = PanelContainer.new()
	panel.name = "CameraDevPanel"
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(320, 380)
	panel.visible = true

	var toggle_btn = Button.new()
	toggle_btn.name = "DevWidgetToggleButton"
	toggle_btn.text = "🎥 Cam Dev (F1)"
	toggle_btn.position = Vector2(20, 20)
	toggle_btn.custom_minimum_size = Vector2(120, 32)
	camera_dev_layer.add_child(toggle_btn)

	toggle_btn.pressed.connect(func():
		panel.visible = not panel.visible
	)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_right", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var header = Label.new()
	header.text = "🎥 Runtime Camera Controller (F1)"
	header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(header)

	var status_label = Label.new()
	status_label.text = "Press F1 or Click Button"
	status_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(status_label)

	var create_row = func(label_text: String, min_v: float, max_v: float, step_v: float, init_val: float, callback: Callable) -> HBoxContainer:
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(75, 0)
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)

		var slider = HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = min_v
		slider.max_value = max_v
		slider.step = step_v
		slider.value = init_val
		row.add_child(slider)

		var spin = SpinBox.new()
		spin.custom_minimum_size = Vector2(65, 0)
		spin.min_value = min_v
		spin.max_value = max_v
		spin.step = step_v
		spin.value = init_val
		row.add_child(spin)

		slider.value_changed.connect(func(v):
			spin.set_value_no_signal(v)
			callback.call(v)
		)
		spin.value_changed.connect(func(v):
			slider.set_value_no_signal(v)
			callback.call(v)
		)
		return row

	vbox.add_child(create_row.call("Cam Pos X:", -20.0, 20.0, 0.1, room_camera_pos.x, func(v):
		room_camera_pos.x = v
		if camera_pivot and is_fixed_diorama_room: camera_pivot.global_position.x = v
	))
	vbox.add_child(create_row.call("Cam Pos Y:", -10.0, 20.0, 0.1, room_camera_pos.y, func(v):
		room_camera_pos.y = v
		if camera_pivot: camera_pivot.global_position.y = v
	))
	vbox.add_child(create_row.call("Cam Pos Z:", -20.0, 30.0, 0.1, room_camera_pos.z, func(v):
		room_camera_pos.z = v
		if camera_pivot: camera_pivot.global_position.z = v
	))

	vbox.add_child(create_row.call("Rot Pitch:", -90.0, 90.0, 0.5, room_camera_rot.x, func(v):
		room_camera_rot.x = v
		if camera_pivot: camera_pivot.rotation_degrees.x = v
	))
	vbox.add_child(create_row.call("Rot Yaw:", -180.0, 180.0, 0.5, room_camera_rot.y, func(v):
		room_camera_rot.y = v
		if camera_pivot: camera_pivot.rotation_degrees.y = v
	))
	vbox.add_child(create_row.call("Rot Roll:", -180.0, 180.0, 0.5, room_camera_rot.z, func(v):
		room_camera_rot.z = v
		if camera_pivot: camera_pivot.rotation_degrees.z = v
	))

	vbox.add_child(create_row.call("SpringArm:", 0.0, 20.0, 0.1, spring_arm_length, func(v):
		spring_arm_length = v
		if spring_arm: spring_arm.spring_length = v
	))

	var copy_btn = Button.new()
	copy_btn.text = "📋 COPY CAMERA JSON"
	vbox.add_child(copy_btn)

	copy_btn.pressed.connect(func():
		var dict = {
			"room_camera_pos": [snapped(room_camera_pos.x, 0.01), snapped(room_camera_pos.y, 0.01), snapped(room_camera_pos.z, 0.01)],
			"room_camera_rot": [snapped(room_camera_rot.x, 0.1), snapped(room_camera_rot.y, 0.1), snapped(room_camera_rot.z, 0.1)],
			"spring_arm_length": snapped(spring_arm_length, 0.01),
			"camera_follow_speed": snapped(camera_follow_speed, 0.1)
		}
		var json_str = JSON.stringify(dict, "  ")
		DisplayServer.clipboard_set(json_str)
		print("CAMERA_JSON_EXPORT:\n", json_str)
		status_label.text = "✓ Copied JSON to Clipboard!"
	)

	camera_dev_layer.add_child(panel)

func _setup_player_mesh() -> void:
	if character_mesh:
		for child in character_mesh.get_children():
			child.queue_free()
		var player_model = CharacterFactory.create_character_mesh("player")
		character_mesh.add_child(player_model)
		anim_left_leg = player_model.find_child("LeftLegPivot", true, false)
		anim_right_leg = player_model.find_child("RightLegPivot", true, false)
		anim_left_arm = player_model.find_child("LeftArmPivot", true, false)
		anim_right_arm = player_model.find_child("RightArmPivot", true, false)
		anim_body = player_model.find_child("BodyPivot", true, false)
		anim_head = player_model.find_child("HeadPivot", true, false)

func _setup_dollhouse_camera() -> void:
	if spring_arm:
		spring_arm.spring_length = spring_arm_length
	camera_pivot.global_position = room_camera_pos
	camera_pivot.rotation_degrees = room_camera_rot

func _input(event: InputEvent) -> void:
	if is_development_mode:
		if event.is_action_pressed("toggle_dev_camera") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_F1 or event.physical_keycode == KEY_F1)):
			if camera_dev_layer:
				var panel = camera_dev_layer.find_child("CameraDevPanel", true, false)
				if panel:
					panel.visible = not panel.visible
				else:
					camera_dev_layer.visible = not camera_dev_layer.visible
				get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target:
		if current_target.has_method("interact"):
			current_target.interact()
			return

	if event.is_action_pressed("toggle_id_card"):
		if GameController and GameController.hud_ref:
			GameController.hud_ref._toggle_id_card()
			return

	if event.is_action_pressed("toggle_journal"):
		if GameController and GameController.hud_ref:
			GameController.hud_ref._toggle_journal()
			return

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var can_move = true
	if GameController and GameController.current_phase != GameController.Phase.EXPLORING:
		can_move = false
	if EncounterManager and EncounterManager.current_state != EncounterManager.State.LOBBY:
		can_move = false

	_update_dollhouse_camera(delta, can_move)

	if can_move:
		_handle_ground_movement(delta)
	else:
		_apply_friction(delta)

	_update_procedural_animations(delta, can_move)
	move_and_slide()

func _update_procedural_animations(delta: float, can_move: bool) -> void:
	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var speed = horiz_vel.length()

	var anim_player: AnimationPlayer = null
	if character_mesh:
		anim_player = character_mesh.find_child("AnimationPlayer", true, false) as AnimationPlayer

	if anim_player:
		if can_move and speed > 0.1:
			var target_anim = "run" if speed > run_speed_threshold else "walk"
			if anim_player.current_animation != target_anim:
				anim_player.play(target_anim)
		else:
			if anim_player.current_animation != "idle":
				anim_player.play("idle")
		return

	if can_move and speed > 0.1:
		walk_anim_time += delta * speed * 3.2
		var stride = sin(walk_anim_time)
		var arm_stride = cos(walk_anim_time)

		if anim_left_leg:
			anim_left_leg.rotation.x = stride * deg_to_rad(leg_swing_deg)
		if anim_right_leg:
			anim_right_leg.rotation.x = -stride * deg_to_rad(leg_swing_deg)

		if anim_left_arm:
			anim_left_arm.rotation.x = -arm_stride * deg_to_rad(arm_swing_deg)
		if anim_right_arm:
			anim_right_arm.rotation.x = arm_stride * deg_to_rad(arm_swing_deg)

		if anim_body:
			anim_body.position.y = body_base_y + abs(sin(walk_anim_time * 2.0)) * body_bob_amount
	else:
		walk_anim_time += delta * 2.5
		var breath = sin(walk_anim_time) * breathing_amplitude

		if anim_left_leg:
			anim_left_leg.rotation.x = lerp_angle(anim_left_leg.rotation.x, 0.0, 10.0 * delta)
		if anim_right_leg:
			anim_right_leg.rotation.x = lerp_angle(anim_right_leg.rotation.x, 0.0, 10.0 * delta)
		if anim_left_arm:
			anim_left_arm.rotation.x = lerp_angle(anim_left_arm.rotation.x, 0.0, 10.0 * delta)
		if anim_right_arm:
			anim_right_arm.rotation.x = lerp_angle(anim_right_arm.rotation.x, 0.0, 10.0 * delta)

		if anim_body:
			anim_body.position.y = lerp(anim_body.position.y, body_base_y + breath, 8.0 * delta)
		if anim_head:
			anim_head.rotation.z = lerp_angle(anim_head.rotation.z, sin(walk_anim_time * 0.5) * deg_to_rad(head_tilt_deg), 5.0 * delta)

func _update_dollhouse_camera(delta: float, can_move: bool) -> void:
	if not camera_pivot:
		return

	if can_move:
		if is_fixed_diorama_room:
			# Stationary Diorama Camera framing full room box
			camera_pivot.global_position = camera_pivot.global_position.lerp(room_camera_pos, camera_follow_speed * delta)
			camera_pivot.rotation_degrees = camera_pivot.rotation_degrees.lerp(room_camera_rot, camera_follow_speed * delta)
		else:
			# Large corridor follow player mode
			var target_x = clamp(global_position.x, corridor_min_x, corridor_max_x)
			var target_pos = Vector3(target_x, room_camera_pos.y, room_camera_pos.z)
			camera_pivot.global_position = camera_pivot.global_position.lerp(target_pos, camera_follow_speed * delta)
			camera_pivot.rotation_degrees = camera_pivot.rotation_degrees.lerp(room_camera_rot, camera_follow_speed * delta)
	else:
		# Dialogue mode: Smooth left-framed camera zoom on characters
		var npcs = get_tree().get_nodes_in_group("npcs")
		if npcs.size() > 0:
			var target_npc = npcs[0]
			var mid_point = (global_position + target_npc.global_position) / 2.0
			var target_pos = Vector3(mid_point.x + dialogue_camera_offset.x, dialogue_camera_offset.y, mid_point.z + dialogue_camera_offset.z)
			camera_pivot.global_position = camera_pivot.global_position.lerp(target_pos, camera_follow_speed * delta)

func _handle_ground_movement(delta: float) -> void:
	var raw_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if raw_input == Vector2.ZERO:
		raw_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var is_running = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	var target_speed = run_speed if is_running else walk_speed

	var direction = Vector3(raw_input.x, 0, raw_input.y).normalized()

	if direction.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)

		var target_angle = atan2(direction.x, direction.z)
		character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, target_angle, mesh_turn_speed * delta)
	else:
		_apply_friction(delta)

func _apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

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
