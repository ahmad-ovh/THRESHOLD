# res://scenes/main_menu/MainMenu.gd
extends CanvasLayer

@onready var username_input: LineEdit = $Control/VBoxContainer/UsernameInput
@onready var start_button: Button = $Control/VBoxContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	username_input.text = PlayerStore.player_id

func _on_start_pressed() -> void:
	var name_txt = username_input.text.strip_edges()
	if name_txt != "":
		GameController.start_new_game(name_txt)
