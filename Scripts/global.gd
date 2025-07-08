extends Node

var game_difficulty := 0
# Players Score tracking
var player_score := 0
var player_high_score := 0
signal change_high_score(new_value)
var restart_button_pressed := false

# Loads the players high score from disk
func load_high_score():
	# Make sure the file exists
	if not FileAccess.file_exists("user://savegame.save"):
		return
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string = save_file.get_line()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return
	
	player_high_score = int(json.data["player_high_score"])

# Serializes the players score to keep track of high scores
func save():
	var save_dict = {
		"player_high_score" : player_high_score
	}
	return save_dict

# Saves the players high score out to disk
func save_high_score():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var score_data = save()
	var json_string = JSON.stringify(score_data)
	# Set the file pointer to overwrite the previous data
	save_file.seek(0)
	save_file.store_line(json_string)
	print("Game saved...")

func difficulty_increase():
	game_difficulty += 1
	
func reset_game():
	game_difficulty = 0

func level_loaded():
	var root = get_tree().current_scene
	var player = root.get_node("Player")
	player_score = 0
	player.connect("reached_new_record_y", _on_player_reached_new_record_y)
	root.connect("difficulty_increase", difficulty_increase)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_high_score()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		save_high_score()

func _ready() -> void:
	# Load the high score data from save files
	load_high_score()
	
func _on_player_reached_new_record_y(old_y: Variant, new_y: Variant) -> void:
	player_score += -round(new_y - old_y)
	if player_score > player_high_score:
		player_high_score = player_score
		change_high_score.emit(player_score)
