class_name PorteTrompeuse
extends Area3D

## Une porte qui mène ailleurs selon ce que le joueur regarde en la traversant.

## Délai pendant lequel une porte ne renvoie pas un joueur qui vient d'arriver.
const DELAI_MS := 400

@export var destinations: Array[NodePath] = []
@export var cible_regard: NodePath
@export var angle_max_deg := 15.0
@export var index_si_regard := 1
@export var index_sinon := 0


static func choisir(dir_regard: Vector3, vers_cible: Vector3, angle_max: float, si_regard: int, sinon: int) -> int:
	return si_regard if rad_to_deg(dir_regard.angle_to(vers_cible)) <= angle_max else sinon


## Place le joueur par rapport à la sortie comme il l'était par rapport à l'entrée.
static func transfert(entree: Transform3D, sortie: Transform3D, joueur: Transform3D) -> Transform3D:
	return sortie * entree.affine_inverse() * joueur


func _ready() -> void:
	body_entered.connect(_corps_entre)


func _corps_entre(corps: Node3D) -> void:
	if not corps is Player or destinations.is_empty():
		return
	var joueur := corps as Player
	var maintenant := Time.get_ticks_msec()
	if maintenant - int(joueur.get_meta("arrivee_ms", -DELAI_MS)) < DELAI_MS:
		return
	var index := index_sinon
	var cible := get_node_or_null(cible_regard) as Node3D
	if cible != null:
		var cam := joueur.camera
		index = choisir(-cam.global_basis.z, cible.global_position - cam.global_position, angle_max_deg, index_si_regard, index_sinon)
	var sortie := get_node_or_null(destinations[clampi(index, 0, destinations.size() - 1)]) as Node3D
	if sortie == null:
		return
	joueur.set_meta("arrivee_ms", maintenant)
	joueur.teleport(transfert(global_transform, sortie.global_transform, joueur.global_transform))
