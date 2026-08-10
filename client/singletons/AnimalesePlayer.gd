# res://singletons/AnimalesePlayer.gd
extends Node

class NPCVoiceProfile extends RefCounted:
	var npc_id: String = ""
	var voice_set: String = "voice_1"
	var pitch_scale: float = 1.0
	var letter_delay_ms: float = 100.0

	static func create_from_id(p_npc_id: String) -> NPCVoiceProfile:
		var prof = NPCVoiceProfile.new()
		prof.npc_id = p_npc_id
		var h = AnimalesePlayer.stable_hash(p_npc_id)
		
		# Map voice sets: voice_1 (Sweet), voice_2 (Peppy), voice_3 (Big Sister), voice_4 (Snooty)
		var set_idx = 1 + (h % 4)
		prof.voice_set = "voice_" + str(set_idx)
		
		# Deterministic pitch scale range: 0.82x (deep) to 1.22x (high/cheerful)
		prof.pitch_scale = 0.82 + float((h >> 3) % 40) / 100.0
		prof.letter_delay_ms = 95.0 + float((h >> 6) % 30)
		return prof

const POOL_SIZE: int = 8
var _players: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

# Cached audio streams: [voice_set][name] -> AudioStream
var _samples: Dictionary = {}
var _profile_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_pool()
	_load_voice_samples()

func _setup_audio_pool() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

func _load_voice_samples() -> void:
	var voice_sets = ["voice_1", "voice_2", "voice_3", "voice_4"]
	var letters = [
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
		"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
	]
	var reactions = ["Deska", "Gwah", "OK"]
	
	for v_set in voice_sets:
		_samples[v_set] = {}
		var base_path = "res://assets/audio/animalese/" + v_set + "/"
		for l in letters:
			var path = base_path + l + ".ogg"
			if ResourceLoader.exists(path):
				_samples[v_set][l] = load(path)
				
		for r in reactions:
			var path = base_path + r + ".ogg"
			if ResourceLoader.exists(path):
				_samples[v_set][r] = load(path)

func get_profile_for_npc(npc_id: String) -> NPCVoiceProfile:
	if npc_id == "":
		npc_id = "stranger"
	if _profile_cache.has(npc_id):
		return _profile_cache[npc_id]
	var prof = NPCVoiceProfile.create_from_id(npc_id)
	_profile_cache[npc_id] = prof
	return prof

func play_letter(npc_id: String, letter: String) -> void:
	var clean_char = letter.to_lower()
	if clean_char < "a" or clean_char > "z":
		return
		
	var prof = get_profile_for_npc(npc_id)
	var set_dict = _samples.get(prof.voice_set, {})
	var stream = set_dict.get(clean_char, null)
	
	if stream:
		_play_stream_from_pool(stream, prof.pitch_scale)

func play_reaction(npc_id: String, reaction_name: String) -> void:
	var prof = get_profile_for_npc(npc_id)
	var set_dict = _samples.get(prof.voice_set, {})
	
	var r_key = "Gwah"
	var key_lower = reaction_name.to_lower()
	if key_lower == "ok":
		r_key = "OK"
	elif key_lower == "deska":
		r_key = "Deska"
		
	var stream = set_dict.get(r_key, null)
	if stream:
		_play_stream_from_pool(stream, prof.pitch_scale)

func _play_stream_from_pool(stream: AudioStream, pitch: float) -> void:
	if _players.size() == 0:
		return
	var player = _players[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()

func stop_all() -> void:
	for p in _players:
		if p and is_instance_valid(p):
			p.stop()

static func stable_hash(text: String) -> int:
	var h: int = 2166136261
	var bytes = text.to_utf8_buffer()
	for b in bytes:
		h = (h ^ b) * 16777619
		h = h & 0x7FFFFFFF
	return h
