# res://scenes/ui/PauseMenu.gd
extends CanvasLayer

@onready var resume_button: Button = $Control/PanelContainer/ContentArea/ResumeButton
@onready var main_menu_button: Button = $Control/PanelContainer/ContentArea/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Process input even when scene tree is paused
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	_setup_button_animations(resume_button)
	_setup_button_animations(main_menu_button)

func _setup_button_animations(btn: Button) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _on_resume_pressed() -> void:
	GameController.set_paused(false)

func _on_main_menu_pressed() -> void:
	GameController.return_to_main_menu()
