func _ready() -> void:
	var player = get_node_or_null("Player3D")
	if player:
		player.is_fixed_diorama_room = false
		player.room_camera_pos = Vector3(0.0, 2.2, 4.5)
		player.room_camera_rot = Vector3(-15.0, 0.0, 0.0)
	_setup_visual_environment()
	_setup_street_lights()
	_populate_urban_street_decor()
	_ensure_street_boundary_colliders()
	_setup_street_physics_colliders()
	
	if SceneManager:
		SceneManager.position_player_in_scene(self)

func _setup_visual_environment() -> void:
	var world_env: WorldEnvironment = null
	if has_node("WorldEnvironment"):
		world_env = get_node("WorldEnvironment") as WorldEnvironment
	else:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)

	if ResourceLoader.exists("res://visual/threshold_visual_environment.tres"):
		var env_res = load("res://visual/threshold_visual_environment.tres")
		if env_res:
			world_env.environment = env_res

func _setup_street_lights() -> void:
	# Add warm OmniLight3D nodes to street lamps
	var lamp_paths = [
		"EnvironmentProps/StreetLamp_1",
		"EnvironmentProps/StreetLamp_2",
		"EnvironmentProps/StreetLamp_3",
		"EnvironmentProps/StreetLamp_4"
	]
	for path in lamp_paths:
		var lamp = get_node_or_null(path)
		if lamp and not lamp.has_node("LampLight"):
			var light = OmniLight3D.new()
			light.name = "LampLight"
			light.light_color = Color(1.0, 0.85, 0.62) # Warm golden amber glow
			light.light_energy = 2.5
			light.omni_range = 9.5
			light.omni_attenuation = 0.8
			light.shadow_enabled = true
			light.position = Vector3(0, 3.8, 0.5)
			lamp.add_child(light)

	# Add inviting entrance lights to building doors
	var door_paths = [
		"Doors/DoorToAdler",
		"Doors/DoorToCafe",
		"Doors/DoorToApartment",
		"Doors/DoorToCampus",
		"Doors/DoorToOffice"
	]
	for path in door_paths:
		var door = get_node_or_null(path)
		if door and not door.has_node("DoorLight"):
			var light = OmniLight3D.new()
			light.name = "DoorLight"
			light.light_color = Color(1.0, 0.92, 0.75) # Soft warm doorway welcome light
			light.light_energy = 1.8
			light.omni_range = 4.5
			light.position = Vector3(0, 2.2, 0.6)
			door.add_child(light)

func _populate_urban_street_decor() -> void:
	if has_node("UrbanDecor"):
		return
		
	var decor_root = Node3D.new()
	decor_root.name = "UrbanDecor"
	add_child(decor_root)

	var spawn_prop = func(res_path: String, pos: Vector3, rot_deg_y: float = 0.0, scale_vec: Vector3 = Vector3.ONE) -> Node3D:
		if not ResourceLoader.exists(res_path):
			return null
		var scene = load(res_path) as PackedScene
		if not scene:
			return null
		var inst = scene.instantiate() as Node3D
		inst.position = pos
		inst.rotation_degrees.y = rot_deg_y
		inst.scale = scale_vec
		decor_root.add_child(inst)
		return inst

	# --- Zone 1: Outdoor Cafe Bistro Terrace (In front of Cafe, X = -6) ---
	spawn_prop.call("res://assets/threshold/props/rug_01.gltf", Vector3(-6.5, 0.01, 1.2), 0.0, Vector3(2.5, 1.0, 2.0))
	spawn_prop.call("res://assets/threshold/furniture/table_01.gltf", Vector3(-6.5, 0.0, 1.2), 0.0, Vector3(2.8, 2.8, 2.8))
	spawn_prop.call("res://assets/threshold/furniture/chair_01.gltf", Vector3(-7.4, 0.0, 1.2), 90.0, Vector3(2.8, 2.8, 2.8))
	spawn_prop.call("res://assets/threshold/furniture/chair_03.gltf", Vector3(-5.6, 0.0, 1.2), -90.0, Vector3(2.8, 2.8, 2.8))
	spawn_prop.call("res://assets/threshold/props/plant_01.gltf", Vector3(-4.2, 0.0, 0.8), 15.0, Vector3(2.5, 2.5, 2.5))
	spawn_prop.call("res://assets/threshold/props/plant_02.gltf", Vector3(-8.8, 0.0, 0.8), -25.0, Vector3(2.5, 2.5, 2.5))

	# --- Zone 2: Public Reading Plaza & Botanical Park (Between Apartment & Campus, X = 10) ---
	spawn_prop.call("res://assets/threshold/furniture/table_03.gltf", Vector3(10.0, 0.0, 1.0), 0.0, Vector3(2.6, 2.6, 2.6))
	spawn_prop.call("res://assets/threshold/props/book_01.gltf", Vector3(9.8, 0.72, 0.95), 12.0, Vector3(2.0, 2.0, 2.0))
	spawn_prop.call("res://assets/threshold/props/book_02.gltf", Vector3(10.2, 0.72, 1.05), -35.0, Vector3(2.0, 2.0, 2.0))
	spawn_prop.call("res://assets/threshold/props/picture_frame_01.gltf", Vector3(10.0, 0.72, 1.2), 0.0, Vector3(2.0, 2.0, 2.0))
	spawn_prop.call("res://assets/threshold/props/plant_02.gltf", Vector3(8.0, 0.0, 0.8), 45.0, Vector3(2.6, 2.6, 2.6))
	spawn_prop.call("res://assets/threshold/props/plant_01.gltf", Vector3(12.0, 0.0, 0.8), -10.0, Vector3(2.6, 2.6, 2.6))

	# --- Zone 3: Adler Study Lounge Terrace (X = -18) ---
	spawn_prop.call("res://assets/threshold/furniture/armchair_01.gltf", Vector3(-16.0, 0.0, 1.2), 30.0, Vector3(2.8, 2.8, 2.8))
	spawn_prop.call("res://assets/threshold/furniture/table_03.gltf", Vector3(-14.8, 0.0, 1.2), 0.0, Vector3(2.4, 2.4, 2.4))
	spawn_prop.call("res://assets/threshold/props/plant_01.gltf", Vector3(-21.2, 0.0, 0.8), 0.0, Vector3(2.8, 2.8, 2.8))

	# --- Zone 4: Office Courtyard Lounge (X = 22) ---
	spawn_prop.call("res://assets/threshold/furniture/couch_01.gltf", Vector3(22.8, 0.0, 1.2), 0.0, Vector3(2.8, 2.8, 2.8))
	spawn_prop.call("res://assets/threshold/furniture/table_02.gltf", Vector3(22.8, 0.0, 2.2), 90.0, Vector3(2.6, 2.6, 2.6))
	spawn_prop.call("res://assets/threshold/props/plant_02.gltf", Vector3(24.8, 0.0, 0.8), 60.0, Vector3(2.8, 2.8, 2.8))

	# --- Zone 5: Urban Boundary Foliage Backdrop (Z = -5.5 behind buildings) ---
	var backdrop_x_positions = [-32.0, -28.0, -25.0, -14.0, -1.0, 4.0, 8.0, 16.0, 20.0, 28.0, 32.0]
	for x_pos in backdrop_x_positions:
		spawn_prop.call("res://assets/threshold/nature/bush_01.gltf", Vector3(x_pos, 0.0, -5.2), float(int(x_pos * 17.0) % 360), Vector3(3.2, 3.2, 3.2))

func _ensure_street_boundary_colliders() -> void:
	if has_node("StreetBoundaries"):
		return
		
	var boundaries = Node3D.new()
	boundaries.name = "StreetBoundaries"
	add_child(boundaries)
	
	# Front barrier (Z = +6.0) facing camera
	var front_wall = CSGBox3D.new()
	front_wall.name = "FrontBoundary"
	front_wall.use_collision = true
	front_wall.visible = false
	front_wall.size = Vector3(80.0, 5.0, 0.4)
	front_wall.position = Vector3(0.0, 2.5, 6.0)
	boundaries.add_child(front_wall)

	# Left boundary (X = -40.0)
	var left_wall = CSGBox3D.new()
	left_wall.name = "LeftBoundary"
	left_wall.use_collision = true
	left_wall.visible = false
	left_wall.size = Vector3(0.4, 5.0, 12.0)
	left_wall.position = Vector3(-40.0, 2.5, 0.0)
	boundaries.add_child(left_wall)

	# Right boundary (X = +40.0)
	var right_wall = CSGBox3D.new()
	right_wall.name = "RightBoundary"
	right_wall.use_collision = true
	right_wall.visible = false
	right_wall.size = Vector3(0.4, 5.0, 12.0)
	right_wall.position = Vector3(40.0, 2.5, 0.0)
	boundaries.add_child(right_wall)

func _setup_street_physics_colliders() -> void:
	var root_groups = ["Architecture", "EnvironmentProps", "UrbanDecor"]
	for group_name in root_groups:
		var root_node = get_node_or_null(group_name)
		if root_node:
			for child in root_node.get_children():
				if child is Node3D and not child.name.to_lower().contains("rug"):
					_add_collider_to_instance(child)

func _add_collider_to_instance(inst: Node3D) -> void:
	if inst.has_node("Collision_Auto"):
		return
	var mesh_node = _find_first_mesh_instance(inst)
	if not mesh_node or not mesh_node.mesh:
		return
	var local_aabb = mesh_node.mesh.get_aabb()
	if local_aabb.size.length() < 0.05:
		return
	var sb = StaticBody3D.new()
	sb.name = "Collision_Auto"
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = local_aabb.size
	cs.shape = box
	cs.position = local_aabb.get_center()
	if mesh_node != inst:
		cs.position = mesh_node.position + local_aabb.get_center()
		cs.rotation = mesh_node.rotation
	sb.add_child(cs)
	inst.add_child(sb)

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh:
		return node
	for child in node.get_children():
		var found = _find_first_mesh_instance(child)
		if found:
			return found
	return null

func _process(delta: float) -> void:
	var player = get_node_or_null("Player3D")
	if player and is_instance_valid(player):
		var camera_pivot = player.get_node_or_null("CameraPivot")
		if camera_pivot:
			var target_x = clamp(player.global_position.x, -38.0, 38.0)
			# Force update the camera pivot position, overriding the player's own clamp if it happens earlier
			camera_pivot.global_position.x = lerp(camera_pivot.global_position.x, target_x, 5.0 * delta)

