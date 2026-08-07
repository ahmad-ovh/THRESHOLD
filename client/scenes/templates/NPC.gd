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
var anim_body: Node3D
var anim_head: Node3D
var anim_left_arm: Node3D
var anim_right_arm: Node3D
var idle_anim_time: float = 0.0

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

	var model: Node3D
	if active_data and active_data.mesh_scene:
		model = active_data.mesh_scene.instantiate()
	else:
		model = CharacterFactory.create_character_mesh(npc_id)
	mesh_container.add_child(model)

	anim_body = model.find_child("BodyPivot", true, false)
	anim_head = model.find_child("HeadPivot", true, false)
	anim_left_arm = model.find_child("LeftArmPivot", true, false)
	anim_right_arm = model.find_child("RightArmPivot", true, false)
	idle_anim_time = float(hash(npc_id) % 100)

	var name_str = active_data.display_name if active_data else npc_id.capitalize()
	prompt_label.text = "Press [E] to talk to " + name_str
	prompt_label.visible = false
	if active_data:
		set_mood_emoji(active_data.default_expression)

func _process(delta: float) -> void:
	idle_anim_time += delta * 2.0
	_update_idle_animation(delta)

func _update_idle_animation(delta: float) -> void:
	var anim_player: AnimationPlayer = null
	if mesh_container:
		anim_player = mesh_container.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		if anim_player.has_animation("idle") and anim_player.current_animation != "idle":
			anim_player.play("idle")
		return

	if not anim_body:
		return

	match npc_id:
		"prof_adler":
			var breath = sin(idle_anim_time * 1.2) * 0.008
			anim_body.position.y = 0.76 + breath
			if anim_head:
				anim_head.rotation.x = sin(idle_anim_time * 0.4) * deg_to_rad(2.0)
				anim_head.rotation.y = cos(idle_anim_time * 0.3) * deg_to_rad(3.0)

		"daria":
			var breath = sin(idle_anim_time * 1.8) * 0.012
			anim_body.position.y = 0.76 + breath
			if anim_head:
				anim_head.rotation.z = sin(idle_anim_time * 0.8) * deg_to_rad(3.5)

		"barista":
			var breath = sin(idle_anim_time * 2.4) * 0.015
			anim_body.position.y = 0.76 + breath
			if anim_left_arm:
				anim_left_arm.rotation.x = sin(idle_anim_time * 1.2) * deg_to_rad(5.0)

		"ms_hartwell":
			var breath = sin(idle_anim_time * 1.0) * 0.006
			anim_body.position.y = 0.76 + breath
			if anim_head:
				anim_head.rotation.y = sin(idle_anim_time * 0.5) * deg_to_rad(4.0)

		"felix":
			var breath = sin(idle_anim_time * 2.8) * 0.018
			anim_body.position.y = 0.76 + breath
			if anim_head:
				anim_head.rotation.x = sin(idle_anim_time * 1.4) * deg_to_rad(4.0)

		_:
			var breath = sin(idle_anim_time * 1.5) * 0.010
			anim_body.position.y = 0.76 + breath
			if anim_head:
				anim_head.rotation.z = sin(idle_anim_time * 0.6) * deg_to_rad(2.0)

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
