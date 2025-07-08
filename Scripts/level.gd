extends Node2D

# Time in seconds between difficulty increments
@export var difficulty_time_increments := 5
@export var difficulty_time_increment_increased := 2
# Wall Spawning controls
@export var wall_height := 1250
@export var wall_left_x := -280
@export var wall_right_x := 270
@export var wall_scene_path := "res://Scenes/wall.tscn"
# The spawning distance determines which walls to delete and which to spawn
var next_spawn_position := -1250
# Parent of all walls
var wall_container = null
var wall_scene = load(wall_scene_path)
# Platform Spawning controls
@export var platform_max_x_boundary := 230
@export var platform_min_x_boundary := -230
@export var platform_height_range_min := 100
@export var platform_height_range_max := 150
@export var platform_scene_path := "res://Scenes/platform_moving.tscn"
# Flag to roughly determine which side of the game the platform should favor
var platform_left_spawn_flag := false
# Added boundry to top and bottom of camera viewport for spawning / despawning platforms
@export var camera_spawn_boundry := 100
# Marks the next location for a platform to spawn at
var next_platform_y := -430
# Parent of all platforms
var platform_container = null
var platform_scene = load(platform_scene_path)
# As the camera scrolls, respawn a platform just out of view
# Delete past platforms that are no longer in view

# Camera Node
var camera = null
# Signal that the difficulty is increasing
signal difficulty_increase
var time_passed := 0
var rng = RandomNumberGenerator.new()

var player = null
var player_alive = true
# The boundry that the player is allowed to exist outside the camera without dying
@export var camera_player_boundry := -500
signal player_death

# Create new walls based on spawning distance
# Deletes old walls bases on spawning distance
func update_walls():
	if camera.position.y <= next_spawn_position:
		# Delete the old walls
		var threshold = next_spawn_position + wall_height
		for wall in wall_container.get_children():
			if wall.position.y >= threshold:
				wall.queue_free()
		
		# Create the new walls
		var wall1 = wall_scene.instantiate()
		var wall2 = wall_scene.instantiate()
		wall1.position = Vector2(wall_left_x, next_spawn_position - wall_height)
		wall2.position = Vector2(wall_right_x, next_spawn_position - wall_height)
		wall1.z_index = 1
		wall2.z_index = 1
		wall_container.add_child(wall1)
		wall_container.add_child(wall2)
		next_spawn_position -= wall_height

# Creates new platforms as the camera pans and destroy old platforms that are no longer visible
func update_platforms():
	var camera_top = camera.position.y - (get_viewport().size[1] / 2) - camera_spawn_boundry
	var camera_bottom = camera.position.y + (get_viewport().size[1] / 2) + camera_spawn_boundry
	
	# Remove old platforms that are no longer visible
	for platform in platform_container.get_children():
		if platform.position.y >= camera_bottom:
			platform.queue_free()
	
	# Spawn a new platform and recalculate the next position
	if camera_top <= next_platform_y:
		var platform = platform_scene.instantiate()
		platform.position.y = next_platform_y
		if platform_left_spawn_flag:
			platform.position.x = rng.randf_range(platform_min_x_boundary, 0)
			platform_left_spawn_flag = false
		else:
			platform.position.x = rng.randf_range(0, platform_max_x_boundary)
			platform_left_spawn_flag = true
		platform_container.add_child(platform)
		var next_platform_increment = rng.randf_range(platform_height_range_min, platform_height_range_max)
		next_platform_y -= next_platform_increment

# Checks if the player is within the bounds of the camera
# Deletes the player if they are outside the bounds and produces the death screen	
func check_player_death():
	var camera_top = camera.position.y - (get_viewport().size[1] / 2) - camera_player_boundry
	var camera_bottom = camera.position.y + (get_viewport().size[1] / 2) + camera_player_boundry
	
	# Kill the player and inform the game of the death
	if player.position.y < camera_top or player.position.y > camera_bottom:
		player.queue_free()
		player_death.emit()
		player_alive = false

func play_game() -> void:
	$DifficultyTimer.wait_time = difficulty_time_increments
	$DifficultyTimer.start()

func _ready() -> void:
	wall_container = get_node("Walls")
	platform_container = get_node("Platforms")
	player = get_node("Player")
	camera = get_node("GameCamera")
	player_alive = true
	Global.level_loaded()
	
# Processes procedural generation
func _process(_delta: float) -> void:
	update_walls()
	update_platforms()
	if player_alive:
		check_player_death()

# Increases the games difficulty on the timers increments
func _on_difficulty_timer_timeout() -> void:
	difficulty_time_increments += difficulty_time_increment_increased
	$DifficultyTimer.wait_time = difficulty_time_increments
	$DifficultyTimer.start()
	difficulty_increase.emit()

func _on_main_menu_start_game() -> void:
	$GameCamera/MainMenu.visible = false
	$GameCamera/PlayerUI.visible = true
	var os = OS.get_name()
	if os == "Android" or os == "iOS":
		$GameCamera/TouchInterface.visible = true
	play_game()

func _on_main_menu_controls_pressed() -> void:
	$GameCamera/MainMenu.visible = false
	var os = OS.get_name()
	if os != "Android" and os != "iOS":
		$GameCamera/ControlsDesktop.visible = true
	else:
		$GameCamera/ControlsMobile.visible = true
	

func _on_controls_desktop_main_menu_pressed() -> void:
	$GameCamera/MainMenu.visible = true
	$GameCamera/ControlsDesktop.visible = false

func _on_controls_mobile_main_menu_pressed() -> void:
	$GameCamera/MainMenu.visible = true
	$GameCamera/ControlsMobile.visible = false
