# res://scenes/ui/OverviewModal.gd
extends CanvasLayer

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var outcome_badge: Label = $PanelContainer/VBoxContainer/OutcomeBadge
@onready var narrative_text: RichTextLabel = $PanelContainer/VBoxContainer/NarrativeText
@onready var observer_card: PanelContainer = $PanelContainer/VBoxContainer/ObserverCard
@onready var observer_text: Label = $PanelContainer/VBoxContainer/ObserverCard/VBoxContainer/ObserverText
@onready var level_up_banner: PanelContainer = $PanelContainer/VBoxContainer/LevelUpBanner
@onready var level_up_text: Label = $PanelContainer/VBoxContainer/LevelUpBanner/LevelUpText
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

signal closed

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func show_settlement(end_data: Dictionary, level_data: Dictionary = {}) -> void:
	visible = true
	
	var summary = end_data.get("encounter_summary", {})
	var perf = summary.get("performance_outcome", "NEUTRAL").to_upper()
	var narr = summary.get("narrative_outcome", "The encounter reached a conclusion.")
	var obs = end_data.get("observer_event", {})
	var lvl_up = end_data.get("level_up", {})
	
	# Set Performance Badge
	outcome_badge.text = " PERFORMANCE: " + perf + " "
	match perf:
		"GOOD":
			outcome_badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		"POOR":
			outcome_badge.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
		_:
			outcome_badge.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
			
	narrative_text.text = "[b]Outcome:[/b]\n" + narr
	
	# Observer Event Reveal Card
	if obs.get("fired", false):
		observer_card.visible = true
		observer_text.text = "👁️ " + obs.get("message", "Pattern observed in your communication.")
	else:
		observer_card.visible = false
		
	# Level Up Celebration Banner
	if lvl_up.get("level_up", false) or level_data.get("level_up", false):
		level_up_banner.visible = true
		var new_lvl = lvl_up.get("new_level", level_data.get("new_level", 2))
		level_up_text.text = "🎉 LEVEL UP! You reached Level " + str(new_lvl) + "!"
	else:
		level_up_banner.visible = false

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
