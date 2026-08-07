# res://scenes/ui/CharacterCustomization.gd
extends CanvasLayer

@onready var back_button: Button = $Control/MarginContainer/VBoxContainer/HeaderBox/BackButton
@onready var save_button: Button = $Control/MarginContainer/VBoxContainer/HeaderBox/SaveButton

@onready var main_hbox: HBoxContainer = $Control/MarginContainer/VBoxContainer/MainHBox
@onready var model_pivot: Node3D = $Control/MarginContainer/VBoxContainer/MainHBox/ViewportCard/SubViewportContainer/SubViewport/PreviewWorld/ModelPivot

@onready var skin_picker: ColorPickerButton = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/SkinRow/SkinPicker

@onready var hair_prev_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/HairRow/HairPrevBtn
@onready var hair_next_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/HairRow/HairNextBtn
@onready var hair_style_label: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/HairRow/HairStyleLabel
@onready var hair_picker: ColorPickerButton = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/HairRow/HairPicker

@onready var eye_prev_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/EyeRow/EyePrevBtn
@onready var eye_next_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/EyeRow/EyeNextBtn
@onready var eye_style_label: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/EyeRow/EyeStyleLabel

@onready var iris_picker: ColorPickerButton = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/IrisRow/IrisPicker
@onready var pupil_picker: ColorPickerButton = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/PupilRow/PupilPicker
@onready var sclera_picker: ColorPickerButton = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/ScleraRow/ScleraPicker

@onready var nose_prev_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/NoseRow/NosePrevBtn
@onready var nose_next_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/NoseRow/NoseNextBtn
@onready var nose_style_label: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/NoseRow/NoseStyleLabel

@onready var mouth_prev_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/MouthRow/MouthPrevBtn
@onready var mouth_next_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/MouthRow/MouthNextBtn
@onready var mouth_style_label: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/MouthRow/MouthStyleLabel

@onready var acc_prev_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/AccRow/AccPrevBtn
@onready var acc_next_btn: Button = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/AccRow/AccNextBtn
@onready var acc_style_label: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/ControlsList/AccRow/AccStyleLabel

const ACC_NAMES: Array[String] = ["None", "Glasses", "Scarf", "Backpack", "Crown/Band"]

var auto_rotate: bool = false
var selected_part: String = "head"

var alignment_data: Dictionary = {
	"body": {"position": Vector3(0.0, 0.0, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(2.5, 2.5, 2.5)},
	"head": {"position": Vector3(0.0, 1.15, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(0.7, 0.7, 0.7)},
	"hair": {"position": Vector3(0.0, 1.45, 0.0), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(2.5, 2.5, 2.5)},
	"glasses": {"position": Vector3(0.0, 1.15, 0.05), "rotation": Vector3(-90.0, 0.0, 0.0), "scale": Vector3(0.7, 0.7, 0.7)}
}

var spin_px: SpinBox
var spin_py: SpinBox
var spin_pz: SpinBox

var spin_rx: SpinBox
var spin_ry: SpinBox
var spin_rz: SpinBox

var spin_sx: SpinBox
var spin_sy: SpinBox
var spin_sz: SpinBox

var gizmo_status_label: Label
var current_avatar_instance: Node3D

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)

	_setup_customizer_ui()
	_setup_gizmo_ui()
	_update_character_preview()

func _process(delta: float) -> void:
	if model_pivot and auto_rotate:
		model_pivot.rotation.y += delta * 0.5

func _setup_customizer_ui() -> void:
	var c = PlayerStore.customization

	skin_picker.color = c.get("skin_color", Color(0.92, 0.76, 0.65))
	hair_picker.color = c.get("hair_color", Color(0.24, 0.16, 0.10))
	iris_picker.color = c.get("eye_iris_color", Color(0.18, 0.55, 0.85))
	pupil_picker.color = c.get("eye_pupil_color", Color(0.1, 0.1, 0.1))
	sclera_picker.color = c.get("eye_sclera_color", Color(1.0, 1.0, 1.0))

	skin_picker.color_changed.connect(func(col): PlayerStore.customization["skin_color"] = col; _update_character_preview())
	hair_picker.color_changed.connect(func(col): PlayerStore.customization["hair_color"] = col; _update_character_preview())
	iris_picker.color_changed.connect(func(col): PlayerStore.customization["eye_iris_color"] = col; _update_character_preview())
	pupil_picker.color_changed.connect(func(col): PlayerStore.customization["eye_pupil_color"] = col; _update_character_preview())
	sclera_picker.color_changed.connect(func(col): PlayerStore.customization["eye_sclera_color"] = col; _update_character_preview())

	hair_prev_btn.pressed.connect(func(): _cycle_int("hair_style", -1, 0, 133))
	hair_next_btn.pressed.connect(func(): _cycle_int("hair_style", 1, 0, 133))

	eye_prev_btn.pressed.connect(func(): _cycle_int("eye_style", -1, 1, 60))
	eye_next_btn.pressed.connect(func(): _cycle_int("eye_style", 1, 1, 60))

	nose_prev_btn.pressed.connect(func(): _cycle_int("nose_style", -1, 1, 18))
	nose_next_btn.pressed.connect(func(): _cycle_int("nose_style", 1, 1, 18))

	mouth_prev_btn.pressed.connect(func(): _cycle_int("mouth_style", -1, 1, 36))
	mouth_next_btn.pressed.connect(func(): _cycle_int("mouth_style", 1, 1, 36))

	acc_prev_btn.pressed.connect(func(): _cycle_int("accessory_style", -1, 0, ACC_NAMES.size() - 1))
	acc_next_btn.pressed.connect(func(): _cycle_int("accessory_style", 1, 0, ACC_NAMES.size() - 1))

	_refresh_labels()

func _setup_gizmo_ui() -> void:
	var gizmo_panel = PanelContainer.new()
	gizmo_panel.name = "GizmoPanel"
	gizmo_panel.custom_minimum_size = Vector2(280, 0)
	main_hbox.add_child(gizmo_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	gizmo_panel.add_child(vbox)

	var title = Label.new()
	title.text = "🛠️ Alignment Gizmo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var auto_rotate_check = CheckBox.new()
	auto_rotate_check.text = "Auto Rotate Camera"
	auto_rotate_check.button_pressed = auto_rotate
	auto_rotate_check.toggled.connect(func(t): auto_rotate = t; if not t and model_pivot: model_pivot.rotation.y = 0.0)
	vbox.add_child(auto_rotate_check)

	var part_hbox = HBoxContainer.new()
	part_hbox.add_child(_make_label("Part:"))
	var part_option = OptionButton.new()
	part_option.add_item("head", 0)
	part_option.add_item("body", 1)
	part_option.add_item("hair", 2)
	part_option.add_item("glasses", 3)
	part_option.item_selected.connect(func(idx): selected_part = part_option.get_item_text(idx); _update_gizmo_spinboxes())
	part_hbox.add_child(part_option)
	vbox.add_child(part_hbox)

	vbox.add_child(_make_label("Position (X, Y, Z):"))
	var pos_hbox = HBoxContainer.new()
	spin_px = _make_spinbox(-5.0, 5.0, 0.01, func(_v): _on_transform_changed())
	spin_py = _make_spinbox(-5.0, 5.0, 0.01, func(_v): _on_transform_changed())
	spin_pz = _make_spinbox(-5.0, 5.0, 0.01, func(_v): _on_transform_changed())
	pos_hbox.add_child(spin_px)
	pos_hbox.add_child(spin_py)
	pos_hbox.add_child(spin_pz)
	vbox.add_child(pos_hbox)

	vbox.add_child(_make_label("Rotation Deg (X, Y, Z):"))
	var rot_hbox = HBoxContainer.new()
	spin_rx = _make_spinbox(-360.0, 360.0, 1.0, func(_v): _on_transform_changed())
	spin_ry = _make_spinbox(-360.0, 360.0, 1.0, func(_v): _on_transform_changed())
	spin_rz = _make_spinbox(-360.0, 360.0, 1.0, func(_v): _on_transform_changed())
	rot_hbox.add_child(spin_rx)
	rot_hbox.add_child(spin_ry)
	rot_hbox.add_child(spin_rz)
	vbox.add_child(rot_hbox)

	vbox.add_child(_make_label("Scale (X, Y, Z):"))
	var scale_hbox = HBoxContainer.new()
	spin_sx = _make_spinbox(0.01, 10.0, 0.05, func(_v): _on_transform_changed())
	spin_sy = _make_spinbox(0.01, 10.0, 0.05, func(_v): _on_transform_changed())
	spin_sz = _make_spinbox(0.01, 10.0, 0.05, func(_v): _on_transform_changed())
	scale_hbox.add_child(spin_sx)
	scale_hbox.add_child(spin_sy)
	scale_hbox.add_child(spin_sz)
	vbox.add_child(scale_hbox)

	var copy_btn = Button.new()
	copy_btn.text = "📋 COPY ALIGNMENT JSON"
	copy_btn.custom_minimum_size = Vector2(0, 40)
	copy_btn.pressed.connect(_on_copy_json_pressed)
	vbox.add_child(copy_btn)

	gizmo_status_label = Label.new()
	gizmo_status_label.text = ""
	gizmo_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	gizmo_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gizmo_status_label)

	_update_gizmo_spinboxes()

func _make_label(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	return l

func _make_spinbox(min_v: float, max_v: float, step_v: float, callback: Callable) -> SpinBox:
	var sb = SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = step_v
	sb.custom_minimum_size = Vector2(65, 0)
	sb.value_changed.connect(callback)
	return sb

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
	gizmo_status_label.text = "✓ JSON Copied to Clipboard & Saved to user://alignment.json!"

func _cycle_int(key: String, delta: int, min_val: int, max_val: int) -> void:
	var cur: int = PlayerStore.customization.get(key, min_val)
	cur += delta
	if cur < min_val:
		cur = max_val
	elif cur > max_val:
		cur = min_val
	PlayerStore.customization[key] = cur
	_refresh_labels()
	_update_character_preview()

func _refresh_labels() -> void:
	var c = PlayerStore.customization
	var hair_idx: int = c.get("hair_style", 0)
	hair_style_label.text = "Hair Style %03d (%d/134)" % [hair_idx, hair_idx + 1]

	var eye_idx: int = c.get("eye_style", 1)
	eye_style_label.text = "Style %02d (%d/60)" % [eye_idx, eye_idx]

	var nose_idx: int = c.get("nose_style", 1)
	nose_style_label.text = "Style %02d (%d/18)" % [nose_idx, nose_idx]

	var mouth_idx: int = c.get("mouth_style", 1)
	mouth_style_label.text = "Style %02d (%d/36)" % [mouth_idx, mouth_idx]

	var acc_idx: int = c.get("accessory_style", 0)
	var acc_name = ACC_NAMES[acc_idx] if acc_idx >= 0 and acc_idx < ACC_NAMES.size() else "Custom"
	acc_style_label.text = "%s (%d/%d)" % [acc_name, acc_idx + 1, ACC_NAMES.size()]

func _update_character_preview() -> void:
	if not model_pivot:
		return
	for child in model_pivot.get_children():
		child.queue_free()
	current_avatar_instance = CharacterFactory.create_character_mesh("player")
	model_pivot.add_child(current_avatar_instance)
	CharacterFactory.apply_alignment(current_avatar_instance, alignment_data)
	_take_debug_screenshot("character_preview")

func _take_debug_screenshot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var vp = get_node_or_null("Control/MarginContainer/VBoxContainer/MainHBox/ViewportCard/SubViewportContainer/SubViewport")
	if vp:
		var img = vp.get_texture().get_image()
		if img:
			var scratch_dir = "c:/Users/User/Documents/THRESHOLD/scratch"
			DirAccess.make_dir_absolute(scratch_dir)
			img.save_png(scratch_dir + "/" + file_name + ".png")

func _on_save_pressed() -> void:
	PlayerStore.save_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_back_pressed() -> void:
	PlayerStore.load_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
