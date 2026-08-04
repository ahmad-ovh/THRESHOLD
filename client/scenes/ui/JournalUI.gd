# res://scenes/ui/JournalUI.gd
extends CanvasLayer

@onready var close_button: Button = $PanelContainer/Margin/VBoxContainer/Header/CloseButton
@onready var level_num_label: Label = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/LeftCard/LevelHeader/LevelNumLabel
@onready var overall_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/LeftCard/OverallProgressBar
@onready var clarity_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/ClarityBar
@onready var empathy_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/EmpathyBar
@onready var politeness_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/PolitenessBar
@onready var expression_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/ExpressionBar

@onready var report_text: RichTextLabel = $"PanelContainer/Margin/VBoxContainer/TabContainer/Growth Report/ReportText"
@onready var refresh_button: Button = $"PanelContainer/Margin/VBoxContainer/TabContainer/Growth Report/RefreshButton"

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_report_pressed)
	PlayerStore.player_data_updated.connect(_update_profile)

func toggle() -> void:
	visible = not visible
	if visible:
		_update_profile()

func _update_profile() -> void:
	level_num_label.text = "Lv. " + str(PlayerStore.level)
	overall_bar.value = PlayerStore.xp_progress * 100.0
	
	var vec = PlayerStore.skill_vector
	clarity_bar.value = vec.get("clarity", 0.5) * 100.0
	empathy_bar.value = vec.get("empathy", 0.5) * 100.0
	politeness_bar.value = vec.get("politeness", 0.5) * 100.0
	expression_bar.value = vec.get("expression", 0.5) * 100.0

func _on_refresh_report_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	report_text.text = "[i]Analyzing conversation history and generating report...[/i]"
	refresh_button.disabled = true
	
	var res = await ApiClient.get_growth_report(PlayerStore.player_id)
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
