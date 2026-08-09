# res://scenes/intro/SplashScreen.gd
extends CanvasLayer

## Standard game-dev splash screen with background loading.
## Shows partner/university logos → game title reveal → preloads MainMenu in background.
## Skip only unlocks after BOTH animation finishes AND MainMenu is loaded.

const MAIN_MENU_PATH := "res://scenes/main_menu/MainMenu.tscn"

@onready var root: Control = $Root
@onready var paper_bg: TextureRect = $Root/PaperBg
@onready var studio_logo_1: TextureRect = $Root/StudioLogo1
@onready var studio_logo_2: TextureRect = $Root/StudioLogo2
@onready var game_logo: TextureRect = $Root/GameLogo
@onready var tagline_label: Label = $Root/TaglineLabel
@onready var rule_line: ColorRect = $Root/RuleLine
@onready var press_any_key: Label = $Root/PressAnyKeyLabel

var _loading_done := false
var _animation_done := false
var _skippable := false
var _transitioning := false

func _ready() -> void:
	# Start background loading immediately
	ResourceLoader.load_threaded_request(MAIN_MENU_PATH)
	
	# Hide everything initially
	paper_bg.modulate.a = 0.0
	studio_logo_1.modulate.a = 0.0
	studio_logo_2.modulate.a = 0.0
	game_logo.modulate.a = 0.0
	game_logo.scale = Vector2(0.6, 0.6)
	game_logo.pivot_offset = game_logo.size / 2.0
	tagline_label.modulate.a = 0.0
	rule_line.scale.x = 0.0
	rule_line.pivot_offset = Vector2(0, 0)
	press_any_key.modulate.a = 0.0
	press_any_key.visible = false
	
	# Start the animation sequence
	_play_intro_sequence()

func _process(_delta: float) -> void:
	if not _loading_done:
		var status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loading_done = true
			_check_ready_to_skip()

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if _skippable and (event is InputEventKey or event is InputEventMouseButton):
		if event.pressed:
			_transition_to_menu()

func _check_ready_to_skip() -> void:
	if _loading_done and _animation_done:
		_skippable = true
		press_any_key.visible = true
		# Blink loop
		var blink_tween = create_tween().set_loops()
		blink_tween.tween_property(press_any_key, "modulate:a", 1.0, 0.5)
		blink_tween.tween_property(press_any_key, "modulate:a", 0.2, 0.5)

func _play_intro_sequence() -> void:
	var seq = create_tween()
	
	# --- Phase 1: Paper background fade (0.0 → 0.5s) ---
	seq.tween_property(paper_bg, "modulate:a", 1.0, 0.5)
	
	# --- Phase 2: UTM logo fade in/out (0.5 → 2.2s) ---
	seq.tween_property(studio_logo_1, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.8)
	seq.tween_property(studio_logo_1, "modulate:a", 0.0, 0.5)
	
	# --- Phase 3: Tencent Cloud logo fade in/out (2.2 → 3.9s) ---
	seq.tween_property(studio_logo_2, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.8)
	seq.tween_property(studio_logo_2, "modulate:a", 0.0, 0.5)
	
	# --- Phase 4: Game logo reveal (3.9 → 5.0s) ---
	seq.tween_callback(func():
		if AudioManager and AudioManager.has_method("play_click"):
			AudioManager.play_click()
	)
	var logo_group = seq.parallel()
	logo_group.tween_property(game_logo, "modulate:a", 1.0, 0.4)
	logo_group.tween_property(game_logo, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	seq.tween_interval(0.1)
	
	# --- Phase 5: Tagline (5.0 → 5.8s) ---
	seq.tween_property(tagline_label, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.2)
	
	# --- Phase 6: Rule line draws (5.8 → 6.3s) ---
	seq.tween_property(rule_line, "scale:x", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# --- Phase 7: Animation complete ---
	seq.tween_callback(func():
		_animation_done = true
		_check_ready_to_skip()
	)
	
	# Auto-advance after a short wait if already skippable
	seq.tween_interval(2.0)
	seq.tween_callback(func():
		if _skippable and not _transitioning:
			_transition_to_menu()
	)

func _transition_to_menu() -> void:
	_transitioning = true
	
	# Fade everything out
	var fade = create_tween().set_parallel(true)
	fade.tween_property(root, "modulate:a", 0.0, 0.5)
	await fade.finished
	
	# Switch to the preloaded MainMenu
	var packed_scene = ResourceLoader.load_threaded_get(MAIN_MENU_PATH)
	get_tree().change_scene_to_packed(packed_scene)
