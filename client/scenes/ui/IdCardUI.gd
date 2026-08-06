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

@onready var report_text: RichTextLabel = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/ReportText
@onready var refresh_button: Button = $PanelContainer/Margin/VBoxContainer/Body/RightSection/ReportPanel/Margin/VBox/RefreshButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_report_pressed)
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
	report_text.text = "[i]Analyzing dialogue history and compiling growth report...[/i]"
	refresh_button.disabled = true
	
	var res = await ApiClient.get_report(PlayerStore.player_id)
	refresh_button.disabled = false
	
	if res.has("error"):
		report_text.text = "[color=red]Failed to generate report: " + str(res.get("detail", "Server error")) + "[/color]"
		return
		
	var summary = res.get("summary", "")
	var rec = res.get("recommendation", "")
	report_text.text = "[b]Growth Analysis:[/b]\n" + summary + "\n\n[b]Recommendation:[/b]\n" + rec

func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
