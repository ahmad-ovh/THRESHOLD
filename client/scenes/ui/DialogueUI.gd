# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var speaker_label: Label = $DialogueBox/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $DialogueBox/VBoxContainer/DialogueText
@onready var message_input: LineEdit = $DialogueBox/VBoxContainer/InputContainer/MessageInput
@onready var send_button: Button = $DialogueBox/VBoxContainer/InputContainer/SendButton

signal message_submitted(text: String)

func _ready() -> void:
	visible = false
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(_on_text_submitted)

func _on_text_submitted(_text: String) -> void:
	_on_send_pressed()

func open_dialogue(npc_name: String, opening_line: String) -> void:
	speaker_label.text = npc_name
	visible = true
	message_input.editable = true
	send_button.disabled = false
	display_reply(opening_line)

func display_reply(text: String) -> void:
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, 1.2)
	message_input.editable = true
	send_button.disabled = false

func set_submitting_state() -> void:
	message_input.editable = false
	send_button.disabled = true

func close_dialogue() -> void:
	visible = false

func _on_send_pressed() -> void:
	var txt = message_input.text.strip_edges()
	if txt != "":
		message_input.text = ""
		set_submitting_state()
		message_submitted.emit(txt)
