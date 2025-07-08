extends Control

signal main_menu_pressed

func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
