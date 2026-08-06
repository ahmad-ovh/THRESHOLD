# res://scenes/ui/CharacterCustomization.gd
extends CanvasLayer

@onready var back_button: Button = $Control/MarginContainer/VBoxContainer/HeaderBox/BackButton
@onready var save_button: Button = $Control/MarginContainer/VBoxContainer/HeaderBox/SaveButton

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

const HAIR_NAMES: Array[String] = ["Short", "Bob", "Combed", "Spiky", "Afro", "Top Bun", "Beanie", "Cap"]
const ACC_NAMES: Array[String] = ["None", "Glasses", "Scarf", "Backpack", "Crown/Band"]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)

	_setup_customizer_ui()
	_update_character_preview()

func _process(delta: float) -> void:
	if model_pivot:
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

	hair_prev_btn.pressed.connect(func(): _cycle_int("hair_style", -1, 0, HAIR_NAMES.size() - 1))
	hair_next_btn.pressed.connect(func(): _cycle_int("hair_style", 1, 0, HAIR_NAMES.size() - 1))

	eye_prev_btn.pressed.connect(func(): _cycle_int("eye_style", -1, 1, 60))
	eye_next_btn.pressed.connect(func(): _cycle_int("eye_style", 1, 1, 60))

	nose_prev_btn.pressed.connect(func(): _cycle_int("nose_style", -1, 1, 18))
	nose_next_btn.pressed.connect(func(): _cycle_int("nose_style", 1, 1, 18))

	mouth_prev_btn.pressed.connect(func(): _cycle_int("mouth_style", -1, 1, 36))
	mouth_next_btn.pressed.connect(func(): _cycle_int("mouth_style", 1, 1, 36))

	acc_prev_btn.pressed.connect(func(): _cycle_int("accessory_style", -1, 0, ACC_NAMES.size() - 1))
	acc_next_btn.pressed.connect(func(): _cycle_int("accessory_style", 1, 0, ACC_NAMES.size() - 1))

	_refresh_labels()

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
	var hair_name = HAIR_NAMES[hair_idx] if hair_idx >= 0 and hair_idx < HAIR_NAMES.size() else "Custom"
	hair_style_label.text = "%s (%d/%d)" % [hair_name, hair_idx + 1, HAIR_NAMES.size()]

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
	var mesh = CharacterFactory.create_character_mesh("player")
	model_pivot.add_child(mesh)

func _on_save_pressed() -> void:
	PlayerStore.save_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_back_pressed() -> void:
	# Reload saved customization to revert unsaved tweaks if backed out
	PlayerStore.load_customization()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
