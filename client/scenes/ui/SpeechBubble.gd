# res://scenes/ui/SpeechBubble.gd
extends Control

@onready var bubble_panel: PanelContainer = $BubblePanel
@onready var speaker_badge: Label = $BubblePanel/VBox/SpeakerBadge
@onready var message_text: RichTextLabel = $BubblePanel/VBox/MessageText
@onready var tail_triangle: Polygon2D = $TailTriangle

var target_3d_node: Node3D = null
var offset_3d: Vector3 = Vector3(0, 2.2, 0)
var active_camera: Camera3D = null

func _ready() -> void:
	pivot_offset = Vector2(130, 90)

func setup(speaker: String, text: String, target_node: Node3D = null, is_player: bool = false) -> void:
	speaker_badge.text = speaker
	if is_player:
		speaker_badge.add_theme_color_override("font_color", Color(0.8, 0.4, 0.1))
	else:
		speaker_badge.add_theme_color_override("font_color", Color(0.15, 0.5, 0.85))
		
	message_text.text = text
	target_3d_node = target_node
	active_camera = get_viewport().get_camera_3d()
	
	# Initial positioning
	_update_screen_position()
	
	# Animal Crossing / Tomodachi Life pop-in scale bounce animation
	scale = Vector2(0.2, 0.2)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Typewriter text effect
	message_text.visible_ratio = 0.0
	var text_tween = create_tween()
	text_tween.tween_property(message_text, "visible_ratio", 1.0, 0.8)
	if AudioManager:
		AudioManager.play_typewriter_tick()

func update_text_only(new_text: String) -> void:
	message_text.text = new_text
	message_text.visible_ratio = 1.0

func _process(_delta: float) -> void:
	_update_screen_position()

func _update_screen_position() -> void:
	if not target_3d_node or not is_instance_valid(target_3d_node):
		return
	if not active_camera or not is_instance_valid(active_camera):
		active_camera = get_viewport().get_camera_3d()
		if not active_camera:
			return
			
	var world_pos = target_3d_node.global_position + offset_3d
	if active_camera.is_position_behind(world_pos):
		visible = false
		return
		
	visible = true
	var screen_pos = active_camera.unproject_position(world_pos)
	position = screen_pos - Vector2(130, 90)
