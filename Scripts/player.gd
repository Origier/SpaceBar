extends CharacterBody2D

# The force applied to jumps
@export var jump_speed := -450
# The force applied to sideways movements
@export var dash_speed := 300
# The scalar applied to the held jump
@export var hold_scalar := 3
# The required downward velocity to allow jumping to continue
@export var falling_speed_requirement := 200

# Time in seconds to clear the buffer and use the data provided to make a move
@export var buffer_refresh_time := 0.075
var input_buffer := []
# Cooldown timer for the charged jump in seconds
@export var hold_jump_cooldown = 10
var hold_jump_available := true
# Timer to determine how long the player held the spacebar for
var hold_timer := 0.0
# Flag to determine if to add hold time or not
var hold_flag := false

# Keyboard code for the spacebar
var SPACE_BAR_CODE = 32

# State machine to control how the player operates in different states
enum STATE {
	IDLE,
	JUMPING,
	FALLING,
	FALLING_FAST
}

# States for the space bar to track for input buffering
enum SPACE_BAR_STATE {
	PRESS,
	HOLD,
	PRESS_AND_RELEASE
}

# State of the state machine
var current_state := STATE.IDLE

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
	current_state = STATE.IDLE
	$InputBufferTimer.wait_time = buffer_refresh_time
	$HoldJumpTimer.wait_time = hold_jump_cooldown
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	update_state()
	move_and_slide()
	# Tracking if the player is holding the space bar
	if hold_flag and hold_jump_available:
		velocity.y = 0
		hold_timer += delta

# Flushes the input buffer while processing the input
func process_input_buffer():
	# Input buffer based on size
	# Logic for held jump
	if len(input_buffer) >= 2 and input_buffer[1] == SPACE_BAR_STATE.HOLD and hold_jump_available:
		current_state = STATE.JUMPING
		velocity = Vector2.ZERO
		velocity.y = jump_speed * hold_timer * hold_scalar
		hold_timer = 0.0
		hold_jump_available = false
		$HoldJumpTimer.start()
	# Logic for the other combos
	else:
		var correct_state = current_state == STATE.IDLE or current_state == STATE.FALLING_FAST
		# Ensure the player is in the right state before applying any jumps
		if not correct_state:
			input_buffer = []
			pass
		# Jump Logic
		if len(input_buffer) == 1 and input_buffer[0] == SPACE_BAR_STATE.PRESS_AND_RELEASE:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
		# Logic for jumping to the right
		elif len(input_buffer) == 2 and input_buffer[1] == SPACE_BAR_STATE.PRESS_AND_RELEASE:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
			velocity.x = dash_speed
		# Logic for jumping to the left
		elif len(input_buffer) >= 3 and input_buffer[2] == SPACE_BAR_STATE.PRESS_AND_RELEASE:
			current_state = STATE.JUMPING
			velocity = Vector2.ZERO
			velocity.y = jump_speed
			velocity.x = -dash_speed
	input_buffer = []

# Handles all key press events and dispatches accordingly
func handle_key_press_event(event):
	match event.keycode:
		# Capture the press and release to determine the start of input
		SPACE_BAR_CODE:
			# Each key press resets the timer - allowing for further key presses to register
			var pressed = event.is_pressed()
			var repeating = event.is_echo()
			if pressed:
				$InputBufferTimer.stop()
				input_buffer.append(SPACE_BAR_STATE.PRESS)
				if repeating:
					hold_flag = true
					input_buffer[-1] = SPACE_BAR_STATE.HOLD
			else:
				$InputBufferTimer.start()
				hold_flag = false
				input_buffer[-1] = SPACE_BAR_STATE.PRESS_AND_RELEASE

# Main function for handling events in the game due to sporadic physics type events
func _unhandled_input(event):
	if event is InputEventKey:
		handle_key_press_event(event)

func _on_idle_timer_timeout() -> void:
	# check again to validate the player has stopped moving
	if velocity == Vector2.ZERO or is_on_floor():
		current_state = STATE.IDLE
		velocity.x = 0

# Calls the process function to handle the input buffer
func _on_input_buffer_timer_timeout() -> void:
	process_input_buffer()

# Resets the hold jump ability
func _on_hold_jump_timer_timeout() -> void:
	hold_jump_available = true
