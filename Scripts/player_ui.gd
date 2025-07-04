extends Control

var player_score := 0

func _ready() -> void:
	$PlayerScore.text = "Score: " + str(player_score)
	$PlayerHighScore.text = "High Score: " + str(Global.player_high_score)
	Global.connect("change_high_score", _on_player_change_high_score)

func _on_player_reached_new_record_y(old_y: Variant, new_y: Variant) -> void:
	player_score += -round(new_y - old_y)
	$PlayerScore.text = "Score: " + str(player_score)

func _on_player_change_high_score(new_value: Variant) -> void:
	$PlayerHighScore.text = "High Score: " + str(new_value)

func _on_level_player_death() -> void:
	visible = false
