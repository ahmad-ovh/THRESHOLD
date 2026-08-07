# res://scenes/tools/ModelAligner.gd
extends Control

@onready var model_pivot: Node3D = $SubViewportContainer/SubViewport/PreviewWorld/ModelPivot
@onready var camera: Camera3D = $SubViewportContainer/SubViewport/PreviewWorld/Camera3D

# Control references
@onready var part_option: OptionButton = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/PartHBox/PartOption
@onready var auto_rotate_check: CheckBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/AutoRotateCheck

@onready var spin_px: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/PosHBox/SpinPX
@onready var spin_py: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/PosHBox/SpinPY
@onready var spin_pz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/PosHBox/SpinPZ

@onready var spin_rx: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/RotHBox/SpinRX
@onready var spin_ry: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/RotHBox/SpinRY
@onready var spin_rz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/RotHBox/SpinRZ

@onready var spin_sx: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/ScaleHBox/SpinSX
@onready var spin_sy: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/ScaleHBox/SpinSY
@onready var spin_sz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/ScaleHBox/SpinSZ

@onready var copy_btn: Button = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/CopyBtn
@onready var status_label: Label = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/StatusLabel
@onready var back_btn: Button = $MarginContainer/HBoxContainer/RightPanel/VBoxContainer/BackBtn

# Model selector controls
@onready var head_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/HeadRow/HeadSpin
@onready var hair_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/HairRow/HairSpin
@onready var glasses_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/GlassesRow/GlassesSpin
@onready var body_option: OptionButton = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/BodyRow/BodyOption

var auto_rotate: bool = false
var selected_part: String = "head"
var is_orbiting: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

var alignment_data: Dictionary = {
	"body": {"position": Vector3(0.0, 0.0, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(2.5, 2.5, 2.5)},
	"head": {"position": Vector3(0.0, 1.15, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(0.7, 0.7, 0.7)},
	"hair": {"position": Vector3(0.0, 1.45, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(2.5, 2.5, 2.5)},
	"glasses": {"position": Vector3(0.0, 1.15, 0.05), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(0.7, 0.7, 0.7)}
}

var current_avatar_instance: Node3D

func _ready() -> void:
	_connect_signals()
	_update_gizmo_spinboxes()
	_rebuild_avatar()

func _process(delta: float) -> void:
	if model_pivot and auto_rotate:
		model_pivot.rotation.y += delta * 0.5

var is_dragging_part: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_select_3d_part(event.position)
				is_dragging_part = true
				last_mouse_pos = event.position
			else:
				is_dragging_part = false
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_orbiting = event.pressed
			last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and camera:
			camera.position.z = max(0.8, camera.position.z - 0.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and camera:
			camera.position.z = min(5.0, camera.position.z + 0.15)
	elif event is InputEventMouseMotion:
		if is_orbiting and model_pivot:
			var delta_m = event.position - last_mouse_pos
			last_mouse_pos = event.position
			model_pivot.rotation.y += delta_m.x * 0.01
			model_pivot.rotation.x += delta_m.y * 0.01
		elif is_dragging_part and current_avatar_instance:
			var delta_m = event.position - last_mouse_pos
			last_mouse_pos = event.position
			var move_speed = 0.005
			var t = alignment_data[selected_part]
			var cur_pos: Vector3 = t["position"]

			if Input.is_key_pressed(KEY_SHIFT):
				cur_pos.z += delta_m.y * move_speed
			else:
				cur_pos.x += delta_m.x * move_speed
				cur_pos.y -= delta_m.y * move_speed

			alignment_data[selected_part]["position"] = cur_pos
			_update_gizmo_spinboxes()
			_on_transform_changed()
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_nudge(event)

func _try_select_3d_part(mouse_pos: Vector2) -> void:
	if not camera or not current_avatar_instance:
		return
	var mii = current_avatar_instance.get_node_or_null("MiiAvatar") if current_avatar_instance.name != "MiiAvatar" else current_avatar_instance
	if not mii:
		return

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var best_part = selected_part
	var min_dist = 9999.0

	for part in ["head", "body", "hair", "glasses"]:
		var node_name = "GLTF" + part.capitalize()
		var node = mii.get_node_or_null(node_name)
		if node and node is Node3D:
			var pos_3d = node.global_position
			var dist_to_ray = (pos_3d - ray_origin).cross(ray_dir).length()
			if dist_to_ray < min_dist:
				min_dist = dist_to_ray
				best_part = part

	if min_dist < 0.6:
		selected_part = best_part
		for i in range(part_option.item_count):
			if part_option.get_item_text(i) == selected_part:
				part_option.select(i)
				break
		_update_gizmo_spinboxes()

func _handle_keyboard_nudge(event: InputEventKey) -> void:
	if not alignment_data.has(selected_part):
		return
	var step = 0.01
	if event.shift_pressed: step = 0.05
	var cur_pos: Vector3 = alignment_data[selected_part]["position"]
	var cur_rot: Vector3 = alignment_data[selected_part]["rotation"]

	match event.keycode:
		KEY_W, KEY_UP:
			cur_pos.y += step
		KEY_S, KEY_DOWN:
			cur_pos.y -= step
		KEY_A, KEY_LEFT:
			cur_pos.x -= step
		KEY_D, KEY_RIGHT:
			cur_pos.x += step
		KEY_Q:
			cur_pos.z -= step
		KEY_E:
			cur_pos.z += step
		KEY_R:
			cur_rot.y += 15.0
		KEY_T:
			cur_rot.x += 15.0
		_:
			return

	alignment_data[selected_part]["position"] = cur_pos
	alignment_data[selected_part]["rotation"] = cur_rot
	_update_gizmo_spinboxes()
	_on_transform_changed()

func _connect_signals() -> void:
	auto_rotate_check.toggled.connect(func(t):
		auto_rotate = t
		if not t and model_pivot:
			model_pivot.rotation = Vector3.ZERO
	)

	part_option.item_selected.connect(func(idx):
		selected_part = part_option.get_item_text(idx)
		_update_gizmo_spinboxes()
	)

	spin_px.value_changed.connect(func(_v): _on_transform_changed())
	spin_py.value_changed.connect(func(_v): _on_transform_changed())
	spin_pz.value_changed.connect(func(_v): _on_transform_changed())

	spin_rx.value_changed.connect(func(_v): _on_transform_changed())
	spin_ry.value_changed.connect(func(_v): _on_transform_changed())
	spin_rz.value_changed.connect(func(_v): _on_transform_changed())

	spin_sx.value_changed.connect(func(_v): _on_transform_changed())
	spin_sy.value_changed.connect(func(_v): _on_transform_changed())
	spin_sz.value_changed.connect(func(_v): _on_transform_changed())

	copy_btn.pressed.connect(_on_copy_json_pressed)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))

	head_spin.value_changed.connect(func(v): PlayerStore.customization["head_style"] = int(v); _rebuild_avatar())
	hair_spin.value_changed.connect(func(v): PlayerStore.customization["hair_style"] = int(v); _rebuild_avatar())
	glasses_spin.value_changed.connect(func(v): PlayerStore.customization["glasses_style"] = int(v); _rebuild_avatar())
	body_option.item_selected.connect(func(idx): PlayerStore.customization["body_style"] = idx; _rebuild_avatar())

func _update_gizmo_spinboxes() -> void:
	if not alignment_data.has(selected_part):
		return
	var t = alignment_data[selected_part]
	var p: Vector3 = t["position"]
	var r: Vector3 = t["rotation"]
	var s: Vector3 = t["scale"]

	spin_px.set_value_no_signal(p.x)
	spin_py.set_value_no_signal(p.y)
	spin_pz.set_value_no_signal(p.z)

	spin_rx.set_value_no_signal(r.x)
	spin_ry.set_value_no_signal(r.y)
	spin_rz.set_value_no_signal(r.z)

	spin_sx.set_value_no_signal(s.x)
	spin_sy.set_value_no_signal(s.y)
	spin_sz.set_value_no_signal(s.z)

func _on_transform_changed() -> void:
	if not alignment_data.has(selected_part):
		return
	alignment_data[selected_part]["position"] = Vector3(spin_px.value, spin_py.value, spin_pz.value)
	alignment_data[selected_part]["rotation"] = Vector3(spin_rx.value, spin_ry.value, spin_rz.value)
	alignment_data[selected_part]["scale"] = Vector3(spin_sx.value, spin_sy.value, spin_sz.value)

	if current_avatar_instance:
		CharacterFactory.apply_alignment(current_avatar_instance, alignment_data)

func _rebuild_avatar() -> void:
	if not model_pivot:
		return
	for child in model_pivot.get_children():
		child.queue_free()
	current_avatar_instance = CharacterFactory.create_character_mesh("player")
	model_pivot.add_child(current_avatar_instance)
	CharacterFactory.apply_alignment(current_avatar_instance, alignment_data)
	_take_debug_screenshot("authoring_alignment_preview")

func _on_copy_json_pressed() -> void:
	var export_dict = {}
	for k in alignment_data.keys():
		export_dict[k] = {
			"position": [snapped(alignment_data[k]["position"].x, 0.001), snapped(alignment_data[k]["position"].y, 0.001), snapped(alignment_data[k]["position"].z, 0.001)],
			"rotation": [snapped(alignment_data[k]["rotation"].x, 0.1), snapped(alignment_data[k]["rotation"].y, 0.1), snapped(alignment_data[k]["rotation"].z, 0.1)],
			"scale": [snapped(alignment_data[k]["scale"].x, 0.001), snapped(alignment_data[k]["scale"].y, 0.001), snapped(alignment_data[k]["scale"].z, 0.001)]
		}
	var json_text = JSON.stringify(export_dict, "  ")
	DisplayServer.clipboard_set(json_text)

	var f = FileAccess.open("user://alignment.json", FileAccess.WRITE)
	if f:
		f.store_string(json_text)
		f.close()

	var scratch_path = "c:/Users/User/Documents/THRESHOLD/scratch/alignment.json"
	var f2 = FileAccess.open(scratch_path, FileAccess.WRITE)
	if f2:
		f2.store_string(json_text)
		f2.close()

	print("ALIGNMENT_JSON_EXPORT:\n", json_text)
	status_label.text = "✓ JSON Copied to Clipboard & Saved to user://alignment.json!"

func _take_debug_screenshot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var vp = get_node_or_null("SubViewportContainer/SubViewport")
	if vp:
		var img = vp.get_texture().get_image()
		if img:
			var scratch_dir = "c:/Users/User/Documents/THRESHOLD/scratch"
			DirAccess.make_dir_absolute(scratch_dir)
			img.save_png(scratch_dir + "/" + file_name + ".png")
