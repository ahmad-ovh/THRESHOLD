# res://scenes/rooms/InteriorLighting.gd
class_name InteriorLighting
extends Object

static func get_profile(mood: String) -> Dictionary:
	match mood.to_lower():
		"hallway", "cool":
			return {
				"ambient_color": Color(0.38, 0.44, 0.52),
				"ambient_energy": 0.42,
				"fill_color": Color(0.85, 0.92, 1.0),
				"fill_energy": 0.48,
				"practical_color": Color(0.90, 0.95, 1.0),
				"practical_energy": 0.60
			}
		"adler_office", "cozy_study":
			return {
				"ambient_color": Color(0.42, 0.35, 0.30),
				"ambient_energy": 0.40,
				"fill_color": Color(0.92, 0.82, 0.72),
				"fill_energy": 0.45,
				"practical_color": Color(1.0, 0.85, 0.62),
				"practical_energy": 0.85
			}
		"classroom", "neutral_warm", "okoro_classroom":
			return {
				"ambient_color": Color(0.44, 0.42, 0.40),
				"ambient_energy": 0.45,
				"fill_color": Color(1.0, 0.95, 0.88),
				"fill_energy": 0.52,
				"practical_color": Color(1.0, 0.94, 0.84),
				"practical_energy": 0.70
			}
		"cafe", "warm", "living_room", "apartment_living":
			return {
				"ambient_color": Color(0.46, 0.38, 0.30),
				"ambient_energy": 0.42,
				"fill_color": Color(1.0, 0.86, 0.70),
				"fill_energy": 0.48,
				"practical_color": Color(1.0, 0.82, 0.58),
				"practical_energy": 0.80
			}
		"balcony", "apartment_balcony":
			return {
				"ambient_color": Color(0.30, 0.36, 0.48),
				"ambient_energy": 0.35,
				"fill_color": Color(0.65, 0.78, 0.95),
				"fill_energy": 0.45,
				"practical_color": Color(1.0, 0.84, 0.62),
				"practical_energy": 0.85
			}
		"lobby", "neutral", "office_lobby":
			return {
				"ambient_color": Color(0.40, 0.44, 0.50),
				"ambient_energy": 0.42,
				"fill_color": Color(0.92, 0.96, 1.0),
				"fill_energy": 0.50,
				"practical_color": Color(0.94, 0.96, 1.0),
				"practical_energy": 0.70
			}
		"conference", "neutral_cool", "office_conference":
			return {
				"ambient_color": Color(0.40, 0.42, 0.48),
				"ambient_energy": 0.42,
				"fill_color": Color(0.90, 0.93, 1.0),
				"fill_energy": 0.48,
				"practical_color": Color(0.92, 0.94, 1.0),
				"practical_energy": 0.65
			}
		"executive", "office_suite":
			return {
				"ambient_color": Color(0.44, 0.38, 0.32),
				"ambient_energy": 0.40,
				"fill_color": Color(1.0, 0.90, 0.75),
				"fill_energy": 0.46,
				"practical_color": Color(1.0, 0.88, 0.65),
				"practical_energy": 0.80
			}
		_:
			return {
				"ambient_color": Color(0.42, 0.40, 0.38),
				"ambient_energy": 0.40,
				"fill_color": Color(0.95, 0.90, 0.82),
				"fill_energy": 0.48,
				"practical_color": Color(1.0, 0.85, 0.65),
				"practical_energy": 0.75
			}

static func apply_to_room(room: Node3D, mood: String) -> void:
	var profile = get_profile(mood)
	
	# 1. Update WorldEnvironment for balanced global ambient base
	var world_env: WorldEnvironment = room.get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		room.add_child(world_env)
		
	if world_env and world_env.environment:
		var env = world_env.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = profile["ambient_color"]
		env.ambient_light_energy = profile["ambient_energy"]
		env.tonemap_mode = Environment.TONEMAP_ACES
		env.tonemap_exposure = 0.90
		env.glow_enabled = false
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.98
		env.adjustment_contrast = 1.08
		env.adjustment_saturation = 1.04

	# 2. Get or create Lighting parent node
	var lighting_node: Node3D = room.get_node_or_null("Lighting")
	if not lighting_node:
		lighting_node = Node3D.new()
		lighting_node.name = "Lighting"
		room.add_child(lighting_node)

	# Remove any single-corner DirectionalLight3D in interior rooms
	for child in lighting_node.get_children():
		if child is DirectionalLight3D:
			child.queue_free()

	# 3. Create or update Distributed Overhead Fill Lights (No shadows, broad smooth coverage)
	var fill_container: Node3D = lighting_node.get_node_or_null("DistributedRoomFill")
	if not fill_container:
		fill_container = Node3D.new()
		fill_container.name = "DistributedRoomFill"
		lighting_node.add_child(fill_container)
	else:
		for c in fill_container.get_children():
			c.queue_free()

	# Determine room floor dimensions to distribute fill lights evenly
	var room_width = 12.0
	var room_depth = 8.0
	var floor_node = room.get_node_or_null("RoomBounds/Floor") as CSGBox3D
	if floor_node:
		room_width = floor_node.size.x
		room_depth = floor_node.size.z

	# Position 4 broad overhead fill lights (front-left, front-right, back-left, back-right)
	var x_offset = room_width * 0.25
	var z_offset = room_depth * 0.25
	var fill_positions = [
		Vector3(-x_offset, 3.2, -z_offset),
		Vector3(x_offset, 3.2, -z_offset),
		Vector3(-x_offset, 3.2, z_offset),
		Vector3(x_offset, 3.2, z_offset)
	]

	for i in range(fill_positions.size()):
		var fill_light = OmniLight3D.new()
		fill_light.name = "BroadFill_" + str(i + 1)
		fill_light.position = fill_positions[i]
		fill_light.light_color = profile["fill_color"]
		fill_light.light_energy = profile["fill_energy"]
		fill_light.omni_range = max(room_width, room_depth) * 0.95
		fill_light.omni_attenuation = 1.0
		fill_light.shadow_enabled = false # Fill lights never cast directional shadows!
		fill_container.add_child(fill_light)

	# 4. Tune existing practical lights for localized accent warmth with soft grounding shadows
	for child in lighting_node.get_children():
		if child is OmniLight3D and child.get_parent() != fill_container:
			child.light_color = profile["practical_color"]
			child.light_energy = profile["practical_energy"]
			child.omni_range = 4.5
			child.shadow_enabled = true
			child.shadow_opacity = 0.35 # Soft, subtle grounding shadow
