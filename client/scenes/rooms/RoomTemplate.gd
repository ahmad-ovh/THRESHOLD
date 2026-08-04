# res://scenes/rooms/RoomTemplate.gd
extends Node3D

@export var is_fixed_diorama_room: bool = true
@export var camera_position: Vector3 = Vector3(0, 3.2, 7.5)
@export var camera_rotation: Vector3 = Vector3(-14.0, 0.0, 0.0)

func _ready() -> void:
	if has_node("CameraAnchor"):
		var camera_anchor = get_node("CameraAnchor") as Node3D
		camera_anchor.position = camera_position
		camera_anchor.rotation_degrees = camera_rotation
