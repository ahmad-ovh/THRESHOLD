# res://scenes/ui/HUD.gd
extends CanvasLayer

@onready var player_id_label: Label = $TopBar/MarginContainer/HBoxContainer/PlayerIdLabel
@onready var level_label: Label = $TopBar/MarginContainer/HBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $TopBar/MarginContainer/HBoxContainer/XPProgressBar
@onready var streak_label: Label = $TopBar/MarginContainer/HBoxContainer/StreakLabel
@onready var journal_button: Button = $TopBar/MarginContainer/HBoxContainer/JournalButton

var journal_ref: CanvasLayer = null

func _ready() -> void:
	journal_button.pressed.connect(_toggle_journal)
	PlayerStore.player_data_updated.connect(_update_hud)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		_toggle_journal()

func _update_hud() -> void:
	player_id_label.text = "Player: " + PlayerStore.player_id
	level_label.text = "Lvl " + str(PlayerStore.level)
	xp_bar.value = PlayerStore.xp_progress * 100.0
	streak_label.text = "🔥 " + str(PlayerStore.daily_streak)

func _toggle_journal() -> void:
	if not journal_ref:
		var scene = preload("res://scenes/ui/JournalUI.tscn")
		journal_ref = scene.instantiate()
		get_tree().root.add_child(journal_ref)
		
	journal_ref.toggle()
