# res://singletons/SceneManager.gd
extends CanvasLayer

var color_rect: ColorRect
var target_spawn_id: String = ""
var saved_positions: Dictionary = {}

func _ready() -> void:
	layer = 100 # Keep transition color rect above all UI
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func change_room(scene_path: String, spawn_id: String = "default") -> void:
	# Save current player position in current scene before transitioning
	var current_scene = get_tree().current_scene
	if current_scene:
		var current_path = current_scene.scene_file_path if current_scene.scene_file_path != "" else (current_scene.get("filename") if "filename" in current_scene else "")
		if current_path != "":
			var current_player = get_tree().get_first_node_in_group("player")
			if current_player and is_instance_valid(current_player):
				saved_positions[current_path] = current_player.global_transform

	target_spawn_id = spawn_id
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to Black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.4)
	await tween.finished
	
	# Change Scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Position Player
	_position_player(scene_path)
	
	# Fade from Black
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.4)
	await fade_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _position_player(scene_path: String = "") -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# If we have a saved position for this room scene, restore exact location & orientation
	if scene_path != "" and saved_positions.has(scene_path):
		player.global_transform = saved_positions[scene_path]
	else:
		var spawn_markers = get_tree().get_nodes_in_group("spawn_markers")
		for marker in spawn_markers:
			if marker.name == target_spawn_id or marker.get("spawn_id") == target_spawn_id:
				player.global_transform = marker.global_transform
				break

	# Adjust camera pivot position immediately to match player position
	var camera_pivot = player.get_node_or_null("CameraPivot")
	if camera_pivot and not player.get("is_fixed_diorama_room"):
		var target_x = clamp(player.global_position.x, -38.0, 38.0)
		camera_pivot.global_position.x = target_x

func clear_saved_positions() -> void:
	saved_positions.clear()

