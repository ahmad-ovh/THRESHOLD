# res://scenes/tools/ModelAligner.gd
extends Control

@onready var model_pivot: Node3D = $SubViewportContainer/SubViewport/PreviewWorld/ModelPivot
@onready var camera: Camera3D = $SubViewportContainer/SubViewport/PreviewWorld/Camera3D
@onready var preview_world: Node3D = $SubViewportContainer/SubViewport/PreviewWorld

# Control references
@onready var part_option: OptionButton = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PartHBox/PartOption
@onready var gizmo_mode_option: OptionButton = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/GizmoModeHBox/GizmoModeOption
@onready var auto_rotate_check: CheckBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/AutoRotateCheck

# Position Sliders & Spinboxes
@onready var slider_px: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowX/SliderPX
@onready var spin_px: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowX/SpinPX

@onready var slider_py: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowY/SliderPY
@onready var spin_py: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowY/SpinPY

@onready var slider_pz: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowZ/SliderPZ
@onready var spin_pz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/PosRowZ/SpinPZ

# Rotation Sliders & Spinboxes
@onready var slider_rx: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowX/SliderRX
@onready var spin_rx: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowX/SpinRX

@onready var slider_ry: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowY/SliderRY
@onready var spin_ry: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowY/SpinRY

@onready var slider_rz: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowZ/SliderRZ
@onready var spin_rz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/RotRowZ/SpinRZ

# Scale Sliders & Spinboxes
@onready var slider_sx: HSlider = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/ScaleRow/SliderSX
@onready var spin_sx: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/ScaleRow/SpinSX
@onready var spin_sy: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/ScaleRow/SpinSY
@onready var spin_sz: SpinBox = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/ScaleRow/SpinSZ

@onready var undo_btn: Button = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/UndoRedoHBox/UndoBtn
@onready var redo_btn: Button = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/UndoRedoHBox/RedoBtn
@onready var copy_btn: Button = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/CopyBtn
@onready var status_label: Label = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/StatusLabel
@onready var back_btn: Button = $MarginContainer/HBoxContainer/RightPanel/RightScroll/VBoxContainer/BackBtn

# Model selector controls & preset buttons
@onready var head_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/HeadRow/HeadSpin
@onready var hair_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/HairRow/HairSpin
@onready var glasses_spin: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/GlassesRow/GlassesSpin
@onready var body_option: OptionButton = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/BodyRow/BodyOption

@onready var save_preset_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/SavePresetBtn
@onready var save_catalog_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/SaveCatalogBtn
@onready var preset_status_label: Label = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/PresetStatusLabel

# Visibility Checkboxes & Focus Button
@onready var check_head: CheckBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/CheckHead
@onready var check_hair: CheckBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/CheckHair
@onready var check_glasses: CheckBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/CheckGlasses
@onready var focus_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/FocusBtn

# Face Texture UV Sliders
@onready var slider_eye_x: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeXRow/SliderEyeX
@onready var spin_eye_x: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeXRow/SpinEyeX
@onready var slider_eye_y: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeYRow/SliderEyeY
@onready var spin_eye_y: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeYRow/SpinEyeY
@onready var slider_eye_size: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeSizeRow/SliderEyeSize
@onready var spin_eye_size: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/EyeSizeRow/SpinEyeSize

@onready var slider_nose_y: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/NoseYRow/SliderNoseY
@onready var spin_nose_y: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/NoseYRow/SpinNoseY

@onready var slider_mouth_y: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/MouthYRow/SliderMouthY
@onready var spin_mouth_y: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/MouthYRow/SpinMouthY

@onready var slider_glass_x: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/GlassXRow/SliderGlassX
@onready var spin_glass_x: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/GlassXRow/SpinGlassX
@onready var slider_glass_y: HSlider = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/GlassYRow/SliderGlassY
@onready var spin_glass_y: SpinBox = $MarginContainer/HBoxContainer/LeftPanel/LeftScroll/VBoxContainer/GlassYRow/SpinGlassY

var auto_rotate: bool = false
var selected_part: String = "head"
var gizmo_mode: String = "move" # "move", "rotate", "scale"
var is_orbiting: bool = false
var active_gizmo_axis: String = "" # "X", "Y", "Z", or ""
var last_mouse_pos: Vector2 = Vector2.ZERO

var cam_yaw: float = 0.0
var cam_pitch: float = deg_to_rad(10.0)
var cam_distance: float = 2.2
var cam_anchor: Vector3 = Vector3(0.0, 1.0, 0.0)

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_UNDO_STACK: int = 50

var alignment_data: Dictionary = {
	"body": {"position": Vector3(0.0, 0.0, 0.0), "rotation": Vector3(0.0, 0.0, 0.0), "scale": Vector3(2.5, 2.5, 2.5)},
	"head": {"position": Vector3(0.0, 1.155, 0.0), "rotation": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	"hair": {"position": Vector3(0.0, 1.605, 0.0), "rotation": Vector3(0.0, 0.0, 0.0), "scale": Vector3(6.6, 6.6, 6.6)},
	"glasses": {"position": Vector3(0.0, 1.12, 0.31), "rotation": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)}
}

var catalog_presets: Dictionary = {}
var current_avatar_instance: Node3D
var gizmo_node: Node3D

func _ready() -> void:
	_load_catalog()
	_connect_signals()
	_rebuild_avatar()
	_update_gizmo_spinboxes()
	_update_camera_orbit()

func _load_catalog() -> void:
	catalog_presets = CharacterFactory.get_model_presets().duplicate(true)

func _process(delta: float) -> void:
	if model_pivot and auto_rotate:
		cam_yaw += delta * 0.5
		_update_camera_orbit()
	_update_gizmo_3d_position()

func _update_camera_orbit() -> void:
	if not camera:
		return
	var rot_q = Quaternion.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
	camera.global_position = cam_anchor + rot_q * Vector3(0.0, 0.0, cam_distance)
	camera.look_at(cam_anchor, Vector3.UP)

func _focus_camera_on_selected_part() -> void:
	match selected_part:
		"head":
			cam_anchor = Vector3(0.0, 1.155, 0.0)
			cam_distance = 1.0
		"hair":
			cam_anchor = Vector3(0.0, 1.400, 0.0)
			cam_distance = 1.2
		"glasses":
			cam_anchor = Vector3(0.0, 1.155, 0.05)
			cam_distance = 0.75
		"body":
			cam_anchor = Vector3(0.0, 0.600, 0.0)
			cam_distance = 2.2
	_update_camera_orbit()

func _push_undo() -> void:
	undo_stack.append(alignment_data.duplicate(true))
	if undo_stack.size() > MAX_UNDO_STACK:
		undo_stack.pop_front()
	redo_stack.clear()

func undo() -> void:
	if undo_stack.is_empty():
		status_label.text = "Nothing to Undo"
		return
	redo_stack.append(alignment_data.duplicate(true))
	alignment_data = undo_stack.pop_back()
	_update_gizmo_spinboxes()
	_on_transform_changed()
	status_label.text = "↩ Undo"

func redo() -> void:
	if redo_stack.is_empty():
		status_label.text = "Nothing to Redo"
		return
	undo_stack.append(alignment_data.duplicate(true))
	alignment_data = redo_stack.pop_back()
	_update_gizmo_spinboxes()
	_on_transform_changed()
	status_label.text = "↪ Redo"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var axis = _hit_test_gizmo(event.position)
				if axis != "":
					_push_undo()
					active_gizmo_axis = axis
				else:
					_try_select_3d_part(event.position)
					active_gizmo_axis = ""
				last_mouse_pos = event.position
			else:
				active_gizmo_axis = ""
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_orbiting = event.pressed
			last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and camera:
			cam_distance = max(0.4, cam_distance - 0.15)
			_update_camera_orbit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and camera:
			cam_distance = min(6.0, cam_distance + 0.15)
			_update_camera_orbit()

	elif event is InputEventMouseMotion:
		if is_orbiting and camera:
			var delta_m = event.position - last_mouse_pos
			last_mouse_pos = event.position
			cam_yaw -= delta_m.x * 0.005
			cam_pitch = clamp(cam_pitch - delta_m.y * 0.005, deg_to_rad(-85.0), deg_to_rad(85.0))
			_update_camera_orbit()
		elif active_gizmo_axis != "" and current_avatar_instance:
			var delta_m = event.position - last_mouse_pos
			last_mouse_pos = event.position
			var t = alignment_data[selected_part]

			if gizmo_mode == "move":
				var move_speed = 0.005
				var cur_pos: Vector3 = t["position"]
				match active_gizmo_axis:
					"X": cur_pos.x += delta_m.x * move_speed
					"Y": cur_pos.y -= delta_m.y * move_speed
					"Z": cur_pos.z += delta_m.y * move_speed
				alignment_data[selected_part]["position"] = cur_pos

			elif gizmo_mode == "rotate":
				var rot_speed = 1.0
				var cur_rot: Vector3 = t["rotation"]
				match active_gizmo_axis:
					"X": cur_rot.x -= delta_m.y * rot_speed
					"Y": cur_rot.y += delta_m.x * rot_speed
					"Z": cur_rot.z += delta_m.x * rot_speed
				alignment_data[selected_part]["rotation"] = cur_rot

			elif gizmo_mode == "scale":
				var scale_speed = 0.02
				var cur_scale: Vector3 = t["scale"]
				match active_gizmo_axis:
					"X": cur_scale.x += delta_m.x * scale_speed
					"Y": cur_scale.y -= delta_m.y * scale_speed
					"Z": cur_scale.z += delta_m.y * scale_speed
				alignment_data[selected_part]["scale"] = cur_scale

			_update_gizmo_spinboxes()
			_on_transform_changed()

	elif event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				redo()
			else:
				undo()
			accept_event()
			return
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			redo()
			accept_event()
			return
		_handle_keyboard_nudge(event)

func _hit_test_gizmo(mouse_pos: Vector2) -> String:
	if not camera or not gizmo_node:
		return ""
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var gizmo_pos = gizmo_node.global_position
	var threshold = 0.20 if gizmo_mode == "rotate" else 0.15

	var pos_x = gizmo_pos + Vector3(0.2, 0, 0)
	if (pos_x - ray_origin).cross(ray_dir).length() < threshold:
		return "X"

	var pos_y = gizmo_pos + Vector3(0, 0.2, 0)
	if (pos_y - ray_origin).cross(ray_dir).length() < threshold:
		return "Y"

	var pos_z = gizmo_pos + Vector3(0, 0, 0.2)
	if (pos_z - ray_origin).cross(ray_dir).length() < threshold:
		return "Z"

	return ""

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
		if node and node is Node3D and node.visible:
			var pos_3d = node.global_position
			var dist_to_ray = (pos_3d - ray_origin).cross(ray_dir).length()
			if dist_to_ray < min_dist:
				min_dist = dist_to_ray
				best_part = part

	if min_dist < 0.6:
		_set_selected_part(best_part)

func _set_selected_part(part: String) -> void:
	selected_part = part
	for i in range(part_option.item_count):
		if part_option.get_item_text(i) == selected_part:
			part_option.select(i)
			break

	if selected_part == "glasses" and glasses_spin.value == 0:
		glasses_spin.value = 1
		PlayerStore.customization["glasses_style"] = 1
		_rebuild_avatar()

	_update_gizmo_spinboxes()
	_spawn_3d_gizmo()

func _handle_keyboard_nudge(event: InputEventKey) -> void:
	if not alignment_data.has(selected_part):
		return
	_push_undo()
	var step = 0.005
	if event.shift_pressed: step = 0.05
	var cur_pos: Vector3 = alignment_data[selected_part]["position"]
	var cur_rot: Vector3 = alignment_data[selected_part]["rotation"]

	match event.keycode:
		KEY_W, KEY_UP: cur_pos.y += step
		KEY_S, KEY_DOWN: cur_pos.y -= step
		KEY_A, KEY_LEFT: cur_pos.x -= step
		KEY_D, KEY_RIGHT: cur_pos.x += step
		KEY_Q: cur_pos.z -= step
		KEY_E: cur_pos.z += step
		KEY_R: cur_rot.y += 15.0
		KEY_T: cur_rot.x += 15.0
		_: return

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
		var p_name = part_option.get_item_text(idx)
		_set_selected_part(p_name)
	)

	if gizmo_mode_option:
		gizmo_mode_option.item_selected.connect(func(idx):
			match idx:
				0: gizmo_mode = "move"
				1: gizmo_mode = "rotate"
				2: gizmo_mode = "scale"
			_spawn_3d_gizmo()
		)

	if undo_btn: undo_btn.pressed.connect(undo)
	if redo_btn: redo_btn.pressed.connect(redo)
	if focus_btn: focus_btn.pressed.connect(_focus_camera_on_selected_part)

	if check_head: check_head.toggled.connect(func(_t): _update_part_visibilities())
	if check_hair: check_hair.toggled.connect(func(_t): _update_part_visibilities())
	if check_glasses: check_glasses.toggled.connect(func(_t): _update_part_visibilities())

	# Position Sliders & Spinboxes
	slider_px.value_changed.connect(func(v): _push_undo(); spin_px.set_value_no_signal(v); _on_transform_changed())
	spin_px.value_changed.connect(func(v): _push_undo(); slider_px.set_value_no_signal(v); _on_transform_changed())

	slider_py.value_changed.connect(func(v): _push_undo(); spin_py.set_value_no_signal(v); _on_transform_changed())
	spin_py.value_changed.connect(func(v): _push_undo(); slider_py.set_value_no_signal(v); _on_transform_changed())

	slider_pz.value_changed.connect(func(v): _push_undo(); spin_pz.set_value_no_signal(v); _on_transform_changed())
	spin_pz.value_changed.connect(func(v): _push_undo(); slider_pz.set_value_no_signal(v); _on_transform_changed())

	# Rotation Sliders & Spinboxes
	slider_rx.value_changed.connect(func(v): _push_undo(); spin_rx.set_value_no_signal(v); _on_transform_changed())
	spin_rx.value_changed.connect(func(v): _push_undo(); slider_rx.set_value_no_signal(v); _on_transform_changed())

	slider_ry.value_changed.connect(func(v): _push_undo(); spin_ry.set_value_no_signal(v); _on_transform_changed())
	spin_ry.value_changed.connect(func(v): _push_undo(); slider_ry.set_value_no_signal(v); _on_transform_changed())

	slider_rz.value_changed.connect(func(v): _push_undo(); spin_rz.set_value_no_signal(v); _on_transform_changed())
	spin_rz.value_changed.connect(func(v): _push_undo(); slider_rz.set_value_no_signal(v); _on_transform_changed())

	# Scale Sliders & Spinboxes
	slider_sx.value_changed.connect(func(v): _push_undo(); spin_sx.set_value_no_signal(v); spin_sy.set_value_no_signal(v); spin_sz.set_value_no_signal(v); _on_transform_changed())
	spin_sx.value_changed.connect(func(v): _push_undo(); slider_sx.set_value_no_signal(v); _on_transform_changed())
	spin_sy.value_changed.connect(func(_v): _push_undo(); _on_transform_changed())
	spin_sz.value_changed.connect(func(_v): _push_undo(); _on_transform_changed())

	# Face Texture UV Sliders & Spinboxes
	var update_face_offsets = func():
		_push_undo()
		if not PlayerStore.customization.has("face_offsets"):
			PlayerStore.customization["face_offsets"] = {}
		PlayerStore.customization["face_offsets"]["eye_x"] = int(spin_eye_x.value)
		PlayerStore.customization["face_offsets"]["eye_y"] = int(spin_eye_y.value)
		PlayerStore.customization["face_offsets"]["eye_size"] = int(spin_eye_size.value)
		PlayerStore.customization["face_offsets"]["nose_y"] = int(spin_nose_y.value)
		PlayerStore.customization["face_offsets"]["mouth_y"] = int(spin_mouth_y.value)
		PlayerStore.customization["face_offsets"]["glass_x"] = int(spin_glass_x.value)
		PlayerStore.customization["face_offsets"]["glass_y"] = int(spin_glass_y.value)
		_rebuild_avatar()

	slider_eye_x.value_changed.connect(func(v): spin_eye_x.set_value_no_signal(v); update_face_offsets.call())
	spin_eye_x.value_changed.connect(func(v): slider_eye_x.set_value_no_signal(v); update_face_offsets.call())

	slider_eye_y.value_changed.connect(func(v): spin_eye_y.set_value_no_signal(v); update_face_offsets.call())
	spin_eye_y.value_changed.connect(func(v): slider_eye_y.set_value_no_signal(v); update_face_offsets.call())

	slider_eye_size.value_changed.connect(func(v): spin_eye_size.set_value_no_signal(v); update_face_offsets.call())
	spin_eye_size.value_changed.connect(func(v): slider_eye_size.set_value_no_signal(v); update_face_offsets.call())

	slider_nose_y.value_changed.connect(func(v): spin_nose_y.set_value_no_signal(v); update_face_offsets.call())
	spin_nose_y.value_changed.connect(func(v): slider_nose_y.set_value_no_signal(v); update_face_offsets.call())

	slider_mouth_y.value_changed.connect(func(v): spin_mouth_y.set_value_no_signal(v); update_face_offsets.call())
	spin_mouth_y.value_changed.connect(func(v): slider_mouth_y.set_value_no_signal(v); update_face_offsets.call())

	slider_glass_x.value_changed.connect(func(v): spin_glass_x.set_value_no_signal(v); update_face_offsets.call())
	spin_glass_x.value_changed.connect(func(v): slider_glass_x.set_value_no_signal(v); update_face_offsets.call())

	slider_glass_y.value_changed.connect(func(v): spin_glass_y.set_value_no_signal(v); update_face_offsets.call())
	spin_glass_y.value_changed.connect(func(v): slider_glass_y.set_value_no_signal(v); update_face_offsets.call())

	copy_btn.pressed.connect(_on_copy_json_pressed)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))

	if save_preset_btn: save_preset_btn.pressed.connect(_on_save_current_item_preset)
	if save_catalog_btn: save_catalog_btn.pressed.connect(_on_save_catalog_to_file)

	head_spin.value_changed.connect(func(v):
		PlayerStore.customization["head_style"] = int(v)
		_on_item_changed("heads", "head_%03d" % int(v), "head")
	)

	hair_spin.value_changed.connect(func(v):
		PlayerStore.customization["hair_style"] = int(v)
		_on_item_changed("hair", "hair_%03d" % int(v), "hair")
	)

	glasses_spin.value_changed.connect(func(v):
		PlayerStore.customization["glasses_style"] = int(v)
		_on_item_changed("glasses", "glasses_%d" % int(v), "glasses")
	)

	body_option.item_selected.connect(func(idx): PlayerStore.customization["body_style"] = idx; _rebuild_avatar())

func _update_part_visibilities() -> void:
	if not current_avatar_instance:
		return
	var mii = current_avatar_instance.get_node_or_null("MiiAvatar") if current_avatar_instance.name != "MiiAvatar" else current_avatar_instance
	if not mii:
		return
	var gh = mii.get_node_or_null("GLTFHead")
	var ghr = mii.get_node_or_null("GLTFHair")
	var gl = mii.get_node_or_null("GLTFGlasses")

	if gh and check_head: gh.visible = check_head.button_pressed
	if ghr and check_hair: ghr.visible = check_hair.button_pressed
	if gl and check_glasses: gl.visible = check_glasses.button_pressed

func _get_current_item_info() -> Dictionary:
	match selected_part:
		"head": return {"cat": "heads", "key": "head_%03d" % int(head_spin.value)}
		"hair": return {"cat": "hair", "key": "hair_%03d" % int(hair_spin.value)}
		"glasses": return {"cat": "glasses", "key": "glasses_%d" % int(glasses_spin.value)}
		_: return {"cat": "body", "key": "body"}

func _on_item_changed(cat: String, item_key: String, part: String) -> void:
	if catalog_presets.has(cat) and catalog_presets[cat].has(item_key):
		var t = catalog_presets[cat][item_key]
		if t.has("position"): alignment_data[part]["position"] = Vector3(t["position"][0], t["position"][1], t["position"][2])
		if t.has("rotation"): alignment_data[part]["rotation"] = Vector3(t["rotation"][0], t["rotation"][1], t["rotation"][2])
		if t.has("scale"): alignment_data[part]["scale"] = Vector3(t["scale"][0], t["scale"][1], t["scale"][2])
	_rebuild_avatar()
	_update_gizmo_spinboxes()

func _on_save_current_item_preset() -> void:
	var info = _get_current_item_info()
	var cat = info["cat"]
	var item_key = info["key"]

	if not catalog_presets.has(cat):
		catalog_presets[cat] = {}

	var t = alignment_data[selected_part]
	catalog_presets[cat][item_key] = {
		"position": [snapped(t["position"].x, 0.001), snapped(t["position"].y, 0.001), snapped(t["position"].z, 0.001)],
		"rotation": [snapped(t["rotation"].x, 0.1), snapped(t["rotation"].y, 0.1), snapped(t["rotation"].z, 0.1)],
		"scale": [snapped(t["scale"].x, 0.001), snapped(t["scale"].y, 0.001), snapped(t["scale"].z, 0.001)]
	}

	_on_save_catalog_to_file()
	if preset_status_label:
		preset_status_label.text = "✓ Saved " + item_key

func _on_save_catalog_to_file() -> void:
	var json_text = JSON.stringify(catalog_presets, "  ")
	var res_path = "c:/Users/User/Documents/THRESHOLD/client/assets/character_models/model_presets.json"
	var f = FileAccess.open(res_path, FileAccess.WRITE)
	if f:
		f.store_string(json_text)
		f.close()

	var user_path = "user://model_presets.json"
	var f2 = FileAccess.open(user_path, FileAccess.WRITE)
	if f2:
		f2.store_string(json_text)
		f2.close()

	CharacterFactory._load_model_presets()
	if preset_status_label:
		preset_status_label.text = "✓ Presets saved to catalog!"

func _update_gizmo_spinboxes() -> void:
	if not alignment_data.has(selected_part):
		return
	var t = alignment_data[selected_part]
	var p: Vector3 = t["position"]
	var r: Vector3 = t["rotation"]
	var s: Vector3 = t["scale"]

	spin_px.set_value_no_signal(p.x)
	slider_px.set_value_no_signal(p.x)

	spin_py.set_value_no_signal(p.y)
	slider_py.set_value_no_signal(p.y)

	spin_pz.set_value_no_signal(p.z)
	slider_pz.set_value_no_signal(p.z)

	spin_rx.set_value_no_signal(r.x)
	slider_rx.set_value_no_signal(r.x)

	spin_ry.set_value_no_signal(r.y)
	slider_ry.set_value_no_signal(r.y)

	spin_rz.set_value_no_signal(r.z)
	slider_rz.set_value_no_signal(r.z)

	spin_sx.set_value_no_signal(s.x)
	spin_sy.set_value_no_signal(s.y)
	spin_sz.set_value_no_signal(s.z)
	slider_sx.set_value_no_signal(s.x)

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
	_update_part_visibilities()
	_spawn_3d_gizmo()

func _spawn_3d_gizmo() -> void:
	if gizmo_node:
		gizmo_node.queue_free()

	gizmo_node = Node3D.new()
	gizmo_node.name = "TransformGizmo3D"
	preview_world.add_child(gizmo_node)

	var mat_x = StandardMaterial3D.new()
	mat_x.albedo_color = Color(1.0, 0.25, 0.25)
	mat_x.no_depth_test = true
	mat_x.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mat_y = StandardMaterial3D.new()
	mat_y.albedo_color = Color(0.25, 1.0, 0.25)
	mat_y.no_depth_test = true
	mat_y.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mat_z = StandardMaterial3D.new()
	mat_z.albedo_color = Color(0.3, 0.55, 1.0)
	mat_z.no_depth_test = true
	mat_z.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	if gizmo_mode == "rotate":
		# Render 3D Rotation Rings
		var ring_x = MeshInstance3D.new()
		var torus_x = TorusMesh.new()
		torus_x.outer_radius = 0.25
		torus_x.inner_radius = 0.23
		ring_x.mesh = torus_x
		ring_x.material_override = mat_x
		ring_x.rotation_degrees = Vector3(0, 90, 0)
		gizmo_node.add_child(ring_x)

		var ring_y = MeshInstance3D.new()
		var torus_y = TorusMesh.new()
		torus_y.outer_radius = 0.25
		torus_y.inner_radius = 0.23
		ring_y.mesh = torus_y
		ring_y.material_override = mat_y
		ring_y.rotation_degrees = Vector3(90, 0, 0)
		gizmo_node.add_child(ring_y)

		var ring_z = MeshInstance3D.new()
		var torus_z = TorusMesh.new()
		torus_z.outer_radius = 0.25
		torus_z.inner_radius = 0.23
		ring_z.mesh = torus_z
		ring_z.material_override = mat_z
		ring_z.rotation_degrees = Vector3(0, 0, 0)
		gizmo_node.add_child(ring_z)

	elif gizmo_mode == "scale":
		# Render Scale Cubes
		var box_x = MeshInstance3D.new()
		var cube_x = BoxMesh.new()
		cube_x.size = Vector3(0.05, 0.05, 0.05)
		box_x.mesh = cube_x
		box_x.material_override = mat_x
		box_x.position = Vector3(0.25, 0, 0)
		gizmo_node.add_child(box_x)

		var box_y = MeshInstance3D.new()
		var cube_y = BoxMesh.new()
		cube_y.size = Vector3(0.05, 0.05, 0.05)
		box_y.mesh = cube_y
		box_y.material_override = mat_y
		box_y.position = Vector3(0, 0.25, 0)
		gizmo_node.add_child(box_y)

		var box_z = MeshInstance3D.new()
		var cube_z = BoxMesh.new()
		cube_z.size = Vector3(0.05, 0.05, 0.05)
		box_z.mesh = cube_z
		box_z.material_override = mat_z
		box_z.position = Vector3(0, 0, 0.25)
		gizmo_node.add_child(box_z)

	else:
		# Render Linear Movement Arrows
		var axis_x = MeshInstance3D.new()
		var cyl_x = CylinderMesh.new()
		cyl_x.top_radius = 0.015
		cyl_x.bottom_radius = 0.015
		cyl_x.height = 0.4
		axis_x.mesh = cyl_x
		axis_x.material_override = mat_x
		axis_x.position = Vector3(0.2, 0.0, 0.0)
		axis_x.rotation_degrees = Vector3(0, 0, -90)
		gizmo_node.add_child(axis_x)

		var axis_y = MeshInstance3D.new()
		var cyl_y = CylinderMesh.new()
		cyl_y.top_radius = 0.015
		cyl_y.bottom_radius = 0.015
		cyl_y.height = 0.4
		axis_y.mesh = cyl_y
		axis_y.material_override = mat_y
		axis_y.position = Vector3(0.0, 0.2, 0.0)
		gizmo_node.add_child(axis_y)

		var axis_z = MeshInstance3D.new()
		var cyl_z = CylinderMesh.new()
		cyl_z.top_radius = 0.015
		cyl_z.bottom_radius = 0.015
		cyl_z.height = 0.4
		axis_z.mesh = cyl_z
		axis_z.material_override = mat_z
		axis_z.position = Vector3(0.0, 0.0, 0.2)
		axis_z.rotation_degrees = Vector3(90, 0, 0)
		gizmo_node.add_child(axis_z)

func _update_gizmo_3d_position() -> void:
	if not gizmo_node or not current_avatar_instance:
		return
	var mii = current_avatar_instance.get_node_or_null("MiiAvatar") if current_avatar_instance.name != "MiiAvatar" else current_avatar_instance
	if not mii:
		return
	var node_name = "GLTF" + selected_part.capitalize()
	var part_node = mii.get_node_or_null(node_name)
	if part_node and part_node is Node3D:
		gizmo_node.global_position = part_node.global_position
	elif selected_part == "glasses":
		gizmo_node.global_position = Vector3(0.0, 1.155, 0.05) + alignment_data["glasses"]["position"]

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
