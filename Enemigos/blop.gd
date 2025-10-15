extends CharacterBody2D

const SPEED = 150.0
const RAY_FLOOR_POSITION_X = 29
const RAY_WALL_TARGET_POSITION_X = 18

var vida_max = 3
var vida_actual = vida_max
var No_esta_muerto = false
var atacando = false
var direccion = 1 # 1 = derecha, -1 = izquierda
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$AnimatedSprite2D.play("Iddle")
	velocity.x = SPEED 
	$RayCast2D_floor_detection.position.x = RAY_FLOOR_POSITION_X
	$RayCast2D_wall_detection.target_position.x = RAY_WALL_TARGET_POSITION_X


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
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()

# --- DETECCIÓN DE GOLPES ---
func _on_area_daño_area_entered(area: Area2D) -> void:
	if No_esta_muerto:
		return
	if area.is_in_group("golpe"):
		_recibir_daño(1)
		print("Daño por área de golpe a blop")
