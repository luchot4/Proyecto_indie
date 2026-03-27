extends Node2D
@export var carp_tox_escena : Array[PackedScene]
@export var blop_escena : Array[PackedScene]
@export var puntos_carp_tox : Array[Marker2D]
@export var puntos_blop : Array[Marker2D]


func _ready():
	Spawn_Enemigos()
	
func Spawn_Enemigos():
	for puntoSpawnCT in range(min(carp_tox_escena.size(), puntos_carp_tox.size())):
		var carpTox = carp_tox_escena[puntoSpawnCT].instantiate()
		carpTox.global_position = puntos_carp_tox[puntoSpawnCT].global_position
		add_child(carpTox)
	for puntoSpawnB in range(min(blop_escena.size(), puntos_blop.size())):
		var blop = blop_escena[puntoSpawnB].instantiate()
		blop.global_position = puntos_blop[puntoSpawnB].global_position
		add_child(blop)

	
