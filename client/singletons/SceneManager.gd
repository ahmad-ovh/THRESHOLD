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

	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var target_id_clean = target_spawn_id.strip_edges().to_lower().replace("_", "").replace(" ", "")
	var target_marker: Node3D = null

	# Collect all Marker3D nodes in the active scene hierarchy
	var all_markers: Array[Node3D] = []
	_collect_markers(current_scene, all_markers)

	# 1. Search for exact or fuzzy name match
	if target_id_clean != "":
		for marker in all_markers:
			var m_name = marker.name.to_lower().replace("_", "").replace(" ", "")
			var m_spawn_id = str(marker.get("spawn_id")).to_lower().replace("_", "").replace(" ", "") if marker.get("spawn_id") else ""
			if m_name == target_id_clean or m_spawn_id == target_id_clean or m_name == "spawn" + target_id_clean or m_name == "from" + target_id_clean:
				target_marker = marker
				break

	# 2. Fallback to default markers if specific target marker is not found
	if not target_marker:
		for marker in all_markers:
			var m_name = marker.name.to_lower().replace("_", "").replace(" ", "")
			if m_name == "spawndefault" or m_name == "default" or m_name == "fromstreet" or m_name == "spawn":
				target_marker = marker
				break

	# 3. Final fallback to first marker found in scene
	if not target_marker and all_markers.size() > 0:
		target_marker = all_markers[0]

	# Apply Marker3D global transform directly to Player
	if target_marker:
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO
		player.global_transform = target_marker.global_transform

	# Snap camera pivot position immediately to match player position
	var camera_pivot = player.get_node_or_null("CameraPivot")
	if camera_pivot and not player.get("is_fixed_diorama_room"):
		var target_x = clamp(player.global_position.x, -38.0, 38.0)
		camera_pivot.global_position.x = target_x

func _collect_markers(node: Node, result: Array[Node3D]) -> void:
	if node is Marker3D or (node is Node3D and node.is_in_group("spawn_markers")):
		result.append(node as Node3D)
	for child in node.get_children():
		_collect_markers(child, result)

func clear_saved_positions() -> void:
	pass




