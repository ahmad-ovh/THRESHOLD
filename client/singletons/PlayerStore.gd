# res://singletons/PlayerStore.gd
extends Node

signal player_data_updated
signal customization_updated

var player_id: String = "player_01"
var level: int = 1
var xp_progress: float = 0.0
var daily_streak: int = 0
var skill_vector: Dictionary = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}

var customization: Dictionary = {
	"skin_color": Color(0.92, 0.76, 0.65),
	"shirt_color": Color(0.95, 0.95, 0.95),
	"pants_color": Color(0.20, 0.25, 0.35),
	"hair_style": 0,
	"hair_color": Color(0.24, 0.16, 0.10),
	"eye_style": 1,
	"eye_sclera_color": Color(1.0, 1.0, 1.0),
	"eye_pupil_color": Color(0.1, 0.1, 0.1),
	"eye_iris_color": Color(0.18, 0.55, 0.85),
	"nose_style": 1,
	"mouth_style": 1,
	"lip_color": Color(0.85, 0.45, 0.50),
	"upper_lip_color": Color(0.70, 0.37, 0.41),
	"lower_lip_color": Color(0.85, 0.45, 0.50),
	"accessory_style": 0
}


const CUSTOMIZATION_SAVE_PATH: String = "user://customization.json"

func _ready() -> void:
	load_customization()

func update_from_status(data: Dictionary) -> void:
	level = data.get("level", level)
	xp_progress = data.get("xp_progress", xp_progress)
	daily_streak = data.get("daily_streak", daily_streak)
	skill_vector = data.get("skill_vector", skill_vector)
	player_data_updated.emit()

func save_customization() -> void:
	var dict_to_save: Dictionary = {}
	for k in customization.keys():
		var val = customization[k]
		if val is Color:
			dict_to_save[k] = val.to_html(true)
		elif val is Dictionary:
			# Persist sub-dictionaries (e.g. face_offsets) as-is
			dict_to_save[k] = val.duplicate(true)
		else:
			dict_to_save[k] = val
	var file = FileAccess.open(CUSTOMIZATION_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(dict_to_save, "\t"))
		file.close()

func load_customization() -> void:
	if not FileAccess.file_exists(CUSTOMIZATION_SAVE_PATH):
		return
	var file = FileAccess.open(CUSTOMIZATION_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var data = json.get_data()
		if data is Dictionary:
			for k in data.keys():
				if k in customization:
					var default_val = customization[k]
					if default_val is Color and data[k] is String:
						customization[k] = Color.html(data[k])
					elif default_val is int and data[k] is float:
						customization[k] = int(data[k])
					else:
						customization[k] = data[k]
				elif data[k] is Dictionary:
					# Accept sub-dictionaries not in the default (e.g. face_offsets)
					customization[k] = data[k].duplicate(true)
	customization_updated.emit()

