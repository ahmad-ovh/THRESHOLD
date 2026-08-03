# res://scenes/ui/PauseMenu.gd
extends CanvasLayer

@onready var resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $Control/VBoxContainer/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Process input even when scene tree is paused
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed() -> void:
	GameController.set_paused(false)

func _on_main_menu_pressed() -> void:
	GameController.return_to_main_menu()
