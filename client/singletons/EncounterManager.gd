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

	# Keep player at current standing position (no movement lerp)
	# Smoothly rotate player and NPC to face each other from current positions
	if target_npc and player:
		# 1. Rotate Player toward NPC
		var p_mesh = player.get_node_or_null("CharacterMesh") if player.has_node("CharacterMesh") else player
		if p_mesh:
			var dir_to_npc = (target_npc.global_position - player.global_position).normalized()
			if dir_to_npc.length_squared() > 0.001:
				var p_target_angle = atan2(dir_to_npc.x, dir_to_npc.z)
				var current_angle = p_mesh.rotation.y
				var diff = fmod((p_target_angle - current_angle + PI), TAU) - PI
				var tween_p = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween_p.tween_property(p_mesh, "rotation:y", current_angle + diff, 0.35)

		# 2. Rotate NPC toward Player
		var npc_mesh = target_npc.get_node_or_null("MeshContainer") if target_npc.has_node("MeshContainer") else target_npc
		if npc_mesh:
			var dir_to_player = (player.global_position - target_npc.global_position).normalized()
			if dir_to_player.length_squared() > 0.001:
				var npc_target_angle = atan2(dir_to_player.x, dir_to_player.z)
				var current_angle = npc_mesh.rotation.y
				var diff = fmod((npc_target_angle - current_angle + PI), TAU) - PI
				var tween_npc = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween_npc.tween_property(npc_mesh, "rotation:y", current_angle + diff, 0.35)

	_ensure_dialogue_ui()
	if dialogue_ui_ref.has_method("set_spatial_targets"):
		dialogue_ui_ref.set_spatial_targets(target_npc, player)
	
	# Keep dialogue UI hidden during initial fetch so it does not flash before Perception/Overview Modal
	dialogue_ui_ref.visible = false
	var res = await ApiClient.start_interaction(PlayerStore.player_id, npc_id)
	if res.has("error"):
		dialogue_ui_ref.show_connecting_state(npc_id)
		var detail = res.get("detail", "Could not connect to server.")
		dialogue_ui_ref.display_error(detail)
		if player:
			player.set_physics_process(true)
		return

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

signal prefetch_finished

var _prefetch_data: Dictionary = {}
var _is_prefetching: bool = false

func _start_prefetch(p_id: String, npc_id: String) -> void:
	_is_prefetching = true
	_prefetch_data.clear()
	var end_res = await ApiClient.end_interaction(p_id, npc_id)
	var status = await ApiClient.get_player_status(p_id)
	_prefetch_data = {
		"end_res": end_res,
		"status": status
	}
	_is_prefetching = false
	prefetch_finished.emit()

func _finalize_encounter() -> void:
	if current_state == State.RESOLVING:
		return
	current_state = State.RESOLVING
	
	# Start background generation of settlement and status update immediately via Callable
	# so player experiences zero latency when they confirm dialogue exit
	_start_prefetch.call(PlayerStore.player_id, active_npc_id)
	
	# Close Dialogue UI immediately (no banner)
	if dialogue_ui_ref:
		dialogue_ui_ref.close_dialogue()
		
	# If background prefetch is still in flight, wait for it to complete
	if _is_prefetching:
		await prefetch_finished
		
	var end_res: Dictionary = _prefetch_data.get("end_res", {})
	var status: Dictionary = _prefetch_data.get("status", {})
	_prefetch_data.clear()
	
	# Refresh player status after encounter end
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
