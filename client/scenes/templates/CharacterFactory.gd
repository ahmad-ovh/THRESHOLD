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
	head_pivot.add_child(_sphere(0.19, Vector3(0.0, 0.16, 0.0), skin_mat))

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

static func _build_player(root: Node3D) -> void:
	var c = PlayerStore.customization
	var skin_color: Color = c.get("skin_color", Color(0.92, 0.76, 0.65))
	var skin_mat = _mat(skin_color)
	var shirt_mat = _mat(Color(0.95, 0.95, 0.95))
	var jacket_mat = _mat(Color(0.14, 0.48, 0.55))
	var pants_mat = _mat(Color(0.18, 0.26, 0.42))
	var shoes_mat = _mat(Color(0.90, 0.90, 0.92))
	var hair_color: Color = c.get("hair_color", Color(0.24, 0.16, 0.10))
	var hair_mat = _mat(hair_color)

	var rig = _add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat, false)
	var head_pivot = rig.head_pivot

	# --- Eyes with Chroma Key Shader ---
	var eye_style: int = c.get("eye_style", 1)
	var sclera_col: Color = c.get("eye_sclera_color", Color(1.0, 1.0, 1.0))
	var pupil_col: Color = c.get("eye_pupil_color", Color(0.1, 0.1, 0.1))
	var iris_col: Color = c.get("eye_iris_color", Color(0.18, 0.55, 0.85))

	var eye_l_path = "res://resources/character_customization/eyes/eye_%02d_L.png" % eye_style
	var eye_r_path = "res://resources/character_customization/eyes/eye_%02d_R.png" % eye_style

	if not ResourceLoader.exists(eye_l_path):
		eye_l_path = "res://resources/character_customization/eyes/eye_01_L.png"
	if not ResourceLoader.exists(eye_r_path):
		eye_r_path = "res://resources/character_customization/eyes/eye_01_R.png"

	var tex_l = load(eye_l_path)
	var tex_r = load(eye_r_path)
	var chroma_shader = load("res://resources/character_customization/eye_chroma.gdshader")

	if chroma_shader and tex_l:
		var mat_l = ShaderMaterial.new()
		mat_l.shader = chroma_shader
		mat_l.set_shader_parameter("eye_texture", tex_l)
		mat_l.set_shader_parameter("sclera_color", sclera_col)
		mat_l.set_shader_parameter("pupil_color", pupil_col)
		mat_l.set_shader_parameter("iris_color", iris_col)
		head_pivot.add_child(_face_plane(Vector2(0.11, 0.11), Vector3(-0.075, 0.18, 0.192), mat_l))

	if chroma_shader and tex_r:
		var mat_r = ShaderMaterial.new()
		mat_r.shader = chroma_shader
		mat_r.set_shader_parameter("eye_texture", tex_r)
		mat_r.set_shader_parameter("sclera_color", sclera_col)
		mat_r.set_shader_parameter("pupil_color", pupil_col)
		mat_r.set_shader_parameter("iris_color", iris_col)
		head_pivot.add_child(_face_plane(Vector2(0.11, 0.11), Vector3(0.075, 0.18, 0.192), mat_r))

	# --- Nose ---
	var nose_style: int = c.get("nose_style", 1)
	var nose_path = "res://resources/character_customization/noses/nose_%02d.png" % nose_style
	if not ResourceLoader.exists(nose_path):
		nose_path = "res://resources/character_customization/noses/nose_01.png"
	var nose_tex = load(nose_path)
	if nose_tex:
		var nose_mat = StandardMaterial3D.new()
		nose_mat.albedo_texture = nose_tex
		nose_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		nose_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		nose_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		head_pivot.add_child(_face_plane(Vector2(0.08, 0.08), Vector3(0.0, 0.125, 0.194), nose_mat))

	# --- Mouth ---
	var mouth_style: int = c.get("mouth_style", 1)
	var mouth_path = "res://resources/character_customization/mouths/mouth_mask_%02d.png" % mouth_style
	if not ResourceLoader.exists(mouth_path):
		mouth_path = "res://resources/character_customization/mouths/mouth_mask_01.png"
	var mouth_tex = load(mouth_path)
	if mouth_tex:
		var mouth_mat = StandardMaterial3D.new()
		mouth_mat.albedo_texture = mouth_tex
		mouth_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mouth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mouth_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		head_pivot.add_child(_face_plane(Vector2(0.10, 0.08), Vector3(0.0, 0.065, 0.193), mouth_mat))

	# --- Hair ---
	var hair_style: int = c.get("hair_style", 0)
	_add_hair_style(head_pivot, hair_style, hair_mat)

	# --- Accessories ---
	var acc_style: int = c.get("accessory_style", 0)
	_add_accessory(rig.body_pivot, head_pivot, acc_style)

	# Open Teal Jacket
	rig.body_pivot.add_child(_box(Vector3(0.22, 0.60, 0.30), Vector3(-0.13, 0.35, 0.0), jacket_mat))
	rig.body_pivot.add_child(_box(Vector3(0.22, 0.60, 0.30), Vector3(0.13, 0.35, 0.0), jacket_mat))

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
