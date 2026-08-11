@tool
# res://scenes/templates/NPC.gd
extends CharacterBody3D

@export var npc_id: String = ""

@export_group("Interaction Trigger Bounds")
@export var interaction_radius: float = 4.5:
	set(value):
		interaction_radius = max(0.1, value)
		_update_interaction_bounds()

@export var interaction_offset: Vector3 = Vector3(0, 0.9, 0):
	set(value):
		interaction_offset = value
		_update_interaction_bounds()

static var _npc_resource_cache: Dictionary = {}

static func get_npc_data(id: String) -> NPCData:
	if id == "":
		return null
	if _npc_resource_cache.has(id):
		return _npc_resource_cache[id]
	var res_path = "res://resources/npc_data/" + id + "_data.tres"
	if ResourceLoader.exists(res_path):
		var res = load(res_path) as NPCData
		if res:
			_npc_resource_cache[id] = res
			return res
	return null

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
	_update_interaction_bounds()
	if ground_ring:
		ground_ring.visible = false
	if not Engine.is_editor_hint():
		if not active_data and npc_id != "":
			active_data = get_npc_data(npc_id)
		_setup_visuals()

func _update_interaction_bounds() -> void:
	var area_shape = get_node_or_null("InteractionArea/CollisionShape3D")
	if not area_shape:
		return
		
	area_shape.position = interaction_offset
	
	var sphere: SphereShape3D = null
	if area_shape.shape:
		if not area_shape.shape.is_local_to_scene():
			area_shape.shape = area_shape.shape.duplicate()
		sphere = area_shape.shape as SphereShape3D
	else:
		sphere = SphereShape3D.new()
		area_shape.shape = sphere
		
	if sphere:
		sphere.radius = interaction_radius

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
	if Engine.is_editor_hint():
		return
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
