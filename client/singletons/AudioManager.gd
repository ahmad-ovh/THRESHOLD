# res://singletons/AudioManager.gd
extends Node

var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	player.stream = generator
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func play_click() -> void:
	_generate_tone(800.0, 0.04, 0.2)

func play_typewriter_tick() -> void:
	_generate_tone(1200.0, 0.015, 0.05)

func play_mood_pop() -> void:
	_generate_tone(600.0, 0.03, 0.2)
	_generate_tone(900.0, 0.05, 0.3)

func play_door_open() -> void:
	_generate_tone(300.0, 0.08, 0.3)
	_generate_tone(200.0, 0.1, 0.2)

func play_level_up() -> void:
	_generate_tone(523.25, 0.08, 0.4) # C5
	_generate_tone(659.25, 0.08, 0.4) # E5
	_generate_tone(783.99, 0.12, 0.5) # G5
	_generate_tone(1046.50, 0.2, 0.6) # C6

func _generate_tone(freq: float, duration: float, volume: float = 0.3) -> void:
	if not playback:
		return
	var frames = int(duration * sample_rate)
	var phase = 0.0
	var phase_inc = (freq * TAU) / sample_rate
	for i in range(frames):
		var env = 1.0 - (float(i) / float(frames))
		var value = sin(phase) * volume * env
		if playback.can_push_buffer(1):
			playback.push_frame(Vector2(value, value))
		phase += phase_inc
		if phase >= TAU:
			phase -= TAU
