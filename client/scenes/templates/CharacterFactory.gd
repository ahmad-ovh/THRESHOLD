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
	return inst

static func _set_node_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_set_node_material(child, mat)

static func _setup_mixamo_animations(anim_player: AnimationPlayer) -> void:
	if not anim_player:
		return
		
	var anim_files = {
		"idle": "res://assets/character_models/animations/idle.fbx",
		"walk": "res://assets/character_models/animations/walk.fbx",
		"run": "res://assets/character_models/animations/run.fbx",
		"talk": "res://assets/character_models/animations/talk.fbx"
	}
	
	var lib = AnimationLibrary.new()
	for anim_name in anim_files:
		var path = anim_files[anim_name]
		if ResourceLoader.exists(path):
			var scene = load(path) as PackedScene
			if scene:
				var inst = scene.instantiate()
				var sub_ap = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
				if sub_ap:
					var anim_list = sub_ap.get_animation_list()
					if anim_list.size() > 0:
						var anim = sub_ap.get_animation(anim_list[0]).duplicate()
						lib.add_animation(anim_name, anim)
				inst.queue_free()
				
	if lib.get_animation_list().size() > 0:
		if anim_player.has_animation_library(""):
			var existing_lib = anim_player.get_animation_library("")
			for anim_n in lib.get_animation_list():
				if not existing_lib.has_animation(anim_n):
					existing_lib.add_animation(anim_n, lib.get_animation(anim_n))
		else:
			anim_player.add_animation_library("", lib)

static func _get_or_create_head_bone_attachment(skeleton: Skeleton3D) -> BoneAttachment3D:
	if not skeleton:
		return null
	for child in skeleton.get_children():
		if child is BoneAttachment3D:
			var idx = skeleton.find_bone(child.bone_name)
			if idx != -1:
				child.bone_idx = idx
			return child

	var head_bone_name = ""
	var head_bone_idx = -1

	for candidate in ["mixamorig_Head", "mixamorig:Head", "Head"]:
		var idx = skeleton.find_bone(candidate)
		if idx != -1:
			head_bone_name = candidate
			head_bone_idx = idx
			break

	if head_bone_idx == -1:
		for i in range(skeleton.get_bone_count()):
			var bname = skeleton.get_bone_name(i)
			if "head" in bname.to_lower() and not "end" in bname.to_lower() and not "top" in bname.to_lower():
				head_bone_name = bname
				head_bone_idx = i
				break

	if head_bone_idx == -1:
		head_bone_idx = 0
		head_bone_name = skeleton.get_bone_name(0)

	var ba = BoneAttachment3D.new()
	ba.name = "HeadBoneAttachment"
	ba.bone_name = head_bone_name
	ba.bone_idx = head_bone_idx
	skeleton.add_child(ba)
	return ba

static func _center_gltf_mesh(node: Node3D) -> void:
	if not node:
		return
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	if meshes.size() > 0:
		var mi = meshes[0] as MeshInstance3D
		if mi and mi.mesh:
			var aabb = mi.mesh.get_aabb()
			mi.position = -aabb.get_center()



static func _build_fallback_player(root: Node3D) -> void:
	var c = PlayerStore.customization
	var skin_color: Color = c.get("skin_color", Color(0.92, 0.76, 0.65))
	var hair_color: Color = c.get("hair_color", Color(0.24, 0.16, 0.10))

	var hair_mat = _mat(hair_color)
	var shirt_mat = _mat(Color(0.95, 0.95, 0.95))

	var avatar = Node3D.new()
	avatar.name = "MiiAvatar"
	root.add_child(avatar)

	var body_style: int = c.get("body_style", 0)
	var body_path = "res://assets/character_models/body/body_torso_m.gltf" if body_style == 0 else "res://assets/character_models/body/body_torso_f.gltf"
	var body_gltf = _load_gltf(body_path)
	if body_gltf:
		body_gltf.name = "GLTFBody"
		body_gltf.scale = Vector3(2.5, 2.5, 2.5)
		_set_node_material(body_gltf, shirt_mat)
		avatar.add_child(body_gltf)

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
	model_presets = {}

	# 1. Base project presets from res://
	var res_path = "res://assets/character_models/model_presets.json"
	if FileAccess.file_exists(res_path):
		var f = FileAccess.open(res_path, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				model_presets = json.data.duplicate(true)

	# 2. Overriding user presets saved by Model Aligner to user://
	var user_path = "user://model_presets.json"
	if FileAccess.file_exists(user_path):
		var f_user = FileAccess.open(user_path, FileAccess.READ)
		if f_user:
			var txt_user = f_user.get_as_text()
			f_user.close()
			var json_u = JSON.new()
			if json_u.parse(txt_user) == OK and json_u.data is Dictionary:
				var u_data = json_u.data as Dictionary
				for cat in u_data.keys():
					if u_data[cat] is Dictionary:
						if not model_presets.has(cat):
							model_presets[cat] = {}
						if cat == "face_offsets":
							model_presets[cat] = u_data[cat].duplicate(true)
						else:
							for item in u_data[cat].keys():
								model_presets[cat][item] = u_data[cat][item]


	if model_presets.has("face_offsets") and model_presets["face_offsets"] is Dictionary:
		var loaded_offsets = model_presets["face_offsets"] as Dictionary
		if not PlayerStore.customization.has("face_offsets"):
			PlayerStore.customization["face_offsets"] = {}
		for k in loaded_offsets.keys():
			# Only fill in keys the player's save file didn't already provide
			if not PlayerStore.customization["face_offsets"].has(k):
				PlayerStore.customization["face_offsets"][k] = loaded_offsets[k]


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
		mii = avatar

	for part in ["body", "head", "hair", "glasses"]:
		if alignment.has(part):
			var t = alignment[part]
			var node: Node3D = null
			if part == "body":
				node = mii
			else:
				node = mii.find_child("GLTF" + part.capitalize() + "*", true, false) as Node3D
				if not node and part != "head":
					node = mii.find_child("*" + part.capitalize() + "*", true, false) as Node3D

			if node:
				if t.has("position"): node.position = t["position"]
				if t.has("rotation"): node.rotation_degrees = t["rotation"]
				if t.has("scale"): node.scale = t["scale"]

static func _rotate_image_exact(src: Image, angle_deg: float) -> Image:
	if src == null:
		return null
	if angle_deg == 0.0 or angle_deg == 360.0:
		return src
	if src.is_compressed():
		src.decompress()
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)

	var norm_angle = posmod(angle_deg, 360.0)
	if norm_angle == 90.0:
		var copy = src.duplicate()
		copy.rotate_90(ClockDirection.CLOCKWISE)
		return copy
	elif norm_angle == 180.0:
		var copy = src.duplicate()
		copy.rotate_180()
		return copy
	elif norm_angle == 270.0:
		var copy = src.duplicate()
		copy.rotate_90(ClockDirection.COUNTERCLOCKWISE)
		return copy

	var rad = deg_to_rad(norm_angle)
	var cos_a = cos(rad)
	var sin_a = sin(rad)

	var sw = src.get_width()
	var sh = src.get_height()
	var cx = sw / 2.0
	var cy = sh / 2.0

	var dst = Image.create(sw, sh, false, Image.FORMAT_RGBA8)

	for y in range(sh):
		for x in range(sw):
			var dx = x - cx
			var dy = y - cy

			var sx = dx * cos_a + dy * sin_a + cx
			var sy = -dx * sin_a + dy * cos_a + cy

			if sx >= 0 and sx < sw - 1 and sy >= 0 and sy < sh - 1:
				var x0 = int(sx)
				var y0 = int(sy)
				var fx = sx - x0
				var fy = sy - y0

				var c00 = src.get_pixel(x0, y0)
				var c10 = src.get_pixel(x0 + 1, y0)
				var c01 = src.get_pixel(x0, y0 + 1)
				var c11 = src.get_pixel(x0 + 1, y0 + 1)

				var top = c00.lerp(c10, fx)
				var bot = c01.lerp(c11, fx)
				var final_c = top.lerp(bot, fy)

				dst.set_pixel(x, y, final_c)

	return dst

static var _cpu_img_cache: Dictionary = {}

static func _load_cpu_image(res_path: String) -> Image:
	if _cpu_img_cache.has(res_path):
		return _cpu_img_cache[res_path]
	if not ResourceLoader.exists(res_path):
		return null
	var global_path = ProjectSettings.globalize_path(res_path)
	var img = Image.load_from_file(global_path)
	if img:
		_cpu_img_cache[res_path] = img
		return img
	var tex = load(res_path) as Texture2D
	if tex:
		var tex_img = tex.get_image()
		_cpu_img_cache[res_path] = tex_img
		return tex_img
	return null

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
	var eye_x_off: int = int(face_offsets.get("eye_x", 26))
	var eye_y_off: int = int(face_offsets.get("eye_y", -135))
	var eye_size: int = int(face_offsets.get("eye_size", 43))
	var eye_rot: float = float(face_offsets.get("eye_rot", 90.0))

	var nose_x_off: int = int(face_offsets.get("nose_x", 0))
	var nose_y_off: int = int(face_offsets.get("nose_y", 0))
	var nose_size_val: int = int(face_offsets.get("nose_size", 32))
	var nose_rot: float = float(face_offsets.get("nose_rot", 0))

	var mouth_x_off: int = int(face_offsets.get("mouth_x", 0))
	var mouth_y_off: int = int(face_offsets.get("mouth_y", 0))
	var mouth_size_val: int = int(face_offsets.get("mouth_size", 28))
	var mouth_rot: float = float(face_offsets.get("mouth_rot", 0))

	var glass_x_off: int = int(face_offsets.get("glass_x", 0))
	var glass_y_off: int = int(face_offsets.get("glass_y", 0))
	var glass_w: int = int(face_offsets.get("glass_w", 60))
	var glass_h: int = int(face_offsets.get("glass_h", 30))
	var glass_rot: float = float(face_offsets.get("glass_rot", 0))

	# High-Resolution 1024x1024 Crisp Texture Map
	var tex_w = 1024
	var tex_h = 1024
	var face_img = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	face_img.fill(skin_color)

	# 1024x1024 UV Scaling
	var scale_factor = 2.0
	var hd_eye_size = max(16, int(eye_size * scale_factor))

	# Shared Eye Pivot Center (Between Eyes)
	var eye_center = Vector2(512.0, 420.0 + (eye_y_off * scale_factor))
	var rad_eye = deg_to_rad(eye_rot)
	var rel_left = Vector2(eye_x_off * scale_factor, 0.0).rotated(rad_eye)
	var rel_right = Vector2(-eye_x_off * scale_factor, 0.0).rotated(rad_eye)

	var eye_l_pos = Vector2i(eye_center + rel_left - Vector2(hd_eye_size / 2.0, hd_eye_size / 2.0))
	var eye_r_pos = Vector2i(eye_center + rel_right - Vector2(hd_eye_size / 2.0, hd_eye_size / 2.0))

	# 1. Load / Chroma-Key Eyes from 'eye sprite_rgb.png'
	var eye_sheet_path = "res://assets/character_models/textures/eye sprite_rgb.png"
	var eye_drawn = false
	var sheet_img = _load_cpu_image(eye_sheet_path)
	if sheet_img:
		if sheet_img.is_compressed():
			sheet_img.decompress()
		var total_frames = 60
		var frame_w = sheet_img.get_width() / total_frames
		var frame_h = sheet_img.get_height()
		var idx = clamp(eye_style - 1, 0, total_frames - 1)
		var eye_frame = sheet_img.get_region(Rect2i(idx * frame_w, 0, frame_w, frame_h))
		if eye_frame and hd_eye_size > 0:
			eye_frame.resize(hd_eye_size, hd_eye_size, Image.INTERPOLATE_BILINEAR)
			var eye_l_img = _rotate_image_exact(eye_frame.duplicate(), eye_rot)
			var eye_r_frame = eye_frame.duplicate()
			eye_r_frame.flip_x()
			var eye_r_img = _rotate_image_exact(eye_r_frame, eye_rot)
			_apply_chroma_and_blit(face_img, eye_l_img, eye_l_pos, sclera_col, pupil_col, iris_col)
			_apply_chroma_and_blit(face_img, eye_r_img, eye_r_pos, sclera_col, pupil_col, iris_col)
			eye_drawn = true

	if not eye_drawn:
		_draw_procedural_eye_style(face_img, eye_l_pos + Vector2i(hd_eye_size / 2, hd_eye_size / 2), hd_eye_size / 2, eye_style, sclera_col, pupil_col, iris_col, eye_rot, true)
		_draw_procedural_eye_style(face_img, eye_r_pos + Vector2i(hd_eye_size / 2, hd_eye_size / 2), hd_eye_size / 2, eye_style, sclera_col, pupil_col, iris_col, eye_rot, false)

	# 2. Load Nose from 'nose_sprite.png'
	var nose_sheet_path = "res://assets/character_models/textures/nose_sprite.png"
	var nose_size = Vector2i(int(nose_size_val * scale_factor), int(nose_size_val * scale_factor))
	var nose_rendered_h = nose_size.y
	var nose_base_y = int(eye_center.y) + hd_eye_size / 2 + nose_rendered_h / 2
	var nose_center = Vector2i(512 + int(nose_x_off * scale_factor), nose_base_y + int(nose_y_off * scale_factor))
	var nose_top_left = nose_center - nose_size / 2
	var nose_drawn = false

	var nose_sheet_img = _load_cpu_image(nose_sheet_path)
	if nose_sheet_img:
		if nose_sheet_img.is_compressed():
			nose_sheet_img.decompress()
		var total_frames = 18
		var frame_w = nose_sheet_img.get_width() / total_frames
		var frame_h = nose_sheet_img.get_height()
		var idx = clamp(nose_style - 1, 0, total_frames - 1)
		var nose_frame = nose_sheet_img.get_region(Rect2i(idx * frame_w, 0, frame_w, frame_h))
		if nose_frame and nose_size.x > 0 and nose_size.y > 0:
			nose_frame.resize(nose_size.x, nose_size.y, Image.INTERPOLATE_BILINEAR)
			nose_frame = _rotate_image_exact(nose_frame, nose_rot)
			_blit_alpha(face_img, nose_frame, nose_top_left)
			nose_drawn = true

	if not nose_drawn:
		_draw_procedural_nose_style(face_img, nose_center, nose_style, skin_color.darkened(0.25), nose_rot)

	# 3. Load Mouth from 'mouth_sprite_rgb.png'
	var mouth_sheet_path = "res://assets/character_models/textures/mouth_sprite_rgb.png"
	if not ResourceLoader.exists(mouth_sheet_path):
		mouth_sheet_path = "res://assets/character_models/textures/mouth_sprite.png"
	var mouth_aspect = 44.0 / 28.0
	var mouth_size = Vector2i(int(mouth_size_val * mouth_aspect * scale_factor), int(mouth_size_val * scale_factor))
	var mouth_rendered_h = mouth_size.y
	var mouth_base_y = nose_base_y + nose_rendered_h / 2 + mouth_rendered_h / 2
	var mouth_center = Vector2i(512 + int(mouth_x_off * scale_factor), mouth_base_y + int(mouth_y_off * scale_factor))
	var mouth_top_left = mouth_center - mouth_size / 2
	var mouth_drawn = false

	var mouth_sheet_img = _load_cpu_image(mouth_sheet_path)
	if mouth_sheet_img:
		if mouth_sheet_img.is_compressed():
			mouth_sheet_img.decompress()
		var total_frames = 36
		var frame_w = mouth_sheet_img.get_width() / total_frames
		var frame_h = mouth_sheet_img.get_height()
		var idx = clamp(mouth_style - 1, 0, total_frames - 1)
		var mouth_frame = mouth_sheet_img.get_region(Rect2i(idx * frame_w, 0, frame_w, frame_h))
		if mouth_frame and mouth_size.x > 0 and mouth_size.y > 0:
			mouth_frame.resize(mouth_size.x, mouth_size.y, Image.INTERPOLATE_BILINEAR)
			mouth_frame = _rotate_image_exact(mouth_frame, mouth_rot)
			_blit_alpha(face_img, mouth_frame, mouth_top_left)
			mouth_drawn = true

	if not mouth_drawn:
		_draw_procedural_mouth_style(face_img, mouth_center, mouth_style, Color(0.7, 0.25, 0.25), mouth_rot)

	# 4. Load Glasses directly onto Face Texture Map (Highest Layer Order!)
	if glasses_style > 0:
		var glasses_atlas_path = "res://assets/character_models/glasses/glasses_sprite.png"
		var glasses_atlas_img = _load_cpu_image(glasses_atlas_path)
		if glasses_atlas_img:
			if glasses_atlas_img.is_compressed():
				glasses_atlas_img.decompress()
			var frame_w = glasses_atlas_img.get_width() / 10
			var frame_h = glasses_atlas_img.get_height()
			if frame_w > 0 and frame_h > 0:
				var idx = clamp(glasses_style - 1, 0, 9)
				var rect = Rect2i(idx * frame_w, 0, frame_w, frame_h)
				var glass_frame = glasses_atlas_img.get_region(rect)
				var hd_glass_w = int(glass_w * scale_factor)
				var hd_glass_h = int(glass_h * scale_factor)
				if glass_frame and hd_glass_w > 0 and hd_glass_h > 0:
					glass_frame.resize(hd_glass_w, hd_glass_h, Image.INTERPOLATE_BILINEAR)
					glass_frame = _rotate_image_exact(glass_frame, glass_rot)
					var glass_center = Vector2i(512 + int(glass_x_off * scale_factor), int(eye_center.y) + int(glass_y_off * scale_factor))
					_blit_alpha(face_img, glass_frame, glass_center - Vector2i(hd_glass_w / 2, hd_glass_h / 2))

	return ImageTexture.create_from_image(face_img)

static func _draw_procedural_eye_style(dest: Image, center: Vector2i, radius: int, style: int, sclera: Color, pupil: Color, iris: Color, rot_deg: float, _is_left: bool) -> void:
	var rad = deg_to_rad(rot_deg)
	var cos_a = cos(rad)
	var sin_a = sin(rad)

	# Procedural style variations based on style index (1..60)
	var iris_ratio = clamp(0.40 + float(style % 5) * 0.08, 0.35, 0.75)
	var pupil_ratio = clamp(0.20 + float((style / 5) % 4) * 0.05, 0.15, 0.45)
	var pupil_shape_sq = (style % 3 == 0)

	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var rx = x * cos_a + y * sin_a
			var ry = -x * sin_a + y * cos_a

			var dist_sq = rx * rx + ry * ry
			if dist_sq <= radius * radius:
				var px = center.x + x
				var py = center.y + y
				if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
					var is_pupil = false
					if pupil_shape_sq:
						is_pupil = abs(rx) <= radius * pupil_ratio and abs(ry) <= radius * pupil_ratio
					else:
						is_pupil = dist_sq <= (radius * pupil_ratio) * (radius * pupil_ratio)

					if is_pupil:
						dest.set_pixel(px, py, pupil)
					elif dist_sq <= (radius * iris_ratio) * (radius * iris_ratio):
						dest.set_pixel(px, py, iris)
					else:
						dest.set_pixel(px, py, sclera)

static func _draw_procedural_nose_style(dest: Image, center: Vector2i, style: int, color: Color, rot_deg: float) -> void:
	var rad = deg_to_rad(rot_deg)
	var cos_a = cos(rad)
	var sin_a = sin(rad)
	var half_h = 16 + (style % 4) * 4

	for y in range(-half_h, half_h + 1):
		var progress = (float(y) + half_h) / (half_h * 2.0)
		var w = int((16.0 + float(style % 3) * 4.0) * (1.0 - progress * 0.6))
		for x in range(-w, w + 1):
			var rx = x * cos_a - y * sin_a
			var ry = x * sin_a + y * cos_a

			var px = center.x + int(rx)
			var py = center.y + int(ry)
			if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
				dest.set_pixel(px, py, color)

static func _draw_procedural_mouth_style(dest: Image, center: Vector2i, style: int, color: Color, rot_deg: float) -> void:
	var rad = deg_to_rad(rot_deg)
	var cos_a = cos(rad)
	var sin_a = sin(rad)
	var half_w = 20 + (style % 5) * 4

	for y in range(-6, 8):
		var progress = float(y + 6) / 14.0
		var w = int(float(half_w) * (1.0 - progress * 0.4))
		for x in range(-w, w + 1):
			var rx = x * cos_a - y * sin_a
			var ry = x * sin_a + y * cos_a

			var px = center.x + int(rx)
			var py = center.y + int(ry)
			if px >= 0 and px < dest.get_width() and py >= 0 and py < dest.get_height():
				dest.set_pixel(px, py, color)

static func _apply_chroma_and_blit(dest: Image, src: Image, pos: Vector2i, sclera: Color, pupil: Color, iris: Color) -> void:
	if src == null or dest == null:
		return
	if src.is_compressed():
		src.decompress()
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	if dest.is_compressed():
		dest.decompress()
	if dest.get_format() != Image.FORMAT_RGBA8:
		dest.convert(Image.FORMAT_RGBA8)

	var sw = src.get_width()
	var sh = src.get_height()
	var dw = dest.get_width()
	var dh = dest.get_height()
	if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0:
		return

	for y in range(sh):
		var dy = pos.y + y
		if dy < 0 or dy >= dh:
			continue
		for x in range(sw):
			var dx = pos.x + x
			if dx < 0 or dx >= dw:
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
	if src == null or dest == null:
		return
	if src.is_compressed():
		src.decompress()
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	if dest.is_compressed():
		dest.decompress()
	if dest.get_format() != Image.FORMAT_RGBA8:
		dest.convert(Image.FORMAT_RGBA8)

	var sw = src.get_width()
	var sh = src.get_height()
	var dw = dest.get_width()
	var dh = dest.get_height()
	if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0:
		return

	for y in range(sh):
		var dy = pos.y + y
		if dy < 0 or dy >= dh:
			continue
		for x in range(sw):
			var dx = pos.x + x
			if dx < 0 or dx >= dw:
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

static func attach_hair_to_character(avatar_root: Node3D, hair_style: int, hair_color: Color = Color.WHITE) -> Node3D:
	if not avatar_root:
		return null
	var mii = avatar_root.get_node_or_null("MiiAvatar") if avatar_root.name != "MiiAvatar" else avatar_root
	if not mii:
		mii = avatar_root

	var skeleton = mii.find_child("Armature", true, false) as Skeleton3D
	if not skeleton:
		skeleton = mii.find_child("*Skeleton*", true, false) as Skeleton3D
	if not skeleton:
		return null

	var head_attach = _get_or_create_head_bone_attachment(skeleton)
	if not head_attach:
		return null

	# Remove any existing hair nodes immediately
	var to_remove = []
	for child in head_attach.get_children():
		if child.name.begins_with("GLTFHair") or child.name.to_lower().contains("hair"):
			to_remove.append(child)

	var old_hairs = mii.find_children("*hair*", "Node3D", true, false)
	for h in old_hairs:
		if h != null and is_instance_valid(h) and not to_remove.has(h):
			to_remove.append(h)

	for node in to_remove:
		if is_instance_valid(node):
			var parent = node.get_parent()
			if parent:
				parent.remove_child(node)
			node.free()

	# Load hair GLTF
	var hair_path = "res://assets/character_models/hair/hair_%03d.gltf" % hair_style
	if not ResourceLoader.exists(hair_path):
		hair_path = "res://assets/character_models/hair/hair_000.gltf"

	var hair_gltf = _load_gltf(hair_path)
	if not hair_gltf:
		return null

	hair_gltf.name = "GLTFHair"
	var hair_key = "hair_%03d" % hair_style

	# Inherit exact anchoring metrics established by Model Aligner from model_presets.json
	_apply_item_transform(hair_gltf, "hair", hair_key, Vector3(0.0, 0.002, 0.0001), Vector3.ZERO, Vector3(0.0168, 0.0168, 0.0168))

	var hair_mat = _mat(hair_color)
	_set_node_material(hair_gltf, hair_mat)

	head_attach.add_child(hair_gltf)
	return hair_gltf

static func _build_player(root: Node3D) -> void:
	_build_character_from_dict(root, PlayerStore.customization)

static func _build_character_from_dict(root: Node3D, c: Dictionary) -> void:
	var idle_path = "res://assets/character_models/animations/idle.fbx"
	if not ResourceLoader.exists(idle_path):
		_build_fallback_player(root)
		return

	var idle_scene = load(idle_path) as PackedScene
	if not idle_scene:
		_build_fallback_player(root)
		return

	var avatar = idle_scene.instantiate() as Node3D
	avatar.name = "MiiAvatar"
	root.add_child(avatar)

	# Scale Mixamo rig if needed
	avatar.scale = Vector3(2.5, 2.5, 2.5)

	# 1. Setup AnimationPlayer and load animation tracks
	var anim_player = avatar.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_setup_mixamo_animations(anim_player)
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

	# 2. Material & Customization Mapping
	var skin_color: Color = c.get("skin_color", Color(0.92, 0.76, 0.65))
	var hair_color: Color = c.get("hair_color", Color(0.24, 0.16, 0.10))
	var shirt_color: Color = c.get("shirt_color", Color(0.95, 0.95, 0.95))
	var pants_color: Color = c.get("pants_color", Color(0.2, 0.2, 0.25))

	var face_tex = _create_face_texture(c)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color.WHITE
	head_mat.albedo_texture = face_tex
	head_mat.roughness = 0.85
	head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	var shirt_mat = _mat(shirt_color)
	var pants_mat = _mat(pants_color)
	var hair_mat = _mat(hair_color)

	# Flexible MeshInstance3D lookup matching Godot imported FBX node names
	var all_meshes = avatar.find_children("*", "MeshInstance3D", true, false)
	for child in all_meshes:
		var mi = child as MeshInstance3D
		var node_name = mi.name.to_lower()
		if "head" in node_name:
			mi.material_override = head_mat
		elif "001" in node_name or "pants" in node_name or "legs" in node_name:
			mi.material_override = pants_mat
		elif "body" in node_name or "shirt" in node_name or "torso" in node_name:
			mi.material_override = shirt_mat

	# 3. Skeleton & Attachments (Head, Hair & Glasses)
	var head_mesh = avatar.find_child("Head_Mesh", true, false) as MeshInstance3D
	var head_style: int = c.get("head_style", 1)

	var skeleton = avatar.find_child("Armature", true, false) as Skeleton3D
	if not skeleton:
		skeleton = avatar.find_child("*Skeleton*", true, false) as Skeleton3D

	if skeleton:
		var head_attach = _get_or_create_head_bone_attachment(skeleton)
		if head_attach:
			# Clear existing custom head nodes
			for child in head_attach.get_children():
				if child.name.begins_with("GLTFHead") or child.name.to_lower().contains("head"):
					head_attach.remove_child(child)
					child.free()

			if head_style == 1:
				# Base Head 1 uses rigged Head_Mesh on idle.fbx
				if head_mesh:
					head_mesh.visible = true
					head_mesh.material_override = head_mat
			else:
				# Custom Head styles 2..12
				if head_mesh:
					head_mesh.visible = false

				var head_path = "res://assets/character_models/heads/head_head_%03d.gltf" % head_style
				if ResourceLoader.exists(head_path):
					var head_gltf = _load_gltf(head_path)
					if head_gltf:
						head_gltf.name = "GLTFHead"
						var head_key = "head_%03d" % head_style
						_apply_item_transform(head_gltf, "heads", head_key, Vector3(0.0, 0.002, 0.0), Vector3.ZERO, Vector3(0.002, 0.002, 0.002))
						_set_node_material(head_gltf, head_mat)
						head_attach.add_child(head_gltf)

			# 3D Hair Attachment via dedicated attach_hair_to_character helper
			var hair_style: int = c.get("hair_style", 0)
			attach_hair_to_character(avatar, hair_style, hair_color)

			# Clear existing glasses nodes
			for child in head_attach.get_children():
				if child.name.begins_with("GLTFGlasses") or child.name.to_lower().contains("glasses"):
					head_attach.remove_child(child)
					child.free()

			# Glasses Attachment
			var glasses_style: int = c.get("glasses_style", 0)
			if glasses_style > 0:
				var glasses_path = "res://assets/character_models/glasses/glasses_glasses%d.gltf" % glasses_style
				if ResourceLoader.exists(glasses_path):
					var glasses_gltf = _load_gltf(glasses_path)
					if glasses_gltf:
						glasses_gltf.name = "GLTFGlasses"
						var glasses_key = "glasses_%d" % glasses_style
						_apply_item_transform(glasses_gltf, "glasses", glasses_key, Vector3(0.0, -0.02, 0.08), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
						head_attach.add_child(glasses_gltf)



static func _build_prof_adler(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.88, 0.74, 0.64),
		"shirt_color": Color(0.22, 0.24, 0.28),
		"pants_color": Color(0.22, 0.24, 0.28),
		"hair_color": Color(0.72, 0.74, 0.76),
		"hair_style": 2,
		"glasses_style": 1
	})

static func _build_daria(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.94, 0.78, 0.68),
		"shirt_color": Color(0.85, 0.58, 0.18),
		"pants_color": Color(0.20, 0.25, 0.35),
		"hair_color": Color(0.48, 0.24, 0.14),
		"hair_style": 1
	})

static func _build_ms_hartwell(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.90, 0.75, 0.66),
		"shirt_color": Color(0.12, 0.14, 0.18),
		"pants_color": Color(0.12, 0.14, 0.18),
		"hair_color": Color(0.14, 0.12, 0.12),
		"hair_style": 5
	})

static func _build_barista(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.86, 0.70, 0.58),
		"shirt_color": Color(0.40, 0.55, 0.68),
		"pants_color": Color(0.20, 0.20, 0.22),
		"hair_color": Color(0.20, 0.15, 0.10),
		"hair_style": 0
	})

static func _build_ms_okoro(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.62, 0.42, 0.28),
		"shirt_color": Color(0.55, 0.18, 0.24),
		"pants_color": Color(0.22, 0.22, 0.26),
		"hair_color": Color(0.12, 0.10, 0.10),
		"hair_style": 4,
		"glasses_style": 1
	})

static func _build_mr_vance(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.92, 0.77, 0.67),
		"shirt_color": Color(0.18, 0.28, 0.45),
		"pants_color": Color(0.52, 0.46, 0.38),
		"hair_color": Color(0.35, 0.25, 0.18),
		"hair_style": 3
	})

static func _build_felix(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.92, 0.75, 0.63),
		"shirt_color": Color(0.95, 0.42, 0.22),
		"pants_color": Color(0.30, 0.32, 0.36),
		"hair_color": Color(0.20, 0.15, 0.10),
		"hair_style": 3
	})

static func _build_priya(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.80, 0.62, 0.48),
		"shirt_color": Color(0.20, 0.28, 0.45),
		"pants_color": Color(0.32, 0.38, 0.28),
		"hair_color": Color(0.12, 0.10, 0.10),
		"hair_style": 5
	})

static func _build_nadia(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.90, 0.74, 0.65),
		"shirt_color": Color(0.60, 0.52, 0.65),
		"pants_color": Color(0.60, 0.52, 0.65),
		"hair_color": Color(0.16, 0.14, 0.14),
		"hair_style": 1
	})

static func _build_tomas(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.88, 0.72, 0.60),
		"shirt_color": Color(0.68, 0.82, 0.92),
		"pants_color": Color(0.22, 0.24, 0.28),
		"hair_color": Color(0.18, 0.14, 0.12),
		"hair_style": 0
	})

static func _build_seren(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.92, 0.77, 0.68),
		"shirt_color": Color(0.88, 0.84, 0.76),
		"pants_color": Color(0.20, 0.22, 0.26),
		"hair_color": Color(0.55, 0.35, 0.20),
		"hair_style": 0,
		"glasses_style": 1
	})

static func _build_sibling(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.94, 0.78, 0.68),
		"shirt_color": Color(0.95, 0.95, 0.95),
		"pants_color": Color(0.25, 0.40, 0.65),
		"hair_color": Color(0.42, 0.26, 0.16),
		"hair_style": 0
	})

static func _build_parent(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.90, 0.75, 0.64),
		"shirt_color": Color(0.35, 0.52, 0.68),
		"pants_color": Color(0.70, 0.68, 0.62),
		"hair_color": Color(0.60, 0.58, 0.56),
		"hair_style": 0
	})

static func _build_stranger(root: Node3D) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.85, 0.70, 0.60),
		"shirt_color": Color(0.15, 0.16, 0.18),
		"pants_color": Color(0.15, 0.16, 0.18),
		"hair_color": Color(0.10, 0.10, 0.12),
		"hair_style": 0
	})

static func _build_generic(root: Node3D, _character_id: String) -> void:
	_build_character_from_dict(root, {
		"skin_color": Color(0.88, 0.74, 0.64),
		"shirt_color": Color(0.45, 0.50, 0.55),
		"pants_color": Color(0.25, 0.28, 0.32),
		"hair_color": Color(0.30, 0.20, 0.15),
		"hair_style": 0
	})
