# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var speaker_label: Label = $OverlayRoot/HeaderContainer/SpeakerLabel
@onready var role_badge: Label = $OverlayRoot/HeaderContainer/RoleBadge
@onready var tier_label: Label = $OverlayRoot/HeaderContainer/TierLabel
@onready var mood_label: Label = $OverlayRoot/HeaderContainer/MoodLabel
@onready var loading_label: Label = $OverlayRoot/HeaderContainer/LoadingLabel
@onready var leave_button: Button = $OverlayRoot/HeaderContainer/LeaveButton

@onready var scenario_goal_banner: PanelContainer = $OverlayRoot/ScenarioGoalBanner
@onready var scenario_goal_label: Label = $OverlayRoot/ScenarioGoalBanner/ScenarioGoalLabel
@onready var coach_hint_banner: PanelContainer = $OverlayRoot/CoachHintBanner
@onready var coach_hint_label: Label = $OverlayRoot/CoachHintBanner/CoachHintLabel

@onready var status_ribbon_panel: PanelContainer = $OverlayRoot/StatusRibbonPanel
@onready var status_ribbon_label: Label = $OverlayRoot/StatusRibbonPanel/StatusRibbonLabel

@onready var message_input: LineEdit = $OverlayRoot/BottomInputPanel/InputContainer/MessageInput
@onready var send_button: Button = $OverlayRoot/BottomInputPanel/InputContainer/SendButton

@onready var overall_label: Label = $OverlayRoot/FeedbackPanel/OverallContainer/OverallLabel
@onready var delta_label: Label = $OverlayRoot/FeedbackPanel/OverallContainer/DeltaLabel
@onready var overall_bar: ProgressBar = $OverlayRoot/FeedbackPanel/OverallProgressBar
@onready var status_badge_label: Label = $OverlayRoot/FeedbackPanel/StatusBadgeLabel

@onready var clarity_label: Label = $OverlayRoot/FeedbackPanel/ClarityLabel
@onready var clarity_bar: ProgressBar = $OverlayRoot/FeedbackPanel/ClarityBar
@onready var empathy_label: Label = $OverlayRoot/FeedbackPanel/EmpathyLabel
@onready var empathy_bar: ProgressBar = $OverlayRoot/FeedbackPanel/EmpathyBar
@onready var politeness_label: Label = $OverlayRoot/FeedbackPanel/PolitenessLabel
@onready var politeness_bar: ProgressBar = $OverlayRoot/FeedbackPanel/PolitenessBar
@onready var expression_label: Label = $OverlayRoot/FeedbackPanel/ExpressionLabel
@onready var expression_bar: ProgressBar = $OverlayRoot/FeedbackPanel/ExpressionBar
@onready var feedback_text: RichTextLabel = $OverlayRoot/FeedbackPanel/FeedbackText

@onready var bubbles_container: Control = $OverlayRoot/BubblesContainer

signal message_submitted(text: String)
signal leave_requested

var active_npc_name: String = ""
var active_npc_node: Node3D = null
var active_player_node: Node3D = null

var active_npc_bubble: Control = null
var active_player_bubble: Control = null

var is_thinking: bool = false
var thinking_timer: float = 0.0
var dot_count: int = 1

# Cumulative Encounter Performance Tracking
var turn_history_scores: Array[Dictionary] = []
var previous_overall_score: float = 50.0

func _ready() -> void:
	visible = false
	loading_label.visible = false
	coach_hint_banner.visible = false
	status_ribbon_panel.visible = false
	send_button.pressed.connect(_on_send_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	message_input.text_submitted.connect(_on_text_submitted)
	_reset_encounter_metrics()

func _process(delta: float) -> void:
	if is_thinking:
		thinking_timer += delta
		if thinking_timer >= 0.35:
			thinking_timer = 0.0
			dot_count = (dot_count % 3) + 1
			var dots = ".".repeat(dot_count)
			loading_label.text = active_npc_name + " pauses" + dots
			if active_npc_bubble and active_npc_bubble.has_method("update_text_only"):
				active_npc_bubble.update_text_only("[i]" + active_npc_name + " considers your words" + dots + "[/i]")

func show_status_ribbon(text: String) -> void:
	status_ribbon_label.text = text
	status_ribbon_panel.visible = true
	var tween = create_tween()
	tween.tween_property(status_ribbon_panel, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(2.5).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property(status_ribbon_panel, "modulate:a", 0.0, 0.4)
	await fade_tween.finished
	status_ribbon_panel.visible = false
	status_ribbon_panel.modulate.a = 1.0

func _reset_encounter_metrics() -> void:
	turn_history_scores.clear()
	previous_overall_score = 50.0
	overall_label.text = "Overall: 50%"
	delta_label.text = "[--]"
	delta_label.remove_theme_color_override("font_color")
	overall_bar.value = 50.0
	status_badge_label.text = "Status: Baseline"
	status_badge_label.remove_theme_color_override("font_color")
	
	clarity_bar.value = 50.0
	clarity_label.text = "Clarity: 50%"
	empathy_bar.value = 50.0
	empathy_label.text = "Empathy: 50%"
	politeness_bar.value = 50.0
	politeness_label.text = "Politeness: 50%"
	expression_bar.value = 50.0
	expression_label.text = "Expression: 50%"

func set_spatial_targets(npc_node: Node3D, player_node: Node3D) -> void:
	active_npc_node = npc_node
	active_player_node = player_node

func set_scenario_context(role: String, goal_text: String) -> void:
	role_badge.text = "[Role: " + role.capitalize() + "]"
	scenario_goal_label.text = "Conversation Focus: " + goal_text

func show_connecting_state(npc_name: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	role_badge.text = "[Role: Peer]"
	tier_label.text = "[Tier: Stranger]"
	mood_label.text = "[Mood: neutral]"
	scenario_goal_label.text = "Conversation Focus: Active listening and sharing"
	visible = true
	_clear_bubbles()
	_reset_encounter_metrics()
	
	# Spawn instant in-world speech bubble above NPC
	_spawn_npc_bubble("Walking over to " + active_npc_name + "...")
	
	message_input.editable = false
	send_button.disabled = true
	leave_button.disabled = true
	loading_label.visible = true
	loading_label.text = "Walking over..."
	coach_hint_banner.visible = false
	status_ribbon_panel.visible = false
	feedback_text.text = "Awaiting response..."

func open_dialogue(npc_name: String, opening_line: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	visible = true
	stop_thinking()
	
	# Replace connecting bubble with actual opening line
	_spawn_npc_bubble(opening_line)
	
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false
	message_input.placeholder_text = "Say something to " + active_npc_name + "..."
	message_input.grab_focus()

func append_player_message(text: String) -> void:
	_spawn_player_bubble(text)
	start_thinking()

func update_turn_data(data: Dictionary) -> void:
	var prev_tier = tier_label.text
	
	# Update Status Pills
	if data.has("relationship_tier"):
		var new_tier = str(data.get("relationship_tier", "Stranger"))
		tier_label.text = "[Tier: " + new_tier + "]"
		if prev_tier != "" and prev_tier != "[Tier: " + new_tier + "]":
			show_status_ribbon("Relationship with " + active_npc_name + " deepened: " + new_tier + "!")
			
	if data.has("npc_state"):
		mood_label.text = "[Mood: " + str(data.get("npc_state", "neutral")) + "]"
		
	# Update Coach Hint Banner
	var hint = data.get("coach_hint", {})
	if hint is Dictionary and hint.get("shown", false) == true:
		coach_hint_banner.visible = true
		coach_hint_label.text = "Coach Hint: " + str(hint.get("line", ""))
	else:
		coach_hint_banner.visible = false
		
	# Process Cumulative Turn Scores
	var turn_scores = data.get("turn_scores", {})
	if turn_scores is Dictionary and turn_scores.size() > 0:
		turn_history_scores.append(turn_scores)
		_recalculate_cumulative_performance()
		
	# Update Feedback Text
	var fb = data.get("feedback", {})
	if fb is Dictionary:
		var str_text = fb.get("strength", "")
		var imp_text = fb.get("improvement", "")
		var txt = ""
		if str_text != "":
			txt += "[color=green][b]Strength:[/b] " + str(str_text) + "[/color]\n"
		if imp_text != "":
			txt += "[color=yellow][b]Improvement:[/b] " + str(imp_text) + "[/color]"
		feedback_text.text = txt

func _recalculate_cumulative_performance() -> void:
	if turn_history_scores.size() == 0:
		return
		
	var sum_c: float = 0.0
	var sum_e: float = 0.0
	var sum_p: float = 0.0
	var sum_x: float = 0.0
	var count = float(turn_history_scores.size())
	
	for turn in turn_history_scores:
		sum_c += turn.get("clarity", 0.5)
		sum_e += turn.get("empathy", 0.5)
		sum_p += turn.get("politeness", 0.5)
		sum_x += turn.get("expression", 0.5)
		
	var avg_c = (sum_c / count) * 100.0
	var avg_e = (sum_e / count) * 100.0
	var avg_p = (sum_p / count) * 100.0
	var avg_x = (sum_x / count) * 100.0
	
	var overall = (avg_c + avg_e + avg_p + avg_x) / 4.0
	var delta = overall - previous_overall_score
	previous_overall_score = overall
	
	# Update Overall Score & Bar with smooth animation
	overall_label.text = "Overall: %d%%" % int(overall)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(overall_bar, "value", overall, 0.4)
	tween.tween_property(clarity_bar, "value", avg_c, 0.4)
	tween.tween_property(empathy_bar, "value", avg_e, 0.4)
	tween.tween_property(politeness_bar, "value", avg_p, 0.4)
	tween.tween_property(expression_bar, "value", avg_x, 0.4)
	
	clarity_label.text = "Clarity: %d%%" % int(avg_c)
	empathy_label.text = "Empathy: %d%%" % int(avg_e)
	politeness_label.text = "Politeness: %d%%" % int(avg_p)
	expression_label.text = "Expression: %d%%" % int(avg_x)
	
	# Update Delta Badge
	if delta > 0.5:
		delta_label.text = "+%d%% ↑" % int(delta)
		delta_label.add_theme_color_override("font_color", Color(0.18, 0.55, 0.25))
	elif delta < -0.5:
		delta_label.text = "%d%% ↓" % int(delta)
		delta_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
	else:
		delta_label.text = "[=" + "]"
		delta_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		
	# Update Overall Performance Status Badge
	if overall >= 70.0:
		status_badge_label.text = "Status: Doing Great! (GOOD)"
		status_badge_label.add_theme_color_override("font_color", Color(0.18, 0.55, 0.25))
	elif overall >= 45.0:
		status_badge_label.text = "Status: Doing Okay (NEUTRAL)"
		status_badge_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.1))
	else:
		status_badge_label.text = "Status: Needs Work (POOR)"
		status_badge_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))

func start_thinking() -> void:
	is_thinking = true
	thinking_timer = 0.0
	dot_count = 1
	loading_label.visible = true
	loading_label.text = active_npc_name + " pauses."
	message_input.editable = false
	message_input.placeholder_text = active_npc_name + " considers your words..."
	send_button.disabled = true
	leave_button.disabled = false
	_spawn_npc_bubble("[i]" + active_npc_name + " considers your words.[/i]")

func stop_thinking() -> void:
	is_thinking = false
	loading_label.visible = false

func display_reply(text: String) -> void:
	stop_thinking()
	_spawn_npc_bubble(text)
	
	message_input.editable = true
	message_input.placeholder_text = "Say something to " + active_npc_name + "..."
	send_button.disabled = false
	leave_button.disabled = false
	message_input.grab_focus()

func display_error(error_msg: String) -> void:
	stop_thinking()
	_spawn_npc_bubble("[color=red]" + error_msg + "[/color]")
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false

func close_dialogue_gracefully() -> void:
	message_input.editable = false
	send_button.disabled = true
	leave_button.disabled = true
	await get_tree().create_timer(1.5).timeout
	close_dialogue()

func close_dialogue() -> void:
	stop_thinking()
	_clear_bubbles()
	visible = false

func _spawn_npc_bubble(text: String) -> void:
	if active_npc_bubble and is_instance_valid(active_npc_bubble):
		active_npc_bubble.queue_free()
		
	var target = active_npc_node
	if not target:
		var npcs = get_tree().get_nodes_in_group("npcs")
		if npcs.size() > 0:
			target = npcs[0]
			
	var scene = preload("res://scenes/ui/SpeechBubble.tscn")
	active_npc_bubble = scene.instantiate()
	bubbles_container.add_child(active_npc_bubble)
	active_npc_bubble.setup(active_npc_name, text, target, false)

func _spawn_player_bubble(text: String) -> void:
	if active_player_bubble and is_instance_valid(active_player_bubble):
		active_player_bubble.queue_free()
		
	var target = active_player_node
	if not target:
		target = get_tree().get_first_node_in_group("player")
		
	var scene = preload("res://scenes/ui/SpeechBubble.tscn")
	active_player_bubble = scene.instantiate()
	bubbles_container.add_child(active_player_bubble)
	active_player_bubble.setup("You", text, target, true)

func _clear_bubbles() -> void:
	for child in bubbles_container.get_children():
		child.queue_free()
	active_npc_bubble = null
	active_player_bubble = null

func _on_text_submitted(_text: String) -> void:
	_on_send_pressed()

func _on_send_pressed() -> void:
	if is_thinking:
		return
	var txt = message_input.text.strip_edges()
	if txt != "":
		if AudioManager:
			AudioManager.play_click()
		message_input.text = ""
		append_player_message(txt)
		message_submitted.emit(txt)

func _on_leave_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	leave_requested.emit()
