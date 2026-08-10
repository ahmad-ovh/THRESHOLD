# res://scenes/ui/StoryboardLoading.gd
extends CanvasLayer

signal storyboard_completed

@export var target_scene_path: String = "res://scenes/rooms/Street.tscn"

@onready var root: Control = $Root
@onready var paper_bg: TextureRect = $Root/PaperBg
@onready var panel_card: Control = $Root/PanelCard
@onready var panel_image: TextureRect = $Root/PanelCard/MarginContainer/VBoxContainer/ImageContainer/PanelImage
@onready var chapter_label: Label = $Root/PanelCard/MarginContainer/VBoxContainer/ChapterLabel
@onready var narrative_label: RichTextLabel = $Root/PanelCard/MarginContainer/VBoxContainer/NarrativeLabel
@onready var progress_bar: ProgressBar = $Root/BottomBar/VBoxContainer/ProgressBar
@onready var status_label: Label = $Root/BottomBar/VBoxContainer/StatusLabel
@onready var prompt_label: Label = $Root/BottomBar/PromptLabel

var _current_panel_index := 0
var _narrative_panels: Array = [
	{
		"chapter": "CHAPTER I • THE THRESHOLD",
		"text": "Beyond the fog lies THRESHOLD — a city where words shape reality. Every choice you make echoes through its streets.",
		"image": "res://assets/ui/paper_craft/splash.png"
	},
	{
		"chapter": "CHAPTER II • IDENTITY & TONE",
		"text": "Clarity and politeness are your primary currency. Citizens evaluate your intent carefully before extending trust.",
		"image": "res://assets/ui/paper_craft/customization.png"
	},
	{
		"chapter": "CHAPTER III • THE JOURNEY BEGINS",
		"text": "Step across the boundary into the city streets. Prepare yourself — your narrative begins now.",
		"image": "res://assets/ui/paper_craft/journal.png"
	}
]

var _sequence_finished := false
var _scene_loaded := false
var _can_advance := false

func _ready() -> void:
	layer = 95
	root.modulate.a = 0.0
	prompt_label.modulate.a = 0.0
	prompt_label.text = "Press [Space / Click] to continue"
	
	# Fade in overlay
	var fade_in = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	fade_in.tween_property(root, "modulate:a", 1.0, 0.4)
	
	_show_panel(0)
	_start_panel_timer()

func _process(_delta: float) -> void:
	if not _scene_loaded:
		if target_scene_path != "" and SceneManager.has_method("is_scene_loaded"):
			if SceneManager.is_scene_loaded(target_scene_path):
				_scene_loaded = true
				progress_bar.value = 100
				status_label.text = "World Loaded 100%"
				_check_completion()
			else:
				var status = ResourceLoader.load_threaded_get_status(target_scene_path)
				if status == ResourceLoader.THREAD_LOAD_LOADED:
					_scene_loaded = true
					progress_bar.value = 100
					status_label.text = "World Loaded 100%"
					_check_completion()
				else:
					var progress: Array = []
					ResourceLoader.load_threaded_get_status(target_scene_path, progress)
					if progress.size() > 0:
						var pct = int(progress[0] * 100)
						progress_bar.value = clamp(pct, 15, 95)
						status_label.text = "Loading World... " + str(pct) + "%"

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		if _sequence_finished:
			_complete()
		elif _can_advance:
			_advance_panel()

func _show_panel(index: int) -> void:
	_current_panel_index = index
	_can_advance = false
	var p = _narrative_panels[index]
	
	chapter_label.text = p.get("chapter", "")
	narrative_label.text = p.get("text", "")
	
	var img_path = p.get("image", "")
	if ResourceLoader.exists(img_path):
		panel_image.texture = load(img_path)
		
	# Panel transition animation (paper tilt / zoom)
	panel_card.scale = Vector2(0.95, 0.95)
	panel_card.pivot_offset = panel_card.size / 2.0
	
	var card_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	card_tween.tween_property(panel_card, "scale", Vector2(1.0, 1.0), 0.4)
	
	if AudioManager and AudioManager.has_method("play_hover"):
		AudioManager.play_hover()
		
	# Unlock advance after brief delay
	get_tree().create_timer(0.2).timeout.connect(func():
		_can_advance = true
	)

func _start_panel_timer() -> void:
	# Auto advance panels every 4 seconds if user doesn't click
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if not _sequence_finished and _current_panel_index < _narrative_panels.size() - 1:
			_advance_panel()
			_start_panel_timer()
		elif not _sequence_finished and _current_panel_index == _narrative_panels.size() - 1:
			_sequence_finished = true
			_check_completion()
	)

func _advance_panel() -> void:
	if _current_panel_index < _narrative_panels.size() - 1:
		_show_panel(_current_panel_index + 1)
	else:
		_sequence_finished = true
		_check_completion()

func _check_completion() -> void:
	if _sequence_finished and _scene_loaded:
		prompt_label.text = "Press [Any Key] to enter Threshold"
		var blink = create_tween().set_loops()
		blink.tween_property(prompt_label, "modulate:a", 1.0, 0.4)
		blink.tween_property(prompt_label, "modulate:a", 0.3, 0.4)
		get_tree().create_timer(0.8).timeout.connect(func():
			_complete()
		)
	elif _sequence_finished and not _scene_loaded:
		status_label.text = "Finalizing world generation..."

func _complete() -> void:
	if not _scene_loaded:
		return
	storyboard_completed.emit()

func fade_out_and_close() -> void:
	var fade_out = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fade_out.tween_property(root, "modulate:a", 0.0, 0.5)
	await fade_out.finished
	queue_free()
