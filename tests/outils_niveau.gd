extends RefCounted

## Aides partagées par les tests des niveaux (maison, Égypte…).

## Murs, sols, plafonds… : deux de ces boîtes ne doivent jamais occuper le
## même volume (leurs faces se superposent et scintillent).
const STRUCTURE := ["Mur", "Plafond", "Sol", "Estrade", "Colonne", "Arche", "PorteSortie", "Socle", "Troncon", "Terrasse", "Falaise", "Enceinte"]


static func tous(racine: Node, filtre: Callable) -> Array[Node]:
	var res: Array[Node] = []
	for n in racine.find_children("*", "", true, false):
		if filtre.call(n):
			res.append(n)
	return res


## Tourne le joueur pour que sa caméra vise ce point.
static func viser(j: Player, cible: Vector3) -> void:
	var d := cible - j.camera.global_position
	j.rotation.y = atan2(-d.x, -d.z)
	j.head.rotation.x = asin(d.normalized().y)


static func boite(b: CSGBox3D) -> AABB:
	return b.global_transform * AABB(-b.size / 2, b.size)


static func epoque(n: Node) -> int:
	var e := n.get_node_or_null("EpochMember")
	return e.epoque if e != null else -1


static func boites(n: Node, prefixes: Array) -> Array[Node]:
	return tous(n, func(x: Node) -> bool:
		return x is CSGBox3D and not (x.get_parent() is CSGShape3D) \
			and prefixes.any(func(p: String) -> bool: return String(x.name).begins_with(p)))


static func chevauchements(liste: Array[Node]) -> Array[String]:
	var res: Array[String] = []
	for i in liste.size():
		for k in range(i + 1, liste.size()):
			var a: CSGBox3D = liste[i]
			var b: CSGBox3D = liste[k]
			if epoque(a) >= 0 and epoque(b) >= 0 and epoque(a) != epoque(b):
				continue
			var inter := boite(a).intersection(boite(b))
			if inter.size.x * inter.size.y * inter.size.z > 1e-6:
				res.append("%s / %s" % [a.get_path(), b.get_path()])
	return res


## Les boîtes solides qui n'existent qu'à cette époque, comme les voit
## `Temps.basculer`.
static func solides_de(racine: Node, ep: int) -> Array[AABB]:
	var res: Array[AABB] = []
	for m in tous(racine, func(x: Node) -> bool: return x is EpochMember and x.epoque == ep):
		res.append_array(m.aabbs_solides())
	return res
