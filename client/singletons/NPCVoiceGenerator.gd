# res://singletons/NPCVoiceGenerator.gd
class_name NPCVoiceGenerator
extends RefCounted

enum Waveform { SINE, TRIANGLE, SOFT_SQUARE }

class NPCVoiceProfile extends RefCounted:
	var npc_id: String = ""
	var base_pitch: float = 320.0
	var pitch_variance: float = 0.10
	var waveform_type: Waveform = Waveform.TRIANGLE
	var base_duration: float = 0.025
	var duration_variance: float = 0.008
	var min_voice_gap: int = 2
	var max_voice_gap: int = 5
	var voice_density: float = 0.45
	var base_volume: float = 0.3

	static func create_from_id(p_npc_id: String) -> NPCVoiceProfile:
		var prof = NPCVoiceProfile.new()
		prof.npc_id = p_npc_id
		var h = NPCVoiceGenerator.stable_hash(p_npc_id)
		
		# Base pitch range: 180.0 Hz (deep) to 520.0 Hz (cheerful/high)
		prof.base_pitch = 180.0 + float(h % 340)
		prof.pitch_variance = 0.05 + float((h >> 3) % 12) / 100.0
		prof.waveform_type = (h % 3) as Waveform
		
		# Blip duration range: 20ms - 35ms
		prof.base_duration = 0.020 + float((h >> 6) % 15) / 1000.0
		prof.duration_variance = 0.004 + float((h >> 9) % 6) / 1000.0
		
		# Gap bounds
		prof.min_voice_gap = 2 + (h % 2)                        # 2 or 3
		prof.max_voice_gap = prof.min_voice_gap + 2 + ((h >> 2) % 2) # 4 or 5
		prof.voice_density = 0.35 + float((h >> 5) % 30) / 100.0   # 0.35 - 0.65
		prof.base_volume = 0.25 + float((h >> 7) % 10) / 100.0     # 0.25 - 0.35
		
		return prof

class VoiceEvent extends RefCounted:
	var timestamp_ms: float = 0.0
	var pitch: float = 300.0
	var duration: float = 0.025
	var volume: float = 0.3
	var waveform: int = 1

class TextStep extends RefCounted:
	var timestamp_ms: float = 0.0
	var visible_character_count: int = 0

class DialogueTimeline extends RefCounted:
	var text_steps: Array[TextStep] = []
	var voice_events: Array[VoiceEvent] = []
	var total_duration_ms: float = 0.0

	static func build(raw_text: String, profile: NPCVoiceProfile) -> DialogueTimeline:
		var timeline = DialogueTimeline.new()
		var clean_text = NPCVoiceGenerator.strip_bbcode(raw_text)
		var total_chars = clean_text.length()
		
		if total_chars == 0:
			return timeline
			
		var current_time: float = 0.0
		var chars_since_last_blip: int = 999 # Force initial blip
		
		# Check if dialogue contains a question for pitch inflection
		var is_question = clean_text.contains("?")
		
		for i in range(total_chars):
			var c = clean_text[i]
			
			# Determine character reveal step duration
			var step_dur: float = 35.0 # Base ~28 chars/sec
			
			if c == ' ':
				step_dur = 20.0
			elif c == ',':
				step_dur = 140.0
			elif c in ['.', '!', '?', ':', ';']:
				# Check for ellipsis (...)
				if c == '.' and i + 2 < total_chars and clean_text[i+1] == '.' and clean_text[i+2] == '.':
					step_dur = 150.0
				else:
					step_dur = 260.0
					
			# Record text reveal step
			var step = TextStep.new()
			step.timestamp_ms = current_time
			step.visible_character_count = i + 1
			timeline.text_steps.append(step)
			
			# Voice Event Scheduling
			var is_eligible = not (c in [' ', ',', '.', '!', '?', ':', ';', '-', '\n', '\t'])
			if is_eligible:
				var trigger = false
				if chars_since_last_blip >= profile.max_voice_gap:
					trigger = true
				elif chars_since_last_blip >= profile.min_voice_gap:
					var h = NPCVoiceGenerator.stable_hash(profile.npc_id + clean_text + str(i))
					var roll = h % 100
					trigger = (roll < int(profile.voice_density * 100.0))
				elif timeline.voice_events.size() == 0:
					# Guaranteed initial blip on first valid character
					trigger = true
					
				if trigger:
					chars_since_last_blip = 0
					var h_event = NPCVoiceGenerator.stable_hash(profile.npc_id + clean_text + str(i) + "_evt")
					
					# Pitch variation (-1.0 to 1.0 multiplier on variance)
					var pitch_norm = (float(h_event % 200) - 100.0) / 100.0
					var pitch_factor = 1.0 + (pitch_norm * profile.pitch_variance)
					
					# Question inflection at end of sentence
					if is_question and i > int(total_chars * 0.7):
						pitch_factor *= 1.12 # +12% rising pitch
						
					var final_pitch = profile.base_pitch * pitch_factor
					
					# Duration variation
					var dur_norm = (float((h_event >> 4) % 200) - 100.0) / 100.0
					var final_dur = clamp(profile.base_duration + (dur_norm * profile.duration_variance), 0.015, 0.040)
					
					var evt = VoiceEvent.new()
					evt.timestamp_ms = current_time
					evt.pitch = final_pitch
					evt.duration = final_dur
					evt.volume = profile.base_volume
					evt.waveform = profile.waveform_type as int
					timeline.voice_events.append(evt)
				else:
					chars_since_last_blip += 1
					
			current_time += step_dur
			
		timeline.total_duration_ms = current_time
		
		# End-of-timeline Audio Truncation Rule:
		# Ensure no voice blip extends past the dialogue completion timestamp
		for evt in timeline.voice_events:
			var end_ms = evt.timestamp_ms + (evt.duration * 1000.0)
			if end_ms > timeline.total_duration_ms:
				evt.duration = max(0.010, (timeline.total_duration_ms - evt.timestamp_ms) / 1000.0)
				
		return timeline

static func stable_hash(text: String) -> int:
	var h: int = 2166136261
	var bytes = text.to_utf8_buffer()
	for b in bytes:
		h = (h ^ b) * 16777619
		h = h & 0x7FFFFFFF # Positive 31-bit integer
	return h

static func strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]*\\]")
	return regex.sub(text, "", true)
