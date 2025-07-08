extends Control

signal start_game
signal controls_pressed

func _ready() -> void:
	if Global.restart_button_pressed:
		start_game.emit()

func _on_start_button_pressed() -> void:
	start_game.emit()

func _on_controls_button_pressed() -> void:
	controls_pressed.emit()
