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
