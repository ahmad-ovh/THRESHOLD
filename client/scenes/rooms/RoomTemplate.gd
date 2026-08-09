# res://scenes/rooms/RoomTemplate.gd
extends Node3D

@export var is_fixed_diorama_room: bool = false
@export var camera_position: Vector3 = Vector3(0.0, 2.2, 4.5)
@export var camera_rotation: Vector3 = Vector3(-15.0, 0.0, 0.0)

const VISUAL_ENV_PATH = "res://visual/threshold_visual_environment.tres"

func _ready() -> void:
	if has_node("CameraAnchor"):
		var camera_anchor = get_node("CameraAnchor") as Node3D
		camera_anchor.position = camera_position
		camera_anchor.rotation_degrees = camera_rotation
		
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

	if ResourceLoader.exists(VISUAL_ENV_PATH):
		var env_res = load(VISUAL_ENV_PATH)
		if env_res:
			world_env.environment = env_res

func _generate_model_collisions(node: Node) -> void:
	for child in node.get_children():
		# Skip doors, trigger areas, NPCs, and player
		if child is Area3D or child is CharacterBody3D or child.name.begins_with("Door") or child.name.begins_with("NPC_") or child.name == "Player3D":
			continue
			
		if child is MeshInstance3D and child.mesh:
			_ensure_mesh_collision(child)
			
		_generate_model_collisions(child)

func _ensure_mesh_collision(mi: MeshInstance3D) -> void:
	# Skip if collision already exists
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
