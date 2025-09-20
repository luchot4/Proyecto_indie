extends CharacterBody2D
const SPEED = 150.0
const RAY_FLOOR_POSITION_X = 23
const RAY_WALL_TARGET_POSITION_X = 27

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	velocity.x = SPEED 
	$RayCast2D_floor_detection.position.x = RAY_FLOOR_POSITION_X
	$RayCast2D_wall_detection.target_position.x = RAY_WALL_TARGET_POSITION_X
func _physics_process(delta: float):
	##Add the gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if not $RayCast2D_floor_detection.is_colliding():
		velocity.x *= -1
		$RayCast2D_floor_detection.position.x *= -1
		
	if is_on_wall():
		if !$AnimatedSprite2D.flip_h:
			velocity.x = SPEED
		else:
			velocity.x = -SPEED
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0:
		$AnimatedSprite2D.flip_h = true
	move_and_slide()
