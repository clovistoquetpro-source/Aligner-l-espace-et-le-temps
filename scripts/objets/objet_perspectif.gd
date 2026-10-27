class_name ObjetPerspectif
extends RigidBody3D

## Un objet à perspective forcée : quand on le porte, il garde la même taille à
## l'écran. Visé loin, il se pose loin et devient grand ; visé près, il
## rapetisse. Posé, il garde sa nouvelle taille.

const TAILLE_MIN := 0.15
const TAILLE_MAX := 4.0
const DIST_MIN := 0.6
const DIST_MAX := 30.0
const KILL_Y := -20.0

@export var taille_depart := 0.5
## Si l'objet sort de cette zone (coordonnées du monde) sans être porté, il
## revient à sa place de départ. Une zone vide désactive ce retour.
@export var zone := AABB()

var porte := false
var taille: float:
	set(t):
		taille = t
		if is_node_ready():
			_appliquer_taille()

var _depart: Transform3D
## Taille de la boîte de collision pour `taille == 1` (un cube : Vector3.ONE).
var _forme_base := Vector3.ONE

## Le dessin de l'objet : un seul mesh ou plusieurs formes.
@onready var _mesh: Node3D = $Mesh
@onready var _forme: CollisionShape3D = $CollisionShape3D


static func taille_pour(ratio: float, distance: float) -> float:
	return clampf(ratio * distance, TAILLE_MIN, TAILLE_MAX)


func _ready() -> void:
	_forme_base = (_forme.shape as BoxShape3D).size
	_forme.shape = _forme.shape.duplicate()
	taille = taille_depart
	_appliquer_taille()
	_depart = global_transform


func _appliquer_taille() -> void:
	_mesh.scale = Vector3.ONE * taille
	(_forme.shape as BoxShape3D).size = _forme_base * taille


func reinitialiser() -> void:
	global_transform = _depart
	taille = taille_depart
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if porte:
		return
	var hors_zone := zone.has_volume() and not zone.has_point(global_position)
	if hors_zone or global_position.y < KILL_Y:
		reinitialiser()


## Place l'objet le plus loin possible dans le regard de la caméra, à une
## taille proportionnelle à la distance (ratio = taille / distance).
func placer(cam: Camera3D, ratio: float, exclure: Array[RID]) -> void:
	var origine := cam.global_position
	var dir := -cam.global_basis.z
	var base := Basis(Vector3.UP, cam.global_rotation.y)
	var espace := get_world_3d().direct_space_state
	var excl: Array[RID] = exclure.duplicate()
	excl.append(get_rid())
	var rayon := PhysicsRayQueryParameters3D.create(origine, origine + dir * DIST_MAX)
	rayon.exclude = excl
	var touche := espace.intersect_ray(rayon)
	var hi := DIST_MAX if touche.is_empty() else origine.distance_to(touche["position"])
	var lo := DIST_MIN
	# Recherche de la plus grande distance où l'objet ne touche rien.
	for i in 12:
		if hi - lo < 0.01:
			break
		var milieu := (lo + hi) / 2.0
		if _libre(espace, Transform3D(base, origine + dir * milieu), taille_pour(ratio, milieu), excl):
			lo = milieu
		else:
			hi = milieu
	taille = taille_pour(ratio, lo)
	global_transform = Transform3D(base, origine + dir * lo)


func _libre(espace: PhysicsDirectSpaceState3D, t: Transform3D, cote: float, excl: Array[RID]) -> bool:
	var boite := BoxShape3D.new()
	boite.size = _forme_base * cote * 0.98
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = boite
	q.transform = t
	q.exclude = excl
	return espace.intersect_shape(q, 1).is_empty()
