class_name Cartouche
extends Area3D

## Le cartouche doré au bout d'une zone : le toucher réussit la zone, une
## seule fois. Il tourne lentement tant qu'on ne l'a pas touché.

const OR := Color("f3c330")
const ETEINT := Color("8f8a80")
const VITESSE := 0.8

signal touche(zone: String)

## « carriere », « rampe », « camp » ou « temple ».
@export var zone := ""

var est_touche := false

@onready var _visuel: Node3D = $Visuel


func _ready() -> void:
	body_entered.connect(_corps_entre)
	_colorer(Style.materiau(OR, true))


func _process(delta: float) -> void:
	if not est_touche:
		_visuel.rotate_y(VITESSE * delta)


func _corps_entre(corps: Node3D) -> void:
	if est_touche or not corps is Player:
		return
	est_touche = true
	_colorer(Style.materiau(ETEINT))
	touche.emit(zone)


func _colorer(m: StandardMaterial3D) -> void:
	for f in _visuel.get_children():
		if f is CSGShape3D:
			f.material = m
