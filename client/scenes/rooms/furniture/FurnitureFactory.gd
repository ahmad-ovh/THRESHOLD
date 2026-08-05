class_name FurnitureFactory
extends Object

static func _mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat

static func create_chair(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	# Seat
	var seat = CSGBox3D.new()
	seat.size = Vector3(0.5, 0.05, 0.5)
	seat.position = Vector3(0, 0.45, 0)
	seat.material = mat
	seat.use_collision = true
	root.add_child(seat)
	
	# Back
	var back = CSGBox3D.new()
	back.size = Vector3(0.45, 0.4, 0.05)
	back.position = Vector3(0, 0.7, -0.22)
	back.material = mat
	root.add_child(back)
	
	# Legs
	for i in range(4):
		var leg = CSGBox3D.new()
		leg.size = Vector3(0.04, 0.45, 0.04)
		var lx = 0.22 if i % 2 == 0 else -0.22
		var lz = 0.22 if i < 2 else -0.22
		leg.position = Vector3(lx, 0.225, lz)
		leg.material = mat
		root.add_child(leg)
		
	return root

static func create_couch(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var base = CSGBox3D.new()
	base.size = Vector3(2.0, 0.3, 0.8)
	base.position = Vector3(0, 0.15, 0)
	base.material = mat
	base.use_collision = true
	root.add_child(base)
	
	var seat = CSGBox3D.new()
	seat.size = Vector3(1.6, 0.15, 0.7)
	seat.position = Vector3(0, 0.375, 0.05)
	seat.material = mat
	root.add_child(seat)
	
	var back = CSGBox3D.new()
	back.size = Vector3(2.0, 0.5, 0.2)
	back.position = Vector3(0, 0.55, -0.3)
	back.material = mat
	root.add_child(back)
	
	var armL = CSGBox3D.new()
	armL.size = Vector3(0.2, 0.3, 0.8)
	armL.position = Vector3(-0.9, 0.45, 0)
	armL.material = mat
	root.add_child(armL)
	
	var armR = CSGBox3D.new()
	armR.size = Vector3(0.2, 0.3, 0.8)
	armR.position = Vector3(0.9, 0.45, 0)
	armR.material = mat
	root.add_child(armR)
	
	return root

static func create_bench(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var seat = CSGBox3D.new()
	seat.size = Vector3(2.0, 0.08, 0.5)
	seat.position = Vector3(0, 0.45, 0)
	seat.material = mat
	seat.use_collision = true
	root.add_child(seat)
	
	var legL = CSGBox3D.new()
	legL.size = Vector3(0.08, 0.45, 0.4)
	legL.position = Vector3(-0.8, 0.225, 0)
	legL.material = mat
	root.add_child(legL)
	
	var legR = CSGBox3D.new()
	legR.size = Vector3(0.08, 0.45, 0.4)
	legR.position = Vector3(0.8, 0.225, 0)
	legR.material = mat
	root.add_child(legR)
	
	return root

static func create_patio_chair(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var seat = CSGBox3D.new()
	seat.size = Vector3(0.5, 0.05, 0.5)
	seat.position = Vector3(0, 0.4, 0)
	seat.material = mat
	seat.use_collision = true
	root.add_child(seat)
	
	var back = CSGBox3D.new()
	back.size = Vector3(0.45, 0.4, 0.05)
	back.position = Vector3(0, 0.65, -0.22)
	back.rotation_degrees = Vector3(10, 0, 0)
	back.material = mat
	root.add_child(back)
	
	for i in range(4):
		var leg = CSGCylinder3D.new()
		leg.radius = 0.02
		leg.height = 0.4
		var lx = 0.22 if i % 2 == 0 else -0.22
		var lz = 0.22 if i < 2 else -0.22
		leg.position = Vector3(lx, 0.2, lz)
		leg.material = mat
		root.add_child(leg)
		
	return root

static func create_desk(color: Color, scale_mult: float = 1.0) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var width = 1.4 * scale_mult
	var depth = 0.7 * scale_mult
	var height = 0.78
	
	var top = CSGBox3D.new()
	top.size = Vector3(width, 0.05, depth)
	top.position = Vector3(0, height, 0)
	top.material = mat
	top.use_collision = true
	root.add_child(top)
	
	for i in range(4):
		var leg = CSGBox3D.new()
		leg.size = Vector3(0.06, height, 0.06)
		var lx = (width/2 - 0.06) if i % 2 == 0 else -(width/2 - 0.06)
		var lz = (depth/2 - 0.06) if i < 2 else -(depth/2 - 0.06)
		leg.position = Vector3(lx, height/2, lz)
		leg.material = mat
		root.add_child(leg)
		
	return root

static func create_round_table(color: Color, scale_mult: float = 1.0) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var radius = 0.4 * scale_mult
	var height = 0.75
	
	var top = CSGCylinder3D.new()
	top.radius = radius
	top.height = 0.05
	top.position = Vector3(0, height, 0)
	top.material = mat
	top.use_collision = true
	root.add_child(top)
	
	var ped = CSGCylinder3D.new()
	ped.radius = 0.06
	ped.height = height
	ped.position = Vector3(0, height/2, 0)
	ped.material = mat
	root.add_child(ped)
	
	var base = CSGCylinder3D.new()
	base.radius = 0.25 * scale_mult
	base.height = 0.03
	base.position = Vector3(0, 0.015, 0)
	base.material = mat
	root.add_child(base)
	
	return root

static func create_coffee_table(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var width = 1.0
	var depth = 0.5
	var height = 0.4
	
	var top = CSGBox3D.new()
	top.size = Vector3(width, 0.05, depth)
	top.position = Vector3(0, height, 0)
	top.material = mat
	top.use_collision = true
	root.add_child(top)
	
	for i in range(4):
		var leg = CSGBox3D.new()
		leg.size = Vector3(0.05, height, 0.05)
		var lx = (width/2 - 0.05) if i % 2 == 0 else -(width/2 - 0.05)
		var lz = (depth/2 - 0.05) if i < 2 else -(depth/2 - 0.05)
		leg.position = Vector3(lx, height/2, lz)
		leg.material = mat
		root.add_child(leg)
		
	return root

static func create_counter(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var width = 3.0
	var depth = 0.7
	var height = 1.0
	
	var base = CSGBox3D.new()
	base.size = Vector3(width, height - 0.05, depth - 0.1)
	base.position = Vector3(0, (height - 0.05)/2, 0)
	base.material = mat
	base.use_collision = true
	root.add_child(base)
	
	var top = CSGBox3D.new()
	top.size = Vector3(width + 0.1, 0.05, depth)
	top.position = Vector3(0, height, 0)
	top.material = mat
	root.add_child(top)
	
	return root

static func create_shelf(color: Color, content_color: Color = Color.WHITE) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	var cmat = _mat(content_color)
	
	var width = 1.2
	var depth = 0.3
	var height = 2.0
	
	var back = CSGBox3D.new()
	back.size = Vector3(width, height, 0.02)
	back.position = Vector3(0, height/2, -depth/2 + 0.01)
	back.material = mat
	back.use_collision = true
	root.add_child(back)
	
	var sideL = CSGBox3D.new()
	sideL.size = Vector3(0.04, height, depth)
	sideL.position = Vector3(-width/2 + 0.02, height/2, 0)
	sideL.material = mat
	root.add_child(sideL)
	
	var sideR = CSGBox3D.new()
	sideR.size = Vector3(0.04, height, depth)
	sideR.position = Vector3(width/2 - 0.02, height/2, 0)
	sideR.material = mat
	root.add_child(sideR)
	
	var shelves = 4
	for i in range(shelves + 1):
		var sh = CSGBox3D.new()
		sh.size = Vector3(width, 0.04, depth)
		sh.position = Vector3(0, i * (height/shelves), 0)
		if i == shelves:
			sh.position.y -= 0.02
		sh.material = mat
		root.add_child(sh)
		
		# Add fake books on some shelves
		if i > 0 and i < shelves:
			var books = CSGBox3D.new()
			books.size = Vector3(width * 0.7, 0.25, 0.2)
			books.position = Vector3(0, i * (height/shelves) + 0.14, 0.02)
			books.material = cmat
			root.add_child(books)
			
	return root

static func create_cabinet(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var width = 0.5
	var depth = 0.5
	var height = 0.8
	
	var base = CSGBox3D.new()
	base.size = Vector3(width, height, depth)
	base.position = Vector3(0, height/2, 0)
	base.material = mat
	base.use_collision = true
	root.add_child(base)
	
	# Handles
	var handle_mat = _mat(Color(0.8, 0.8, 0.8))
	for i in range(2):
		var handle = CSGBox3D.new()
		handle.size = Vector3(0.15, 0.02, 0.03)
		handle.position = Vector3(0, height * 0.7 - i * (height/2), depth/2 + 0.015)
		handle.material = handle_mat
		root.add_child(handle)
		
		# Drawer split line
		var line = CSGBox3D.new()
		line.size = Vector3(width, 0.01, 0.01)
		line.position = Vector3(0, height * 0.5, depth/2 + 0.005)
		line.material = _mat(Color.BLACK)
		root.add_child(line)
		
	return root

static func create_desk_lamp(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var base = CSGCylinder3D.new()
	base.radius = 0.08
	base.height = 0.02
	base.position = Vector3(0, 0.01, 0)
	base.material = mat
	root.add_child(base)
	
	var arm = CSGCylinder3D.new()
	arm.radius = 0.01
	arm.height = 0.3
	arm.position = Vector3(0, 0.15, 0)
	arm.rotation_degrees = Vector3(15, 0, 0)
	arm.material = mat
	root.add_child(arm)
	
	var shade = CSGCylinder3D.new()
	shade.radius = 0.06
	shade.height = 0.1
	shade.cone = true
	shade.position = Vector3(0, 0.3, 0.05)
	shade.rotation_degrees = Vector3(-30, 0, 0)
	shade.material = mat
	root.add_child(shade)
	
	return root

static func create_floor_lamp(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var base = CSGCylinder3D.new()
	base.radius = 0.15
	base.height = 0.03
	base.position = Vector3(0, 0.015, 0)
	base.material = mat
	base.use_collision = true
	root.add_child(base)
	
	var pole = CSGCylinder3D.new()
	pole.radius = 0.02
	pole.height = 1.4
	pole.position = Vector3(0, 0.7, 0)
	pole.material = mat
	root.add_child(pole)
	
	var shade = CSGCylinder3D.new()
	shade.radius = 0.2
	shade.height = 0.25
	shade.position = Vector3(0, 1.4, 0)
	shade.material = _mat(Color(0.9, 0.9, 0.8)) # warm shade
	root.add_child(shade)
	
	return root

static func create_pendant_lamp(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var rod = CSGCylinder3D.new()
	rod.radius = 0.01
	rod.height = 0.3
	rod.position = Vector3(0, -0.15, 0)
	rod.material = _mat(Color.BLACK)
	root.add_child(rod)
	
	var shade = CSGCylinder3D.new()
	shade.radius = 0.2
	shade.height = 0.15
	shade.cone = true
	shade.position = Vector3(0, -0.3, 0)
	shade.material = mat
	root.add_child(shade)
	
	return root

static func create_board(color: Color, width: float = 2.0) -> Node3D:
	var root = Node3D.new()
	var frame_mat = _mat(Color(0.4, 0.3, 0.2)) # default wood frame
	var face_mat = _mat(color)
	
	var frame = CSGBox3D.new()
	frame.size = Vector3(width, 1.2, 0.05)
	frame.material = frame_mat
	root.add_child(frame)
	
	var face = CSGBox3D.new()
	face.size = Vector3(width - 0.1, 1.1, 0.06)
	face.material = face_mat
	root.add_child(face)
	
	return root

static func create_frame(color: Color, face_color: Color = Color.WHITE) -> Node3D:
	var root = Node3D.new()
	var frame_mat = _mat(color)
	var face_mat = _mat(face_color)
	
	var frame = CSGBox3D.new()
	frame.size = Vector3(0.4, 0.3, 0.03)
	frame.material = frame_mat
	root.add_child(frame)
	
	var face = CSGBox3D.new()
	face.size = Vector3(0.35, 0.25, 0.04)
	face.material = face_mat
	root.add_child(face)
	
	return root

static func create_mug(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var cup = CSGCylinder3D.new()
	cup.radius = 0.04
	cup.height = 0.1
	cup.position = Vector3(0, 0.05, 0)
	cup.material = mat
	root.add_child(cup)
	
	var handle = CSGBox3D.new()
	handle.size = Vector3(0.04, 0.06, 0.01)
	handle.position = Vector3(0.04, 0.05, 0)
	handle.material = mat
	root.add_child(handle)
	
	return root

static func create_paper_stack(color: Color, height: float = 0.05) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var paper = CSGBox3D.new()
	paper.size = Vector3(0.21, height, 0.3)
	paper.position = Vector3(0, height/2, 0)
	paper.material = mat
	root.add_child(paper)
	
	return root

static func create_plant(pot_color: Color, leaf_color: Color) -> Node3D:
	var root = Node3D.new()
	
	var pot = CSGCylinder3D.new()
	pot.radius = 0.075
	pot.height = 0.15
	pot.position = Vector3(0, 0.075, 0)
	pot.material = _mat(pot_color)
	root.add_child(pot)
	
	var leaves = CSGSphere3D.new()
	leaves.radius = 0.12
	leaves.position = Vector3(0, 0.2, 0)
	leaves.material = _mat(leaf_color)
	root.add_child(leaves)
	
	return root

static func create_book(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var cover = CSGBox3D.new()
	cover.size = Vector3(0.15, 0.03, 0.21)
	cover.position = Vector3(0, 0.015, 0)
	cover.material = mat
	root.add_child(cover)
	
	var pages = CSGBox3D.new()
	pages.size = Vector3(0.14, 0.02, 0.2)
	pages.position = Vector3(0.005, 0.015, 0)
	pages.material = _mat(Color.WHITE)
	root.add_child(pages)
	
	return root

static func create_bag(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	
	var main_body = CSGBox3D.new()
	main_body.size = Vector3(0.3, 0.4, 0.2)
	main_body.position = Vector3(0, 0.2, 0)
	main_body.material = mat
	root.add_child(main_body)
	
	var pocket = CSGBox3D.new()
	pocket.size = Vector3(0.2, 0.15, 0.05)
	pocket.position = Vector3(0, 0.15, 0.1)
	pocket.material = mat
	root.add_child(pocket)
	
	return root

static func create_phone() -> Node3D:
	var root = Node3D.new()
	
	var phone = CSGBox3D.new()
	phone.size = Vector3(0.07, 0.01, 0.14)
	phone.position = Vector3(0, 0.005, 0)
	phone.material = _mat(Color.BLACK)
	root.add_child(phone)
	
	return root

static func create_pen_holder(color: Color) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(color)
	var pen_mat = _mat(Color.RED)
	
	var holder = CSGCylinder3D.new()
	holder.radius = 0.03
	holder.height = 0.08
	holder.position = Vector3(0, 0.04, 0)
	holder.material = mat
	root.add_child(holder)
	
	var pen = CSGCylinder3D.new()
	pen.radius = 0.005
	pen.height = 0.12
	pen.position = Vector3(0.01, 0.06, 0.01)
	pen.rotation_degrees = Vector3(15, 0, 15)
	pen.material = pen_mat
	root.add_child(pen)
	
	return root

static func create_pitcher() -> Node3D:
	var root = Node3D.new()
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	
	var pitcher = CSGCylinder3D.new()
	pitcher.radius = 0.06
	pitcher.height = 0.2
	pitcher.position = Vector3(0, 0.1, 0)
	pitcher.material = glass_mat
	root.add_child(pitcher)
	
	var glass = CSGCylinder3D.new()
	glass.radius = 0.03
	glass.height = 0.1
	glass.position = Vector3(0.12, 0.05, 0)
	glass.material = glass_mat
	root.add_child(glass)
	
	return root

static func create_newspaper() -> Node3D:
	var root = Node3D.new()
	var mat = _mat(Color(0.95, 0.95, 0.9))
	
	var paper = CSGBox3D.new()
	paper.size = Vector3(0.3, 0.005, 0.4)
	paper.position = Vector3(0, 0.0025, 0)
	paper.material = mat
	root.add_child(paper)
	
	var fold = CSGBox3D.new()
	fold.size = Vector3(0.3, 0.006, 0.02)
	fold.position = Vector3(0, 0.003, 0.19)
	fold.material = _mat(Color(0.8, 0.8, 0.75))
	root.add_child(fold)
	
	return root

static func create_streetlamp() -> Node3D:
	var root = Node3D.new()
	var metal = _mat(Color(0.2, 0.2, 0.2))
	
	var pole = CSGCylinder3D.new()
	pole.radius = 0.05
	pole.height = 3.5
	pole.position = Vector3(0, 1.75, 0)
	pole.material = metal
	pole.use_collision = true
	root.add_child(pole)
	
	var arm = CSGBox3D.new()
	arm.size = Vector3(0.6, 0.05, 0.05)
	arm.position = Vector3(0.3, 3.4, 0)
	arm.material = metal
	root.add_child(arm)
	
	var light_bulb = CSGSphere3D.new()
	light_bulb.radius = 0.15
	light_bulb.position = Vector3(0.6, 3.3, 0)
	light_bulb.material = _mat(Color(1, 0.9, 0.7))
	
	var actual_light = OmniLight3D.new()
	actual_light.light_color = Color(1, 0.9, 0.7)
	actual_light.light_energy = 2.0
	actual_light.omni_range = 10.0
	light_bulb.add_child(actual_light)
	
	root.add_child(light_bulb)
	
	return root

static func create_tree() -> Node3D:
	var root = Node3D.new()
	
	var trunk = CSGCylinder3D.new()
	trunk.radius = 0.2
	trunk.height = 1.5
	trunk.position = Vector3(0, 0.75, 0)
	trunk.material = _mat(Color(0.4, 0.25, 0.1))
	trunk.use_collision = true
	root.add_child(trunk)
	
	var leaves = CSGSphere3D.new()
	leaves.radius = 1.2
	leaves.position = Vector3(0, 2.0, 0)
	leaves.material = _mat(Color(0.2, 0.5, 0.2))
	root.add_child(leaves)
	
	var leaves2 = CSGSphere3D.new()
	leaves2.radius = 0.9
	leaves2.position = Vector3(0.4, 2.5, 0.2)
	leaves2.material = _mat(Color(0.2, 0.5, 0.2))
	root.add_child(leaves2)
	
	var leaves3 = CSGSphere3D.new()
	leaves3.radius = 0.8
	leaves3.position = Vector3(-0.3, 2.7, -0.3)
	leaves3.material = _mat(Color(0.2, 0.5, 0.2))
	root.add_child(leaves3)
	
	return root

static func create_railing(width: float = 4.0) -> Node3D:
	var root = Node3D.new()
	var mat = _mat(Color(0.3, 0.3, 0.3))
	var height = 1.0
	
	var top = CSGBox3D.new()
	top.size = Vector3(width, 0.05, 0.05)
	top.position = Vector3(0, height, 0)
	top.material = mat
	top.use_collision = true
	root.add_child(top)
	
	var bottom = CSGBox3D.new()
	bottom.size = Vector3(width, 0.05, 0.05)
	bottom.position = Vector3(0, 0.1, 0)
	bottom.material = mat
	bottom.use_collision = true
	root.add_child(bottom)
	
	var bars = int(width / 0.2)
	for i in range(bars):
		var bar = CSGCylinder3D.new()
		bar.radius = 0.01
		bar.height = height
		var pos_x = -width/2 + (width/bars) * i + (width/bars)/2
		bar.position = Vector3(pos_x, height/2, 0)
		bar.material = mat
		root.add_child(bar)
		
	return root
