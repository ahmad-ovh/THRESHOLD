# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var main_title_label: Label = $OverlayRoot/MainTitleLabel
@onready var npc_info_card: PanelContainer = $OverlayRoot/NPCInfoCard
@onready var speaker_label: Label = $OverlayRoot/NPCInfoCard/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var npc_sub_info_label: Label = $OverlayRoot/NPCInfoCard/MarginContainer/HBoxContainer/VBoxContainer/NPCSubInfoLabel
@onready var loading_label: Label = $OverlayRoot/NPCInfoCard/MarginContainer/HBoxContainer/VBoxContainer/LoadingLabel
@onready var leave_button: Button = $OverlayRoot/NPCInfoCard/MarginContainer/HBoxContainer/LeaveButton

@onready var chat_scroll_container: ScrollContainer = $OverlayRoot/ChatScrollContainer
@onready var bubbles_container: VBoxContainer = $OverlayRoot/ChatScrollContainer/BubblesContainer

@onready var message_input: LineEdit = $OverlayRoot/BottomInputPanel/InputContainer/MessageInput
@onready var send_button: Button = $OverlayRoot/SendButton
@onready var conversation_end_banner: Button = $OverlayRoot/ConversationEndBanner

@onready var overall_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/OverallContainer/OverallLabel
@onready var delta_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/OverallContainer/DeltaLabel
@onready var overall_bar: ProgressBar = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/OverallProgressBar
@onready var status_badge_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/StatusBadgeLabel

@onready var clarity_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/SubStatsContainer/ClarityLabel
@onready var empathy_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/SubStatsContainer/EmpathyLabel
@onready var politeness_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/SubStatsContainer/PolitenessLabel
@onready var expression_label: Label = $OverlayRoot/FeedbackPanel/Margin/VBoxContainer/SubStatsContainer/ExpressionLabel

signal message_submitted(text: String)
signal conversation_end_confirmed
signal leave_requested

var active_npc_name: String = "Stranger"
var active_npc_node: Node3D = null
var active_player_node: Node3D = null

var active_npc_bubble: Control = null
var active_player_bubble: Control = null

var current_role: String = "Peer"
var current_tier: String = "Stranger"
var current_mood: String = "neutral"

var is_thinking: bool = false
var thinking_timer: float = 0.0
var dot_count: int = 1

# Cumulative Encounter Performance Tracking
var turn_history_scores: Array[Dictionary] = []
var previous_overall_score: float = 50.0

func _ready() -> void:
	visible = false
	loading_label.visible = false
	conversation_end_banner.visible = false
	send_button.pressed.connect(_on_send_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	message_input.text_submitted.connect(_on_text_submitted)
	conversation_end_banner.pressed.connect(_on_end_banner_pressed)
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
				active_npc_bubble.update_text_only("[ " + active_npc_name + " considers your words" + dots + " ]")

func _reset_encounter_metrics() -> void:
	turn_history_scores.clear()
	previous_overall_score = 50.0
	overall_label.text = "Overall: 50%"
	delta_label.text = "[Sleek Bar]"
	delta_label.remove_theme_color_override("font_color")
	overall_bar.value = 50.0
	status_badge_label.text = "Status: Baseline"
	status_badge_label.remove_theme_color_override("font_color")
	
	clarity_label.text = "🔍 Clarity: 50%"
	empathy_label.text = "❤️ Empathy: 50%"
	politeness_label.text = "👍 Politeness: 50%"
	expression_label.text = "😊 Expression: 50%"

func set_spatial_targets(npc_node: Node3D, player_node: Node3D) -> void:
	active_npc_node = npc_node
	active_player_node = player_node

func set_scenario_context(role: String, goal_text: String) -> void:
	current_role = role.capitalize()
	_update_npc_sub_info()

func show_connecting_state(npc_name: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	current_role = "Peer"
	current_tier = "Stranger"
	current_mood = "neutral"
	_update_npc_sub_info()
	visible = true
	_clear_bubbles()
	_reset_encounter_metrics()
	
	# Spawn system action message in bottom-left stack
	_spawn_npc_bubble("[ Walking over to " + active_npc_name + "... ]")
	
	message_input.editable = false
	send_button.disabled = true
	leave_button.disabled = true
	loading_label.visible = true
	loading_label.text = "Walking over..."

func open_dialogue(npc_name: String, opening_line: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	_update_npc_sub_info()
	visible = true
	stop_thinking()
	
	_spawn_npc_bubble(opening_line)
	
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false
	message_input.placeholder_text = "[Character Count] Type your message to " + active_npc_name + "..."
	message_input.grab_focus()

func append_player_message(text: String) -> void:
	_spawn_player_bubble(text)
	start_thinking()

func update_turn_data(data: Dictionary) -> void:
	if data.has("relationship_tier"):
		current_tier = str(data.get("relationship_tier", "Stranger"))
			
	if data.has("npc_state"):
		current_mood = str(data.get("npc_state", "neutral"))
		
	_update_npc_sub_info()
		
	var turn_scores = data.get("turn_scores", {})
	if turn_scores is Dictionary and turn_scores.size() > 0:
		turn_history_scores.append(turn_scores)
		_recalculate_cumulative_performance()

func _update_npc_sub_info() -> void:
	if npc_sub_info_label:
		npc_sub_info_label.text = "[Role: %s 👤 Tier: 🧑 %s Mood: 😐 %s]" % [current_role, current_tier, current_mood]

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
	
	overall_label.text = "Overall: %d%%" % int(overall)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(overall_bar, "value", overall, 0.4)
	
	clarity_label.text = "🔍 Clarity: %d%%" % int(avg_c)
	empathy_label.text = "❤️ Empathy: %d%%" % int(avg_e)
	politeness_label.text = "👍 Politeness: %d%%" % int(avg_p)
	expression_label.text = "😊 Expression: %d%%" % int(avg_x)
	
	if delta > 0.5:
		delta_label.text = "+%d%% ↑" % int(delta)
		delta_label.add_theme_color_override("font_color", Color(0.18, 0.55, 0.25))
	elif delta < -0.5:
		delta_label.text = "%d%% ↓" % int(delta)
		delta_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
	else:
		delta_label.text = "[Sleek Bar]"
		delta_label.remove_theme_color_override("font_color")
		
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
	_spawn_npc_bubble("[ " + active_npc_name + " considers your words ]")

func stop_thinking() -> void:
	is_thinking = false
	loading_label.visible = false

func display_reply(text: String) -> void:
	stop_thinking()
	_spawn_npc_bubble(text)
	
	message_input.editable = true
	message_input.placeholder_text = "[Character Count] Type your message..."
	send_button.disabled = false
	leave_button.disabled = false
	message_input.grab_focus()

func display_error(error_msg: String) -> void:
	stop_thinking()
	_spawn_npc_bubble("[ " + error_msg + " ]")
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false

func close_dialogue_gracefully() -> void:
	message_input.editable = false
	send_button.disabled = true
	leave_button.disabled = true
	_show_end_banner()
	await conversation_end_confirmed
	close_dialogue()

func _show_end_banner() -> void:
	conversation_end_banner.modulate.a = 0.0
	conversation_end_banner.visible = true
	var tween = create_tween()
	tween.tween_property(conversation_end_banner, "modulate:a", 1.0, 0.5)
	await tween.finished
	var pulse = create_tween().set_loops()
	pulse.tween_property(conversation_end_banner, "modulate:a", 0.6, 0.8)
	pulse.tween_property(conversation_end_banner, "modulate:a", 1.0, 0.8)

func _hide_end_banner() -> void:
	conversation_end_banner.visible = false

func _on_end_banner_pressed() -> void:
	_hide_end_banner()
	conversation_end_confirmed.emit()

func close_dialogue() -> void:
	stop_thinking()
	_hide_end_banner()
	_clear_bubbles()
	visible = false

func _spawn_npc_bubble(text: String) -> void:
	var scene = preload("res://scenes/ui/SpeechBubble.tscn")
	active_npc_bubble = scene.instantiate()
	bubbles_container.add_child(active_npc_bubble)
	active_npc_bubble.setup(active_npc_name, text, null, false)
	_scroll_to_bottom()

func _spawn_player_bubble(text: String) -> void:
	var scene = preload("res://scenes/ui/SpeechBubble.tscn")
	active_player_bubble = scene.instantiate()
	bubbles_container.add_child(active_player_bubble)
	active_player_bubble.setup("You", text, null, true)
	_scroll_to_bottom()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if chat_scroll_container:
		chat_scroll_container.scroll_vertical = int(chat_scroll_container.get_v_scroll_bar().max_value)

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
