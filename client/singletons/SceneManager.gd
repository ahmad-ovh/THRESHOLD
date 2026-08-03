# res://singletons/SceneManager.gd
extends CanvasLayer

var color_rect: ColorRect
var target_spawn_id: String = ""

func _ready() -> void:
	layer = 100 # Keep transition color rect above all UI
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func change_room(scene_path: String, spawn_id: String = "default") -> void:
	target_spawn_id = spawn_id
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to Black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.4)
	await tween.finished
	
	# Change Scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Position Player at SpawnMarker3D
	_position_player()
	
	# Fade from Black
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.4)
	await fade_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _position_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var spawn_markers = get_tree().get_nodes_in_group("spawn_markers")
	for marker in spawn_markers:
		if marker.name == target_spawn_id or marker.get("spawn_id") == target_spawn_id:
			player.global_transform = marker.global_transform
			return
