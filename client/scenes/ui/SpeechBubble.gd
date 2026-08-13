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
var active_timeline: NPCVoiceGenerator.DialogueTimeline = null
var voice_profile: NPCVoiceGenerator.NPCVoiceProfile = null
var timeline_elapsed_ms: float = 0.0
var is_timeline_active: bool = false
var next_voice_event_idx: int = 0
var prefix_char_count: int = 0
var active_speaker_id: String = "stranger"
var clean_text_to_speak: String = ""
var last_revealed_char_index: int = 0

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

const MIN_BUBBLE_WIDTH: float = 100.0
const MAX_BUBBLE_WIDTH: float = 340.0

func _ready() -> void:
	pivot_offset = Vector2(180, 50)
	continue_arrow.visible = false
	_position_speaker_badge()

func setup(speaker: String, text: String, target_node: Node3D = null, is_player: bool = false, npc_id: String = "") -> void:
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
		
	var style = speaker_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = badge_color
		speaker_badge_panel.add_theme_stylebox_override("panel", style)

	if is_system_bubble:
		speaker_badge_panel.visible = false
		message_text.text = "[center][b]" + clean_text + "[/b][/center]"
		prefix_char_count = 0
	else:
		speaker_badge_panel.visible = true
		_position_speaker_badge()
		
		var color_hex = badge_color.to_html(false)
		var prefix = "[color=#" + color_hex + "][b]" + speaker + ":[/b][/color] "
		message_text.text = prefix + clean_text
		prefix_char_count = speaker.length() + 2
		
	active_camera = get_viewport().get_camera_3d()
	continue_arrow.visible = false
	_update_screen_position()
	_recalculate_dynamic_size()
	
	scale = Vector2(0.8, 0.8)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	
	# Timeline initialization
	_start_dialogue_timeline(npc_id if npc_id != "" else key, clean_text)

func setup_typing_indicator(npc_name: String) -> void:
	is_system_bubble = true
	speaker_label.text = npc_name
	speaker_badge_panel.visible = false
	message_text.text = "[center][b]. . .[/b][/center]"
	target_3d_node = null
	active_camera = null
	continue_arrow.visible = false
	is_timeline_active = false
	message_text.visible_characters = -1
	_recalculate_dynamic_size()
	
	scale = Vector2(0.8, 0.8)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func update_typing_dots(dots: String) -> void:
	speaker_badge_panel.visible = false
	message_text.text = "[center][b]" + dots + "[/b][/center]"
	is_timeline_active = false
	message_text.visible_characters = -1
	_recalculate_dynamic_size()

func setup_coach_hint(hint_text: String) -> void:
	is_system_bubble = true
	speaker_label.text = "Coach Hint"
	speaker_badge_panel.visible = true
	_position_speaker_badge()
	
	var badge_style = speaker_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if badge_style:
		badge_style.bg_color = Color(0.12, 0.45, 0.85) # Blue badge for Coach Hint
		speaker_badge_panel.add_theme_stylebox_override("panel", badge_style)

	var bubble_style = bubble_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if bubble_style:
		bubble_style.bg_color = Color(0.90, 0.94, 0.99, 0.97) # Soft light blue paper background
		bubble_style.border_color = Color(0.35, 0.60, 0.90, 1.0) # Sleek blue border outline
		bubble_panel.add_theme_stylebox_override("panel", bubble_style)
		
	var clean_text = hint_text.strip_edges()
	message_text.text = "[color=#0D3875][b]Coach Hint:[/b][/color] " + clean_text
	prefix_char_count = 0
	
	target_3d_node = null
	active_camera = null
	continue_arrow.visible = false
	is_timeline_active = false
	message_text.visible_characters = -1
	_recalculate_dynamic_size()
	
	scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)

func convert_to_npc_reply(npc_name: String, text: String, npc_id: String = "") -> void:
	is_system_bubble = false
	speaker_label.text = npc_name
	speaker_badge_panel.visible = true
	_position_speaker_badge()
	
	var key = npc_name.to_lower()
	var badge_color = speaker_colors.get(key, Color(0.85, 0.45, 0.08))
	var style = speaker_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = badge_color
		speaker_badge_panel.add_theme_stylebox_override("panel", style)
		
	var color_hex = badge_color.to_html(false)
	var clean_text = text.strip_edges()
	var prefix = "[color=#" + color_hex + "][b]" + npc_name + ":[/b][/color] "
	message_text.text = prefix + clean_text
	prefix_char_count = npc_name.length() + 2
	
	_recalculate_dynamic_size()
	
	# Start timeline for NPC reply
	_start_dialogue_timeline(npc_id if npc_id != "" else key, clean_text)

func update_text_only(new_text: String) -> void:
	var clean_text = new_text.strip_edges()
	is_system_bubble = clean_text.begins_with("[") and clean_text.ends_with("]")
	if is_system_bubble:
		speaker_badge_panel.visible = false
		message_text.text = "[center][b]" + clean_text + "[/b][/center]"
		prefix_char_count = 0
	else:
		speaker_badge_panel.visible = true
		var badge_style = speaker_badge_panel.get_theme_stylebox("panel") as StyleBoxFlat
		var badge_color = badge_style.bg_color if badge_style else Color(0.85, 0.45, 0.08)
		var color_hex = badge_color.to_html(false)
		var prefix = "[color=#" + color_hex + "][b]" + speaker_label.text + ":[/b][/color] "
		message_text.text = prefix + clean_text
		prefix_char_count = speaker_label.text.length() + 2
	
	is_timeline_active = false
	message_text.visible_characters = -1
	continue_arrow.visible = false
	_recalculate_dynamic_size()

func _start_dialogue_timeline(speaker_id: String, text_to_speak: String) -> void:
	active_speaker_id = speaker_id if speaker_id != "" else "stranger"
	clean_text_to_speak = NPCVoiceGenerator.strip_bbcode(text_to_speak)
	last_revealed_char_index = 0
	
	if is_player_bubble or is_system_bubble:
		voice_profile = null
	else:
		voice_profile = NPCVoiceGenerator.NPCVoiceProfile.create_from_id(active_speaker_id)
		
	active_timeline = NPCVoiceGenerator.DialogueTimeline.build(text_to_speak, voice_profile if voice_profile else NPCVoiceGenerator.NPCVoiceProfile.new())
	
	if is_player_bubble:
		active_timeline.voice_events.clear()
		
	timeline_elapsed_ms = 0.0
	next_voice_event_idx = 0
	is_timeline_active = true
	message_text.visible_characters = prefix_char_count

func skip_reveal() -> void:
	if is_timeline_active:
		is_timeline_active = false
		message_text.visible_characters = -1
		if AnimalesePlayer:
			AnimalesePlayer.stop_all()
		if continue_arrow and target_3d_node != null:
			continue_arrow.visible = not is_system_bubble

func _recalculate_dynamic_size() -> void:
	if not message_text:
		return
		
	var font = message_text.get_theme_font("normal_font")
	var font_size = message_text.get_theme_font_size("normal_font_size")
	var raw_text = message_text.get_parsed_text()
	
	var text_width: float = 0.0
	if font:
		text_width = font.get_string_size(raw_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	else:
		text_width = float(raw_text.length() * 9)
		
	var content_width = text_width + 42.0
	if speaker_badge_panel and speaker_badge_panel.visible:
		var badge_width = speaker_badge_panel.size.x + 36.0
		content_width = max(content_width, badge_width)
		
	var target_width = clamp(content_width, MIN_BUBBLE_WIDTH, MAX_BUBBLE_WIDTH)
	
	bubble_panel.custom_minimum_size.x = target_width
	custom_minimum_size.x = target_width
	
	if continue_arrow and not target_3d_node:
		continue_arrow.visible = false
		
	await get_tree().process_frame
	if bubble_panel:
		var required_height = max(48.0, bubble_panel.size.y + 4.0)
		custom_minimum_size.y = required_height

func _process(delta: float) -> void:
	_update_screen_position()
	_update_top_fade()
	
	# Dialogue Timeline Clock Driver
	if is_timeline_active and active_timeline:
		timeline_elapsed_ms += delta * 1000.0
		
		# Update character reveal step
		var target_visible = prefix_char_count
		for step in active_timeline.text_steps:
			if step.timestamp_ms <= timeline_elapsed_ms:
				target_visible = prefix_char_count + step.visible_character_count
			else:
				break
				
		var new_char_count = target_visible - prefix_char_count
		if new_char_count > last_revealed_char_index:
			# Play letter sounds for newly revealed characters
			if not is_player_bubble and not is_system_bubble and AnimalesePlayer:
				for i in range(last_revealed_char_index, new_char_count):
					if i >= 0 and i < clean_text_to_speak.length():
						var c = clean_text_to_speak[i]
						AnimalesePlayer.play_letter(active_speaker_id, c)
			last_revealed_char_index = new_char_count
			
		message_text.visible_characters = target_visible
				
		# Check timeline completion
		if timeline_elapsed_ms >= active_timeline.total_duration_ms:
			is_timeline_active = false
			message_text.visible_characters = -1
			if continue_arrow and target_3d_node != null:
				continue_arrow.visible = not is_system_bubble
				
	if continue_arrow and continue_arrow.visible and target_3d_node != null:
		arrow_bounce_timer += delta * 8.0
		var bounce_y = sin(arrow_bounce_timer) * 3.0
		continue_arrow.position.y = (bubble_panel.position.y + bubble_panel.size.y - 12.0) + bounce_y

func _position_speaker_badge() -> void:
	if speaker_badge_panel:
		speaker_badge_panel.position = Vector2(16, -14)

func _update_screen_position() -> void:
	_position_speaker_badge()
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
	position = screen_pos - Vector2(180, 50)

func _update_top_fade() -> void:
	if target_3d_node != null:
		return
		
	var parent_node = get_parent()
	while parent_node and not (parent_node is ScrollContainer):
		parent_node = parent_node.get_parent()
		
	if parent_node and parent_node is ScrollContainer:
		var scroll_top_y = parent_node.global_position.y
		var bubble_top_y = global_position.y
		var fade_zone_height: float = 100.0
		var dist_from_top = bubble_top_y - scroll_top_y
		
		if dist_from_top <= 0.0:
			modulate.a = 0.0
		elif dist_from_top < fade_zone_height:
			modulate.a = dist_from_top / fade_zone_height
		else:
			modulate.a = 1.0
