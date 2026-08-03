# res://scenes/player/Player3D.gd
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 6.5
@export var acceleration: float = 20.0
@export var friction: float = 25.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -50.0 # Degrees looking up
@export var max_pitch: float = 30.0  # Degrees looking down

@onready var camera_pivot: Node3D = $CameraPivot
@onready var character_mesh: Node3D = $CharacterMesh
@onready var interaction_detector: Area3D = $InteractionDetector

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var current_target: Node3D = null
var is_orbiting_camera: bool = false

func _ready() -> void:
	add_to_group("player")
	interaction_detector.area_entered.connect(_on_area_entered)
	interaction_detector.area_exited.connect(_on_area_exited)

func _unhandled_input(event: InputEvent) -> void:
	# Interaction trigger
	if event.is_action_pressed("interact") and current_target:
		if current_target.has_method("interact"):
			current_target.interact()
			return

	if event.is_action_pressed("toggle_journal"):
		if GameController and GameController.hud_ref:
			GameController.hud_ref._toggle_journal()
			return

	# Right-click mouse drag to orbit camera
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_orbiting_camera = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_orbiting_camera else Input.MOUSE_MODE_VISIBLE

	# Mouse look rotation
	if is_orbiting_camera and event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		var current_pitch = camera_pivot.rotation_degrees.x
		var new_pitch = clamp(current_pitch - event.relative.y * mouse_sensitivity * 50.0, min_pitch, max_pitch)
		camera_pivot.rotation_degrees.x = new_pitch

func _physics_process(delta: float) -> void:
	# Apply gravity (no jumping in this story game)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Check control state lock (pause / dialogue)
	var can_move = true
	if GameController and GameController.current_phase != GameController.Phase.EXPLORING:
		can_move = false
	if EncounterManager and EncounterManager.current_state != EncounterManager.State.LOBBY:
		can_move = false

	if can_move:
		_handle_ground_movement(delta)
	else:
		_apply_friction(delta)

	move_and_slide()

func _handle_ground_movement(delta: float) -> void:
	var raw_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if raw_input == Vector2.ZERO:
		raw_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var is_running = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	var target_speed = run_speed if is_running else walk_speed

	# Calculate direction relative to camera facing
	var camera_basis = camera_pivot.global_transform.basis
	var direction = (camera_basis * Vector3(raw_input.x, 0, raw_input.y)).normalized()
	direction.y = 0

	if direction.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)

		# Smooth character rotation to face movement direction
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
