extends StaticBody2D
# These are the globally defining variables for the platforms speed
# It will never be less than min nor greater than max
# The speed will be a smaller range that incrementally increases as the games
# difficulty increases
@export var platform_max_speed := 500
@export var platform_min_speed := 75
# Increments based on difficulty increases
@export var platform_speed_increment := 50
# Range of speed between local platform speed min and max
@export var platform_speed_range := 100
# Will need to be relative to screen size
@export var platform_max_travel_width := 300
@export var platform_min_travel_width := 100
@export var wait_time_max := 1.0
@export var wait_time_min := 0.1

# Varies depending on how far along the game is - will increase the range of speed as the game progresses
var platform_speed := 200
var platform_min_x := -50
var platform_max_x := 200
var wait_time := 0.5

enum STATE {
	MOVING_LEFT,
	MOVING_RIGHT,
	IDLE
}
var current_state := STATE.IDLE
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
# Game operation:
# Spawn platforms randomly with set spacing
# Grab platform position and apply the movement range to the platform
# Give the platform varying attributes to add novelty and challenge
func _ready() -> void:
	# Platform attribute setup
	var platform_local_min_speed = platform_min_speed + (Global.game_difficulty * platform_speed_increment)
	var platform_local_max_speed = platform_local_min_speed + platform_speed_range
	platform_speed = rng.randi_range(platform_local_min_speed, platform_local_max_speed)
	var platform_travel_width = rng.randi_range(platform_min_travel_width, platform_max_travel_width)
	platform_min_x = position.x - platform_travel_width / 2
	platform_max_x = position.x + platform_travel_width / 2
	wait_time = rng.randf_range(wait_time_min, wait_time_max)
	
	# Platform state machine setup
	current_state = STATE.IDLE
	$IdleTimer.wait_time = wait_time
	$IdleTimer.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state == STATE.MOVING_LEFT:
		position.x -= platform_speed * delta
		constant_linear_velocity = Vector2(-platform_speed * 2.5, 0)
		if position.x <= platform_min_x:
			constant_linear_velocity = Vector2(0, 0)
			current_state = STATE.IDLE
			$IdleTimer.start()
			position.x = platform_min_x

	if current_state == STATE.MOVING_RIGHT:
		position.x += platform_speed * delta
		constant_linear_velocity = Vector2(platform_speed * 2.5, 0)
		if position.x >= platform_max_x:
			constant_linear_velocity = Vector2(0, 0)
			current_state = STATE.IDLE
			$IdleTimer.start()
			position.x = platform_max_x


func _on_idle_timer_timeout() -> void:
	if position.x == platform_max_x:
		current_state = STATE.MOVING_LEFT
	else:
		current_state = STATE.MOVING_RIGHT
