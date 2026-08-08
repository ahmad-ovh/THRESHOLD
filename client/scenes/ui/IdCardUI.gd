# res://scenes/ui/IdCardUI.gd
extends CanvasLayer

@onready var close_button: Button = $PanelContainer/Margin/VBoxContainer/Header/CloseButton
@onready var player_id_label: Label = $PanelContainer/Margin/VBoxContainer/Body/LeftCard/PlayerIdLabel
@onready var level_num_label: Label = $PanelContainer/Margin/VBoxContainer/Body/LeftCard/LevelHeader/LevelNumLabel
@onready var overall_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/Body/LeftCard/OverallProgressBar
@onready var streak_label: Label = $PanelContainer/Margin/VBoxContainer/Body/LeftCard/StreakLabel

@onready var clarity_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/Body/RightSection/SkillGrid/ClarityBar
@onready var empathy_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/Body/RightSection/SkillGrid/EmpathyBar
@onready var politeness_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/Body/RightSection/SkillGrid/PolitenessBar
@onready var expression_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/Body/RightSection/SkillGrid/ExpressionBar

@onready var strongest_val: Label = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportTabContainer/Overview/VBox/StrongestRow/Value
@onready var focus_val: Label = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportTabContainer/Overview/VBox/FocusRow/Value
@onready var analysis_text: RichTextLabel = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportTabContainer/Analysis/AnalysisText
@onready var advice_text: RichTextLabel = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportTabContainer/Advice/AdviceText
@onready var refresh_button: Button = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/RefreshButton
@onready var mini_refresh_button: Button = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportHeaderRow/MiniRefreshButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_report_pressed)
	mini_refresh_button.pressed.connect(_on_refresh_report_pressed)
	PlayerStore.player_data_updated.connect(_update_id_card)

func toggle() -> void:
	visible = not visible
	if visible:
		_update_id_card()

func _update_id_card() -> void:
	player_id_label.text = "ID: " + PlayerStore.player_id.to_upper()
	level_num_label.text = "Lv. " + str(PlayerStore.level)
	overall_bar.value = PlayerStore.xp_progress * 100.0
	streak_label.text = "Daily Streak: " + str(PlayerStore.daily_streak) + " 🔥"
	
	var vec = PlayerStore.skill_vector
	clarity_bar.value = vec.get("clarity", 0.5) * 100.0
	empathy_bar.value = vec.get("empathy", 0.5) * 100.0
	politeness_bar.value = vec.get("politeness", 0.5) * 100.0
	expression_bar.value = vec.get("expression", 0.5) * 100.0

func _on_refresh_report_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	
	refresh_button.visible = false
	mini_refresh_button.disabled = true
	
	analysis_text.text = "[i]Analyzing dialogue history and compiling growth report...[/i]"
	advice_text.text = "[i]Compiling recommendations...[/i]"
	
	var res = await ApiClient.get_report(PlayerStore.player_id)
	mini_refresh_button.disabled = false

	
	if res.has("error"):
		analysis_text.text = "[color=red]Failed to generate report: " + str(res.get("detail", "Server error")) + "[/color]"
		advice_text.text = "[color=red]Failed to generate report.[/color]"
		return
		
	var strongest = str(res.get("strongest_skill", "—"))
	var improving = str(res.get("improving_area", "—"))
	var pattern = str(res.get("recent_pattern_summary", "—"))
	var practice = str(res.get("recommended_practice", "—"))

	strongest_val.text = strongest.capitalize()
	focus_val.text = improving.capitalize()
	analysis_text.text = pattern
	advice_text.text = practice



func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
