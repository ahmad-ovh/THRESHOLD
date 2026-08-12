# res://singletons/GameController.gd
extends Node

signal game_phase_changed(old_phase: Phase, new_phase: Phase)
signal game_paused_changed(is_paused: bool)
signal is_development_mode_changed(enabled: bool)

@export var is_development_mode: bool = false:
	set(value):
		is_development_mode = value
		is_development_mode_changed.emit(value)

enum Phase {
	MAIN_MENU,
	EXPLORING,
	DIALOGUE,
	PAUSED
}

var current_phase: Phase = Phase.MAIN_MENU
var is_paused: bool = false
var pause_menu_ref: CanvasLayer = null
var hud_ref: CanvasLayer = null
var has_shown_storyboard: bool = false

@export_group("Storyboard Options")
@export var enable_storyboard: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when get_tree().paused is true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_phase == Phase.EXPLORING or current_phase == Phase.PAUSED:
			toggle_pause()

func set_phase(new_phase: Phase) -> void:
	if current_phase == new_phase:
		return
	var old_phase = current_phase
	current_phase = new_phase
	game_phase_changed.emit(old_phase, new_phase)

func toggle_pause() -> void:
	set_paused(not is_paused)

func set_paused(paused_state: bool) -> void:
	is_paused = paused_state
	get_tree().paused = is_paused
	
	if not pause_menu_ref:
		var scene = preload("res://scenes/ui/PauseMenu.tscn")
		pause_menu_ref = scene.instantiate()
		get_tree().root.add_child(pause_menu_ref)
		
	pause_menu_ref.visible = is_paused
	if is_paused:
		set_phase(Phase.PAUSED)
	else:
		set_phase(Phase.EXPLORING)
		
	game_paused_changed.emit(is_paused)

func start_new_game(p_id: String) -> void:
	if SceneManager and SceneManager.has_method("clear_saved_positions"):
		SceneManager.clear_saved_positions()
	PlayerStore.player_id = p_id
	var status = await ApiClient.get_player_status(p_id)
	if not status.has("error"):
		PlayerStore.update_from_status(status)
		
	set_phase(Phase.EXPLORING)
	_ensure_hud()
	hud_ref.visible = true

	var show_sb: bool = enable_storyboard and not has_shown_storyboard
	if show_sb:
		has_shown_storyboard = true

	await SceneManager.change_room_async("res://scenes/rooms/Street.tscn", "default", show_sb)

func return_to_main_menu() -> void:
	if is_paused:
		set_paused(false)
	if hud_ref:
		hud_ref.visible = false
	set_phase(Phase.MAIN_MENU)
	if SceneManager and SceneManager.has_method("clear_saved_positions"):
		SceneManager.clear_saved_positions()
	SceneManager.change_room("res://scenes/main_menu/MainMenu.tscn")

func _ensure_hud() -> void:
	if not hud_ref:
		var scene = preload("res://scenes/ui/HUD.tscn")
		hud_ref = scene.instantiate()
		get_tree().root.add_child(hud_ref)
