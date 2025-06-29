extends Camera2D

@export var camera_max_speed := 500
@export var camera_min_speed := 10
@export var camera_speed_increment := 25

var camera_speed := camera_min_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y -= camera_speed * delta

func _on_level_difficulty_increase() -> void:
	camera_speed += camera_speed_increment
	if camera_speed > camera_max_speed:
		camera_speed = camera_max_speed
