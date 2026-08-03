# res://scenes/main_menu/MainMenu.gd
extends CanvasLayer

@onready var username_input: LineEdit = $Control/VBoxContainer/UsernameInput
@onready var daily_details: RichTextLabel = $Control/VBoxContainer/DailyCard/VBoxContainer/DailyDetails
@onready var start_button: Button = $Control/VBoxContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	username_input.text_changed.connect(_on_username_changed)
	username_input.text = PlayerStore.player_id
	_fetch_daily(PlayerStore.player_id)

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
	txt += "[b]Focus Skills:[/b] " + focus + " | 🔥 Streak: " + str(streak)
	daily_details.text = txt

func _on_start_pressed() -> void:
	var name_txt = username_input.text.strip_edges()
	if name_txt != "":
		GameController.start_new_game(name_txt)
