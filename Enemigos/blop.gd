extends CharacterBody2D

const SPEED = 150.0
const RAY_FLOOR_POSITION_X = 29
const RAY_WALL_TARGET_POSITION_X = 18

var vida_max = 3
var vida_actual = vida_max
var esta_muerto = false
var atacando = false
var jugador_en_area = false
var objetivo_jugador = null
var direccion = 1 # 1 = derecha, -1 = izquierda
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$AnimatedSprite2D.play("Iddle")
	velocity.x = SPEED 
	$RayCast2D_floor_detection.position.x = RAY_FLOOR_POSITION_X
	$RayCast2D_wall_detection.target_position.x = RAY_WALL_TARGET_POSITION_X


func _physics_process(delta: float):
	if esta_muerto:
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
	move_and_slide()

# --- FUNCIÓN PARA GIRAR ---
func girar():
	direccion *= -1
	velocity.x = SPEED * direccion

	# Cambiar orientación visual
	$AnimatedSprite2D.flip_h = direccion > 0

	# Cambiar posición de detección de suelo y pared
	$RayCast2D_floor_detection.position.x = abs(RAY_FLOOR_POSITION_X) * direccion
	$RayCast2D_wall_detection.target_position.x = abs(RAY_WALL_TARGET_POSITION_X) * direccion

# --- DAÑO Y MUERTE ---
func _recibir_daño(cantidad):
	if esta_muerto:
		return 
	vida_actual -= cantidad
	print("Daño recibido:", cantidad)
	print("Vida actual:", vida_actual)

	if vida_actual <= 0:
		morir()

func morir():
	if esta_muerto:
		return
	
	esta_muerto = true
	atacando = false
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("Death")
	$CollisionShape2D.set_deferred("disabled", true)
	$Area_Ataque.set_deferred("monitoring", false)
	await $AnimatedSprite2D.animation_finished
	queue_free()

# --- DETECCIÓN DE GOLPES ---
func _on_area_daño_area_entered(area: Area2D) -> void:
	if esta_muerto:
		return
	if area.is_in_group("golpe"):
		_recibir_daño(1)
		print("Daño por área de golpe a blop")


func _on_area_ataque_body_entered(body: Node2D) -> void:
	if esta_muerto:
		return
	if body.is_in_group("player"):
		objetivo_jugador = body
		jugador_en_area = true
		atacando = true
		if jugador_en_area and not esta_muerto and objetivo_jugador:
			if objetivo_jugador.puede_recibir_daño:
				objetivo_jugador._recibir_daño(1)
			var direccion_x = sign(objetivo_jugador.global_position.x - global_position.x)
			if direccion_x == 0:
				direccion_x = 1
			var knockback_direccion = Vector2(direccion_x, -0.3).normalized()
			objetivo_jugador.aplicar_knockback(knockback_direccion, 250.0, 0.2)
			
func _on_area_ataque_body_exited(body: Node2D) -> void:
	if esta_muerto:
		return
	if body.is_in_group("player"):
		atacando = false
		jugador_en_area = false
		objetivo_jugador = null
