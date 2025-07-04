extends Control

func _on_level_player_death() -> void:
	visible = true
	$HighScoreLabel.text = "Personal Best: " + str(Global.player_high_score)
	$ScoreLabel.text = "Score: " + str(Global.player_score)


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
