# res://singletons/SceneManager.gd
extends CanvasLayer

var color_rect: ColorRect
var target_spawn_id: String = ""
var _preloaded_paths: Dictionary = {}

var is_transitioning: bool = false

var saved_street_position: Vector3 = Vector3.ZERO
var saved_street_rotation: Vector3 = Vector3.ZERO
var saved_street_mesh_rotation_y: float = 0.0
var has_saved_street_position: bool = false

func _ready() -> void:
	layer = 100 # Keep transition color rect above all UI
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func preload_scene(scene_path: String) -> void:
	if not _preloaded_paths.has(scene_path):
		_preloaded_paths[scene_path] = true
		ResourceLoader.load_threaded_request(scene_path, "", true)

func is_scene_loaded(scene_path: String) -> bool:
	if not _preloaded_paths.has(scene_path):
		return false
	var status = ResourceLoader.load_threaded_get_status(scene_path)
	return status == ResourceLoader.THREAD_LOAD_LOADED

func get_preloaded_scene(scene_path: String) -> PackedScene:
	if is_scene_loaded(scene_path):
		return ResourceLoader.load_threaded_get(scene_path) as PackedScene
	return null

func _switch_to_scene(scene_path: String) -> void:
	var packed = get_preloaded_scene(scene_path)
	if packed:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(scene_path)

func _maybe_save_street_position() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene or not is_instance_valid(current_scene):
		return

	var is_street = false
	if current_scene.scene_file_path and current_scene.scene_file_path.ends_with("Street.tscn"):
		is_street = true
	elif current_scene.name == "Street":
		is_street = true

	if not is_street:
		return

	var player = current_scene.find_child("Player3D", true, false) as Node3D
	if not player:
		player = get_tree().get_first_node_in_group("player") as Node3D
	if not player or not is_instance_valid(player):
		return

	saved_street_position = player.global_position
	saved_street_rotation = player.global_rotation
	var char_mesh = player.get_node_or_null("CharacterMesh")
	if char_mesh:
		saved_street_mesh_rotation_y = char_mesh.rotation.y
	else:
		saved_street_mesh_rotation_y = 0.0
	has_saved_street_position = true

func change_room(scene_path: String, spawn_id: String = "default") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_maybe_save_street_position()
	target_spawn_id = spawn_id
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	preload_scene(scene_path)
	
	# Fade to Black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.4)
	await tween.finished
	
	# Change Scene
	_switch_to_scene(scene_path)
	await get_tree().process_frame
	
	# Position Player at matching Marker3D node
	_position_player()
	
	# Fade from Black
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.4)
	await fade_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

func change_room_async(scene_path: String, spawn_id: String = "default", show_storyboard: bool = false) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_maybe_save_street_position()
	target_spawn_id = spawn_id
	preload_scene(scene_path)
	
	if show_storyboard:
		var storyboard_scene = preload("res://scenes/ui/StoryboardLoading.tscn")
		var storyboard_instance = storyboard_scene.instantiate()
		storyboard_instance.set("target_scene_path", scene_path)
		get_tree().root.add_child(storyboard_instance)
		
		if storyboard_instance.has_signal("storyboard_completed"):
			await storyboard_instance.storyboard_completed
			
		_switch_to_scene(scene_path)
		await get_tree().process_frame
		_position_player()
		
		if storyboard_instance.has_method("fade_out_and_close"):
			await storyboard_instance.fade_out_and_close()
		else:
			storyboard_instance.queue_free()
		is_transitioning = false
	else:
		is_transitioning = false
		await change_room(scene_path, spawn_id)

func position_player_in_scene(scene_node: Node = null) -> void:
	var root_scene = scene_node
	if not root_scene or not is_instance_valid(root_scene):
		root_scene = get_tree().current_scene
	if not root_scene or not is_instance_valid(root_scene):
		# Fallback to last root child if current_scene is not updated yet by engine
		var root = get_tree().root
		if root and root.get_child_count() > 0:
			root_scene = root.get_child(root.get_child_count() - 1)
			
	if not root_scene or not is_instance_valid(root_scene):
		return

	var player = root_scene.find_child("Player3D", true, false) as Node3D
	if not player:
		player = get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return

	var is_street = false
	if root_scene.scene_file_path and root_scene.scene_file_path.ends_with("Street.tscn"):
		is_street = true
	elif root_scene.name == "Street":
		is_street = true

	if is_street and has_saved_street_position:
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO
		player.global_position = saved_street_position
		player.global_rotation = saved_street_rotation

		var char_mesh = player.get_node_or_null("CharacterMesh")
		if char_mesh:
			char_mesh.rotation.y = saved_street_mesh_rotation_y

		var camera_pivot = player.get_node_or_null("CameraPivot")
		if camera_pivot and not player.get("is_fixed_diorama_room"):
			var target_x = clamp(player.global_position.x, -38.0, 38.0)
			camera_pivot.global_position.x = target_x
		return

	var target_id_clean = target_spawn_id.strip_edges().to_lower().replace("_", "").replace(" ", "")
	var target_marker: Node3D = null

	# Collect all Marker3D nodes in the active scene hierarchy
	var all_markers: Array[Node3D] = []
	_collect_markers(root_scene, all_markers)

	if all_markers.size() == 0:
		return

	# 1. Search for exact or fuzzy name match
	if target_id_clean != "":
		for marker in all_markers:
			var m_name = marker.name.to_lower().replace("_", "").replace(" ", "")
			var m_spawn_id = str(marker.get("spawn_id")).to_lower().replace("_", "").replace(" ", "") if marker.get("spawn_id") else ""
			if m_name == target_id_clean \
				or m_spawn_id == target_id_clean \
				or m_name == "spawn" + target_id_clean \
				or m_name == "from" + target_id_clean \
				or m_name == target_id_clean + "spawn":
				target_marker = marker
				break

	# 2. Fallback search for default start markers
	if not target_marker:
		var default_names = [
			"spawndefault", "default", "playerspawn", "startspawn", 
			"start", "playerstart", "spawnpoint", "startpoint", 
			"spawn", "initialspawn", "fromstreet"
		]
		for marker in all_markers:
			var m_name = marker.name.to_lower().replace("_", "").replace(" ", "")
			if m_name in default_names:
				target_marker = marker
				break

	# 3. Final fallback: use first Marker3D found in scene
	if not target_marker:
		target_marker = all_markers[0]

	# Apply Marker3D global transform directly to Player
	if target_marker:
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO
		player.global_transform = target_marker.global_transform
		player.global_position = target_marker.global_position
		player.global_rotation = target_marker.global_rotation

		var camera_pivot = player.get_node_or_null("CameraPivot")
		if camera_pivot and not player.get("is_fixed_diorama_room"):
			var target_x = clamp(player.global_position.x, -38.0, 38.0)
			camera_pivot.global_position.x = target_x

func _position_player() -> void:
	position_player_in_scene()

func _collect_markers(node: Node, result: Array[Node3D]) -> void:
	if node is Marker3D or (node is Node3D and node.is_in_group("spawn_markers")):
		result.append(node as Node3D)
	for child in node.get_children():
		_collect_markers(child, result)

func clear_saved_positions() -> void:
	has_saved_street_position = false
	saved_street_position = Vector3.ZERO
	saved_street_rotation = Vector3.ZERO
	saved_street_mesh_rotation_y = 0.0





