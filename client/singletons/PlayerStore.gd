# res://singletons/PlayerStore.gd
extends Node

signal player_data_updated

var player_id: String = "player_01"
var level: int = 1
var xp_progress: float = 0.0
var daily_streak: int = 0
var skill_vector: Dictionary = {"clarity": 0.5, "empathy": 0.5, "politeness": 0.5, "expression": 0.5}

func update_from_status(data: Dictionary) -> void:
	level = data.get("level", level)
	xp_progress = data.get("xp_progress", xp_progress)
	daily_streak = data.get("daily_streak", daily_streak)
	skill_vector = data.get("skill_vector", skill_vector)
	player_data_updated.emit()
