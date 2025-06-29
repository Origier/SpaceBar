extends Node

var game_difficulty := 0

func difficulty_increase():
	game_difficulty += 1

func _ready() -> void:
	var root = get_tree().current_scene
	root.connect("difficulty_increase", difficulty_increase)
