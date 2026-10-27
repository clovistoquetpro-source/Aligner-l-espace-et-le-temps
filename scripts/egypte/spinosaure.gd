class_name Spinosaure
extends AnimatableBody3D

## Le spinosaure endormi en travers de l'entrée de la carrière. Un objet
## perspectif assez grand, posé dans sa zone d'appât, le réveille : il va le
## manger, puis se recouche plus loin et libère le passage. Un objet trop
## petit le fait juste renifler.

enum Etat { DORT, MARCHE, REPU }

signal renifle
signal reveille

@export var zone_appat: NodePath
## Là où il se recouche après son repas.
@export var arrivee: NodePath
@export var taille_min := 1.5
@export var duree_marche := 2.5

var etat := Etat.DORT

## Les petits objets déjà reniflés, tant qu'ils restent posés dans la zone.
var _renifles: Array[Node] = []


static func appat_valable(corps: Node, taille_min: float) -> bool:
	return corps is ObjetPerspectif and not corps.porte and corps.taille >= taille_min


func _ready() -> void:
	_dormir()


func _physics_process(_delta: float) -> void:
	if etat != Etat.DORT:
		return
	var zone := get_node_or_null(zone_appat) as Area3D
	if zone == null:
		return
	var dedans := zone.get_overlapping_bodies()
	_renifles = _renifles.filter(func(c: Node) -> bool: return c in dedans and not c.porte)
	for corps in dedans:
		if appat_valable(corps, taille_min):
			_manger(corps)
			return
		if corps is ObjetPerspectif and not corps.porte and not corps in _renifles:
			_renifles.append(corps)
			renifle.emit()


func _manger(appat: ObjetPerspectif) -> void:
	etat = Etat.MARCHE
	# Le poisson est à lui : on ne peut plus le reprendre.
	appat.freeze = true
	appat.collision_layer = 0
	reveille.emit()
	Anime.jouer(self, "Walk")
	var fin := get_node(arrivee) as Node3D
	var devant := appat.global_position
	devant.y = global_position.y
	var t := create_tween()
	t.tween_callback(_tourner_vers.bind(devant))
	t.tween_property(self, "global_position", devant, duree_marche)
	t.tween_callback(appat.queue_free)
	t.tween_callback(_tourner_vers.bind(fin.global_position))
	t.tween_property(self, "global_position", fin.global_position, duree_marche)
	t.tween_callback(_se_recoucher)


func _tourner_vers(cible: Vector3) -> void:
	var dir := cible - global_position
	if Vector2(dir.x, dir.z).length() > 0.01:
		# Les modèles regardent vers +Z.
		rotation.y = atan2(dir.x, dir.z)


func _se_recoucher() -> void:
	etat = Etat.REPU
	_dormir()


## Pose couchée : la dernière image de l'animation « Death ».
func _dormir() -> void:
	Anime.jouer(self, "Death", true)
