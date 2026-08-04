# res://scenes/ui/OverviewModal.gd
extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/Margin/VBoxContainer/TitleLabel
@onready var outcome_badge: Label = $PanelContainer/Margin/VBoxContainer/OutcomeBadge
@onready var narrative_text: RichTextLabel = $PanelContainer/Margin/VBoxContainer/NarrativeText
@onready var observer_card: PanelContainer = $PanelContainer/Margin/VBoxContainer/ObserverCard
@onready var observer_text: Label = $PanelContainer/Margin/VBoxContainer/ObserverCard/Margin/VBoxContainer/ObserverText
@onready var level_up_banner: PanelContainer = $PanelContainer/Margin/VBoxContainer/LevelUpBanner
@onready var level_up_text: Label = $PanelContainer/Margin/VBoxContainer/LevelUpBanner/Margin/LevelUpText
@onready var close_button: Button = $PanelContainer/Margin/VBoxContainer/CloseButton

signal closed

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func show_settlement(end_data: Dictionary, level_data: Dictionary = {}) -> void:
	visible = true
	
	# Smooth Scale Pop-In Micro-Animation
	panel_container.scale = Vector2(0.8, 0.8)
	panel_container.pivot_offset = panel_container.size / 2.0
	var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.35)
	
	var summary = end_data.get("encounter_summary") if end_data.has("encounter_summary") and end_data["encounter_summary"] != null else {}
	var perf_val = summary.get("performance_outcome", "NEUTRAL") if summary.has("performance_outcome") and summary["performance_outcome"] != null else "NEUTRAL"
	var perf = str(perf_val).to_upper()
	
	var narr_val = summary.get("narrative_outcome", "The encounter reached a conclusion.") if summary.has("narrative_outcome") and summary["narrative_outcome"] != null else "The encounter reached a conclusion."
	var narr_str = str(narr_val)
	
	var obs = end_data.get("observer_event") if end_data.has("observer_event") and end_data["observer_event"] != null else {}
	var lvl_up = end_data.get("level_up") if end_data.has("level_up") and end_data["level_up"] != null else {}
	
	# Set Performance Badge
	outcome_badge.text = " PERFORMANCE: " + perf + " "
	match perf:
		"GOOD":
			outcome_badge.add_theme_color_override("font_color", Color(0.18, 0.55, 0.25))
		"POOR":
			outcome_badge.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
		_:
			outcome_badge.add_theme_color_override("font_color", Color(0.85, 0.5, 0.1))
			
	narrative_text.text = "[b]Outcome:[/b]\n" + narr_str
	
	# Observer Event Reveal Card
	if obs is Dictionary and obs.get("fired", false) == true:
		observer_card.visible = true
		var msg = obs.get("message", "Pattern observed in your communication.")
		observer_text.text = str(msg)
	else:
		observer_card.visible = false
		
	# Level Up Celebration Banner
	var is_lvl_up = false
	var new_lvl = 2
	if lvl_up is Dictionary and lvl_up.get("level_up", false) == true:
		is_lvl_up = true
		new_lvl = lvl_up.get("new_level", 2)
	elif level_data is Dictionary and level_data.get("level_up", false) == true:
		is_lvl_up = true
		new_lvl = level_data.get("new_level", 2)
		
	if is_lvl_up:
		level_up_banner.visible = true
		level_up_text.text = "LEVEL UP! You reached Level " + str(new_lvl) + "!"
		if AudioManager:
			AudioManager.play_level_up()
	else:
		level_up_banner.visible = false

func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
	closed.emit()
