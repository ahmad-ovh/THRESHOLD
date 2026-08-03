# res://scenes/ui/DialogueUI.gd
extends CanvasLayer

@onready var speaker_label: Label = $DialogueBox/HBoxRoot/VBoxMain/HeaderContainer/SpeakerLabel
@onready var tier_label: Label = $DialogueBox/HBoxRoot/VBoxMain/HeaderContainer/TierLabel
@onready var mood_label: Label = $DialogueBox/HBoxRoot/VBoxMain/HeaderContainer/MoodLabel
@onready var loading_label: Label = $DialogueBox/HBoxRoot/VBoxMain/HeaderContainer/LoadingLabel
@onready var leave_button: Button = $DialogueBox/HBoxRoot/VBoxMain/HeaderContainer/LeaveButton
@onready var coach_hint_banner: PanelContainer = $DialogueBox/HBoxRoot/VBoxMain/CoachHintBanner
@onready var coach_hint_label: Label = $DialogueBox/HBoxRoot/VBoxMain/CoachHintBanner/CoachHintLabel
@onready var dialogue_text: RichTextLabel = $DialogueBox/HBoxRoot/VBoxMain/DialogueText
@onready var message_input: LineEdit = $DialogueBox/HBoxRoot/VBoxMain/InputContainer/MessageInput
@onready var send_button: Button = $DialogueBox/HBoxRoot/VBoxMain/InputContainer/SendButton

@onready var overall_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/OverallContainer/OverallLabel
@onready var delta_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/OverallContainer/DeltaLabel
@onready var overall_bar: ProgressBar = $DialogueBox/HBoxRoot/FeedbackPanel/OverallProgressBar
@onready var status_badge_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/StatusBadgeLabel

@onready var clarity_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/ClarityLabel
@onready var clarity_bar: ProgressBar = $DialogueBox/HBoxRoot/FeedbackPanel/ClarityBar
@onready var empathy_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/EmpathyLabel
@onready var empathy_bar: ProgressBar = $DialogueBox/HBoxRoot/FeedbackPanel/EmpathyBar
@onready var politeness_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/PolitenessLabel
@onready var politeness_bar: ProgressBar = $DialogueBox/HBoxRoot/FeedbackPanel/PolitenessBar
@onready var expression_label: Label = $DialogueBox/HBoxRoot/FeedbackPanel/ExpressionLabel
@onready var expression_bar: ProgressBar = $DialogueBox/HBoxRoot/FeedbackPanel/ExpressionBar
@onready var feedback_text: RichTextLabel = $DialogueBox/HBoxRoot/FeedbackPanel/FeedbackText

signal message_submitted(text: String)
signal leave_requested

var dialogue_history: Array[String] = []
var active_npc_name: String = ""
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
			loading_label.text = "💭 Thinking" + dots
			_update_history_with_thinking(dots)

func _reset_encounter_metrics() -> void:
	turn_history_scores.clear()
	previous_overall_score = 50.0
	overall_label.text = "Overall: 50%"
	delta_label.text = "[--]"
	delta_label.remove_theme_color_override("font_color")
	overall_bar.value = 50.0
	status_badge_label.text = "Status: 😐 Baseline"
	status_badge_label.remove_theme_color_override("font_color")
	
	clarity_bar.value = 50.0
	clarity_label.text = "Clarity: 50%"
	empathy_bar.value = 50.0
	empathy_label.text = "Empathy: 50%"
	politeness_bar.value = 50.0
	politeness_label.text = "Politeness: 50%"
	expression_bar.value = 50.0
	expression_label.text = "Expression: 50%"

func show_connecting_state(npc_name: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	tier_label.text = "[Tier: Stranger]"
	mood_label.text = "[Mood: neutral]"
	visible = true
	dialogue_history.clear()
	_reset_encounter_metrics()
	dialogue_text.text = "[color=yellow][i]Approaching " + active_npc_name + "... Connecting to conversation...[/i][/color]"
	message_input.editable = false
	send_button.disabled = true
	leave_button.disabled = true
	loading_label.visible = true
	loading_label.text = "⏳ Connecting..."
	coach_hint_banner.visible = false
	feedback_text.text = "Awaiting first response..."

func open_dialogue(npc_name: String, opening_line: String) -> void:
	active_npc_name = npc_name.capitalize()
	speaker_label.text = active_npc_name
	visible = true
	stop_thinking()
	
	dialogue_history.clear()
	var line = "[b]" + active_npc_name + ":[/b] " + opening_line
	dialogue_history.append(line)
	dialogue_text.text = line
	
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false
	message_input.placeholder_text = "Type your response here..."
	message_input.grab_focus()

func append_player_message(text: String) -> void:
	var player_line = "[b]You:[/b] " + text
	dialogue_history.append(player_line)
	_refresh_dialogue_text()
	start_thinking()

func update_turn_data(data: Dictionary) -> void:
	# Update Status Pills
	if data.has("relationship_tier"):
		tier_label.text = "[Tier: " + str(data.get("relationship_tier", "Stranger")) + "]"
	if data.has("npc_state"):
		mood_label.text = "[Mood: " + str(data.get("npc_state", "neutral")) + "]"
		
	# Update Coach Hint Banner
	var hint = data.get("coach_hint", {})
	if hint is Dictionary and hint.get("shown", false) == true:
		coach_hint_banner.visible = true
		coach_hint_label.text = "💡 Coach Hint: " + str(hint.get("line", ""))
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
		delta_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	elif delta < -0.5:
		delta_label.text = "%d%% ↓" % int(delta)
		delta_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
	else:
		delta_label.text = "[=" + "]"
		delta_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		
	# Update Overall Performance Status Badge
	if overall >= 70.0:
		status_badge_label.text = "Status: 🌟 Doing Great! (GOOD)"
		status_badge_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	elif overall >= 45.0:
		status_badge_label.text = "Status: 😐 Doing Okay (NEUTRAL)"
		status_badge_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	else:
		status_badge_label.text = "Status: ⚠️ Needs Work (POOR)"
		status_badge_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))

func start_thinking() -> void:
	is_thinking = true
	thinking_timer = 0.0
	dot_count = 1
	loading_label.visible = true
	loading_label.text = "💭 Thinking."
	message_input.editable = false
	message_input.placeholder_text = active_npc_name + " is thinking..."
	send_button.disabled = true
	leave_button.disabled = false
	_update_history_with_thinking(".")

func stop_thinking() -> void:
	is_thinking = false
	loading_label.visible = false

func display_reply(text: String) -> void:
	stop_thinking()
	var npc_line = "[b]" + active_npc_name + ":[/b] " + text
	dialogue_history.append(npc_line)
	_refresh_dialogue_text()
	
	# Typewriter effect on dialogue text
	dialogue_text.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, 1.0)
	
	message_input.editable = true
	message_input.placeholder_text = "Type your response here..."
	send_button.disabled = false
	leave_button.disabled = false
	message_input.grab_focus()

func display_error(error_msg: String) -> void:
	stop_thinking()
	dialogue_history.append("[color=red][b]Error:[/b] " + error_msg + "[/color]")
	_refresh_dialogue_text()
	message_input.editable = true
	send_button.disabled = false
	leave_button.disabled = false

func close_dialogue() -> void:
	stop_thinking()
	visible = false

func _refresh_dialogue_text() -> void:
	dialogue_text.text = "\n\n".join(dialogue_history)
	await get_tree().process_frame
	dialogue_text.scroll_to_line(dialogue_text.get_line_count())

func _update_history_with_thinking(dots: String) -> void:
	var thinking_msg = "[color=gray][i]" + active_npc_name + " is thinking" + dots + "[/i][/color]"
	var temp_list = dialogue_history.duplicate()
	temp_list.append(thinking_msg)
	dialogue_text.text = "\n\n".join(temp_list)
	dialogue_text.scroll_to_line(dialogue_text.get_line_count())

func _on_text_submitted(_text: String) -> void:
	_on_send_pressed()

func _on_send_pressed() -> void:
	if is_thinking:
		return
	var txt = message_input.text.strip_edges()
	if txt != "":
		message_input.text = ""
		append_player_message(txt)
		message_submitted.emit(txt)

func _on_leave_pressed() -> void:
	leave_requested.emit()
