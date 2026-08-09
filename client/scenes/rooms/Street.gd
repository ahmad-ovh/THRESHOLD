extends Node3D

func _ready() -> void:
	var player = get_node_or_null("Player3D")
	if player:
		player.is_fixed_diorama_room = false
		player.room_camera_pos = Vector3(0.0, 2.2, 4.5)
		player.room_camera_rot = Vector3(-15.0, 0.0, 0.0)
	_setup_visual_environment()
	_generate_model_collisions(self)

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

func _generate_model_collisions(node: Node) -> void:
	for child in node.get_children():
		if child is Area3D or child is CharacterBody3D or child.name.begins_with("Door") or child.name.begins_with("NPC_") or child.name == "Player3D":
			continue
			
		if child is MeshInstance3D and child.mesh:
			_ensure_mesh_collision(child)
			
		_generate_model_collisions(child)

func _ensure_mesh_collision(mi: MeshInstance3D) -> void:
	for sibling in mi.get_children():
		if sibling is StaticBody3D or sibling is CollisionShape3D:
			return
	if mi.get_parent() is StaticBody3D:
		return

	var aabb = mi.mesh.get_aabb()
	if aabb.size.length() > 0.01:
		var sb = StaticBody3D.new()
		sb.name = mi.name + "_col"
		var cs = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = aabb.size
		cs.shape = box
		cs.position = aabb.get_center()
		sb.add_child(cs)
		mi.add_child(sb)

func _process(delta: float) -> void:
	var player = get_node_or_null("Player3D")
	if player and is_instance_valid(player):
		var camera_pivot = player.get_node_or_null("CameraPivot")
		if camera_pivot:
			var target_x = clamp(player.global_position.x, -38.0, 38.0)
			# Force update the camera pivot position, overriding the player's own clamp if it happens earlier
			camera_pivot.global_position.x = lerp(camera_pivot.global_position.x, target_x, 5.0 * delta)
