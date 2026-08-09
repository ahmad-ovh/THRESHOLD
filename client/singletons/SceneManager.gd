# res://singletons/SceneManager.gd
extends CanvasLayer

var color_rect: ColorRect
var target_spawn_id: String = ""

func _ready() -> void:
	layer = 100 # Keep transition color rect above all UI
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
	
	# Position Player at matching Marker3D node
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

	var target_marker: Node3D = null
	var target_id_clean = target_spawn_id.strip_edges().to_lower()

	# 1. Search nodes in group "spawn_markers"
	var spawn_markers = get_tree().get_nodes_in_group("spawn_markers")
	if target_id_clean != "":
		for marker in spawn_markers:
			if marker is Node3D:
				var m_name = marker.name.to_lower()
				var m_spawn_id = str(marker.get("spawn_id")).to_lower() if marker.get("spawn_id") else ""
				if m_name == target_id_clean or m_spawn_id == target_id_clean or m_name == "spawn_" + target_id_clean:
					target_marker = marker as Node3D
					break

	# 2. Fallback: Search all Marker3D nodes in the active scene tree
	if not target_marker and target_id_clean != "":
		var all_markers = get_tree().root.find_children("*", "Marker3D", true, false)
		for marker in all_markers:
			if marker is Node3D:
				var m_name = marker.name.to_lower()
				if m_name == target_id_clean or m_name == "spawn_" + target_id_clean:
					target_marker = marker as Node3D
					break

	# 3. Fallback to default spawn markers if specific target marker is not found
	if not target_marker:
		for marker in spawn_markers:
			if marker is Node3D:
				var m_name = marker.name.to_lower()
				if m_name == "spawn_default" or m_name == "default" or m_name == "from_street":
					target_marker = marker as Node3D
					break
		if not target_marker and spawn_markers.size() > 0:
			target_marker = spawn_markers[0] as Node3D

	# Apply Marker3D global transform directly to Player
	if target_marker:
		player.global_transform = target_marker.global_transform

	# Snap camera pivot position immediately to match player position
	var camera_pivot = player.get_node_or_null("CameraPivot")
	if camera_pivot and not player.get("is_fixed_diorama_room"):
		var target_x = clamp(player.global_position.x, -38.0, 38.0)
		camera_pivot.global_position.x = target_x


