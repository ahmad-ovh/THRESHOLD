# res://singletons/EncounterManager.gd
extends Node

enum State { LOBBY, ACTIVE, RESOLVING }

var current_state: State = State.LOBBY
var active_npc_id: String = ""
var dialogue_ui_ref: CanvasLayer = null
var overview_modal_ref: CanvasLayer = null

func start_encounter(npc_id: String) -> void:
	active_npc_id = npc_id
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		
	if GameController and GameController.hud_ref and GameController.hud_ref.has_method("hide_objective"):
		GameController.hud_ref.hide_objective()
		
	# Find target NPC node
	var target_npc: Node3D = null
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.get("npc_id") == npc_id:
			target_npc = npc
			break

	# Calculate parallel side-by-side standing position (2.4m natural distance) relative to dollhouse camera
	if target_npc and player:
		var standing_offset = Vector3(-2.4, 0.0, 0.0)
		var target_pos = target_npc.global_position + standing_offset
		
		# Smoothly glide player to parallel standing spot
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position:x", target_pos.x, 0.4)
		tween.tween_property(player, "global_position:z", target_pos.z, 0.4)
		
		# Rotate both characters sideways to face each other across the camera view
		if player.has_node("CharacterMesh"):
			var p_mesh = player.get_node("CharacterMesh")
			p_mesh.rotation_degrees.y = 90.0 # Facing right toward NPC
		if target_npc.has_node("MeshContainer"):
			var npc_mesh = target_npc.get_node("MeshContainer")
			npc_mesh.rotation_degrees.y = -90.0 # Facing left toward Player

	# Instantly show Dialogue UI in Connecting mode
	_ensure_dialogue_ui()
	if dialogue_ui_ref.has_method("set_spatial_targets"):
		dialogue_ui_ref.set_spatial_targets(target_npc, player)
	dialogue_ui_ref.show_connecting_state(npc_id)
	
	# Fetch opening line from backend
	var res = await ApiClient.start_interaction(PlayerStore.player_id, npc_id)
	if res.has("error"):
		var detail = res.get("detail", "Could not connect to server.")
		dialogue_ui_ref.display_error(detail)
		if player:
			player.set_physics_process(true)
	# Check Perception Layer for Social Context Onboarding
	var perception = res.get("perception_layer", {})
	if perception is Dictionary and perception.get("show_modal", true):
		var modal_scene = preload("res://scenes/ui/PerceptionModal.tscn")
		var perception_modal = modal_scene.instantiate()
		get_tree().root.add_child(perception_modal)
		perception_modal.setup_and_show(perception)
		await perception_modal.acknowledged

	current_state = State.ACTIVE
	dialogue_ui_ref.open_dialogue(res.get("npc_name", npc_id), res.get("opening_line", ""))

func end_encounter_early() -> void:
	if current_state == State.ACTIVE:
		_finalize_encounter()

func _on_player_message_submitted(text: String) -> void:
	var res = await ApiClient.send_message(PlayerStore.player_id, active_npc_id, text)
	if res.has("error"):
		var detail = res.get("detail", "Failed to send message.")
		dialogue_ui_ref.display_error(detail)
		return
		
	dialogue_ui_ref.update_turn_data(res)
	dialogue_ui_ref.display_reply(res.get("npc_reply", ""))
	
	# Update mood emoji on active NPC
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.get("npc_id") == active_npc_id and npc.has_method("set_mood_emoji"):
			npc.set_mood_emoji(res.get("npc_expression", "neutral"))
			
	if res.get("encounter_over", false):
		_finalize_encounter()

func _finalize_encounter() -> void:
	if current_state == State.RESOLVING:
		return
	current_state = State.RESOLVING
	
	# Allow final closing line to rest gracefully before closing window
	if dialogue_ui_ref:
		await dialogue_ui_ref.close_dialogue_gracefully()
		
	var end_res = await ApiClient.end_interaction(PlayerStore.player_id, active_npc_id)
	
	# Refresh player status after encounter end
	var status = await ApiClient.get_player_status(PlayerStore.player_id)
	if not status.has("error"):
		PlayerStore.update_from_status(status)

	# Present Settlement Overview Modal
	if not end_res.has("error"):
		_ensure_overview_modal()
		overview_modal_ref.show_settlement(end_res, status)
		await overview_modal_ref.closed
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		
	current_state = State.LOBBY

func _ensure_dialogue_ui() -> void:
	if not dialogue_ui_ref:
		var ui_scene = preload("res://scenes/ui/DialogueUI.tscn")
		dialogue_ui_ref = ui_scene.instantiate()
		get_tree().root.add_child(dialogue_ui_ref)
		dialogue_ui_ref.message_submitted.connect(_on_player_message_submitted)
		dialogue_ui_ref.leave_requested.connect(end_encounter_early)

func _ensure_overview_modal() -> void:
	if not overview_modal_ref:
		var scene = preload("res://scenes/ui/OverviewModal.tscn")
		overview_modal_ref = scene.instantiate()
		get_tree().root.add_child(overview_modal_ref)
