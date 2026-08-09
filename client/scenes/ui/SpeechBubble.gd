# res://scenes/ui/SpeechBubble.gd
extends Control

@onready var bubble_panel: PanelContainer = $BubblePanel
@onready var speaker_badge_panel: PanelContainer = $SpeakerBadgePanel
@onready var speaker_label: Label = $SpeakerBadgePanel/Margin/SpeakerLabel
@onready var message_text: RichTextLabel = $BubblePanel/Margin/MessageText
@onready var continue_arrow: Label = $ContinueArrow

var target_3d_node: Node3D = null
var offset_3d: Vector3 = Vector3(0, 2.3, 0)
var active_camera: Camera3D = null
var arrow_bounce_timer: float = 0.0
var is_player_bubble: bool = false
var is_system_bubble: bool = false

var speaker_colors: Dictionary = {
	"teddy": Color(1.0, 0.49, 0.15),       # Vibrant Orange
	"blathers": Color(0.48, 0.35, 0.25),    # Earthy Warm Brown
	"daria": Color(0.95, 0.35, 0.5),       # Rose Pink
	"prof_adler": Color(0.2, 0.5, 0.8),    # Scholar Blue
	"ms_hartwell": Color(0.55, 0.3, 0.7),  # Velvet Purple
	"barista": Color(0.8, 0.55, 0.2),      # Caramel Coffee
	"stranger": Color(0.85, 0.45, 0.08),   # Warm Orange/Brown
	"you": Color(0.18, 0.65, 0.3)          # Leaf Green (Player)
}

func _ready() -> void:
	pivot_offset = Vector2(180, 50)
	continue_arrow.visible = false
	_position_speaker_badge()

func setup(speaker: String, text: String, target_node: Node3D = null, is_player: bool = false) -> void:
	is_player_bubble = is_player
	speaker_label.text = speaker
	target_3d_node = target_node
	
	var clean_text = text.strip_edges()
	is_system_bubble = clean_text.begins_with("[") and clean_text.ends_with("]")
	
	var key = speaker.to_lower()
	var badge_color = Color(0.85, 0.45, 0.08) # Default Orange
	if is_player or key == "you":
		badge_color = speaker_colors["you"]
		offset_3d = Vector3(-0.7, 2.3, 0)
	elif speaker_colors.has(key):
		badge_color = speaker_colors[key]
		offset_3d = Vector3(0.7, 2.3, 0)
	else:
		offset_3d = Vector3(0.7, 2.3, 0)
		
	# Apply speaker badge pill stylebox color
	var style = speaker_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = badge_color
		speaker_badge_panel.add_theme_stylebox_override("panel", style)

	if is_system_bubble:
		speaker_badge_panel.visible = false
		message_text.text = "[center][b]" + clean_text + "[/b][/center]"
	else:
		speaker_badge_panel.visible = true
		_position_speaker_badge()
		
		# Format with speaker prefix matching mockup (e.g. "You: hi" or "Stranger: [...]")
		var color_hex = badge_color.to_html(false)
		var prefix = "[color=#" + color_hex + "][b]" + speaker + ":[/b][/color] "
		message_text.text = prefix + text
		
	active_camera = get_viewport().get_camera_3d()
	continue_arrow.visible = false
	
	# Position update
	_update_screen_position()
	
	# Scale animation
	scale = Vector2(0.8, 0.8)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	
	# Typewriter text effect
	message_text.visible_ratio = 0.0
	var text_tween = create_tween()
	text_tween.tween_property(message_text, "visible_ratio", 1.0, 0.5)
	text_tween.finished.connect(func(): if continue_arrow: continue_arrow.visible = not is_system_bubble)
	
	if AudioManager:
		AudioManager.play_typewriter_tick()

func update_text_only(new_text: String) -> void:
	var clean_text = new_text.strip_edges()
	is_system_bubble = clean_text.begins_with("[") and clean_text.ends_with("]")
	if is_system_bubble:
		speaker_badge_panel.visible = false
		message_text.text = "[center][b]" + clean_text + "[/b][/center]"
	else:
		message_text.text = new_text
	message_text.visible_ratio = 1.0
	continue_arrow.visible = false

func _process(delta: float) -> void:
	_update_screen_position()
	if continue_arrow and continue_arrow.visible:
		arrow_bounce_timer += delta * 8.0
		var bounce_y = sin(arrow_bounce_timer) * 3.0
		continue_arrow.position.y = (bubble_panel.position.y + bubble_panel.size.y - 12.0) + bounce_y

func _position_speaker_badge() -> void:
	if speaker_badge_panel:
		# Position badge so it overlaps top-left edge of the message bubble
		speaker_badge_panel.position = Vector2(16, -14)

func _update_screen_position() -> void:
	_position_speaker_badge()
	if not target_3d_node or not is_instance_valid(target_3d_node):
		# If no 3D target, retain standard Control container placement (bottom-left stack)
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
	position = screen_pos - Vector2(180, 50)
