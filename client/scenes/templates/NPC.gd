# res://scenes/templates/NPC.gd
extends CharacterBody3D

@export var npc_id: String = ""
@export var npc_data_registry: Dictionary = {
	"daria": preload("res://resources/npc_data/daria_data.tres"),
	"prof_adler": preload("res://resources/npc_data/prof_adler_data.tres"),
	"ms_hartwell": preload("res://resources/npc_data/ms_hartwell_data.tres"),
	"barista": preload("res://resources/npc_data/barista_data.tres"),
	"ms_okoro": preload("res://resources/npc_data/ms_okoro_data.tres"),
	"mr_vance": preload("res://resources/npc_data/mr_vance_data.tres"),
	"felix": preload("res://resources/npc_data/felix_data.tres"),
	"priya": preload("res://resources/npc_data/priya_data.tres"),
	"nadia": preload("res://resources/npc_data/nadia_data.tres"),
	"tomas": preload("res://resources/npc_data/tomas_data.tres"),
	"seren": preload("res://resources/npc_data/seren_data.tres"),
	"sibling": preload("res://resources/npc_data/sibling_data.tres"),
	"parent": preload("res://resources/npc_data/parent_data.tres"),
	"recurring_stranger": preload("res://resources/npc_data/recurring_stranger_data.tres")
}

@onready var mesh_container: Node3D = $MeshContainer
@onready var mood_sprite: Sprite3D = $HeadMarker/MoodSprite3D
@onready var prompt_label: Label3D = $HeadMarker/PromptLabel3D
@onready var ground_ring: MeshInstance3D = $GroundRing

var active_data: NPCData

func _ready() -> void:
	add_to_group("npcs")
	if ground_ring:
		ground_ring.visible = false
	if npc_data_registry.has(npc_id):
		active_data = npc_data_registry[npc_id]
	_setup_visuals()

func _setup_visuals() -> void:
	for child in mesh_container.get_children():
		child.queue_free()

	if active_data and active_data.mesh_scene:
		mesh_container.add_child(active_data.mesh_scene.instantiate())
	else:
		var model = CharacterFactory.create_character_mesh(npc_id)
		mesh_container.add_child(model)

	var name_str = active_data.display_name if active_data else npc_id.capitalize()
	prompt_label.text = "Press [E] to talk to " + name_str
	prompt_label.visible = false
	if active_data:
		set_mood_emoji(active_data.default_expression)

func set_mood_emoji(expression: String) -> void:
	if active_data and active_data.mood_emojis.has(expression):
		mood_sprite.texture = active_data.mood_emojis[expression]
		_animate_mood_popin()

func _animate_mood_popin() -> void:
	mood_sprite.scale = Vector3.ZERO
	AudioManager.play_mood_pop()
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mood_sprite, "scale", Vector3.ONE * 0.8, 0.35)

func show_prompt(visible_state: bool) -> void:
	prompt_label.visible = visible_state
	if ground_ring:
		ground_ring.visible = visible_state

func interact() -> void:
	EncounterManager.start_encounter(npc_id)
