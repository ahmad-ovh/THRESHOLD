# res://scenes/ui/JournalUI.gd
extends CanvasLayer

@onready var clarity_bar: ProgressBar = $PanelContainer/VBoxContainer/TabContainer/Profile/VBoxContainer/ClarityBar
@onready var empathy_bar: ProgressBar = $PanelContainer/VBoxContainer/TabContainer/Profile/VBoxContainer/EmpathyBar
@onready var politeness_bar: ProgressBar = $PanelContainer/VBoxContainer/TabContainer/Profile/VBoxContainer/PolitenessBar
@onready var expression_bar: ProgressBar = $PanelContainer/VBoxContainer/TabContainer/Profile/VBoxContainer/ExpressionBar
@onready var report_text: RichTextLabel = $PanelContainer/VBoxContainer/TabContainer/GrowthReport/ReportText
@onready var refresh_report_btn: Button = $PanelContainer/VBoxContainer/TabContainer/GrowthReport/RefreshButton
@onready var close_btn: Button = $PanelContainer/VBoxContainer/Header/CloseButton

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close_pressed)
	refresh_report_btn.pressed.connect(_fetch_report)

func _on_close_pressed() -> void:
	visible = false

func toggle() -> void:
	visible = not visible
	if visible:
		_update_profile_tab()

func _update_profile_tab() -> void:
	var sv = PlayerStore.skill_vector
	clarity_bar.value = sv.get("clarity", 0.5) * 100.0
	empathy_bar.value = sv.get("empathy", 0.5) * 100.0
	politeness_bar.value = sv.get("politeness", 0.5) * 100.0
	expression_bar.value = sv.get("expression", 0.5) * 100.0

func _fetch_report() -> void:
	report_text.text = "Generating Communication Report..."
	refresh_report_btn.disabled = true
	var res = await ApiClient.get_report(PlayerStore.player_id)
	refresh_report_btn.disabled = false
	if res.has("error"):
		report_text.text = "Failed to fetch report."
		return
		
	var txt = "[b]Strongest Skill:[/b] " + str(res.get("strongest_skill", "")).capitalize() + "\n"
	txt += "[b]Growth Area:[/b] " + str(res.get("improving_area", "")).capitalize() + "\n\n"
	txt += "[b]Recent Pattern:[/b]\n" + str(res.get("recent_pattern_summary", "")) + "\n\n"
	txt += "[b]Recommended Practice:[/b]\n" + str(res.get("recommended_practice", ""))
	report_text.text = txt
