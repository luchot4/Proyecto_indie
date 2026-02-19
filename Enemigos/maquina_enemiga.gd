extends CharacterBody2D

var vida_max = 3
var vida_actual = vida_max
var No_esta_muerto = false
var jugador_en_area = false
var objetivo_jugador = null

func _physics_process(delta: float):
	if No_esta_muerto:
		return

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
	$CollisionShape2D.set_deferred("disabled", true)
	$"Area_Daño".set_deferred("monitoring", false)
	queue_free()
func _on_area_daño_area_entered(area: Area2D) -> void:
	if No_esta_muerto:
		return
	if area.is_in_group("golpe"):
		_recibir_daño(1)
		print("Daño por área")
