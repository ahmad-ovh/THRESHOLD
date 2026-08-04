# res://scenes/ui/SpeechBubble.gd
extends Control

@onready var bubble_panel: PanelContainer = $BubblePanel
@onready var speaker_badge_panel: PanelContainer = $SpeakerBadgePanel
@onready var speaker_label: Label = $SpeakerBadgePanel/Margin/SpeakerLabel
@onready var message_text: RichTextLabel = $BubblePanel/Margin/MessageText
@onready var continue_arrow: Label = $ContinueArrow

var target_3d_node: Node3D = null
var offset_3d: Vector3 = Vector3(0, 2.2, 0)
var active_camera: Camera3D = null
var arrow_bounce_timer: float = 0.0

var speaker_colors: Dictionary = {
	"teddy": Color(1.0, 0.49, 0.15),       # Vibrant Orange
	"blathers": Color(0.48, 0.35, 0.25),    # Earthy Warm Brown
	"daria": Color(0.95, 0.35, 0.5),       # Rose Pink
	"prof_adler": Color(0.2, 0.5, 0.8),    # Scholar Blue
	"ms_hartwell": Color(0.55, 0.3, 0.7),  # Velvet Purple
	"barista": Color(0.8, 0.55, 0.2),      # Caramel Coffee
	"you": Color(0.18, 0.65, 0.3)          # Leaf Green (Player)
}

func _ready() -> void:
	pivot_offset = Vector2(180, 100)
	continue_arrow.visible = false

func setup(speaker: String, text: String, target_node: Node3D = null, is_player: bool = false) -> void:
	speaker_label.text = speaker
	var key = speaker.to_lower()
	var badge_color = Color(1.0, 0.49, 0.15) # Default Orange
	if is_player or key == "you":
		badge_color = speaker_colors["you"]
	elif speaker_colors.has(key):
		badge_color = speaker_colors[key]
		
	# Apply speaker badge pill stylebox color
	var style = speaker_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = badge_color
		speaker_badge_panel.add_theme_stylebox_override("panel", style)

	# Format text with Animal Crossing name highlight rules
	var formatted_text = text
	if not is_player:
		formatted_text = formatted_text.replace(speaker, "[color=#f57c00]" + speaker + "[/color]")
		formatted_text = formatted_text.replace("You", "[color=#2e7d32]You[/color]")
		
	message_text.text = formatted_text
	target_3d_node = target_node
	active_camera = get_viewport().get_camera_3d()
	continue_arrow.visible = false
	
	# Initial positioning
	_update_screen_position()
	
	# Animal Crossing pop-in scale bounce animation
	scale = Vector2(0.2, 0.2)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Typewriter text effect
	message_text.visible_ratio = 0.0
	var text_tween = create_tween()
	text_tween.tween_property(message_text, "visible_ratio", 1.0, 0.7)
	text_tween.finished.connect(func(): continue_arrow.visible = true)
	
	if AudioManager:
		AudioManager.play_typewriter_tick()

func update_text_only(new_text: String) -> void:
	message_text.text = new_text
	message_text.visible_ratio = 1.0
	continue_arrow.visible = false

func _process(delta: float) -> void:
	_update_screen_position()
	if continue_arrow.visible:
		arrow_bounce_timer += delta * 8.0
		var bounce_y = sin(arrow_bounce_timer) * 3.0
		continue_arrow.position.y = (position.y + 90.0) + bounce_y

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
	position = screen_pos - Vector2(180, 100)
	speaker_badge_panel.position = Vector2(10, -15)
