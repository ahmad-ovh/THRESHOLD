# res://scenes/rooms/InteriorLighting.gd
class_name InteriorLighting
extends Object

static func get_profile(mood: String) -> Dictionary:
	match mood.to_lower():
		"hallway", "cool":
			return {
				"ambient_color": Color(0.38, 0.44, 0.52),
				"ambient_energy": 0.38,
				"key_color": Color(0.88, 0.94, 1.0),
				"key_energy": 0.65,
				"fill_color": Color(0.65, 0.72, 0.85),
				"fill_energy": 0.22,
				"practical_color": Color(0.90, 0.95, 1.0),
				"practical_energy": 0.50
			}
		"adler_office", "cozy_study":
			return {
				"ambient_color": Color(0.42, 0.34, 0.28),
				"ambient_energy": 0.36,
				"key_color": Color(1.0, 0.92, 0.82),
				"key_energy": 0.60,
				"fill_color": Color(0.78, 0.68, 0.58),
				"fill_energy": 0.20,
				"practical_color": Color(1.0, 0.85, 0.62),
				"practical_energy": 0.60
			}
		"classroom", "neutral_warm", "okoro_classroom":
			return {
				"ambient_color": Color(0.42, 0.40, 0.38),
				"ambient_energy": 0.40,
				"key_color": Color(1.0, 0.95, 0.88),
				"key_energy": 0.62,
				"fill_color": Color(0.80, 0.75, 0.70),
				"fill_energy": 0.22,
				"practical_color": Color(1.0, 0.94, 0.84),
				"practical_energy": 0.50
			}
		"cafe", "warm":
			return {
				"ambient_color": Color(0.44, 0.35, 0.26),
				"ambient_energy": 0.36,
				"key_color": Color(1.0, 0.90, 0.78),
				"key_energy": 0.62,
				"fill_color": Color(0.82, 0.68, 0.54),
				"fill_energy": 0.20,
				"practical_color": Color(1.0, 0.82, 0.58),
				"practical_energy": 0.55
			}
		"living_room", "apartment_living":
			return {
				"ambient_color": Color(0.42, 0.33, 0.26),
				"ambient_energy": 0.36,
				"key_color": Color(1.0, 0.90, 0.80),
				"key_energy": 0.60,
				"fill_color": Color(0.80, 0.66, 0.54),
				"fill_energy": 0.20,
				"practical_color": Color(1.0, 0.84, 0.60),
				"practical_energy": 0.55
			}
		"balcony", "apartment_balcony":
			return {
				"ambient_color": Color(0.30, 0.36, 0.48),
				"ambient_energy": 0.34,
				"key_color": Color(0.75, 0.88, 1.0),
				"key_energy": 0.55,
				"fill_color": Color(0.50, 0.60, 0.75),
				"fill_energy": 0.18,
				"practical_color": Color(1.0, 0.84, 0.62),
				"practical_energy": 0.60
			}
		"lobby", "neutral", "office_lobby":
			return {
				"ambient_color": Color(0.38, 0.42, 0.48),
				"ambient_energy": 0.38,
				"key_color": Color(0.92, 0.96, 1.0),
				"key_energy": 0.62,
				"fill_color": Color(0.70, 0.75, 0.82),
				"fill_energy": 0.22,
				"practical_color": Color(0.94, 0.96, 1.0),
				"practical_energy": 0.50
			}
		"conference", "neutral_cool", "office_conference":
			return {
				"ambient_color": Color(0.38, 0.40, 0.46),
				"ambient_energy": 0.38,
				"key_color": Color(0.90, 0.93, 1.0),
				"key_energy": 0.62,
				"fill_color": Color(0.68, 0.72, 0.80),
				"fill_energy": 0.22,
				"practical_color": Color(0.92, 0.94, 1.0),
				"practical_energy": 0.50
			}
		"executive", "office_suite":
			return {
				"ambient_color": Color(0.42, 0.34, 0.28),
				"ambient_energy": 0.36,
				"key_color": Color(1.0, 0.92, 0.80),
				"key_energy": 0.60,
				"fill_color": Color(0.78, 0.66, 0.54),
				"fill_energy": 0.20,
				"practical_color": Color(1.0, 0.88, 0.65),
				"practical_energy": 0.55
			}
		_:
			return {
				"ambient_color": Color(0.40, 0.36, 0.32),
				"ambient_energy": 0.36,
				"key_color": Color(1.0, 0.92, 0.82),
				"key_energy": 0.60,
				"fill_color": Color(0.75, 0.68, 0.58),
				"fill_energy": 0.20,
				"practical_color": Color(1.0, 0.85, 0.65),
				"practical_energy": 0.50
			}

static func apply_to_room(room: Node3D, mood: String) -> void:
	var profile = get_profile(mood)
	
	# 1. Base Layer: Soft Global Ambient + SSAO Grounding (WorldEnvironment)
	var world_env: WorldEnvironment = room.get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		room.add_child(world_env)
		
	if world_env and world_env.environment:
		var env = world_env.environment
		env.ambient_light_source = 2 # AMBIENT_SOURCE_COLOR
		env.ambient_light_color = profile["ambient_color"]
		env.ambient_light_energy = profile["ambient_energy"]
		env.tonemap_mode = 2 # TONEMAP_ACES
		env.tonemap_exposure = 0.95
		env.glow_enabled = false
		env.ssao_enabled = true # Screen-space ambient occlusion for soft contact grounding
		env.ssao_radius = 0.8
		env.ssao_intensity = 1.6
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.97
		env.adjustment_contrast = 1.10
		env.adjustment_saturation = 1.04

	# 2. Get or create Lighting parent node
	var lighting_node: Node3D = room.get_node_or_null("Lighting")
	if not lighting_node:
		lighting_node = Node3D.new()
		lighting_node.name = "Lighting"
		room.add_child(lighting_node)

	# Remove any old DistributedRoomFill OmniLight containers (removes circular light artifacts)
	var old_fill = lighting_node.get_node_or_null("DistributedRoomFill")
	if old_fill:
		old_fill.queue_free()

	# 3. Form Layer: Broad Primary Directional Key (Upper-Front-Left angle for 3D form & contact shadows)
	var broad_key: DirectionalLight3D = lighting_node.get_node_or_null("BroadInteriorKey")
	if not broad_key:
		broad_key = DirectionalLight3D.new()
		broad_key.name = "BroadInteriorKey"
		lighting_node.add_child(broad_key)

	broad_key.position = Vector3(0, 5, 0)
	broad_key.rotation_degrees = Vector3(-50, -30, 0)
	broad_key.light_color = profile["key_color"]
	broad_key.light_energy = profile["key_energy"]
	broad_key.shadow_enabled = true # Provides soft grounding contact shadows under furniture & characters
	broad_key.shadow_opacity = 0.45

	# 4. Fill Layer: Soft Opposing Fill Light (Upper-Back-Right angle to gently lift shadow planes)
	var secondary_fill: DirectionalLight3D = lighting_node.get_node_or_null("SecondaryFillKey")
	if not secondary_fill:
		secondary_fill = DirectionalLight3D.new()
		secondary_fill.name = "SecondaryFillKey"
		lighting_node.add_child(secondary_fill)

	secondary_fill.position = Vector3(0, 5, 0)
	secondary_fill.rotation_degrees = Vector3(-40, 150, 0)
	secondary_fill.light_color = profile["fill_color"]
	secondary_fill.light_energy = profile["fill_energy"]
	secondary_fill.shadow_enabled = false # Fill light never casts conflicting shadows

	# 5. Accent Layer: Practical Lights (Lamps/fixtures act as small localized mood accents)
	for child in lighting_node.get_children():
		if child is OmniLight3D and child != broad_key and child != secondary_fill:
			child.light_color = profile["practical_color"]
			child.light_energy = profile["practical_energy"]
			child.omni_range = 2.5 # Small influence radius
			child.omni_attenuation = 2.0 # Soft falloff
			child.shadow_enabled = false # Prevent spotty OmniLight shadow artifacts
