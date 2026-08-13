# res://singletons/ToastManager.gd
extends CanvasLayer

var toast_container: VBoxContainer

func _ready() -> void:
	layer = 120 # Topmost UI layer
	toast_container = VBoxContainer.new()
	toast_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast_container.position = Vector2(-320, 20)
	toast_container.custom_minimum_size = Vector2(300, 0)
	add_child(toast_container)
	
	# Connect to ApiClient error signal
	if ApiClient:
		ApiClient.request_failed.connect(show_error)

func show_error(message: String) -> void:
	show_toast(message, Color(0.9, 0.25, 0.25, 0.95))

func show_info(message: String) -> void:
	show_toast(message, Color(0.2, 0.6, 0.9, 0.95))

func show_success(message: String) -> void:
	show_toast(message, Color(0.25, 0.8, 0.35, 0.95))

func show_toast(text: String, bg_color: Color) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	
	toast_container.add_child(panel)
	
	# Fade and slide animation
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(3.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(panel.queue_free)
