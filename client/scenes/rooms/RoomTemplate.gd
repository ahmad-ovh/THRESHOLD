# res://scenes/rooms/RoomTemplate.gd
extends Node3D

@export var is_fixed_diorama_room: bool = false
@export var camera_position: Vector3 = Vector3(0.0, 2.2, 4.5)
@export var camera_rotation: Vector3 = Vector3(-15.0, 0.0, 0.0)
@export var lighting_mood: String = "warm"

const VISUAL_ENV_PATH = "res://visual/threshold_visual_environment.tres"

func _ready() -> void:
	if has_node("CameraAnchor"):
		var camera_anchor = get_node("CameraAnchor") as Node3D
		camera_anchor.position = camera_position
		camera_anchor.rotation_degrees = camera_rotation
		
	_setup_visual_environment()
	_apply_room_lighting_profile()
	_ensure_front_wall_collider()
	_generate_model_collisions(self)

func _setup_visual_environment() -> void:
	var world_env: WorldEnvironment = null
	if has_node("WorldEnvironment"):
		world_env = get_node("WorldEnvironment") as WorldEnvironment
	else:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)

	if ResourceLoader.exists(VISUAL_ENV_PATH):
		var env_res = load(VISUAL_ENV_PATH)
		if env_res:
			world_env.environment = env_res

func _apply_room_lighting_profile() -> void:
	var lighting_node = get_node_or_null("Lighting")
	if not lighting_node:
		return

	# Layer 1 & 2 & 3: Configure Light Nodes according to room lighting mood
	match lighting_mood:
		"cozy_study": # Prof. Adler Office
			_set_omni_light(lighting_node, "WarmDeskLight", Color(1.0, 0.86, 0.65), 1.2, 4.5)
			_set_omni_light(lighting_node, "AmbientLight", Color(0.68, 0.58, 0.50), 0.35, 8.0)
		"warm": # Café & Living Room
			_set_omni_light(lighting_node, "OmniLightAmber1", Color(1.0, 0.84, 0.62), 1.0, 6.0)
			_set_omni_light(lighting_node, "OmniLightAmber2", Color(1.0, 0.84, 0.62), 0.9, 6.0)
			_set_omni_light(lighting_node, "WarmLivingLight", Color(1.0, 0.86, 0.68), 1.0, 7.0)
		"cool": # Campus Hallway
			_set_omni_light(lighting_node, "FluorescentLight1", Color(0.85, 0.92, 1.0), 0.75, 6.0)
			_set_omni_light(lighting_node, "FluorescentLight2", Color(0.85, 0.92, 1.0), 0.75, 6.0)
		"neutral_warm": # Okoro Classroom
			_set_omni_light(lighting_node, "ClassroomLight1", Color(1.0, 0.94, 0.84), 0.85, 7.0)
			_set_omni_light(lighting_node, "ClassroomLight2", Color(1.0, 0.94, 0.84), 0.85, 7.0)
		"balcony": # Apartment Balcony
			_set_omni_light(lighting_node, "CoolNightLight", Color(0.60, 0.75, 0.95), 0.55, 5.0)
		"neutral": # Office Lobby
			_set_omni_light(lighting_node, "CoolLobbyLight1", Color(0.90, 0.95, 1.0), 0.75, 7.0)
			_set_omni_light(lighting_node, "CoolLobbyLight2", Color(0.90, 0.95, 1.0), 0.75, 7.0)
		"neutral_cool": # Conference Room
			_set_omni_light(lighting_node, "NeutralLighting", Color(0.92, 0.94, 1.0), 0.75, 8.0)
		"executive": # Executive Suite
			_set_omni_light(lighting_node, "GoldenDeskLight", Color(1.0, 0.88, 0.68), 1.0, 5.0)
			_set_omni_light(lighting_node, "GoldenAmbientLight", Color(0.88, 0.80, 0.70), 0.40, 8.0)

func _set_omni_light(parent: Node, name: String, color: Color, energy: float, light_range: float) -> void:
	if parent.has_node(name):
		var light = parent.get_node(name) as OmniLight3D
		if light:
			light.light_color = color
			light.light_energy = energy
			light.omni_range = light_range
			light.shadow_enabled = true

func _ensure_front_wall_collider() -> void:
	var bounds = get_node_or_null("RoomBounds")
	if not bounds:
		return
		
	if bounds.has_node("FrontWallCollider"):
		return

	var floor_node = bounds.get_node_or_null("Floor") as CSGBox3D
	if not floor_node:
		return

	var floor_size = floor_node.size
	var floor_pos = floor_node.position
	var front_z = floor_pos.z + (floor_size.z / 2.0)
	
	var front_wall = CSGBox3D.new()
	front_wall.name = "FrontWallCollider"
	front_wall.use_collision = true
	front_wall.visible = false
	front_wall.size = Vector3(floor_size.x, 5.0, 0.4)
	front_wall.position = Vector3(floor_pos.x, 2.5, front_z)
	bounds.add_child(front_wall)

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
