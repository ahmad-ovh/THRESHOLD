# res://singletons/EncounterManager.gd
extends Node

enum State { LOBBY, ACTIVE, RESOLVING }

var current_state: State = State.LOBBY
var active_npc_id: String = ""
var dialogue_ui_ref: CanvasLayer = null

func start_encounter(npc_id: String) -> void:
	active_npc_id = npc_id
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		
	var res = await ApiClient.start_interaction(PlayerStore.player_id, npc_id)
	if res.has("error"):
		if player: player.set_physics_process(true)
		return
		
	current_state = State.ACTIVE
	
	# Open Dialogue UI
	if not dialogue_ui_ref:
		var ui_scene = preload("res://scenes/ui/DialogueUI.tscn")
		dialogue_ui_ref = ui_scene.instantiate()
		get_tree().root.add_child(dialogue_ui_ref)
		dialogue_ui_ref.message_submitted.connect(_on_player_message_submitted)
		
	dialogue_ui_ref.open_dialogue(res.get("npc_name", npc_id), res.get("opening_line", ""))

func _on_player_message_submitted(text: String) -> void:
	var res = await ApiClient.send_message(PlayerStore.player_id, active_npc_id, text)
	if res.has("error"):
		return
		
	dialogue_ui_ref.display_reply(res.get("npc_reply", ""))
	
	# Update mood emoji on active NPC
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.get("npc_id") == active_npc_id and npc.has_method("set_mood_emoji"):
			npc.set_mood_emoji(res.get("npc_expression", "neutral"))
			
	if res.get("encounter_over", false):
		_finalize_encounter()

func _finalize_encounter() -> void:
	current_state = State.RESOLVING
	var res = await ApiClient.end_interaction(PlayerStore.player_id, active_npc_id)
	
	# Refresh player status after encounter end
	var status = await ApiClient.get_player_status(PlayerStore.player_id)
	if not status.has("error"):
		PlayerStore.update_from_status(status)

	# Hide dialogue & unfreeze player
	if dialogue_ui_ref:
		dialogue_ui_ref.close_dialogue()
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		
	current_state = State.LOBBY
