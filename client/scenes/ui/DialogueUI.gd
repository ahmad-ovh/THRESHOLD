# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var speaker_label: Label = $DialogueBox/VBoxContainer/HeaderContainer/SpeakerLabel
@onready var loading_label: Label = $DialogueBox/VBoxContainer/HeaderContainer/LoadingLabel
@onready var dialogue_text: RichTextLabel = $DialogueBox/VBoxContainer/DialogueText
@onready var message_input: LineEdit = $DialogueBox/VBoxContainer/InputContainer/MessageInput
@onready var send_button: Button = $DialogueBox/VBoxContainer/InputContainer/SendButton

signal message_submitted(text: String)

var dialogue_history: Array[String] = []
var active_npc_name: String = ""
var is_thinking: bool = false
var thinking_timer: float = 0.0
var dot_count: int = 1

func _ready() -> void:
	visible = false
	loading_label.visible = false
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(_on_text_submitted)

func _process(delta: float) -> void:
	if is_thinking:
		thinking_timer += delta
		if thinking_timer >= 0.35:
			thinking_timer = 0.0
			dot_count = (dot_count % 3) + 1
			var dots = ".".repeat(dot_count)
			loading_label.text = "💭 Thinking" + dots
			_update_history_with_thinking(dots)

func show_connecting_state(npc_name: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	visible = true
	dialogue_history.clear()
	dialogue_text.text = "[color=yellow][i]Approaching " + active_npc_name + "... Connecting to conversation...[/i][/color]"
	message_input.editable = false
	send_button.disabled = true
	loading_label.visible = true
	loading_label.text = "⏳ Connecting..."

func open_dialogue(npc_name: String, opening_line: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	visible = true
	stop_thinking()
	
	dialogue_history.clear()
	var line = "[b]" + active_npc_name + ":[/b] " + opening_line
	dialogue_history.append(line)
	dialogue_text.text = line
	
	message_input.editable = true
	send_button.disabled = false
	message_input.placeholder_text = "Type your response here..."
	message_input.grab_focus()

func append_player_message(text: String) -> void:
	var player_line = "[b]You:[/b] " + text
	dialogue_history.append(player_line)
	_refresh_dialogue_text()
	start_thinking()

func start_thinking() -> void:
	is_thinking = true
	thinking_timer = 0.0
	dot_count = 1
	loading_label.visible = true
	loading_label.text = "💭 Thinking."
	message_input.editable = false
	message_input.placeholder_text = active_npc_name + " is thinking..."
	send_button.disabled = true
	_update_history_with_thinking(".")

func stop_thinking() -> void:
	is_thinking = false
	loading_label.visible = false

func display_reply(text: String) -> void:
	stop_thinking()
	var npc_line = "[b]" + active_npc_name + ":[/b] " + text
	dialogue_history.append(npc_line)
	_refresh_dialogue_text()
	
	# Typewriter effect on dialogue text
	dialogue_text.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, 1.0)
	
	message_input.editable = true
	message_input.placeholder_text = "Type your response here..."
	send_button.disabled = false
	message_input.grab_focus()

func display_error(error_msg: String) -> void:
	stop_thinking()
	dialogue_history.append("[color=red][b]Error:[/b] " + error_msg + "[/color]")
	_refresh_dialogue_text()
	message_input.editable = true
	send_button.disabled = false

func close_dialogue() -> void:
	stop_thinking()
	visible = false

func _refresh_dialogue_text() -> void:
	dialogue_text.text = "\n\n".join(dialogue_history)
	await get_tree().process_frame
	dialogue_text.scroll_to_line(dialogue_text.get_line_count())

func _update_history_with_thinking(dots: String) -> void:
	var thinking_msg = "[color=gray][i]" + active_npc_name + " is thinking" + dots + "[/i][/color]"
	var temp_list = dialogue_history.duplicate()
	temp_list.append(thinking_msg)
	dialogue_text.text = "\n\n".join(temp_list)
	dialogue_text.scroll_to_line(dialogue_text.get_line_count())

func _on_text_submitted(_text: String) -> void:
	_on_send_pressed()

func _on_send_pressed() -> void:
	if is_thinking:
		return
	var txt = message_input.text.strip_edges()
	if txt != "":
		message_input.text = ""
		append_player_message(txt)
		message_submitted.emit(txt)
