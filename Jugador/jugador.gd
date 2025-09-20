extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var appeared:bool = false
var leaved_floor:bool = false
var had_jump:bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$animations.play("Appear")

func _physics_process(delta: float):
	##Add the gravity
	if is_on_floor():
		leaved_floor = false
		had_jump = false
	
	if not is_on_floor():
		if not leaved_floor:	
			$CoyoteTimer.start()
			leaved_floor=true
		velocity.y += gravity * delta
	
	#Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and right_to_jump():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration
	#As good practice, you should replace UI actions with custom gameplay actions
	var direction = Input.get_axis("ui_left","ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()
	decide_animation()
	
func decide_animation():
	#appear
	if not appeared: return
	# X Axis
	if velocity.x == 0:
		#iddle
		$animations.play("Iddle")
	elif velocity.x < 0:
		#left
		$animations.flip_h = true
		$animations.play("Run")
	elif velocity.x > 0:
		#right
		$animations.flip_h = false
		$animations.play("Run")
		
	# Y Axis
	if velocity.y > 0:
		$animations.play("Fall")
	elif velocity.y < 0:
		$animations.play("Jump_up")

func right_to_jump():
	if had_jump: return false
	if is_on_floor(): 
		had_jump = true
		return true
	elif not $CoyoteTimer.is_stopped(): 
		had_jump = true
		return true

func _on_animations_animation_finished() -> void:
	if $animations.animation == "Appear":
		appeared = true
		
func _on_coyote_timer_timeout() -> void:
	print("Lol")
