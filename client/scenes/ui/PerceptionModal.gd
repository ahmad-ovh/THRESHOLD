# res://scenes/ui/PerceptionModal.gd
extends CanvasLayer

signal acknowledged

@onready var location_label: Label = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/Header/LocationLabel
@onready var npc_label: Label = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/Header/NpcLabel
@onready var relationship_label: Label = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/RelationshipPill/RelationshipLabel
@onready var situation_label: Label = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/SituationLabel
@onready var focus_label: Label = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/FocusLabel
@onready var facts_label: RichTextLabel = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/FactsText
@onready var enter_button: Button = $OverlayRoot/CardPanel/MarginContainer/VBoxContainer/EnterButton

var perception_data: Dictionary = {}

func _ready() -> void:
	visible = false
	enter_button.pressed.connect(_on_enter_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		_on_enter_pressed()

func setup_and_show(data: Dictionary) -> void:
	perception_data = data
	visible = true

	var location_name = str(data.get("location_name", "Local Neighborhood"))
	var npc_name = str(data.get("npc_name", "NPC"))
	var npc_role = str(data.get("npc_role", "Resident"))
	var tier = str(data.get("relationship_tier", "Stranger"))
	var situation = str(data.get("situation", "You approach to speak."))
	var focus = str(data.get("encounter_focus", ""))
	var facts = data.get("known_facts", [])

	location_label.text = "📍 " + location_name
	npc_label.text = npc_name + " (" + npc_role + ")"
	relationship_label.text = "Status: " + (tier if tier != "" else "Stranger")
	situation_label.text = situation
	focus_label.text = "Focus: " + focus if focus != "" else ""

	var facts_text = "[b]What you know:[/b]\n"
	if facts is Array and facts.size() > 0:
		for f in facts:
			facts_text += "• " + str(f) + "\n"
	else:
		facts_text += "• First time meeting this person."
	facts_label.text = facts_text

	enter_button.grab_focus()

func _on_enter_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
	acknowledged.emit()
	queue_free()
