extends Node3D

func _ready() -> void:
	var player = get_node_or_null("Player3D")
	if player:
		player.is_fixed_diorama_room = false
		player.room_camera_pos = Vector3(0.0, 2.2, 4.5)
		player.room_camera_rot = Vector3(-15.0, 0.0, 0.0)

func _process(delta: float) -> void:
	var player = get_node_or_null("Player3D")
	if player and is_instance_valid(player):
		var camera_pivot = player.get_node_or_null("CameraPivot")
		if camera_pivot:
			var target_x = clamp(player.global_position.x, -38.0, 38.0)
			# Force update the camera pivot position, overriding the player's own clamp if it happens earlier
			camera_pivot.global_position.x = lerp(camera_pivot.global_position.x, target_x, 5.0 * delta)
