# res://scenes/ui/HUD.gd
extends CanvasLayer

@onready var player_id_label: Label = $PlayerInfoCard/MarginContainer/VBoxContainer/PlayerIdLabel
@onready var level_label: Label = $PlayerInfoCard/MarginContainer/VBoxContainer/HBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $PlayerInfoCard/MarginContainer/VBoxContainer/HBoxContainer/XPProgressBar
@onready var streak_label: Label = $PlayerInfoCard/MarginContainer/VBoxContainer/HBoxContainer/StreakLabel
@onready var id_card_button: TextureButton = $IdCardButton
@onready var journal_button: TextureButton = $JournalButton
@onready var objective_banner: PanelContainer = $ObjectiveBanner
@onready var objective_label: Label = $ObjectiveBanner/MarginContainer/ObjectiveLabel

var journal_ref: CanvasLayer = null
var id_card_ref: CanvasLayer = null

func _ready() -> void:
	id_card_button.pressed.connect(_on_id_card_pressed)
	journal_button.pressed.connect(_on_journal_pressed)
	
	_setup_hover_effect(id_card_button, -4.0)
	_setup_hover_effect(journal_button, 4.0)
	
	PlayerStore.player_data_updated.connect(_update_hud)
	_update_hud()
	set_objective("Objective: Approach an NPC and press [E] to talk")

func _setup_hover_effect(btn: Control, tilt_angle: float) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		if AudioManager and AudioManager.has_method("play_hover"):
			AudioManager.play_hover()
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.18)
		tween.tween_property(btn, "rotation_degrees", tilt_angle, 0.18)
	)
	
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
		tween.tween_property(btn, "rotation_degrees", 0.0, 0.15)
	)

	if btn is BaseButton:
		(btn as BaseButton).button_down.connect(func():
			btn.pivot_offset = btn.size / 2.0
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.08)
		)
		(btn as BaseButton).button_up.connect(func():
			btn.pivot_offset = btn.size / 2.0
			var target_s = Vector2(1.1, 1.1) if btn.is_hovered() else Vector2(1.0, 1.0)
			var target_r = tilt_angle if btn.is_hovered() else 0.0
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", target_s, 0.1)
			tween.tween_property(btn, "rotation_degrees", target_r, 0.1)
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_id_card"):
		_toggle_id_card()
	elif event.is_action_pressed("toggle_journal"):
		_toggle_journal()

func set_objective(text: String) -> void:
	objective_banner.visible = true
	objective_label.text = text

func hide_objective() -> void:
	objective_banner.visible = false

func _update_hud() -> void:
	player_id_label.text = "PLAYER: " + PlayerStore.player_id
	level_label.text = "Lvl " + str(PlayerStore.level)
	xp_bar.value = PlayerStore.xp_progress * 100.0
	streak_label.text = "Streak: " + str(PlayerStore.daily_streak)

func _on_id_card_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	_toggle_id_card()

func _on_journal_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	_toggle_journal()

func _toggle_id_card() -> void:
	if not id_card_ref:
		var scene = preload("res://scenes/ui/IdCardUI.tscn")
		id_card_ref = scene.instantiate()
		get_tree().root.add_child(id_card_ref)
		
	id_card_ref.toggle()

func _toggle_journal() -> void:
	if not journal_ref:
		var scene = preload("res://scenes/ui/JournalUI.tscn")
		journal_ref = scene.instantiate()
		get_tree().root.add_child(journal_ref)
		
	journal_ref.toggle()
