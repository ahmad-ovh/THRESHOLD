# res://scenes/rooms/Door3D.gd
extends Node3D

@export_file("*.tscn") var target_room_scene: String
@export var target_spawn_id: String = "default"

@onready var prompt_label: Label3D = $PromptLabel3D

func _ready() -> void:
	prompt_label.visible = false
	_hide_door_visuals()

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
	prompt_label.visible = visible_state

func interact() -> void:
	if target_room_scene:
		SceneManager.change_room(target_room_scene, target_spawn_id)
