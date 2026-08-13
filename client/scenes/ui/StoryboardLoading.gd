# res://scenes/ui/StoryboardLoading.gd
extends CanvasLayer

signal storyboard_completed

@export var target_scene_path: String = "res://scenes/rooms/Street.tscn"
@export var panel_duration: float = 3.5
@export var fade_duration: float = 0.2

const PANEL_FADE_IN_DURATION: float = 0.4
const PANEL_FADE_OUT_DURATION: float = 0.5

@onready var root: Control = $Root
@onready var next_button: Button = $Root/NextButton

@onready var panel_image_00: TextureRect = $Root/PanelImage00
@onready var panel_image_01: TextureRect = $Root/PanelImage01
@onready var panel_image_02: TextureRect = $Root/PanelImage02
@onready var panel_image_03: TextureRect = $Root/PanelImage03
@onready var panel_image_04: TextureRect = $Root/PanelImage04
@onready var panel_image_05: TextureRect = $Root/PanelImage05
@onready var panel_image_06: TextureRect = $Root/PanelImage06

@onready var storyboard_frames: Array[TextureRect] = [
	panel_image_00,
	panel_image_01,
	panel_image_02,
	panel_image_03,
	panel_image_04,
	panel_image_05,
	panel_image_06
]

var _current_panel_index: int = 0
var _active_panel: TextureRect
var _is_scene_loaded: bool = false
var _is_complete_pending: bool = false
var _is_finishing: bool = false
var _panel_tween: Tween
var _is_transitioning: bool = false
var _next_panel: TextureRect

func _ready() -> void:
	layer = 95
	root.modulate.a = 1.0
	next_button.text = "Next"
	next_button.pressed.connect(_on_next_button_pressed)

	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	for frame: TextureRect in storyboard_frames:
		if frame:
			frame.visible = false
			frame.modulate.a = 0.0
			if frame.texture == null:
				push_error("Storyboard texture is missing on node: " + frame.name)
			else:
				_apply_letterbox_layout(frame)

	_show_current_panel()

func _exit_tree() -> void:
	_cancel_panel_tween()

func _process(_delta: float) -> void:
	if not _is_scene_loaded and target_scene_path != "":
		if SceneManager and SceneManager.has_method("is_scene_loaded") and SceneManager.is_scene_loaded(target_scene_path):
			_is_scene_loaded = true
			_try_finish_storyboard()
		else:
			var status: int = ResourceLoader.load_threaded_get_status(target_scene_path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				_is_scene_loaded = true
				_try_finish_storyboard()

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
		_skip_to_end()

func _on_next_button_pressed() -> void:
	_advance_panel()

func _advance_panel() -> void:
	if _is_finishing:
		return
	if _is_transitioning:
		return

	if _current_panel_index >= storyboard_frames.size() - 1:
		if _active_panel == null or not is_instance_valid(_active_panel):
			_is_complete_pending = true
			_try_finish_storyboard()
			return

		_cancel_panel_tween()
		_is_transitioning = true
		_next_panel = null
		_panel_tween = create_tween()
		_panel_tween.tween_property(_active_panel, "modulate:a", 0.0, PANEL_FADE_OUT_DURATION)
		_panel_tween.tween_callback(_on_last_panel_fade_out)
		return

	if _active_panel == null or not is_instance_valid(_active_panel):
		_current_panel_index += 1
		_show_current_panel()
		return

	var next_index: int = _current_panel_index + 1
	if next_index < 0 or next_index >= storyboard_frames.size():
		push_error("Storyboard next panel index out of range: " + str(next_index))
		_is_complete_pending = true
		_try_finish_storyboard()
		return

	var next_panel: TextureRect = storyboard_frames[next_index]
	if next_panel == null:
		push_error("Missing storyboard panel node at index: " + str(next_index))
		_is_complete_pending = true
		_try_finish_storyboard()
		return
	if next_panel.texture == null:
		push_error("Storyboard frame has no texture for index: " + str(next_index))

	_cancel_panel_tween()
	_apply_letterbox_layout(next_panel)
	next_panel.visible = true
	next_panel.modulate.a = 0.0

	_next_panel = next_panel
	_is_transitioning = true

	_panel_tween = create_tween()
	_panel_tween.tween_property(_active_panel, "modulate:a", 0.0, PANEL_FADE_OUT_DURATION)
	_panel_tween.parallel().tween_property(next_panel, "modulate:a", 1.0, PANEL_FADE_IN_DURATION)
	_panel_tween.tween_callback(_on_active_panel_fade_out)

func _skip_to_end() -> void:
	if _is_finishing:
		return

	var final_panel_index: int = storyboard_frames.size() - 1
	if storyboard_frames.is_empty():
		push_error("No storyboard frames found.")
		_is_complete_pending = true
		_try_finish_storyboard()
		return

	_cancel_panel_tween()
	_current_panel_index = final_panel_index

	_next_panel = null
	for panel: TextureRect in storyboard_frames:
		if panel:
			panel.visible = false
			panel.modulate.a = 0.0

	var final_panel: TextureRect = storyboard_frames[final_panel_index]
	if final_panel == null:
		push_error("Missing storyboard final frame at index: " + str(final_panel_index))
	else:
		_apply_letterbox_layout(final_panel)
		final_panel.visible = true
		final_panel.modulate.a = 1.0
		_active_panel = final_panel

	_is_complete_pending = true
	_try_finish_storyboard()

func _show_current_panel() -> void:
	if storyboard_frames.is_empty():
		push_error("No storyboard frames found.")
		_is_complete_pending = true
		_try_finish_storyboard()
		return

	if _current_panel_index < 0 or _current_panel_index >= storyboard_frames.size():
		push_error("Storyboard panel index out of range: " + str(_current_panel_index))
		return

	var next_panel: TextureRect = storyboard_frames[_current_panel_index]
	if not next_panel:
		push_error("Missing storyboard panel node at index: " + str(_current_panel_index))
		return
	if next_panel.texture == null:
		push_error("Storyboard frame has no texture for index: " + str(_current_panel_index))

	_cancel_panel_tween()

	if _active_panel and is_instance_valid(_active_panel) and _active_panel != next_panel:
		_active_panel.visible = false
		_active_panel.modulate.a = 0.0

	_apply_letterbox_layout(next_panel)
	_active_panel = next_panel
	_active_panel.visible = true
	_active_panel.modulate.a = 0.0

	_panel_tween = create_tween()
	_panel_tween.tween_property(_active_panel, "modulate:a", 1.0, PANEL_FADE_IN_DURATION)

func _on_active_panel_fade_out() -> void:
	if _active_panel and is_instance_valid(_active_panel):
		_active_panel.visible = false
		_active_panel.modulate.a = 0.0

	var next_panel: TextureRect = _next_panel
	_next_panel = null
	_is_transitioning = false

	if next_panel == null or not is_instance_valid(next_panel):
		push_error("Missing next storyboard panel at transition completion.")
		_is_complete_pending = true
		_try_finish_storyboard()
		return

	_active_panel = next_panel
	_current_panel_index += 1

	if _current_panel_index < storyboard_frames.size() - 1:
		return

	_is_complete_pending = true
	_try_finish_storyboard()

func _on_last_panel_fade_out() -> void:
	if _active_panel and is_instance_valid(_active_panel):
		_active_panel.visible = false
		_active_panel.modulate.a = 0.0

	_is_transitioning = false
	_next_panel = null
	_is_complete_pending = true
	_try_finish_storyboard()

func _try_finish_storyboard() -> void:
	if _is_finishing:
		return
	if not _is_complete_pending:
		return
	if not _is_scene_loaded:
		return
	_is_finishing = true
	storyboard_completed.emit()

func _cancel_panel_tween() -> void:
	if _panel_tween:
		_panel_tween.kill()
	_is_transitioning = false
	_next_panel = null

func fade_out_and_close() -> void:
	var fade_out: float = max(fade_duration, 0.0)
	if fade_out == 0.0:
		queue_free()
		return

	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(root, "modulate:a", 0.0, fade_out)
	await fade_tween.finished
	queue_free()

func _on_viewport_size_changed() -> void:
	for panel: TextureRect in storyboard_frames:
		if panel and panel.visible and panel.texture:
			_apply_letterbox_layout(panel)

func _apply_letterbox_layout(panel: TextureRect) -> void:
	if panel == null or panel.texture == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var tex_size: Vector2 = panel.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var fit_scale: float = min(
		viewport_size.x / tex_size.x,
		viewport_size.y / tex_size.y
	)
	var target_size: Vector2 = tex_size * fit_scale
	panel.size = target_size
	panel.position = (viewport_size - target_size) * 0.5
