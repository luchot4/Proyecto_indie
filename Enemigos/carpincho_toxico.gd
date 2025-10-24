extends CharacterBody2D

const SPEED = 150.0
const RAY_FLOOR_POSITION_X = 23
const RAY_WALL_TARGET_POSITION_X = 27

var vida_max = 2
var vida_actual = vida_max
var No_esta_muerto = false
var atacando = false
var jugador_en_area = false
var objetivo_jugador = null  ## SE UTILIZA CUANDO EL JUGADOR ENTRA AL AREA Y PARA EL KNOCKBACK
var direccion = 1 # 1 = derecha, -1 = izquierda
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$AnimatedSprite2D.play("Walking")
	velocity.x = SPEED 
	$RayCast2D_floor_detection.position.x = RAY_FLOOR_POSITION_X
	$RayCast2D_wall_detection.target_position.x = RAY_WALL_TARGET_POSITION_X
	##Contador para controlar cuando el jugador entra al area de daño
	$DañoTimer.wait_time = 0.7
	$DañoTimer.autostart = false
	$DañoTimer.one_shot = false
	
func _physics_process(delta: float):
	if No_esta_muerto:
		return
	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Detección de borde (cambia dirección)
	if not $RayCast2D_floor_detection.is_colliding():
		girar()
		
	# Detección de pared
	if is_on_wall():
		girar()

	# 👉 Solo actualizar flip si NO está atacando ni muerto
	if not atacando and not No_esta_muerto:
		if velocity.x < 0:
			$AnimatedSprite2D.flip_h = false
		elif velocity.x > 0:
			$AnimatedSprite2D.flip_h = true

	move_and_slide()


# --- FUNCIÓN PARA GIRAR ---
func girar():
	direccion *= -1
	velocity.x = SPEED * direccion

	# Cambiar orientación visual
	$AnimatedSprite2D.flip_h = direccion < 0

	# Cambiar posición de detección de suelo y pared
	$RayCast2D_floor_detection.position.x = abs(RAY_FLOOR_POSITION_X) * direccion
	$RayCast2D_wall_detection.target_position.x = abs(RAY_WALL_TARGET_POSITION_X) * direccion

	# Cambiar lado del área de ataque
	$Ataque_Carp_Tox.position.x = abs($Ataque_Carp_Tox.position.x) * direccion

	# Cambiar lado del CollisionShape2D dentro del área
	$Ataque_Carp_Tox/ataque_tox.position.x = abs($Ataque_Carp_Tox/ataque_tox.position.x) * direccion


# --- ATAQUE ---
func _on_ataque_carp_tox_body_entered(body):
	if No_esta_muerto:
		return
	if body.is_in_group("player"):
		objetivo_jugador = body
		jugador_en_area = true
		atacando = true
		velocity = Vector2.ZERO		##SE QUEDA EN EL LUGAR UNA VEZ DETECTA AL JUGADOR
		# Hace que mire hacia el jugador antes de atacar
		if body.global_position.x < global_position.x:
			direccion = -1
			$AnimatedSprite2D.flip_h = false
		else:
			direccion = 1
			$AnimatedSprite2D.flip_h = true

		# Ajustar ataque al nuevo lado
		$Ataque_Carp_Tox.position.x = abs($Ataque_Carp_Tox/ataque_tox.position.x) * direccion
		$Ataque_Carp_Tox/ataque_tox.position.x = abs($Ataque_Carp_Tox/ataque_tox.position.x) * direccion
		
		$AnimatedSprite2D.play("Ataque_tox")
		atacar()		##LLAMA A LA FUNCION DE ATAUE
		$AtaqueTimer.wait_time = 0.9		##TEMPORIZADOR PARA VOLVER A REPETIR LA ANIMACION DE ATAQUE
		$AtaqueTimer.start()		##INICIA EL TEMPORIZADOR DEL ATAQUE
		

func atacar():		##FUNCION PARA CONTROLAR EL ATAQUE DESPUES QUE TERMINO LA ANIMACION
	atacando = true
	$AnimatedSprite2D.play("Ataque_tox")	##INICA LA ANIMACION DE ATAQUE
	await $AnimatedSprite2D.animation_finished  # ⏳ Espera a que termine la animación
	if jugador_en_area and not No_esta_muerto and objetivo_jugador:		##SI EL JUGADOR ESTA EN AREA Y SIGUE VIVO ENTONCES RECIBE DAÑOO
		if objetivo_jugador.puede_recibir_daño:
			objetivo_jugador._recibir_daño(1)
		##get_tree().call_group("player", "_recibir_daño", 1)		##LLAMA A RECIBIR DAÑO Y EL JUGADOR RECIBE UN PUNTO DE DAÑOP
		var direccion_x = sign(objetivo_jugador.global_position.x - global_position.x)
		if direccion_x == 0:
			direccion_x = 1
		var knockback_direccion = Vector2(direccion_x, -0.3).normalized()
		objetivo_jugador.aplicar_knockback(knockback_direccion, 250.0, 0.2)
	atacando = false	
	$AnimatedSprite2D.play("Walking")

func _on_ataque_carp_tox_body_exited(body: Node2D) -> void:
	if No_esta_muerto:
		return
	if body.is_in_group("player"):
		atacando = false
		jugador_en_area = false
		objetivo_jugador = null
		# Reanuda movimiento según dirección
		velocity.x = SPEED * direccion
		$AtaqueTimer.stop()
		$AnimatedSprite2D.play("Walking")

func _on_ataque_timer_timeout() -> void:
	if No_esta_muerto:
		return
	$AnimatedSprite2D.play("Ataque_tox")


# --- DAÑO Y MUERTE ---
func _recibir_daño(cantidad):
	if No_esta_muerto:
		return 
	vida_actual -= cantidad
	print("Daño recibido:", cantidad)
	print("Vida actual:", vida_actual)

	if vida_actual <= 0:
		morir()


func morir():
	if No_esta_muerto:
		return
	
	No_esta_muerto = true
	atacando = false
	
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("Death")
	$CollisionShape2D.set_deferred("disabled", true)
	$Ataque_Carp_Tox.set_deferred("monitoring", false)
	await $AnimatedSprite2D.animation_finished
	queue_free()


# --- DETECCIÓN DE GOLPES ---
func _on_area_daño_area_entered(area: Area2D) -> void:
	if No_esta_muerto:
		return
	if area.is_in_group("golpe"):
		_recibir_daño(1)
		print("Daño por área de golpe")
