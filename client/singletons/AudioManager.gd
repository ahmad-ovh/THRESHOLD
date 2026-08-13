# res://singletons/AudioManager.gd
extends Node

var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

var voice_player: AudioStreamPlayer
var voice_generator: AudioStreamGenerator
var voice_playback: AudioStreamGeneratorPlayback

var sample_rate: float = 44100.0
const CLICK_FREQUENCY: float = 800.0
const CLICK_PITCH_MIN: float = 0.93
const CLICK_PITCH_MAX: float = 1.07

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# UI & Gameplay SFX Channel
	player = AudioStreamPlayer.new()
	generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	player.stream = generator
	add_child(player)
	player.play()
	playback = player.get_stream_playback()
	
	# Dedicated Voice Blip Channel (Isolated from UI SFX)
	voice_player = AudioStreamPlayer.new()
	voice_generator = AudioStreamGenerator.new()
	voice_generator.mix_rate = sample_rate
	voice_generator.buffer_length = 0.1
	voice_player.stream = voice_generator
	add_child(voice_player)
	voice_player.play()
	voice_playback = voice_player.get_stream_playback()

func play_click() -> void:
	_generate_tone(CLICK_FREQUENCY * randf_range(CLICK_PITCH_MIN, CLICK_PITCH_MAX), 0.04, 0.2)

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

func stop_voice_playback() -> void:
	if voice_playback and voice_playback.has_method("clear"):
		voice_playback.clear()

func play_procedural_blip(freq: float, duration: float, volume: float = 0.3, waveform_type: int = 1) -> void:
	if not voice_playback:
		return
	var frames = int(duration * sample_rate)
	if frames <= 0:
		return
		
	# Safety check: Drop blip if buffer cannot accept required frames to prevent main-thread stall
	if not voice_playback.can_push_buffer(frames):
		return
		
	var phase = 0.0
	var phase_inc = (freq * TAU) / sample_rate
	var attack_frames = min(int(0.002 * sample_rate), int(frames * 0.2)) # 2ms attack
	
	for i in range(frames):
		# Envelope calculation: Attack (2ms) + Exponential Decay
		var env = 1.0
		if i < attack_frames and attack_frames > 0:
			env = float(i) / float(attack_frames)
		else:
			var decay_progress = float(i - attack_frames) / float(max(1, frames - attack_frames))
			env = pow(1.0 - decay_progress, 1.5)
			
		# Waveform calculation
		var raw_val = 0.0
		match waveform_type:
			0: # SINE (Soft round)
				raw_val = sin(phase)
			1: # TRIANGLE (Soft retro blip)
				var t = fmod(phase / PI + 1.0, 2.0) - 1.0
				raw_val = (abs(t) * 2.0 - 1.0)
			2: # SOFT_SQUARE (Upbeat harmonic blip)
				raw_val = sin(phase) + 0.35 * sin(3.0 * phase)
			_:
				raw_val = sin(phase)
				
		var value = clamp(raw_val * volume * env, -1.0, 1.0)
		voice_playback.push_frame(Vector2(value, value))
		
		phase += phase_inc
		if phase >= TAU:
			phase -= TAU

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
