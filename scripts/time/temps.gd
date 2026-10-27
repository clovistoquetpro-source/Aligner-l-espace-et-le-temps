extends Node

## Autoload « Temps » : l'époque courante et la bascule entre les époques.

enum Epoque { PRESENT, PASSE }

signal epoque_changee(nouvelle: int)
signal bascule_refusee

## Taille du joueur, pieds à l'origine (voir scenes/player.tscn).
const TAILLE_JOUEUR := Vector3(0.7, 1.8, 0.7)
## Marge pour qu'un sol touché du bout des pieds ne bloque pas la bascule.
const MARGE := 0.05

var courante: int = Epoque.PRESENT


static func bascule_possible(joueur_aabb: AABB, solides_futurs: Array[AABB]) -> bool:
	for s in solides_futurs:
		if joueur_aabb.intersects(s):
			return false
	return true


func basculer(joueur: Node3D) -> bool:
	var future := Epoque.PASSE if courante == Epoque.PRESENT else Epoque.PRESENT
	var solides: Array[AABB] = []
	for m in get_tree().get_nodes_in_group(EpochMember.GROUPE):
		if m.epoque == future:
			solides.append_array(m.aabbs_solides())
	var aabb := AABB(joueur.global_position - Vector3(TAILLE_JOUEUR.x, 0, TAILLE_JOUEUR.z) / 2, TAILLE_JOUEUR).grow(-MARGE)
	if not bascule_possible(aabb, solides):
		bascule_refusee.emit()
		return false
	courante = future
	epoque_changee.emit(courante)
	return true


func reinitialiser() -> void:
	courante = Epoque.PRESENT
	epoque_changee.emit(courante)
