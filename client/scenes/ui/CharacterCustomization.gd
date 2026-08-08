# res://scenes/ui/CharacterCustomization.gd
extends CanvasLayer

@onready var viewport: SubViewport = $Control/MarginContainer/VBoxContainer/MainHBox/ViewportCard/SubViewportContainer/SubViewport
@onready var camera: Camera3D = $Control/MarginContainer/VBoxContainer/MainHBox/ViewportCard/SubViewportContainer/SubViewport/PreviewWorld/PreviewCamera
@onready var model_pivot: Node3D = $Control/MarginContainer/VBoxContainer/MainHBox/ViewportCard/SubViewportContainer/SubViewport/PreviewWorld/ModelPivot

@onready var category_header: HBoxContainer = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/VBoxContainer/CategoryHeader/TabHBox
@onready var category_title: Label = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/VBoxContainer/CategoryHeader/CategoryTitle
@onready var workspace_vbox: VBoxContainer = $Control/MarginContainer/VBoxContainer/MainHBox/ControlsCard/VBoxContainer/WorkspaceVBox

@onready var back_button: Button = $Control/MarginContainer/VBoxContainer/FooterBox/BackButton
@onready var save_button: Button = $Control/MarginContainer/VBoxContainer/FooterBox/SaveButton

var active_avatar_instance: Node3D = null
var active_tab_index: int = 0
var current_hair_page: int = 0
var current_eye_page: int = 0

const PAGE_SIZE: int = 12

# Threshold Warm Theme Colors
const COLOR_ORANGE_ACTIVE: Color = Color(0.9, 0.45, 0.08, 1.0) # #E67314
const COLOR_CREAM_BLOB: Color = Color(0.96, 0.93, 0.85, 0.95)
const COLOR_DARK_BROWN: Color = Color(0.18, 0.15, 0.10, 1.0)

const SKIN_PALETTE: Array[Color] = [
	Color(0.96, 0.82, 0.73), Color(0.92, 0.76, 0.65), Color(0.85, 0.65, 0.52), Color(0.72, 0.52, 0.38),
	Color(0.55, 0.38, 0.26), Color(0.42, 0.28, 0.18), Color(0.30, 0.18, 0.12), Color(0.20, 0.12, 0.08)
]

const HAIR_PALETTE: Array[Color] = [
	Color(0.12, 0.10, 0.08), Color(0.24, 0.16, 0.10), Color(0.45, 0.28, 0.15), Color(0.65, 0.42, 0.22),
	Color(0.85, 0.68, 0.35), Color(0.75, 0.22, 0.18), Color(0.52, 0.28, 0.48), Color(0.22, 0.55, 0.68)
]

const EYE_PALETTE: Array[Color] = [
	Color(0.12, 0.10, 0.08), Color(0.18, 0.55, 0.85), Color(0.25, 0.65, 0.35), Color(0.68, 0.35, 0.18),
	Color(0.55, 0.25, 0.65), Color(0.75, 0.62, 0.20)
]

const CATEGORIES: Array[Dictionary] = [
	{"name": "Skin Tone", "icon": "😊", "mode": "SKIN"},
	{"name": "Hairstyle", "icon": "💇", "mode": "HAIR"},
	{"name": "Eyes", "icon": "👀", "mode": "EYES"},
	{"name": "Nose & Mouth", "icon": "👃", "mode": "NOSE_MOUTH"},
	{"name": "Glasses", "icon": "👓", "mode": "GLASSES"}
]

@export var is_development_mode: bool = false

var camera_tween: Tween = null
var camera_presets: Dictionary = {
	"SKIN": {"pos": [0.12, 1.42, 1.4], "rot": [-4.0, 18.0, 0.0], "pivot_y": -15.0},
	"HAIR": {"pos": [0.12, 1.42, 1.4], "rot": [-4.0, 18.0, 0.0], "pivot_y": -15.0},
	"FACE": {"pos": [0.0, 1.55, 1.05], "rot": [-2.0, 0.0, 0.0], "pivot_y": 0.0}
}
var cam_tuner_layer: CanvasLayer = null
var _tuner_opt: OptionButton = null
var _tuner_rebuild_rows: Callable = Callable()

func _ready() -> void:
	if back_button: back_button.pressed.connect(_on_back_pressed)
	if save_button: save_button.pressed.connect(_on_save_pressed)

	_load_camera_presets()
	_setup_category_tabs()
	_update_character_preview()
	_animate_camera_for_tab(CATEGORIES[0]["mode"])
	_render_active_workspace()

	var is_dev = is_development_mode or (GameController and GameController.is_development_mode)
	if is_dev:
		_setup_cam_tuner_widget()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_Q:
			_switch_tab(posmod(active_tab_index - 1, CATEGORIES.size()))
		elif event.keycode == KEY_E:
			_switch_tab(posmod(active_tab_index + 1, CATEGORIES.size()))

func _load_camera_presets() -> void:
	var user_path = "user://customization_camera_presets.json"
	var res_path = "res://resources/customization_camera_presets.json"
	var target_path = user_path if FileAccess.file_exists(user_path) else (res_path if FileAccess.file_exists(res_path) else "")
	if target_path != "":
		var f = FileAccess.open(target_path, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				for k in json.data.keys():
					camera_presets[k] = json.data[k]

func _save_camera_presets() -> void:
	var json_str = JSON.stringify(camera_presets, "  ")
	var u_f = FileAccess.open("user://customization_camera_presets.json", FileAccess.WRITE)
	if u_f:
		u_f.store_string(json_str)
		u_f.close()

	var res_p = ProjectSettings.globalize_path("res://resources/customization_camera_presets.json")
	if res_p == "":
		res_p = "c:/Users/User/Documents/THRESHOLD/client/resources/customization_camera_presets.json"
	var r_f = FileAccess.open(res_p, FileAccess.WRITE)
	if not r_f:
		r_f = FileAccess.open("res://resources/customization_camera_presets.json", FileAccess.WRITE)
	if r_f:
		r_f.store_string(json_str)
		r_f.close()

func _process(delta: float) -> void:
	# Real-time LookIK Head Tracking toward Mouse Cursor
	if active_avatar_instance and viewport and camera:
		var mouse_pos = viewport.get_mouse_position()
		var vp_size = viewport.size
		if vp_size.x > 0 and vp_size.y > 0:
			var norm_x = (mouse_pos.x / float(vp_size.x) - 0.5) * 2.0
			var norm_y = (mouse_pos.y / float(vp_size.y) - 0.5) * 2.0

			var target_yaw = clamp(-norm_x * deg_to_rad(24.0), deg_to_rad(-35.0), deg_to_rad(35.0))
			var target_pitch = clamp(-norm_y * deg_to_rad(15.0), deg_to_rad(-20.0), deg_to_rad(20.0))

			var skel = active_avatar_instance.find_child("Skeleton3D", true, false) as Skeleton3D
			if skel:
				var head_idx = skel.find_bone("mixamorig:Head")
				if head_idx != -1:
					var cur_pose = skel.get_bone_pose_rotation(head_idx)
					var target_q = Quaternion.from_euler(Vector3(target_pitch, target_yaw, 0.0))
					skel.set_bone_pose_rotation(head_idx, cur_pose.slerp(target_q, 8.0 * delta))

func _setup_category_tabs() -> void:
	if not category_header:
		return
	for child in category_header.get_children():
		child.queue_free()

	for i in range(CATEGORIES.size()):
		var cat = CATEGORIES[i]
		var btn = Button.new()
		btn.text = "%s %s" % [cat["icon"], cat["name"]]
		btn.custom_minimum_size = Vector2(90, 44)
		btn.pivot_offset = Vector2(45, 22)
		btn.pressed.connect(func(): _switch_tab(i))
		category_header.add_child(btn)

func _mode_to_stage_key(mode: String) -> String:
	match mode:
		"SKIN": return "SKIN"
		"HAIR": return "HAIR"
		_: return "FACE"

func _stage_key_to_opt_index(stage_key: String) -> int:
	match stage_key:
		"SKIN": return 0
		"HAIR": return 1
		_: return 2

func _switch_tab(index: int) -> void:
	active_tab_index = index
	var cat = CATEGORIES[index]
	if category_title:
		category_title.text = cat["name"]

	for i in range(category_header.get_child_count()):
		var btn = category_header.get_child(i) as Button
		if btn:
			var is_active = (i == active_tab_index)
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if is_active:
				tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)
			else:
				tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)

	var stage_key = _mode_to_stage_key(cat["mode"])
	_animate_camera_for_tab(stage_key)

	# Sync tuner dropdown to match the active category
	if _tuner_opt:
		_tuner_opt.selected = _stage_key_to_opt_index(stage_key)
	if _tuner_rebuild_rows.is_valid():
		_tuner_rebuild_rows.call(stage_key)

	_render_active_workspace()

func _animate_camera_for_tab(mode: String) -> void:
	if not camera or not model_pivot:
		return

	var stage_key = _mode_to_stage_key(mode)
	var preset = camera_presets.get(stage_key, {"pos": [0.0, 1.05, 2.5], "rot": [0.0, 0.0, 0.0], "pivot_y": 0.0})

	var target_pos = Vector3(preset["pos"][0], preset["pos"][1], preset["pos"][2])
	var target_rot = Vector3(preset["rot"][0], preset["rot"][1], preset["rot"][2])
	var target_pivot_y = deg_to_rad(preset["pivot_y"])

	if camera_tween and camera_tween.is_running():
		camera_tween.kill()

	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(camera, "position", target_pos, 0.45)
	camera_tween.tween_property(camera, "rotation_degrees", target_rot, 0.45)
	camera_tween.tween_property(model_pivot, "rotation:y", target_pivot_y, 0.45)

func _render_active_workspace() -> void:
	if not workspace_vbox:
		return
	for child in workspace_vbox.get_children():
		child.queue_free()

	var mode = CATEGORIES[active_tab_index]["mode"]
	match mode:
		"SKIN": _build_skin_workspace()
		"HAIR": _build_hair_workspace()
		"EYES": _build_eyes_workspace()
		"NOSE_MOUTH": _build_nose_mouth_workspace()
		"GLASSES": _build_glasses_workspace()

func _create_section_label(txt: String) -> Label:
	var lbl = Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", COLOR_DARK_BROWN)
	lbl.add_theme_font_size_override("font_size", 15)
	return lbl

func _create_option_blob(title_text: String, is_selected: bool, on_click: Callable) -> Button:
	var btn = Button.new()
	btn.text = title_text
	btn.custom_minimum_size = Vector2(80, 70)
	btn.pivot_offset = Vector2(40, 35)

	var sb = StyleBoxFlat.new()
	sb.bg_color = COLOR_ORANGE_ACTIVE if is_selected else COLOR_CREAM_BLOB
	sb.set_corner_radius_all(14)
	sb.border_width_left = 3 if is_selected else 1
	sb.border_width_top = 3 if is_selected else 1
	sb.border_width_right = 3 if is_selected else 1
	sb.border_width_bottom = 3 if is_selected else 1
	sb.border_color = COLOR_ORANGE_ACTIVE if is_selected else Color(0.85, 0.80, 0.70)
	btn.add_theme_stylebox_override("normal", sb)

	btn.pressed.connect(func():
		var tw = btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.1)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		on_click.call()
	)
	return btn

func _create_color_swatch(col: Color, is_selected: bool, on_click: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(42, 42)
	btn.pivot_offset = Vector2(21, 21)

	var sb = StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(21)
	sb.border_width_left = 4 if is_selected else 2
	sb.border_width_top = 4 if is_selected else 2
	sb.border_width_right = 4 if is_selected else 2
	sb.border_width_bottom = 4 if is_selected else 2
	sb.border_color = COLOR_ORANGE_ACTIVE if is_selected else Color(1, 1, 1, 0.8)
	btn.add_theme_stylebox_override("normal", sb)

	btn.pressed.connect(func():
		var tw = btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.1)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		on_click.call()
	)
	return btn

# --- Category Workspace Implementations ---

func _build_skin_workspace() -> void:
	workspace_vbox.add_child(_create_section_label("Select Skin Tone:"))
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	workspace_vbox.add_child(grid)

	var cur_skin: Color = PlayerStore.customization.get("skin_color", Color(0.92, 0.76, 0.65))
	for i in range(SKIN_PALETTE.size()):
		var col = SKIN_PALETTE[i]
		var is_sel = (cur_skin.to_html() == col.to_html())
		var swatch = _create_color_swatch(col, is_sel, func():
			PlayerStore.customization["skin_color"] = col
			_update_character_preview()
			_render_active_workspace()
		)
		grid.add_child(swatch)

func _build_hair_workspace() -> void:
	workspace_vbox.add_child(_create_section_label("Select Hair Style:"))

	var paged_hbox = HBoxContainer.new()
	var prev_b = Button.new(); prev_b.text = "<"
	prev_b.pressed.connect(func(): current_hair_page = posmod(current_hair_page - 1, 23); _render_active_workspace())
	paged_hbox.add_child(prev_b)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	paged_hbox.add_child(grid)

	var next_b = Button.new(); next_b.text = ">"
	next_b.pressed.connect(func(): current_hair_page = posmod(current_hair_page + 1, 23); _render_active_workspace())
	paged_hbox.add_child(next_b)
	workspace_vbox.add_child(paged_hbox)

	var cur_hair: int = PlayerStore.customization.get("hair_style", 0)
	var start_idx = current_hair_page * PAGE_SIZE
	for i in range(PAGE_SIZE):
		var h_idx = start_idx + i
		if h_idx > 270: break
		var is_sel = (cur_hair == h_idx)
		var blob = _create_option_blob("Style %d" % (h_idx + 1), is_sel, func():
			PlayerStore.customization["hair_style"] = h_idx
			if active_avatar_instance:
				var h_col = PlayerStore.customization.get("hair_color", Color(0.24, 0.16, 0.10))
				CharacterFactory.attach_hair_to_character(active_avatar_instance, h_idx, h_col)
			_render_active_workspace()
		)
		grid.add_child(blob)

	workspace_vbox.add_child(HSeparator.new())
	workspace_vbox.add_child(_create_section_label("Hair Color:"))
	var color_row = HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 12)
	workspace_vbox.add_child(color_row)

	var cur_h_col: Color = PlayerStore.customization.get("hair_color", Color(0.24, 0.16, 0.10))
	for col in HAIR_PALETTE:
		var is_sel = (cur_h_col.to_html() == col.to_html())
		var swatch = _create_color_swatch(col, is_sel, func():
			PlayerStore.customization["hair_color"] = col
			if active_avatar_instance:
				var h_style = PlayerStore.customization.get("hair_style", 0)
				CharacterFactory.attach_hair_to_character(active_avatar_instance, h_style, col)
			_render_active_workspace()
		)
		color_row.add_child(swatch)

func _build_eyes_workspace() -> void:
	workspace_vbox.add_child(_create_section_label("Select Eye Style:"))

	var paged_hbox = HBoxContainer.new()
	var prev_b = Button.new(); prev_b.text = "<"
	prev_b.pressed.connect(func(): current_eye_page = posmod(current_eye_page - 1, 5); _render_active_workspace())
	paged_hbox.add_child(prev_b)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	paged_hbox.add_child(grid)

	var next_b = Button.new(); next_b.text = ">"
	next_b.pressed.connect(func(): current_eye_page = posmod(current_eye_page + 1, 5); _render_active_workspace())
	paged_hbox.add_child(next_b)
	workspace_vbox.add_child(paged_hbox)

	var cur_eye: int = PlayerStore.customization.get("eye_style", 1)
	var start_idx = current_eye_page * PAGE_SIZE
	for i in range(PAGE_SIZE):
		var e_idx = start_idx + i + 1
		if e_idx > 60: break
		var is_sel = (cur_eye == e_idx)
		var blob = _create_option_blob("Eye %d" % e_idx, is_sel, func():
			PlayerStore.customization["eye_style"] = e_idx
			_update_character_preview()
			_render_active_workspace()
		)
		grid.add_child(blob)

	workspace_vbox.add_child(HSeparator.new())
	workspace_vbox.add_child(_create_section_label("Iris Color:"))
	var color_row = HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 12)
	workspace_vbox.add_child(color_row)

	var cur_iris: Color = PlayerStore.customization.get("eye_iris_color", Color(0.18, 0.55, 0.85))
	for col in EYE_PALETTE:
		var is_sel = (cur_iris.to_html() == col.to_html())
		var swatch = _create_color_swatch(col, is_sel, func():
			PlayerStore.customization["eye_iris_color"] = col
			_update_character_preview()
			_render_active_workspace()
		)
		color_row.add_child(swatch)

func _build_nose_mouth_workspace() -> void:
	workspace_vbox.add_child(_create_section_label("Nose Shape:"))
	var nose_row = HBoxContainer.new()
	nose_row.add_theme_constant_override("separation", 12)
	workspace_vbox.add_child(nose_row)

	var cur_nose: int = PlayerStore.customization.get("nose_style", 1)
	for n_idx in range(1, 7):
		var is_sel = (cur_nose == n_idx)
		var blob = _create_option_blob("Nose %d" % n_idx, is_sel, func():
			PlayerStore.customization["nose_style"] = n_idx
			_update_character_preview()
			_render_active_workspace()
		)
		nose_row.add_child(blob)

	workspace_vbox.add_child(HSeparator.new())
	workspace_vbox.add_child(_create_section_label("Mouth Shape:"))
	var mouth_row = HBoxContainer.new()
	mouth_row.add_theme_constant_override("separation", 12)
	workspace_vbox.add_child(mouth_row)

	var cur_mouth: int = PlayerStore.customization.get("mouth_style", 1)
	for m_idx in range(1, 7):
		var is_sel = (cur_mouth == m_idx)
		var blob = _create_option_blob("Mouth %d" % m_idx, is_sel, func():
			PlayerStore.customization["mouth_style"] = m_idx
			_update_character_preview()
			_render_active_workspace()
		)
		mouth_row.add_child(blob)

func _build_glasses_workspace() -> void:
	workspace_vbox.add_child(_create_section_label("Glasses / Eyewear:"))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	workspace_vbox.add_child(grid)

	const GLASSES_LIST = ["None", "Style 1", "Style 2", "Style 3", "Style 4"]
	var cur_acc: int = PlayerStore.customization.get("glasses_style", 0)
	for g_idx in range(GLASSES_LIST.size()):
		var is_sel = (cur_acc == g_idx)
		var blob = _create_option_blob(GLASSES_LIST[g_idx], is_sel, func():
			PlayerStore.customization["glasses_style"] = g_idx
			_update_character_preview()
			_render_active_workspace()
		)
		grid.add_child(blob)

func _update_character_preview() -> void:
	if not model_pivot:
		return
	for child in model_pivot.get_children():
		model_pivot.remove_child(child)
		child.free()
	active_avatar_instance = CharacterFactory.create_character_mesh("player")
	model_pivot.add_child(active_avatar_instance)

func _on_save_pressed() -> void:
	PlayerStore.save_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_back_pressed() -> void:
	PlayerStore.load_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _setup_cam_tuner_widget() -> void:
	cam_tuner_layer = CanvasLayer.new()
	cam_tuner_layer.name = "CamTunerLayer"
	cam_tuner_layer.layer = 100
	add_child(cam_tuner_layer)

	var panel = PanelContainer.new()
	panel.name = "CamTunerPanel"
	panel.visible = true

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.10, 0.12, 0.14, 0.94)
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	style_box.content_margin_left = 14
	style_box.content_margin_right = 14
	style_box.content_margin_top = 14
	style_box.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style_box)

	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -340
	panel.offset_right = -16
	panel.offset_top = -520
	panel.offset_bottom = -16

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎥 Customization Camera Tuner"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	var status_label = Label.new()
	status_label.text = "Developer Mode Active"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(status_label)

	vbox.add_child(HSeparator.new())

	# Stage Selection Dropdown
	var stage_hbox = HBoxContainer.new()
	var stage_lbl = Label.new()
	stage_lbl.text = "Editing Stage:"
	stage_lbl.custom_minimum_size = Vector2(95, 0)
	stage_lbl.add_theme_font_size_override("font_size", 12)
	stage_hbox.add_child(stage_lbl)

	var opt = OptionButton.new()
	opt.add_item("SKIN (Full Body)", 0)
	opt.add_item("HAIR (3/4 View)", 1)
	opt.add_item("FACE (Eyes/Nose/Glasses)", 2)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_hbox.add_child(opt)
	vbox.add_child(stage_hbox)
	_tuner_opt = opt

	var rows_container = VBoxContainer.new()
	rows_container.add_theme_constant_override("separation", 6)
	vbox.add_child(rows_container)

	var create_row = func(label_text: String, min_val: float, max_val: float, step_val: float, initial_val: float, on_val_changed: Callable) -> HBoxContainer:
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(95, 0)
		lbl.add_theme_font_size_override("font_size", 12)
		hbox.add_child(lbl)

		var slider = HSlider.new()
		slider.min_value = min_val
		slider.max_value = max_val
		slider.step = step_val
		slider.value = initial_val
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(slider)

		var spin = SpinBox.new()
		spin.min_value = min_val
		spin.max_value = max_val
		spin.step = step_val
		spin.value = initial_val
		spin.custom_minimum_size = Vector2(65, 0)
		spin.add_theme_font_size_override("font_size", 11)
		hbox.add_child(spin)

		slider.value_changed.connect(func(v):
			spin.set_value_no_signal(v)
			on_val_changed.call(v)
		)
		spin.value_changed.connect(func(v):
			slider.set_value_no_signal(v)
			on_val_changed.call(v)
		)
		return hbox

	# rebuild_rows now accepts an explicit stage key so it can be driven externally
	var rebuild_rows: Callable
	rebuild_rows = func(stage_key: String):
		for child in rows_container.get_children():
			child.queue_free()

		var p = camera_presets.get(stage_key, {"pos": [0.0, 1.05, 2.5], "rot": [0.0, 0.0, 0.0], "pivot_y": 0.0})
		var cur_p = Vector3(p["pos"][0], p["pos"][1], p["pos"][2])
		var cur_r = Vector3(p["rot"][0], p["rot"][1], p["rot"][2])
		var cur_py = float(p["pivot_y"])

		rows_container.add_child(create_row.call("Cam Pos X:", -3.0, 3.0, 0.01, cur_p.x, func(v):
			p["pos"][0] = snapped(v, 0.01)
			if camera: camera.position.x = v
		))
		rows_container.add_child(create_row.call("Cam Pos Y:", -1.0, 4.0, 0.01, cur_p.y, func(v):
			p["pos"][1] = snapped(v, 0.01)
			if camera: camera.position.y = v
		))
		rows_container.add_child(create_row.call("Cam Pos Z:", 0.2, 8.0, 0.01, cur_p.z, func(v):
			p["pos"][2] = snapped(v, 0.01)
			if camera: camera.position.z = v
		))
		rows_container.add_child(create_row.call("Cam Rot Pitch:", -90.0, 90.0, 0.5, cur_r.x, func(v):
			p["rot"][0] = snapped(v, 0.1)
			if camera: camera.rotation_degrees.x = v
		))
		rows_container.add_child(create_row.call("Cam Rot Yaw:", -180.0, 180.0, 0.5, cur_r.y, func(v):
			p["rot"][1] = snapped(v, 0.1)
			if camera: camera.rotation_degrees.y = v
		))
		rows_container.add_child(create_row.call("Cam Rot Roll:", -180.0, 180.0, 0.5, cur_r.z, func(v):
			p["rot"][2] = snapped(v, 0.1)
			if camera: camera.rotation_degrees.z = v
		))
		rows_container.add_child(create_row.call("Model Yaw:", -180.0, 180.0, 0.5, cur_py, func(v):
			p["pivot_y"] = snapped(v, 0.1)
			if model_pivot: model_pivot.rotation_degrees.y = v
		))

	_tuner_rebuild_rows = rebuild_rows

	# When the user manually picks a stage from the dropdown
	opt.item_selected.connect(func(idx):
		var sk = "SKIN" if idx == 0 else ("HAIR" if idx == 1 else "FACE")
		_animate_camera_for_tab(sk)
		rebuild_rows.call(sk)
	)

	rebuild_rows.call("SKIN")

	var save_btn = Button.new()
	save_btn.text = "💾 SAVE ALL STAGE CAMERAS TO JSON"
	vbox.add_child(save_btn)

	save_btn.pressed.connect(func():
		_save_camera_presets()
		status_label.text = "✓ Camera presets saved to JSON!"
		print("SAVED_CUSTOMIZATION_CAMERAS: ", camera_presets)
	)

	cam_tuner_layer.add_child(panel)
