# res://scenes/templates/NPC.gd
extends CharacterBody3D

@export var npc_id: String = ""
@export var npc_data_registry: Dictionary = {
	"daria": preload("res://resources/npc_data/daria_data.tres"),
	"prof_adler": preload("res://resources/npc_data/prof_adler_data.tres"),
	"ms_hartwell": preload("res://resources/npc_data/ms_hartwell_data.tres"),
	"barista": preload("res://resources/npc_data/barista_data.tres")
}

@onready var mesh_container: Node3D = $MeshContainer
@onready var mood_sprite: Sprite3D = $HeadMarker/MoodSprite3D
@onready var prompt_label: Label3D = $HeadMarker/PromptLabel3D

var active_data: NPCData

func _ready() -> void:
	add_to_group("npcs")
	if npc_data_registry.has(npc_id):
		active_data = npc_data_registry[npc_id]
		_setup_visuals()
	else:
		# Fallback placeholder if custom data resource isn't assigned
		prompt_label.text = "Press [E] to talk to " + npc_id.capitalize()
		prompt_label.visible = false

func _setup_visuals() -> void:
	if active_data.mesh_scene:
		for child in mesh_container.get_children():
			child.queue_free()
		mesh_container.add_child(active_data.mesh_scene.instantiate())
		
	prompt_label.text = "Press [E] to talk to " + active_data.display_name
	prompt_label.visible = false
	set_mood_emoji(active_data.default_expression)

func set_mood_emoji(expression: String) -> void:
	if active_data and active_data.mood_emojis.has(expression):
		mood_sprite.texture = active_data.mood_emojis[expression]
		_animate_mood_popin()

func _animate_mood_popin() -> void:
	mood_sprite.scale = Vector3.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mood_sprite, "scale", Vector3.ONE * 0.8, 0.35)

func show_prompt(visible_state: bool) -> void:
	prompt_label.visible = visible_state

func interact() -> void:
	EncounterManager.start_encounter(npc_id)
