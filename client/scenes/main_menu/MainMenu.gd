# res://scenes/main_menu/MainMenu.gd
extends CanvasLayer

@export_group("Game Settings")
@export var enable_storyboard: bool = true

@export_group("Development Mode")
@export var is_development_mode: bool = false
@export var enable_dev_tools: bool = false

@onready var username_input: LineEdit = $Control/LeftPanel/PlayerCard/MarginContainer/VBoxContainer/UsernameInput
@onready var daily_details: RichTextLabel = $Control/RightPanel/DailyCard/MarginContainer/VBoxContainer/DailyDetails
@onready var start_button: Button = $Control/LeftPanel/ButtonsVBox/StartWrapper/StartButton
@onready var customize_button: Button = $Control/LeftPanel/ButtonsVBox/CustomizeWrapper/CustomizeButton
@onready var settings_button: Button = $Control/LeftPanel/ButtonsVBox/SettingsWrapper/SettingsButton
@onready var aligner_wrapper: Control = $Control/LeftPanel/ButtonsVBox/DevAlignerWrapper
@onready var aligner_button: Button = $Control/LeftPanel/ButtonsVBox/DevAlignerWrapper/DevAlignerButton

var _is_transitioning: bool = false

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	customize_button.pressed.connect(_on_customize_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	
	_setup_button_hover_effects(start_button)
	_setup_button_hover_effects(customize_button)
	_setup_button_hover_effects(settings_button)

	if GameController:
		GameController.is_development_mode_changed.connect(func(enabled: bool):
			_update_dev_ui(enabled)
		)
		_update_dev_ui(GameController.is_development_mode)
	else:
		_update_dev_ui(is_development_mode)

	username_input.text_changed.connect(_on_username_changed)
	username_input.text = PlayerStore.player_id
	_fetch_daily(PlayerStore.player_id)

func _update_dev_ui(dev_enabled: bool) -> void:
	aligner_wrapper.visible = dev_enabled
	if dev_enabled and not aligner_button.pressed.is_connected(_on_aligner_pressed):
		aligner_button.pressed.connect(_on_aligner_pressed)
		_setup_button_hover_effects(aligner_button)

func _setup_button_hover_effects(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		if AudioManager and AudioManager.has_method("play_hover"):
			AudioManager.play_hover()
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)
	)
	btn.mouse_exited.connect(func():
		if btn.disabled:
			return
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	)
	btn.button_down.connect(func():
		if btn.disabled:
			return
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
	)
	btn.button_up.connect(func():
		if btn.disabled:
			return
		var target_s = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2(1.0, 1.0)
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", target_s, 0.1)
	)

func _on_username_changed(new_text: String) -> void:
	var trimmed = new_text.strip_edges()
	if trimmed != "":
		_fetch_daily(trimmed)

func _fetch_daily(p_id: String) -> void:
	daily_details.text = "Loading daily scenario..."
	var res = await ApiClient.get_daily_challenge(p_id)
	if res.has("error"):
		daily_details.text = "Connect server to view daily challenge."
		return

	var npc = str(res.get("npc_id", "Mr. Teo")).capitalize()
	var focus = str(res.get("focus", "Clarity + Politeness"))
	var streak = res.get("streak_count", 0)

	var txt = "[b]Featured NPC:[/b] " + npc + "\n"
	txt += "[b]Focus Skills:[/b] " + focus + "\n"
	txt += "[b]Daily Streak:[/b] " + str(streak) + " Days"
	daily_details.text = txt

func _set_buttons_disabled(disabled_state: bool) -> void:
	if is_instance_valid(start_button):
		start_button.disabled = disabled_state
	if is_instance_valid(customize_button):
		customize_button.disabled = disabled_state
	if is_instance_valid(settings_button):
		settings_button.disabled = disabled_state
	if is_instance_valid(aligner_button):
		aligner_button.disabled = disabled_state

func _on_start_pressed() -> void:
	if _is_transitioning or (SceneManager and SceneManager.is_transitioning):
		return
	var name_txt = username_input.text.strip_edges()
	if name_txt == "":
		return
	_is_transitioning = true
	_set_buttons_disabled(true)
	if AudioManager:
		AudioManager.play_click()
	if GameController:
		GameController.enable_storyboard = enable_storyboard
	await GameController.start_new_game(name_txt)
	if is_instance_valid(self):
		_is_transitioning = false
		_set_buttons_disabled(false)

func _on_customize_pressed() -> void:
	if _is_transitioning or (SceneManager and SceneManager.is_transitioning):
		return
	_is_transitioning = true
	_set_buttons_disabled(true)
	if AudioManager:
		AudioManager.play_click()
	await SceneManager.change_room("res://scenes/ui/CharacterCustomization.tscn")
	if is_instance_valid(self):
		_is_transitioning = false
		_set_buttons_disabled(false)

func _on_settings_pressed() -> void:
	if _is_transitioning:
		return
	if AudioManager:
		AudioManager.play_click()
	if ToastManager:
		ToastManager.show_info("Game Settings coming soon!")

func _on_aligner_pressed() -> void:
	if _is_transitioning or (SceneManager and SceneManager.is_transitioning):
		return
	_is_transitioning = true
	_set_buttons_disabled(true)
	if AudioManager:
		AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/tools/ModelAligner.tscn")
