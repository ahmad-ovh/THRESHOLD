# res://scenes/player/Player3D.gd
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 6.5
@export var acceleration: float = 20.0
@export var friction: float = 25.0

# Dollhouse Side Camera Parameters
@export var camera_follow_speed: float = 5.0
@export var is_fixed_diorama_room: bool = true
@export var room_camera_pos: Vector3 = Vector3(0.0, 3.2, 7.5)
@export var room_camera_rot: Vector3 = Vector3(-14.0, 0.0, 0.0)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var character_mesh: Node3D = $CharacterMesh
@onready var interaction_detector: Area3D = $InteractionDetector

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var current_target: Node3D = null
var default_spring_length: float = 0.0
var dialogue_spring_length: float = 0.0

func _ready() -> void:
	add_to_group("player")
	interaction_detector.area_entered.connect(_on_area_entered)
	interaction_detector.area_exited.connect(_on_area_exited)
	_setup_dollhouse_camera()
	_setup_player_mesh()

func _setup_player_mesh() -> void:
	if character_mesh:
		for child in character_mesh.get_children():
			child.queue_free()
		var player_model = CharacterFactory.create_character_mesh("player")
		character_mesh.add_child(player_model)

func _setup_dollhouse_camera() -> void:
	if spring_arm:
		spring_arm.spring_length = 0.0
	camera_pivot.global_position = room_camera_pos
	camera_pivot.rotation_degrees = room_camera_rot

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target:
		if current_target.has_method("interact"):
			current_target.interact()
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

	move_and_slide()

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
			var target_x = clamp(global_position.x, -12.0, 12.0)
			camera_pivot.global_position.x = lerp(camera_pivot.global_position.x, target_x, camera_follow_speed * delta)
	else:
		# Dialogue mode: Smooth left-framed camera zoom on characters (+1.8m X offset)
		var npcs = get_tree().get_nodes_in_group("npcs")
		if npcs.size() > 0:
			var target_npc = npcs[0]
			var mid_point = (global_position + target_npc.global_position) / 2.0
			var target_pos = Vector3(mid_point.x + 1.8, 2.4, mid_point.z + 4.2)
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

		var target_angle = atan2(-direction.x, -direction.z)
		character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, target_angle, 12.0 * delta)
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
