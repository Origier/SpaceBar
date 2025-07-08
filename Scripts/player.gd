extends CharacterBody2D

# The force applied to jumps
@export var jump_speed := -450
@export var jump_speed_increment := -50
# The force applied to sideways movements
@export var dash_speed := 300
# The scalar applied to the held jump
@export var hold_scalar := 3
# The required downward velocity to allow jumping to continue
@export var falling_speed_requirement := 200

# Cooldown timer for the charged jump in seconds
@export var hold_jump_cooldown = 10
var hold_jump_available := true
# Timer to determine how long the player held the spacebar for
var hold_timer := 0.0
# Flag to determine if to add hold time or not
var hold_flag := false
var game_started := false

# State machine to control how the player operates in different states
enum STATE {
	IDLE,
	JUMPING,
	FALLING,
	FALLING_FAST
}

# State of the state machine
var current_state := STATE.IDLE

# Players record y position - tracked for score keeping
var player_record_y := 0.0
signal reached_new_record_y(old_y, new_y)

# Checks each frame to determine what state the player is in - changing the state machine
func update_state():
	if velocity.y > 0:
		current_state = STATE.FALLING
	if velocity.y > falling_speed_requirement:
		current_state = STATE.FALLING_FAST
	if (velocity == Vector2.ZERO or is_on_floor()) and current_state != STATE.IDLE:
		if $IdleTimer.is_stopped():
			$IdleTimer.start() # If this expires and the velocity is still 0,0 then the player is idle

func _ready():
	player_record_y = position.y
	current_state = STATE.IDLE
	$HoldJumpTimer.wait_time = hold_jump_cooldown
	
func _physics_process(delta: float) -> void:
	if game_started:
		if not is_on_floor():
			velocity += get_gravity() * delta
		update_state()
		var correct_state = current_state == STATE.IDLE or current_state == STATE.FALLING_FAST
		if Input.is_action_just_pressed("jump_left") and correct_state:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
			velocity.x = -dash_speed
		elif Input.is_action_just_pressed("jump_right") and correct_state:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
			velocity.x = dash_speed
		elif Input.is_action_pressed("hold_jump"):
			hold_flag = true
		elif Input.is_action_just_released("hold_jump") and hold_flag:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed * hold_timer * hold_scalar
			hold_timer = 0.0
			hold_jump_available = false
			$HoldJumpTimer.start()
		elif Input.is_action_just_pressed("basic_jump") and correct_state:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
		move_and_slide()
		# Tracking if the player is holding the space bar
		if hold_flag and hold_jump_available:
			velocity.y = 0
			hold_timer += delta
		if position.y < player_record_y:
			reached_new_record_y.emit(player_record_y, position.y)
			player_record_y = position.y
	
# Determines if the player is idle
func _on_idle_timer_timeout() -> void:
	# check again to validate the player has stopped moving
	if velocity == Vector2.ZERO or is_on_floor():
		current_state = STATE.IDLE
		velocity.x = 0

# Resets the hold jump ability
func _on_hold_jump_timer_timeout() -> void:
	hold_jump_available = true

# Allows the player to jump higher and faster at each difficulty increment
func _on_level_difficulty_increase() -> void:
	jump_speed += jump_speed_increment

func _on_main_menu_start_game() -> void:
	game_started = true
