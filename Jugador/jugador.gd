extends CharacterBody2D

const SPEED = 300.0
const SPEED_RUN = 1.2
const JUMP_VELOCITY = -450.0
var appeared:bool = false
var leaved_floor:bool = false
var had_jump:bool = false
##DOBLE SALTO
var max_jumps : int = 2
var cont_jumps : int = 0
@export var ataque: bool = false
var tomar : bool = false
var vida_max = 3
var vida_actual = vida_max
var esta_muerto = false
var puede_recibir_daño = true 
##KNOCKBACK VARIABLES
var knockback : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0
##PEGARSE A LA PARED
var ray_cast_dimension = 9.5
var ver_lado_izquierdo : bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$Area2D/CollisionAtaque.disabled = true
	$animations.play("Appear")
	##PARA PEGARSE A LA PARED
	
	##TEMPORIZADOR PARA EL COOLDOWN DE DAÑO QUE RECIBE EL JUGADOR
	$CoolDownTimer.wait_time = 3.0 ## TIEMPO DE INVULNERABILIDAD
	$CoolDownTimer.one_shot = true
	$CoolDownTimer.autostart = false
	##TEMPORIZADOR PARA EL PARPADEO DURANTE EL DAÑO
	$ParpadeoTimer.wait_time = 0.2
	$ParpadeoTimer.one_shot = false
	$ParpadeoTimer.autostart = false
	


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ataque"):
		atacar_x()
	if ataque:
		actualizar_hitbox()
	if Input.is_action_just_pressed("tomar_mate"):
		tomar_mate()
	pass
func _physics_process(delta: float):
	Animated()
	var velocidad_constante = SPEED_RUN
	var direction = Input.get_axis("ui_left","ui_right")
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	elif tomar:		##PARA QUE CUANDO ESTE EN EL AIRE Y SE PRESIONE PARA TOMAR MATE, NO QUEDE CONGELADO EN EL AIRE
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y += gravity * delta
		move_and_slide()
		return
	else:
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
			cont_jumps += 1
			velocity.y = JUMP_VELOCITY
		# Get the input direction and handle the movement/deceleration
		#As good practice, you should replace UI actions with custom gameplay actions
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		if Input.is_action_pressed("correr"):
			velocidad_constante*=SPEED_RUN
		if direction != 0:
			ver_lado_izquierdo = direction < 0
			velocity.x *= velocidad_constante
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		actualizar_Pared_Raycast()

	pegarse_y_saltar_pared(delta)
	move_and_slide()
	decide_animation()
	
	
func actualizar_Pared_Raycast():
	$RayCast2D_WallJump.target_position = Vector2(-ray_cast_dimension if ver_lado_izquierdo else ray_cast_dimension, 0)
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
	if had_jump: 
		if cont_jumps < max_jumps : return true 
		else : return false
	if is_on_floor(): 
		cont_jumps = 0
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

func Animated():	#Para la animacion de Atacar
	if tomar:
		return		##PARA NO SOBREESCRIBIR LA ANIMACION MIENTRAS TOMA MATE
	if !ataque:
		if velocity.x < 0 :
			$animations.flip_h = true
		elif velocity.x > 0: 
			$animations.flip_h = false
		if is_on_floor():
			if velocity.x != 0:
				$animations.play("Run")
			if velocity.x == 0: 
				$animations.play("Iddle")
		else:
			$animations.play("Jump_up")
		pass
func atacar_x():   #Funcion para cuando se presiona la "x" se ataque
	ataque = true
	$Area2D/CollisionAtaque.disabled = false
	$animations.play("Attack")
	var direction = sign(velocity.x)
	if direction != 0:
		$Area2D/CollisionAtaque.position.x = direction * abs($Area2D/CollisionAtaque.position.x)
	$animations.play("Attack")
	await $animations.animation_finished
	ataque = false
	$Area2D/CollisionAtaque.disabled = true
func actualizar_hitbox():
	var offset = abs($Area2D/CollisionAtaque.position.x)
	if $animations.flip_h:
		$Area2D/CollisionAtaque.position.x = -offset
	else:
		$Area2D/CollisionAtaque.position.x = offset

func tomar_mate():		##FUNCION PARA TOMAR MATE
	tomar = true
	var orientacion_actual = $animations.flip_h
	$animations.play("Tomar_mate")
	$animations.flip_h = orientacion_actual
	await $animations.animation_finished
	tomar = false

func _recibir_daño(cantidad):		##FUNCION PARA QUE EL JUGADOR RECIBA DAÑO DEPENDIENDO DE LA CANTIDAD ASIGNADA
	if esta_muerto or not puede_recibir_daño:
		return
	vida_actual -= cantidad
	puede_recibir_daño = false
	$CoolDownTimer.start()
	$ParpadeoTimer.start()
	##PARA QUE SEA INVULNERABLE DURANTE EL COOLDOWN
	collision_mask &= ~8 	##SACA LA MASCARA 4
	
	print("Daño recibido:", cantidad)
	print("Vida actual:", vida_actual)

	if vida_actual <= 0:
		morir()

func morir():
	if esta_muerto:
		return
	esta_muerto = true
	velocity = Vector2.ZERO
	queue_free()
	
func _on_area_2d_area_entered(area: Area2D) -> void:  ##FUNCION QUE HACIA QUE EL JUGADOR RECIBA DAÑO, POR AHORA BLOQUEADOO
	if area.is_in_group("enemigo_daño"):
		print("daño dado")
	pass # Replace with function body.

 
func _on_cool_down_timer_timeout() -> void:
	puede_recibir_daño = true
	collision_mask |= 8 
	$ParpadeoTimer.stop()
	$animations.visible = true

func aplicar_knockback(direccion: Vector2, force: float, knockback_duracion: float) -> void:
	knockback = direccion * force
	knockback_timer = knockback_duracion

func _on_parpadeo_timer_timeout() -> void:
	$animations.visible = not $animations.visible

##FUNCION PARA PODER PEGARSE Y SALTAR DE LA PARED
func pegarse_y_saltar_pared(_delta):
	##Si el raycast detecta la pared y salta
	if $RayCast2D_WallJump.get_collider():
		if $RayCast2D_WallJump.get_collider().is_in_group("salto pared") :
			##PEGARSE A LA PARED
			cont_jumps = 0
			velocity.y = 0
			##velocity.y = move_toward(velocity.y, 80, 600 * delta) ##amortiguar caida
		
			##SALTO DE PARED
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y =JUMP_VELOCITY
				#Empuje horizontal para separarse de la pared 
				if ver_lado_izquierdo:
					velocity.x = SPEED * 2
				else:
					velocity.x = -SPEED * 2
