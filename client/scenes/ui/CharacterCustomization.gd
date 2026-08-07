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

func _ready() -> void:
	if back_button: back_button.pressed.connect(_on_back_pressed)
	if save_button: save_button.pressed.connect(_on_save_pressed)

	_setup_category_tabs()
	_update_character_preview()
	_render_active_workspace()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_Q:
			_switch_tab(posmod(active_tab_index - 1, CATEGORIES.size()))
		elif event.keycode == KEY_E:
			_switch_tab(posmod(active_tab_index + 1, CATEGORIES.size()))

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

	_render_active_workspace()

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
		child.queue_free()
	active_avatar_instance = CharacterFactory.create_character_mesh("player")
	model_pivot.add_child(active_avatar_instance)

func _on_save_pressed() -> void:
	PlayerStore.save_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_back_pressed() -> void:
	PlayerStore.load_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
