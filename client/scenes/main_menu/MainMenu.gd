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
		PlayerStore.player_id = name_txt
		
		# Fetch initial status
		var status = await ApiClient.get_player_status(name_txt)
		if not status.has("error"):
			PlayerStore.update_from_status(status)
			
		SceneManager.change_room("res://scenes/rooms/Room_Start.tscn")
