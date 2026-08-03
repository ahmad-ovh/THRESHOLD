# res://resources/npc_data/NPCData.gd
class_name NPCData
extends Resource

@export var npc_id: String = ""
@export var display_name: String = ""
@export var mesh_scene: PackedScene
@export var default_expression: String = "neutral"
@export var mood_emojis: Dictionary = {} # Key: expression enum string -> Value: Texture2D
