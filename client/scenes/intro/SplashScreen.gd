# res://scenes/intro/SplashScreen.gd
extends CanvasLayer

## Standard game-dev splash screen with background loading.
## Shows partner/university logos → game title reveal → preloads MainMenu in background.
## Skip only unlocks after BOTH animation finishes AND MainMenu is loaded.

const MAIN_MENU_PATH := "res://scenes/main_menu/MainMenu.tscn"
const STREET_PATH := "res://scenes/rooms/Street.tscn"
const CUSTOMIZATION_PATH := "res://scenes/ui/CharacterCustomization.tscn"

@onready var root: Control = $Root
@onready var paper_bg: TextureRect = $Root/PaperBg
@onready var studio_logo_1: TextureRect = $Root/StudioLogo1
@onready var studio_logo_2: TextureRect = $Root/StudioLogo2
@onready var studio_logo_3: TextureRect = $Root/StudioLogo3
@onready var game_logo: TextureRect = $Root/GameLogo
@onready var tagline_label: Label = $Root/TaglineLabel
@onready var press_any_key: Label = $Root/PressAnyKeyLabel

var _loading_done := false
var _animation_done := false
var _skippable := false
var _transitioning := false

func _ready() -> void:
	# Start background preloading for Main Menu, Street, and Character Customization scenes
	SceneManager.preload_scene(MAIN_MENU_PATH)
	SceneManager.preload_scene(STREET_PATH)
	SceneManager.preload_scene(CUSTOMIZATION_PATH)
	
	# Paper bg starts at FULL opacity — seamless transition from boot splash
	# (boot splash shows the same splash.png, so no visual seam)
	paper_bg.modulate.a = 1.0
	studio_logo_1.modulate.a = 0.0
	studio_logo_2.modulate.a = 0.0
	studio_logo_3.modulate.a = 0.0
	game_logo.modulate.a = 0.0
	game_logo.scale = Vector2(0.6, 0.6)
	game_logo.pivot_offset = game_logo.size / 2.0
	tagline_label.modulate.a = 0.0
	press_any_key.modulate.a = 0.0
	press_any_key.visible = false
	
	# Start the animation sequence
	_play_intro_sequence()

func _process(_delta: float) -> void:
	if not _loading_done:
		if SceneManager.is_scene_loaded(MAIN_MENU_PATH) and SceneManager.is_scene_loaded(STREET_PATH):
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
	
	# No paper bg fade — it's already at full alpha (matches boot splash).
	# Logos start appearing immediately on the same background.
	
	# --- Phase 1: UTM logo fade in/out (0.0 → 1.7s) ---
	seq.tween_interval(0.3) # brief pause after boot splash loading bar disappears
	seq.tween_property(studio_logo_1, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.8)
	seq.tween_property(studio_logo_1, "modulate:a", 0.0, 0.5)
	
	# --- Phase 2: Tencent Cloud logo fade in/out (1.7 → 3.4s) ---
	seq.tween_property(studio_logo_2, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.8)
	seq.tween_property(studio_logo_2, "modulate:a", 0.0, 0.5)

	# --- Phase 3: Arkie Studio logo fade in/out (3.4 → 5.1s) ---
	seq.tween_property(studio_logo_3, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.8)
	seq.tween_property(studio_logo_3, "modulate:a", 0.0, 0.5)
	
	# --- Phase 4: Game logo reveal ---
	seq.tween_callback(func():
		if AudioManager and AudioManager.has_method("play_click"):
			AudioManager.play_click()
	)
	var logo_group = seq.parallel()
	logo_group.tween_property(game_logo, "modulate:a", 1.0, 0.4)
	logo_group.tween_property(game_logo, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	seq.tween_interval(0.1)
	
	# --- Phase 5: Tagline ---
	seq.tween_property(tagline_label, "modulate:a", 1.0, 0.4)
	seq.tween_interval(0.2)
	
	# --- Phase 6: Animation complete ---
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
	var packed_scene = SceneManager.get_preloaded_scene(MAIN_MENU_PATH)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
