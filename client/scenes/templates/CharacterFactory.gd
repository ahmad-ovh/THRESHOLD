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

static func _add_base_humanoid(
	root: Node3D,
	skin_mat: Material,
	shirt_mat: Material,
	pants_mat: Material,
	shoes_mat: Material
) -> void:
	# Feet / Shoes
	root.add_child(_box(Vector3(0.14, 0.12, 0.24), Vector3(-0.15, 0.06, 0.03), shoes_mat))
	root.add_child(_box(Vector3(0.14, 0.12, 0.24), Vector3(0.15, 0.06, 0.03), shoes_mat))

	# Legs
	root.add_child(_cylinder(0.08, 0.60, Vector3(-0.15, 0.42, 0.0), pants_mat))
	root.add_child(_cylinder(0.08, 0.60, Vector3(0.15, 0.42, 0.0), pants_mat))

	# Pelvis
	root.add_child(_box(Vector3(0.40, 0.12, 0.24), Vector3(0.0, 0.76, 0.0), pants_mat))

	# Torso (depth 0.26 -> front at Z = +0.13, back at Z = -0.13)
	root.add_child(_box(Vector3(0.44, 0.58, 0.26), Vector3(0.0, 1.11, 0.0), shirt_mat))

	# Arms & Hands
	root.add_child(_cylinder(0.06, 0.46, Vector3(-0.27, 1.05, 0.0), shirt_mat))
	root.add_child(_cylinder(0.06, 0.46, Vector3(0.27, 1.05, 0.0), shirt_mat))
	root.add_child(_sphere(0.06, Vector3(-0.27, 0.76, 0.0), skin_mat))
	root.add_child(_sphere(0.06, Vector3(0.27, 0.76, 0.0), skin_mat))

	# Neck & Head
	root.add_child(_cylinder(0.06, 0.10, Vector3(0.0, 1.45, 0.0), skin_mat))
	root.add_child(_sphere(0.19, Vector3(0.0, 1.61, 0.0), skin_mat))

	# Eyes (Placed outside head sphere surface to prevent Z-fighting)
	var eye_mat = _mat(Color(0.15, 0.15, 0.18), 0.3)
	root.add_child(_sphere(0.035, Vector3(-0.07, 1.63, 0.195), eye_mat))
	root.add_child(_sphere(0.035, Vector3(0.07, 1.63, 0.195), eye_mat))

static func _build_player(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.76, 0.65))
	var shirt_mat = _mat(Color(0.95, 0.95, 0.95))
	var jacket_mat = _mat(Color(0.14, 0.48, 0.55))
	var pants_mat = _mat(Color(0.18, 0.26, 0.42))
	var shoes_mat = _mat(Color(0.90, 0.90, 0.92))
	var hair_mat = _mat(Color(0.24, 0.16, 0.10))
	var backpack_mat = _mat(Color(0.80, 0.22, 0.20))

	_add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	# Open Teal Jacket (depth 0.30 -> front Z=0.15, back Z=-0.15, no Z-fighting with torso)
	root.add_child(_box(Vector3(0.22, 0.60, 0.30), Vector3(-0.13, 1.11, 0.0), jacket_mat))
	root.add_child(_box(Vector3(0.22, 0.60, 0.30), Vector3(0.13, 1.11, 0.0), jacket_mat))

	# Backpack (pos Z=-0.23, depth 0.16 -> Z range [-0.31, -0.15], clear of torso back at -0.13)
	root.add_child(_box(Vector3(0.34, 0.42, 0.16), Vector3(0.0, 1.14, -0.23), backpack_mat))
	root.add_child(_box(Vector3(0.05, 0.45, 0.08), Vector3(-0.14, 1.14, 0.15), backpack_mat))
	root.add_child(_box(Vector3(0.05, 0.45, 0.08), Vector3(0.14, 1.14, 0.15), backpack_mat))

	# Hair (Messy stylish swoop)
	root.add_child(_sphere(0.21, Vector3(0.0, 1.66, -0.02), hair_mat))
	root.add_child(_box(Vector3(0.22, 0.08, 0.14), Vector3(0.04, 1.77, 0.09), hair_mat, Vector3(0, 0, -15)))

static func _build_prof_adler(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.88, 0.74, 0.64))
	var shirt_mat = _mat(Color(0.92, 0.94, 0.96))
	var suit_mat = _mat(Color(0.22, 0.24, 0.28))
	var tie_mat = _mat(Color(0.55, 0.12, 0.15))
	var shoes_mat = _mat(Color(0.12, 0.10, 0.08))
	var hair_mat = _mat(Color(0.72, 0.74, 0.76))
	var glass_mat = _mat(Color(0.1, 0.1, 0.1), 0.1, 0.9)

	_add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	# Vest & Tie (Layered depth: vest 0.29, tie 0.32)
	root.add_child(_box(Vector3(0.26, 0.54, 0.29), Vector3(0.0, 1.11, 0.0), suit_mat))
	root.add_child(_box(Vector3(0.08, 0.40, 0.32), Vector3(0.0, 1.15, 0.0), tie_mat))

	# Combed Silver Hair
	root.add_child(_box(Vector3(0.38, 0.14, 0.38), Vector3(0.0, 1.73, -0.02), hair_mat))

	# Glasses (Placed at Z = 0.23 outside eyes)
	root.add_child(_box(Vector3(0.12, 0.05, 0.02), Vector3(-0.07, 1.64, 0.23), glass_mat))
	root.add_child(_box(Vector3(0.12, 0.05, 0.02), Vector3(0.07, 1.64, 0.23), glass_mat))
	root.add_child(_box(Vector3(0.06, 0.02, 0.02), Vector3(0.0, 1.64, 0.23), glass_mat))

static func _build_daria(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.94, 0.78, 0.68))
	var sweater_mat = _mat(Color(0.85, 0.58, 0.18))
	var scarf_mat = _mat(Color(0.72, 0.22, 0.18))
	var pants_mat = _mat(Color(0.20, 0.25, 0.35))
	var boots_mat = _mat(Color(0.35, 0.22, 0.15))
	var hair_mat = _mat(Color(0.48, 0.24, 0.14))

	_add_base_humanoid(root, skin_mat, sweater_mat, pants_mat, boots_mat)

	# Scarf
	root.add_child(_torus(0.13, 0.05, Vector3(0.0, 1.42, 0.0), scarf_mat))

	# Auburn Bob Hair
	root.add_child(_sphere(0.225, Vector3(0.0, 1.65, -0.02), hair_mat))
	root.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(-0.18, 1.56, 0.04), hair_mat))
	root.add_child(_box(Vector3(0.10, 0.28, 0.16), Vector3(0.18, 1.56, 0.04), hair_mat))

static func _build_ms_hartwell(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.75, 0.66))
	var suit_mat = _mat(Color(0.12, 0.14, 0.18))
	var blouse_mat = _mat(Color(0.10, 0.55, 0.45))
	var shoes_mat = _mat(Color(0.08, 0.08, 0.10))
	var hair_mat = _mat(Color(0.14, 0.12, 0.12))

	_add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	# Emerald Collar / V-neck (depth 0.29 vs torso 0.26)
	root.add_child(_box(Vector3(0.16, 0.32, 0.29), Vector3(0.0, 1.20, 0.0), blouse_mat))

	# High Bun Hair
	root.add_child(_sphere(0.20, Vector3(0.0, 1.64, -0.02), hair_mat))
	root.add_child(_sphere(0.09, Vector3(0.0, 1.83, -0.08), hair_mat))

static func _build_barista(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.86, 0.70, 0.58))
	var shirt_mat = _mat(Color(0.40, 0.55, 0.68))
	var apron_mat = _mat(Color(0.30, 0.20, 0.14))
	var pants_mat = _mat(Color(0.20, 0.20, 0.22))
	var shoes_mat = _mat(Color(0.25, 0.18, 0.14))
	var cap_mat = _mat(Color(0.18, 0.32, 0.22))

	_add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	# Apron front & bib (depth 0.30 vs torso 0.26)
	root.add_child(_box(Vector3(0.36, 0.48, 0.30), Vector3(0.0, 1.05, 0.0), apron_mat))
	root.add_child(_box(Vector3(0.38, 0.40, 0.28), Vector3(0.0, 0.65, 0.0), apron_mat))

	# Barista Cap with visor
	root.add_child(_sphere(0.21, Vector3(0.0, 1.68, 0.0), cap_mat))
	root.add_child(_box(Vector3(0.26, 0.03, 0.12), Vector3(0.0, 1.69, 0.21), cap_mat, Vector3(10, 0, 0)))

static func _build_ms_okoro(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.62, 0.42, 0.28))
	var cardigan_mat = _mat(Color(0.55, 0.18, 0.24))
	var blouse_mat = _mat(Color(0.94, 0.90, 0.82))
	var skirt_mat = _mat(Color(0.22, 0.22, 0.26))
	var shoes_mat = _mat(Color(0.15, 0.12, 0.14))
	var hair_mat = _mat(Color(0.12, 0.10, 0.10))
	var glass_mat = _mat(Color(0.70, 0.50, 0.20), 0.2, 0.8)

	_add_base_humanoid(root, skin_mat, cardigan_mat, skirt_mat, shoes_mat)

	# Blouse inner (depth 0.29)
	root.add_child(_box(Vector3(0.18, 0.44, 0.29), Vector3(0.0, 1.12, 0.0), blouse_mat))

	# Voluminous Curly Hair
	root.add_child(_sphere(0.26, Vector3(0.0, 1.66, -0.04), hair_mat))

	# Tortoiseshell Glasses (Z = 0.22)
	root.add_child(_sphere(0.06, Vector3(-0.07, 1.64, 0.22), glass_mat))
	root.add_child(_sphere(0.06, Vector3(0.07, 1.64, 0.22), glass_mat))

static func _build_mr_vance(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.77, 0.67))
	var shirt_mat = _mat(Color(0.85, 0.88, 0.92))
	var vest_mat = _mat(Color(0.18, 0.28, 0.45))
	var tie_mat = _mat(Color(0.65, 0.20, 0.18))
	var pants_mat = _mat(Color(0.52, 0.46, 0.38))
	var shoes_mat = _mat(Color(0.28, 0.18, 0.12))
	var hair_mat = _mat(Color(0.35, 0.25, 0.18))

	_add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	# Navy Vest & Tie (Vest depth 0.29, tie depth 0.32)
	root.add_child(_box(Vector3(0.44, 0.52, 0.29), Vector3(0.0, 1.08, 0.0), vest_mat))
	root.add_child(_box(Vector3(0.07, 0.42, 0.32), Vector3(0.0, 1.14, 0.0), tie_mat))

	# Short neat hair
	root.add_child(_sphere(0.20, Vector3(0.0, 1.65, -0.02), hair_mat))

static func _build_felix(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.75, 0.63))
	var hoodie_mat = _mat(Color(0.95, 0.42, 0.22))
	var pants_mat = _mat(Color(0.30, 0.32, 0.36))
	var sneakers_mat = _mat(Color(0.88, 0.18, 0.22))
	var beanie_mat = _mat(Color(0.18, 0.18, 0.20))

	_add_base_humanoid(root, skin_mat, hoodie_mat, pants_mat, sneakers_mat)

	# Hoodie pocket & hood fold
	root.add_child(_box(Vector3(0.32, 0.20, 0.30), Vector3(0.0, 0.95, 0.0), hoodie_mat))
	root.add_child(_torus(0.13, 0.05, Vector3(0.0, 1.40, -0.09), hoodie_mat))

	# Beanie
	root.add_child(_sphere(0.21, Vector3(0.0, 1.68, 0.0), beanie_mat))

static func _build_priya(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.80, 0.62, 0.48))
	var jacket_mat = _mat(Color(0.20, 0.28, 0.45))
	var top_mat = _mat(Color(0.15, 0.15, 0.15))
	var scarf_mat = _mat(Color(0.18, 0.55, 0.58))
	var pants_mat = _mat(Color(0.32, 0.38, 0.28))
	var boots_mat = _mat(Color(0.15, 0.15, 0.15))
	var hair_mat = _mat(Color(0.12, 0.10, 0.10))

	_add_base_humanoid(root, skin_mat, jacket_mat, pants_mat, boots_mat)

	root.add_child(_box(Vector3(0.18, 0.45, 0.29), Vector3(0.0, 1.12, 0.0), top_mat))
	root.add_child(_torus(0.12, 0.04, Vector3(0.0, 1.42, 0.0), scarf_mat))

	# Ponytail
	root.add_child(_sphere(0.20, Vector3(0.0, 1.63, -0.02), hair_mat))
	root.add_child(_cylinder(0.05, 0.28, Vector3(0.0, 1.55, -0.20), hair_mat, Vector3(-30, 0, 0)))

static func _build_nadia(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.74, 0.65))
	var suit_mat = _mat(Color(0.60, 0.52, 0.65))
	var top_mat = _mat(Color(0.95, 0.95, 0.95))
	var shoes_mat = _mat(Color(0.20, 0.18, 0.22))
	var hair_mat = _mat(Color(0.16, 0.14, 0.14))

	_add_base_humanoid(root, skin_mat, suit_mat, suit_mat, shoes_mat)

	root.add_child(_box(Vector3(0.18, 0.44, 0.29), Vector3(0.0, 1.12, 0.0), top_mat))
	root.add_child(_sphere(0.21, Vector3(0.0, 1.64, -0.02), hair_mat))
	root.add_child(_box(Vector3(0.08, 0.45, 0.16), Vector3(-0.17, 1.45, -0.02), hair_mat))
	root.add_child(_box(Vector3(0.08, 0.45, 0.16), Vector3(0.17, 1.45, -0.02), hair_mat))

static func _build_tomas(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.88, 0.72, 0.60))
	var shirt_mat = _mat(Color(0.68, 0.82, 0.92))
	var pants_mat = _mat(Color(0.22, 0.24, 0.28))
	var belt_mat = _mat(Color(0.25, 0.16, 0.10))
	var shoes_mat = _mat(Color(0.20, 0.14, 0.10))
	var hair_mat = _mat(Color(0.18, 0.14, 0.12))

	_add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)

	# Belt
	root.add_child(_box(Vector3(0.44, 0.06, 0.28), Vector3(0.0, 0.81, 0.0), belt_mat))
	root.add_child(_sphere(0.19, Vector3(0.0, 1.64, -0.02), hair_mat))

static func _build_seren(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.92, 0.77, 0.68))
	var coat_mat = _mat(Color(0.88, 0.84, 0.76))
	var inner_mat = _mat(Color(0.18, 0.18, 0.20))
	var pants_mat = _mat(Color(0.20, 0.22, 0.26))
	var boots_mat = _mat(Color(0.22, 0.15, 0.12))
	var hair_mat = _mat(Color(0.55, 0.35, 0.20))
	var glass_mat = _mat(Color(0.15, 0.15, 0.15), 0.1, 0.9)

	_add_base_humanoid(root, skin_mat, coat_mat, pants_mat, boots_mat)

	# Inner turtleneck
	root.add_child(_box(Vector3(0.20, 0.46, 0.29), Vector3(0.0, 1.14, 0.0), inner_mat))

	# Hair & Glasses
	root.add_child(_sphere(0.21, Vector3(0.0, 1.65, -0.02), hair_mat))
	root.add_child(_box(Vector3(0.10, 0.04, 0.02), Vector3(-0.06, 1.64, 0.23), glass_mat))
	root.add_child(_box(Vector3(0.10, 0.04, 0.02), Vector3(0.06, 1.64, 0.23), glass_mat))

static func _build_sibling(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.94, 0.78, 0.68))
	var tshirt_mat = _mat(Color(0.95, 0.95, 0.95))
	var pants_mat = _mat(Color(0.25, 0.40, 0.65))
	var shoes_mat = _mat(Color(0.95, 0.80, 0.18))
	var hair_mat = _mat(Color(0.42, 0.26, 0.16))

	_add_base_humanoid(root, skin_mat, tshirt_mat, pants_mat, shoes_mat)

	root.add_child(_sphere(0.20, Vector3(0.0, 1.64, -0.02), hair_mat))

static func _build_parent(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.90, 0.75, 0.64))
	var cardigan_mat = _mat(Color(0.35, 0.52, 0.68))
	var pants_mat = _mat(Color(0.70, 0.68, 0.62))
	var shoes_mat = _mat(Color(0.45, 0.38, 0.32))
	var hair_mat = _mat(Color(0.60, 0.58, 0.56))

	_add_base_humanoid(root, skin_mat, cardigan_mat, pants_mat, shoes_mat)

	root.add_child(_sphere(0.21, Vector3(0.0, 1.64, -0.02), hair_mat))

static func _build_stranger(root: Node3D) -> void:
	var skin_mat = _mat(Color(0.85, 0.70, 0.60))
	var coat_mat = _mat(Color(0.15, 0.16, 0.18))
	var boots_mat = _mat(Color(0.08, 0.08, 0.10))
	var hat_mat = _mat(Color(0.10, 0.10, 0.12))

	_add_base_humanoid(root, skin_mat, coat_mat, coat_mat, boots_mat)

	# Overcoat length
	root.add_child(_box(Vector3(0.48, 0.50, 0.30), Vector3(0.0, 0.65, 0.0), coat_mat))

	# Fedora Hat
	root.add_child(_cylinder(0.30, 0.04, Vector3(0.0, 1.73, 0.0), hat_mat))
	root.add_child(_cylinder(0.19, 0.16, Vector3(0.0, 1.83, 0.0), hat_mat))

static func _build_generic(root: Node3D, character_id: String) -> void:
	var skin_mat = _mat(Color(0.88, 0.74, 0.64))
	var shirt_mat = _mat(Color(0.45, 0.50, 0.55))
	var pants_mat = _mat(Color(0.25, 0.28, 0.32))
	var shoes_mat = _mat(Color(0.20, 0.18, 0.16))
	var hair_mat = _mat(Color(0.30, 0.20, 0.15))

	_add_base_humanoid(root, skin_mat, shirt_mat, pants_mat, shoes_mat)
	root.add_child(_sphere(0.20, Vector3(0.0, 1.64, -0.02), hair_mat))
