@tool
# res://scenes/rooms/Door3D.gd
extends Node3D

@export_file("*.tscn") var target_room_scene: String
@export var target_spawn_id: String = "default"

@export_group("Interaction Trigger Bounds")
@export var interaction_size: Vector3 = Vector3(2.0, 2.5, 2.0):
	set(value):
		interaction_size = value
		_update_trigger_bounds()

@export var interaction_offset: Vector3 = Vector3(0.0, 1.25, 0.0):
	set(value):
		interaction_offset = value
		_update_trigger_bounds()

@onready var prompt_label: Label3D = get_node_or_null("PromptLabel3D")

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if not Engine.is_editor_hint():
		_hide_door_visuals()
	_update_trigger_bounds()

func _update_trigger_bounds() -> void:
	var area_shape = get_node_or_null("TriggerArea/CollisionShape3D")
	if not area_shape:
		return

	area_shape.position = interaction_offset

	var box: BoxShape3D = null
	if area_shape.shape:
		if not area_shape.shape.is_local_to_scene():
			area_shape.shape = area_shape.shape.duplicate()
			area_shape.shape.resource_local_to_scene = true
		box = area_shape.shape as BoxShape3D
	else:
		box = BoxShape3D.new()
		box.resource_local_to_scene = true
		area_shape.shape = box

	if box:
		box.size = interaction_size

func _hide_door_visuals() -> void:
	if has_node("DoorMesh"):
		get_node("DoorMesh").visible = false
		if get_node("DoorMesh").has_method("set_use_collision"):
			get_node("DoorMesh").use_collision = false
	if has_node("door"):
		get_node("door").visible = false

	for child in get_children():
		if child is MeshInstance3D or child is CSGBox3D:
			child.visible = false
			if child.has_method("set_use_collision"):
				child.use_collision = false

func show_prompt(visible_state: bool) -> void:
	if prompt_label:
		prompt_label.visible = visible_state

func interact() -> void:
	if target_room_scene:
		SceneManager.change_room(target_room_scene, target_spawn_id)
