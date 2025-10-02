extends CharacterBody2D
const SPEED = 150.0
const RAY_FLOOR_POSITION_X = 23
const RAY_WALL_TARGET_POSITION_X = 27
var vida_max = 2
var vida_actual = vida_max
var No_esta_muerto = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$AnimatedSprite2D.play("Walking")
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


func _on_ataque_carp_tox_body_entered(body):
	if body.is_in_group("player"):
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("Ataque_tox")
		$AtaqueTimer.wait_time = 0.7
		$AtaqueTimer.start()
	pass # Replace with function body.

func _on_ataque_carp_tox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		velocity.x = SPEED 
		$AtaqueTimer.stop()
		$AnimatedSprite2D.play("Walking")
	pass # Replace with function body.

func _on_ataque_timer_timeout() -> void:
	$AnimatedSprite2D.play("Ataque_tox")
	pass # Replace with function body.

func _recibir_daño(cantidad):
	if No_esta_muerto:
		return 
	vida_actual -= cantidad
	print("Daño recibido: ",cantidad)
	print("Vida actual ", vida_actual)
	if vida_actual <= 0:
		morir()

func morir():		#Corregir
	if No_esta_muerto:
		return 
	No_esta_muerto = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("Death")
	$ataque_carp_tox.set_deferred("monitoring", false)
	
	await  $AnimatedSprite2D.animation_finished
	queue_free()
	

func _on_area_daño_area_entered(area: Area2D) -> void:
	if area.is_in_group("golpe"):
		_recibir_daño(1)
		print("daño")
	pass # Replace with function body.
