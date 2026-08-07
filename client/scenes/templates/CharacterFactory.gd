# res://scenes/templates/CharacterFactory.gd
class_name CharacterFactory
extends Object

static func _mat(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

static func _box(size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	mi.material_override = mat
	return mi

static func _sphere(radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mi.mesh = sphere
	mi.position = pos
	mi.material_override = mat
	return mi

static func _cylinder(radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	mi.material_override = mat
	return mi

static func _torus(outer_r: float, inner_r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.outer_radius = outer_r
	torus.inner_radius = outer_r - inner_r
	mi.mesh = torus
	mi.position = pos
	mi.material_override = mat
	return mi

static func _face_plane(size: Vector2, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = size
	mi.mesh = quad
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	mi.material_override = mat
	return mi

static func create_character_mesh(character_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "Model_" + character_id

	match character_id:
		"player":
			_build_player(root)
		"prof_adler":
			_build_prof_adler(root)
		"daria":
			_build_daria(root)
		"ms_hartwell":
			_build_ms_hartwell(root)
		"barista":
			_build_barista(root)
		"ms_okoro":
			_build_ms_okoro(root)
		"mr_vance":
			_build_mr_vance(root)
		"felix":
			_build_felix(root)
		"priya":
			_build_priya(root)
		"nadia":
			_build_nadia(root)
		"tomas":
			_build_tomas(root)
		"seren":
			_build_seren(root)
		"sibling":
			_build_sibling(root)
		"parent":
			_build_parent(root)
		"recurring_stranger":
			_build_stranger(root)
		_:
			_build_generic(root, character_id)

	return root

# --- Articulated Humanoid Rig Assembly ---
static func _add_base_humanoid(
	root: Node3D,
	skin_mat: Material,
	shirt_mat: Material,
	pants_mat: Material,
	shoes_mat: Material,
	add_default_eyes: bool = true
) -> Dictionary:
	# 1. Left & Right Leg Pivots (at Hips Y=0.72)
	var left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = Vector3(-0.15, 0.72, 0.0)
	root.add_child(left_leg_pivot)
	left_leg_pivot.add_child(_cylinder(0.08, 0.60, Vector3(0.0, -0.30, 0.0), pants_mat))
	left_leg_pivot.add_child(_box(Vector3(0.14, 0.12, 0.24), Vector3(0.0, -0.66, 0.03), shoes_mat))

	var right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = Vector3(0.15, 0.72, 0.0)
	root.add_child(right_leg_pivot)
	right_leg_pivot.add_child(_cylinder(0.08, 0.60, Vector3(0.0, -0.30, 0.0), pants_mat))
	right_leg_pivot.add_child(_box(Vector3(0.14, 0.12, 0.24), Vector3(0.0, -0.66, 0.03), shoes_mat))

	# 2. Body Pivot (at Waist Y=0.76)
	var body_pivot = Node3D.new()
	body_pivot.name = "BodyPivot"
	body_pivot.position = Vector3(0.0, 0.76, 0.0)
	root.add_child(body_pivot)

	# Pelvis
	body_pivot.add_child(_box(Vector3(0.40, 0.12, 0.24), Vector3(0.0, 0.0, 0.0), pants_mat))
	# Torso
	body_pivot.add_child(_box(Vector3(0.44, 0.58, 0.26), Vector3(0.0, 0.35, 0.0), shirt_mat))

	# 3. Arm Pivots (at Shoulders Y=1.30 -> BodyPivot relative Y=0.54)
	var left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = Vector3(-0.27, 0.54, 0.0)
	body_pivot.add_child(left_arm_pivot)
	left_arm_pivot.add_child(_cylinder(0.06, 0.46, Vector3(0.0, -0.25, 0.0), shirt_mat))
	left_arm_pivot.add_child(_sphere(0.06, Vector3(0.0, -0.54, 0.0), skin_mat))

	var right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = Vector3(0.27, 0.54, 0.0)
	body_pivot.add_child(right_arm_pivot)
	right_arm_pivot.add_child(_cylinder(0.06, 0.46, Vector3(0.0, -0.25, 0.0), shirt_mat))
	right_arm_pivot.add_child(_sphere(0.06, Vector3(0.0, -0.54, 0.0), skin_mat))

	# 4. Head Pivot (at Neck base Y=1.45 -> BodyPivot relative Y=0.69)
	var head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.69, 0.0)
	body_pivot.add_child(head_pivot)

	head_pivot.add_child(_cylinder(0.06, 0.10, Vector3(0.0, 0.0, 0.0), skin_mat))
	var base_head_mesh = _sphere(0.19, Vector3(0.0, 0.16, 0.0), skin_mat)
	base_head_mesh.name = "HeadMesh"
	head_pivot.add_child(base_head_mesh)

	if add_default_eyes:
		var eye_mat = _mat(Color(0.15, 0.15, 0.18), 0.3)
		head_pivot.add_child(_sphere(0.035, Vector3(-0.07, 0.18, 0.195), eye_mat))
		head_pivot.add_child(_sphere(0.035, Vector3(0.07, 0.18, 0.195), eye_mat))

	return {
		"body_pivot": body_pivot,
		"head_pivot": head_pivot,
		"left_arm_pivot": left_arm_pivot,
		"right_arm_pivot": right_arm_pivot,
		"left_leg_pivot": left_leg_pivot,
		"right_leg_pivot": right_leg_pivot
	}

# --- Character Specific Models with Rigged Pivots ---

static func _load_gltf(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene = load(path)
	if not scene or not (scene is PackedScene):
		return null
	var inst = scene.instantiate() as Node3D
	if inst:
		inst.position = Vector3.ZERO
		inst.rotation_degrees = Vector3.ZERO
		inst.scale = Vector3.ONE
		for child in inst.get_children():
			if child is Node3D:
				child.position = Vector3.ZERO
				child.rotation_degrees = Vector3.ZERO
				child.scale = Vector3.ONE
	return inst

static func _set_node_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_set_node_material(child, mat)

static func _build_player(root: Node3D) -> void:
	var c = PlayerStore.customization

	var skin_color: Color = c.get("skin_color", Color(0.92, 0.76, 0.65))
	var hair_color: Color = c.get("hair_color", Color(0.24, 0.16, 0.10))

	var skin_mat = _mat(skin_color)
	var hair_mat = _mat(hair_color)
	var shirt_mat = _mat(Color(0.95, 0.95, 0.95))

	var avatar = Node3D.new()
	avatar.name = "MiiAvatar"
	root.add_child(avatar)

	# 1. Base Body GLTF
	var body_style: int = c.get("body_style", 0) # 0: Male, 1: Female
	var body_path = "res://assets/character_models/body/body_torso_m.gltf" if body_style == 0 else "res://assets/character_models/body/body_torso_f.gltf"
	var body_gltf = _load_gltf(body_path)
	if body_gltf:
		body_gltf.name = "GLTFBody"
		body_gltf.position = Vector3(0.0, 0.0, 0.0)
		body_gltf.rotation_degrees = Vector3(0.0, 0.0, 0.0)
		body_gltf.scale = Vector3(2.5, 2.5, 2.5)
		_set_node_material(body_gltf, shirt_mat)
		avatar.add_child(body_gltf)

	# 2. 3D GLTF Head Mesh
	var head_style: int = c.get("head_style", 1) # 1..12
	var head_path = "res://assets/character_models/heads/head_head_%03d.gltf" % head_style
	if not ResourceLoader.exists(head_path):
		head_path = "res://assets/character_models/heads/head_head_001.gltf"

	var head_gltf = _load_gltf(head_path)
	if head_gltf:
		head_gltf.name = "GLTFHead"
		var head_key = "head_%03d" % head_style
		_apply_item_transform(head_gltf, "heads", head_key, Vector3(0.0, 1.155, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
		var face_tex = _create_face_texture(c)
		var head_mat = StandardMaterial3D.new()
		head_mat.albedo_color = Color.WHITE
		head_mat.albedo_texture = face_tex
		head_mat.roughness = 0.85
		_set_node_material(head_gltf, head_mat)
		avatar.add_child(head_gltf)

	# 3. 3D GLTF Hair
	var hair_style: int = c.get("hair_style", 0) # 0..133
	var hair_path = "res://assets/character_models/hair/hair_%03d.gltf" % hair_style
	if not ResourceLoader.exists(hair_path):
		hair_path = "res://assets/character_models/hair/hair_000.gltf"

	var hair_gltf = _load_gltf(hair_path)
	if hair_gltf:
		hair_gltf.name = "GLTFHair"
		var hair_key = "hair_%03d" % hair_style
		_apply_item_transform(hair_gltf, "hair", hair_key, Vector3(0.0, 1.605, 0.0), Vector3.ZERO, Vector3(6.6, 6.6, 6.6))
		_set_node_material(hair_gltf, hair_mat)
		avatar.add_child(hair_gltf)

	# 4. Accessories & Glasses
	var glasses_style: int = c.get("glasses_style", 0) # 0..5
	if glasses_style > 0:
		var glasses_path = "res://assets/character_models/glasses/glasses_glasses%d.gltf" % glasses_style
		if not ResourceLoader.exists(glasses_path):
			glasses_path = "res://assets/character_models/glasses/glasses_0glasses.gltf"
		var glasses_gltf = _load_gltf(glasses_path)
		if glasses_gltf:
			glasses_gltf.name = "GLTFGlasses"
			var glasses_key = "glasses_%d" % glasses_style
			_apply_item_transform(glasses_gltf, "glasses", glasses_key, Vector3(0.0, 1.12, 0.31), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
			var glass_tex = load("res://assets/character_models/glasses/glasses_sprite.png") as Texture2D
			if glass_tex:
				var glass_mat = StandardMaterial3D.new()
				glass_mat.albedo_texture = glass_tex
				glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				_set_node_material(glasses_gltf, glass_mat)
			avatar.add_child(glasses_gltf)

	var acc_style: int = c.get("accessory_style", 0)
	_add_accessory(avatar, avatar, acc_style)

static var model_presets: Dictionary = {}
static var _presets_loaded: bool = false

static func get_model_presets() -> Dictionary:
	if not _presets_loaded:
		_load_model_presets()
	return model_presets

static func _load_model_presets() -> void:
	_presets_loaded = true
	var preset_path = "res://assets/character_models/model_presets.json"
	if FileAccess.file_exists(preset_path):
		var f = FileAccess.open(preset_path, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				model_presets = json.data

static func _apply_item_transform(node: Node3D, cat: String, item_key: String, def_pos: Vector3, def_rot: Vector3, def_scale: Vector3) -> void:
	if not node:
		return
	var presets = get_model_presets()
	if presets.has(cat) and presets[cat].has(item_key):
		var t = presets[cat][item_key]
		if t.has("position"): node.position = Vector3(t["position"][0], t["position"][1], t["position"][2])
		if t.has("rotation"): node.rotation_degrees = Vector3(t["rotation"][0], t["rotation"][1], t["rotation"][2])
		if t.has("scale"): node.scale = Vector3(t["scale"][0], t["scale"][1], t["scale"][2])
	else:
		node.position = def_pos
		node.rotation_degrees = def_rot
		node.scale = def_scale

static func apply_alignment(avatar: Node3D, alignment: Dictionary) -> void:
	if not avatar:
		return
	var mii = avatar.get_node_or_null("MiiAvatar") if avatar.name != "MiiAvatar" else avatar
	if not mii:
		return
	for part in ["body", "head", "hair", "glasses"]:
		if alignment.has(part):
			var node_name = "GLTF" + part.capitalize()
			var node = mii.get_node_or_null(node_name)
			if node:
				var t = alignment[part]
				if t.has("position"): node.position = t["position"]
				if t.has("rotation"): node.rotation_degrees = t["rotation"]
				if t.has("scale"): node.scale = t["scale"]

static func _create_face_texture(customization: Dictionary) -> ImageTexture:
	var skin_color: Color = customization.get("skin_color", Color(0.92, 0.76, 0.65))
	var eye_style: int = customization.get("eye_style", 1)
	var sclera_col: Color = customization.get("eye_sclera_color", Color(1.0, 1.0, 1.0))
	var pupil_col: Color = customization.get("eye_pupil_color", Color(0.1, 0.1, 0.1))
	var iris_col: Color = customization.get("eye_iris_color", Color(0.18, 0.55, 0.85))
	var nose_style: int = customization.get("nose_style", 1)
	var mouth_style: int = customization.get("mouth_style", 1)
	var glasses_style: int = customization.get("glasses_style", 0)

	var face_offsets: Dictionary = customization.get("face_offsets", {})
	var eye_x_off: int = int(face_offsets.get("eye_x", 0))
	var eye_y_off: int = int(face_offsets.get("eye_y", 0))
	var eye_size: int = int(face_offsets.get("eye_size", 24))
	var nose_y_off: int = int(face_offsets.get("nose_y", 0))
	var mouth_y_off: int = int(face_offsets.get("mouth_y", 0))
	var glass_x_off: int = int(face_offsets.get("glass_x", 0))
	var glass_y_off: int = int(face_offsets.get("glass_y", 0))
	var glass_w: int = int(face_offsets.get("glass_w", 60))
	var glass_h: int = int(face_offsets.get("glass_h", 30))

	var tex_w = 512
	var tex_h = 512
	var face_img = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	face_img.fill(skin_color)

	var base_eye_l_pos = Vector2i(242 + eye_x_off, 400 + eye_y_off)
	var base_eye_r_pos = Vector2i(218 - eye_x_off, 400 + eye_y_off)

	# Load Eye L & R
	var eye_l_path = "res://resources/character_customization/eyes/eye_%02d_L.png" % eye_style
	var eye_r_path = "res://resources/character_customization/eyes/eye_%02d_R.png" % eye_style
	if not ResourceLoader.exists(eye_l_path):
		eye_l_path = "res://resources/character_customization/eyes/eye_01_L.png"
	if not ResourceLoader.exists(eye_r_path):
		eye_r_path = "res://resources/character_customization/eyes/eye_01_R.png"

	var eye_l_tex: Texture2D = load(eye_l_path) if ResourceLoader.exists(eye_l_path) else null
	var eye_r_tex: Texture2D = load(eye_r_path) if ResourceLoader.exists(eye_r_path) else null

	if eye_l_tex:
		var img_l = eye_l_tex.get_image()
		img_l.resize(eye_size, eye_size, Image.INTERPOLATE_BILINEAR)
		_apply_chroma_and_blit(face_img, img_l, base_eye_l_pos, sclera_col, pupil_col, iris_col)
	else:
		var half_sz = int(eye_size / 2.0)
		_draw_procedural_eye(face_img, base_eye_l_pos + Vector2i(half_sz, half_sz), half_sz, sclera_col, pupil_col, iris_col)

	if eye_r_tex:
		var img_r = eye_r_tex.get_image()
		img_r.resize(eye_size, eye_size, Image.INTERPOLATE_BILINEAR)
		_apply_chroma_and_blit(face_img, img_r, base_eye_r_pos, sclera_col, pupil_col, iris_col)
	else:
		var half_sz2 = int(eye_size / 2.0)
		_draw_procedural_eye(face_img, base_eye_r_pos + Vector2i(half_sz2, half_sz2), half_sz2, sclera_col, pupil_col, iris_col)

	# Load Nose
	var nose_path = "res://resources/character_customization/noses/nose_%02d.png" % nose_style
	if not ResourceLoader.exists(nose_path):
		nose_path = "res://resources/character_customization/noses/nose_01.png"
	var nose_tex: Texture2D = load(nose_path) if ResourceLoader.exists(nose_path) else null
	var nose_pos = Vector2i(233, 424 + nose_y_off)
	if nose_tex:
		var img_n = nose_tex.get_image()
		img_n.resize(16, 16, Image.INTERPOLATE_BILINEAR)
		_blit_alpha(face_img, img_n, nose_pos)
	else:
		_draw_procedural_nose(face_img, nose_pos + Vector2i(8, 8), skin_color.darkened(0.2))

	# Load Mouth
	var mouth_path = "res://resources/character_customization/mouths/mouth_mask_%02d.png" % mouth_style
	if not ResourceLoader.exists(mouth_path):
		mouth_path = "res://resources/character_customization/mouths/mouth_mask_01.png"
	var mouth_tex: Texture2D = load(mouth_path) if ResourceLoader.exists(mouth_path) else null
	var mouth_pos = Vector2i(230, 440 + mouth_y_off)
	if mouth_tex:
		var img_m = mouth_tex.get_image()
		img_m.resize(22, 14, Image.INTERPOLATE_BILINEAR)
		_blit_alpha(face_img, img_m, mouth_pos)
	else:
		_draw_procedural_mouth(face_img, mouth_pos + Vector2i(11, 7), Color(0.7, 0.25, 0.25))

	# Load Glasses directly onto Face Texture Map (Binds and morphs onto 3D face mesh!)
	if glasses_style > 0:
		var glasses_atlas_path = "res://assets/character_models/glasses/glasses_sprite.png"
		if ResourceLoader.exists(glasses_atlas_path):
			var glasses_atlas = load(glasses_atlas_path) as Texture2D
			if glasses_atlas:
				var atlas_img = glasses_atlas.get_image()
				var frame_w = 950
				var frame_h = 500
				var idx = clamp(glasses_style - 1, 0, 9)
				var rect = Rect2i(idx * frame_w, 0, frame_w, frame_h)
				var glass_frame = atlas_img.get_region(rect)
				glass_frame.resize(glass_w, glass_h, Image.INTERPOLATE_BILINEAR)
				_blit_alpha(face_img, glass_frame, Vector2i(211 + glass_x_off, 396 + glass_y_off))

	return ImageTexture.create_from_image(face_img)

static func _draw_procedural_eye(dest: Image, center: Vector2i, radius: int, sclera: Color, pupil: Color, iris: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var dist_sq = x*x + y*y
			if dist_sq <= radius * radius:
				var px = center.x + x
				var py = center.y + y
				if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
					if dist_sq <= (radius * 0.35) * (radius * 0.35):
						dest.set_pixel(px, py, pupil)
					elif dist_sq <= (radius * 0.65) * (radius * 0.65):
						dest.set_pixel(px, py, iris)
					else:
						dest.set_pixel(px, py, sclera)

static func _draw_procedural_nose(dest: Image, center: Vector2i, color: Color) -> void:
	for y in range(-15, 16):
		var w = int(12.0 * (1.0 - (float(y) + 15.0) / 30.0))
		for x in range(-w, w + 1):
			var px = center.x + x
			var py = center.y + y
			if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
				dest.set_pixel(px, py, color)

static func _draw_procedural_mouth(dest: Image, center: Vector2i, color: Color) -> void:
	for y in range(0, 10):
		var w = int(25.0 * (1.0 - (float(y) / 10.0)))
		for x in range(-w, w + 1):
			var px = center.x + x
			var py = center.y + y
			if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
				dest.set_pixel(px, py, color)

static func _apply_chroma_and_blit(dest: Image, src: Image, pos: Vector2i, sclera: Color, pupil: Color, iris: Color) -> void:
	var sw = src.get_width()
	var sh = src.get_height()
	for y in range(sh):
		for x in range(sw):
			var dx = pos.x + x
			var dy = pos.y + y
			if dx < 0 or dx >= dest.get_width() or dy < 0 or dy >= dest.get_height():
				continue
			var px = src.get_pixel(x, y)
			if px.a < 0.05:
				continue

			var r = px.r
			var g = px.g
			var b = px.b
			var max_c = max(r, max(g, b))

			var final_col: Color
			if max_c < 0.20:
				final_col = Color(0.05, 0.05, 0.05, px.a)
			else:
				var c_rgb = Vector3(1, 1, 1)
				if g > r and g > b:
					c_rgb = lerp(Vector3(sclera.r, sclera.g, sclera.b), Vector3(g, g, g), 0.15)
				elif r > g and r > b and (r - b) > 0.15:
					c_rgb = Vector3(pupil.r, pupil.g, pupil.b)
				elif b > g or (r > 0.35 and b > 0.35):
					c_rgb = Vector3(iris.r, iris.g, iris.b)
				else:
					c_rgb = lerp(Vector3(0.1, 0.1, 0.1), Vector3(sclera.r, sclera.g, sclera.b), max_c)
				final_col = Color(c_rgb.x, c_rgb.y, c_rgb.z, px.a)

			var bg = dest.get_pixel(dx, dy)
			var blended = bg.blend(final_col)
			dest.set_pixel(dx, dy, blended)

static func _blit_alpha(dest: Image, src: Image, pos: Vector2i) -> void:
	var sw = src.get_width()
	var sh = src.get_height()
	for y in range(sh):
		for x in range(sw):
			var dx = pos.x + x
			var dy = pos.y + y
			if dx < 0 or dx >= dest.get_width() or dy < 0 or dy >= dest.get_height():
				continue
			var px = src.get_pixel(x, y)
			if px.a < 0.05:
				continue
			var bg = dest.get_pixel(dx, dy)
			var blended = bg.blend(px)
			dest.set_pixel(dx, dy, blended)

static func _add_hair_style(head_pivot: Node3D, style: int, hair_mat: Material) -> void:
	match style:
		0: # Short Classic
			head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.21, -0.02), hair_mat))
			head_pivot.add_child(_box(Vector3(0.22, 0.08, 0.14), Vector3(0.04, 0.32, 0.09), hair_mat, Vector3(0, 0, -15)))
		1: # Bob / Medium Cut
			head_pivot.add_child(_sphere(0.225, Vector3(0.0, 0.20, -0.02), hair_mat))
			head_pivot.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(-0.18, 0.11, 0.04), hair_mat))
			head_pivot.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(0.18, 0.11, 0.04), hair_mat))
		2: # Combed Side Part
			head_pivot.add_child(_box(Vector3(0.38, 0.14, 0.38), Vector3(0.0, 0.28, -0.02), hair_mat))
			head_pivot.add_child(_sphere(0.18, Vector3(-0.06, 0.30, 0.02), hair_mat))
		3: # Spiky
			head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.20, -0.02), hair_mat))
			head_pivot.add_child(_box(Vector3(0.08, 0.16, 0.08), Vector3(0.0, 0.36, 0.02), hair_mat, Vector3(15, 0, 0)))
			head_pivot.add_child(_box(Vector3(0.07, 0.14, 0.07), Vector3(-0.09, 0.34, 0.05), hair_mat, Vector3(10, 0, -20)))
			head_pivot.add_child(_box(Vector3(0.07, 0.14, 0.07), Vector3(0.09, 0.34, 0.05), hair_mat, Vector3(10, 0, 20)))
		4: # Afro
			head_pivot.add_child(_sphere(0.26, Vector3(0.0, 0.22, -0.03), hair_mat))
			head_pivot.add_child(_sphere(0.12, Vector3(-0.16, 0.28, 0.0), hair_mat))
			head_pivot.add_child(_sphere(0.12, Vector3(0.16, 0.28, 0.0), hair_mat))
		5: # Top Bun
			head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.20, -0.02), hair_mat))
			head_pivot.add_child(_sphere(0.09, Vector3(0.0, 0.38, -0.08), hair_mat))
		6: # Beanie
			var beanie_mat = _mat(Color(0.2, 0.2, 0.25))
			head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.23, 0.0), beanie_mat))
			head_pivot.add_child(_torus(0.21, 0.03, Vector3(0.0, 0.20, 0.0), beanie_mat))
		7: # Cap
			var cap_mat = _mat(Color(0.18, 0.32, 0.22))
			head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.23, 0.0), cap_mat))
			head_pivot.add_child(_box(Vector3(0.26, 0.03, 0.12), Vector3(0.0, 0.24, 0.21), cap_mat, Vector3(10, 0, 0)))
		_:
			head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.21, -0.02), hair_mat))

static func _add_accessory(body_pivot: Node3D, head_pivot: Node3D, style: int) -> void:
	match style:
		1: # Glasses
			var glass_mat = _mat(Color(0.1, 0.1, 0.1), 0.1, 0.9)
			head_pivot.add_child(_box(Vector3(0.10, 0.05, 0.02), Vector3(-0.075, 0.18, 0.205), glass_mat))
			head_pivot.add_child(_box(Vector3(0.10, 0.05, 0.02), Vector3(0.075, 0.18, 0.205), glass_mat))
			head_pivot.add_child(_box(Vector3(0.06, 0.02, 0.02), Vector3(0.0, 0.18, 0.205), glass_mat))
		2: # Scarf
			var scarf_mat = _mat(Color(0.75, 0.22, 0.18))
			head_pivot.add_child(_torus(0.13, 0.05, Vector3(0.0, -0.03, 0.0), scarf_mat))
		3: # Backpack
			var backpack_mat = _mat(Color(0.80, 0.22, 0.20))
			body_pivot.add_child(_box(Vector3(0.34, 0.42, 0.16), Vector3(0.0, 0.38, -0.23), backpack_mat))
			body_pivot.add_child(_box(Vector3(0.05, 0.45, 0.08), Vector3(-0.14, 0.38, 0.15), backpack_mat))
			body_pivot.add_child(_box(Vector3(0.05, 0.45, 0.08), Vector3(0.14, 0.38, 0.15), backpack_mat))
		4: # Crown / Band
			var band_mat = _mat(Color(0.95, 0.80, 0.18), 0.3, 0.7)
			head_pivot.add_child(_torus(0.20, 0.02, Vector3(0.0, 0.26, 0.0), band_mat))


static func _build_prof_adler(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.88, 0.74, 0.64))
	var suit_mat = _mat(Color(0.22, 0.24, 0.28))
	var tie_mat = _mat(Color(0.55, 0.12, 0.15))
	var shoes_mat = _mat(Color(0.12, 0.10, 0.08))
	var hair_mat = _mat(Color(0.72, 0.74, 0.76))
	var glass_mat = _mat(Color(0.1, 0.1, 0.1), 0.1, 0.9)

	var rig = _add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	# Vest & Tie
	rig.body_pivot.add_child(_box(Vector3(0.26, 0.54, 0.29), Vector3(0.0, 0.35, 0.0), suit_mat))
	rig.body_pivot.add_child(_box(Vector3(0.08, 0.40, 0.32), Vector3(0.0, 0.39, 0.0), tie_mat))

	# Combed Silver Hair & Glasses on head
	rig.head_pivot.add_child(_box(Vector3(0.38, 0.14, 0.38), Vector3(0.0, 0.28, -0.02), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.12, 0.05, 0.02), Vector3(-0.07, 0.19, 0.23), glass_mat))
	rig.head_pivot.add_child(_box(Vector3(0.12, 0.05, 0.02), Vector3(0.07, 0.19, 0.23), glass_mat))
	rig.head_pivot.add_child(_box(Vector3(0.06, 0.02, 0.02), Vector3(0.0, 0.19, 0.23), glass_mat))

static func _build_daria(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.94, 0.78, 0.68))
	var sweater_mat = _mat(Color(0.85, 0.58, 0.18))
	var scarf_mat = _mat(Color(0.72, 0.22, 0.18))
	var pants_mat = _mat(Color(0.20, 0.25, 0.35))
	var boots_mat = _mat(Color(0.35, 0.22, 0.15))
	var hair_mat = _mat(Color(0.48, 0.24, 0.14))

	var rig = _add_base_humanoid(root, skin_mat, sweater_mat, pants_mat, boots_mat)

	# Scarf
	rig.head_pivot.add_child(_torus(0.13, 0.05, Vector3(0.0, -0.03, 0.0), scarf_mat))

	# Auburn Bob Hair
	rig.head_pivot.add_child(_sphere(0.225, Vector3(0.0, 0.20, -0.02), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(-0.18, 0.11, 0.04), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(0.18, 0.11, 0.04), hair_mat))

static func _build_ms_hartwell(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.75, 0.66))
	var suit_mat = _mat(Color(0.12, 0.14, 0.18))
	var blouse_mat = _mat(Color(0.10, 0.55, 0.45))
	var shoes_mat = _mat(Color(0.08, 0.08, 0.10))
	var hair_mat = _mat(Color(0.14, 0.12, 0.12))

	var rig = _add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.16, 0.32, 0.29), Vector3(0.0, 0.44, 0.0), blouse_mat))

	rig.head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.19, -0.02), hair_mat))
	rig.head_pivot.add_child(_sphere(0.09, Vector3(0.0, 0.38, -0.08), hair_mat))

static func _build_barista(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.86, 0.70, 0.58))
	var shirt_mat = _mat(Color(0.40, 0.55, 0.68))
	var apron_mat = _mat(Color(0.30, 0.20, 0.14))
	var pants_mat = _mat(Color(0.20, 0.20, 0.22))
	var shoes_mat = _mat(Color(0.25, 0.18, 0.14))
	var cap_mat = _mat(Color(0.18, 0.32, 0.22))

	var rig = _add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.36, 0.48, 0.30), Vector3(0.0, 0.29, 0.0), apron_mat))
	rig.body_pivot.add_child(_box(Vector3(0.38, 0.40, 0.28), Vector3(0.0, -0.11, 0.0), apron_mat))

	rig.head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.23, 0.0), cap_mat))
	rig.head_pivot.add_child(_box(Vector3(0.26, 0.03, 0.12), Vector3(0.0, 0.24, 0.21), cap_mat, Vector3(10, 0, 0)))

static func _build_ms_okoro(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.62, 0.42, 0.28))
	var cardigan_mat = _mat(Color(0.55, 0.18, 0.24))
	var blouse_mat = _mat(Color(0.94, 0.90, 0.82))
	var skirt_mat = _mat(Color(0.22, 0.22, 0.26))
	var shoes_mat = _mat(Color(0.15, 0.12, 0.14))
	var hair_mat = _mat(Color(0.12, 0.10, 0.10))
	var glass_mat = _mat(Color(0.70, 0.50, 0.20), 0.2, 0.8)

	var rig = _add_base_humanoid(root, skin_mat, cardigan_mat, skirt_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.18, 0.44, 0.29), Vector3(0.0, 0.36, 0.0), blouse_mat))

	rig.head_pivot.add_child(_sphere(0.26, Vector3(0.0, 0.21, -0.04), hair_mat))
	rig.head_pivot.add_child(_sphere(0.06, Vector3(-0.07, 0.19, 0.22), glass_mat))
	rig.head_pivot.add_child(_sphere(0.06, Vector3(0.07, 0.19, 0.22), glass_mat))

static func _build_mr_vance(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.77, 0.67))
	var shirt_mat = _mat(Color(0.85, 0.88, 0.92))
	var vest_mat = _mat(Color(0.18, 0.28, 0.45))
	var tie_mat = _mat(Color(0.65, 0.20, 0.18))
	var pants_mat = _mat(Color(0.52, 0.46, 0.38))
	var shoes_mat = _mat(Color(0.28, 0.18, 0.12))
	var hair_mat = _mat(Color(0.35, 0.25, 0.18))

	var rig = _add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.44, 0.52, 0.29), Vector3(0.0, 0.32, 0.0), vest_mat))
	rig.body_pivot.add_child(_box(Vector3(0.07, 0.42, 0.32), Vector3(0.0, 0.38, 0.0), tie_mat))

	rig.head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.20, -0.02), hair_mat))

static func _build_felix(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.75, 0.63))
	var hoodie_mat = _mat(Color(0.95, 0.42, 0.22))
	var pants_mat = _mat(Color(0.30, 0.32, 0.36))
	var sneakers_mat = _mat(Color(0.88, 0.18, 0.22))
	var beanie_mat = _mat(Color(0.18, 0.18, 0.20))

	var rig = _add_base_humanoid(root, skin_mat, hoodie_mat, pants_mat, sneakers_mat)

	rig.body_pivot.add_child(_box(Vector3(0.32, 0.20, 0.30), Vector3(0.0, 0.19, 0.0), hoodie_mat))
	rig.body_pivot.add_child(_torus(0.13, 0.05, Vector3(0.0, 0.64, -0.09), hoodie_mat))

	rig.head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.23, 0.0), beanie_mat))

static func _build_priya(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.80, 0.62, 0.48))
	var jacket_mat = _mat(Color(0.20, 0.28, 0.45))
	var top_mat = _mat(Color(0.15, 0.15, 0.15))
	var scarf_mat = _mat(Color(0.18, 0.55, 0.58))
	var pants_mat = _mat(Color(0.32, 0.38, 0.28))
	var boots_mat = _mat(Color(0.15, 0.15, 0.15))
	var hair_mat = _mat(Color(0.12, 0.10, 0.10))

	var rig = _add_base_humanoid(root, skin_mat, jacket_mat, pants_mat, boots_mat)

	rig.body_pivot.add_child(_box(Vector3(0.18, 0.45, 0.29), Vector3(0.0, 0.36, 0.0), top_mat))
	rig.head_pivot.add_child(_torus(0.12, 0.04, Vector3(0.0, -0.03, 0.0), scarf_mat))

	rig.head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.18, -0.02), hair_mat))
	rig.head_pivot.add_child(_cylinder(0.05, 0.28, Vector3(0.0, 0.10, -0.20), hair_mat, Vector3(-30, 0, 0)))

static func _build_nadia(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.74, 0.65))
	var suit_mat = _mat(Color(0.60, 0.52, 0.65))
	var top_mat = _mat(Color(0.95, 0.95, 0.95))
	var shoes_mat = _mat(Color(0.20, 0.18, 0.22))
	var hair_mat = _mat(Color(0.16, 0.14, 0.14))

	var rig = _add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.18, 0.44, 0.29), Vector3(0.0, 0.36, 0.0), top_mat))
	rig.head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.19, -0.02), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.08, 0.45, 0.16), Vector3(-0.17, 0.0, -0.02), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.08, 0.45, 0.16), Vector3(0.17, 0.0, -0.02), hair_mat))

static func _build_tomas(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.88, 0.72, 0.60))
	var shirt_mat = _mat(Color(0.68, 0.82, 0.92))
	var pants_mat = _mat(Color(0.22, 0.24, 0.28))
	var belt_mat = _mat(Color(0.25, 0.16, 0.10))
	var shoes_mat = _mat(Color(0.20, 0.14, 0.10))
	var hair_mat = _mat(Color(0.18, 0.14, 0.12))

	var rig = _add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	rig.body_pivot.add_child(_box(Vector3(0.44, 0.06, 0.28), Vector3(0.0, 0.05, 0.0), belt_mat))
	rig.head_pivot.add_child(_sphere(0.19, Vector3(0.0, 0.19, -0.02), hair_mat))

static func _build_seren(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.77, 0.68))
	var coat_mat = _mat(Color(0.88, 0.84, 0.76))
	var inner_mat = _mat(Color(0.18, 0.18, 0.20))
	var pants_mat = _mat(Color(0.20, 0.22, 0.26))
	var boots_mat = _mat(Color(0.22, 0.15, 0.12))
	var hair_mat = _mat(Color(0.55, 0.35, 0.20))
	var glass_mat = _mat(Color(0.15, 0.15, 0.15), 0.1, 0.9)

	var rig = _add_base_humanoid(root, skin_mat, coat_mat, pants_mat, boots_mat)

	rig.body_pivot.add_child(_box(Vector3(0.20, 0.46, 0.29), Vector3(0.0, 0.38, 0.0), inner_mat))

	rig.head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.20, -0.02), hair_mat))
	rig.head_pivot.add_child(_box(Vector3(0.10, 0.04, 0.02), Vector3(-0.06, 0.19, 0.23), glass_mat))
	rig.head_pivot.add_child(_box(Vector3(0.10, 0.04, 0.02), Vector3(0.06, 0.19, 0.23), glass_mat))

static func _build_sibling(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.94, 0.78, 0.68))
	var tshirt_mat = _mat(Color(0.95, 0.95, 0.95))
	var pants_mat = _mat(Color(0.25, 0.40, 0.65))
	var shoes_mat = _mat(Color(0.95, 0.80, 0.18))
	var hair_mat = _mat(Color(0.42, 0.26, 0.16))

	var rig = _add_base_humanoid(root, skin_mat, tshirt_mat, pants_mat, shoes_mat)
	rig.head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.19, -0.02), hair_mat))

static func _build_parent(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.75, 0.64))
	var cardigan_mat = _mat(Color(0.35, 0.52, 0.68))
	var pants_mat = _mat(Color(0.70, 0.68, 0.62))
	var shoes_mat = _mat(Color(0.45, 0.38, 0.32))
	var hair_mat = _mat(Color(0.60, 0.58, 0.56))

	var rig = _add_base_humanoid(root, skin_mat, cardigan_mat, pants_mat, shoes_mat)
	rig.head_pivot.add_child(_sphere(0.21, Vector3(0.0, 0.19, -0.02), hair_mat))

static func _build_stranger(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.85, 0.70, 0.60))
	var coat_mat = _mat(Color(0.15, 0.16, 0.18))
	var boots_mat = _mat(Color(0.08, 0.08, 0.10))
	var hat_mat = _mat(Color(0.10, 0.10, 0.12))

	var rig = _add_base_humanoid(root, skin_mat, coat_mat, coat_mat, boots_mat)

	rig.body_pivot.add_child(_box(Vector3(0.48, 0.50, 0.30), Vector3(0.0, -0.11, 0.0), coat_mat))

	rig.head_pivot.add_child(_cylinder(0.30, 0.04, Vector3(0.0, 0.28, 0.0), hat_mat))
	rig.head_pivot.add_child(_cylinder(0.19, 0.16, Vector3(0.0, 0.38, 0.0), hat_mat))

static func _build_generic(root: Node3D, _character_id: String) -> void:
	var skin_mat = _mat(Color(0.88, 0.74, 0.64))
	var shirt_mat = _mat(Color(0.45, 0.50, 0.55))
	var pants_mat = _mat(Color(0.25, 0.28, 0.32))
	var shoes_mat = _mat(Color(0.20, 0.18, 0.16))
	var hair_mat = _mat(Color(0.30, 0.20, 0.15))

	var rig = _add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)
	rig.head_pivot.add_child(_sphere(0.20, Vector3(0.0, 0.19, -0.02), hair_mat))
