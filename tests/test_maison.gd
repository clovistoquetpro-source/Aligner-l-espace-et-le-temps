extends RefCounted

const TempsScript := preload("res://scripts/time/temps.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()


func _charger() -> Node3D:
	_niveau = load("res://scenes/maison.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


func _tous(racine: Node, filtre: Callable) -> Array[Node]:
	var res: Array[Node] = []
	for n in racine.find_children("*", "", true, false):
		if filtre.call(n):
			res.append(n)
	return res


## Tourne le joueur pour que sa caméra vise ce point.
func _viser(j: Player, cible: Vector3) -> void:
	var d := cible - j.camera.global_position
	j.rotation.y = atan2(-d.x, -d.z)
	j.head.rotation.x = asin(d.normalized().y)


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.eq(_tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.ok(_tous(n, func(x: Node) -> bool: return x is PorteTrompeuse).size() >= 1, "une porte trompeuse")
	T.eq(_tous(n, func(x: Node) -> bool: return x is Alignement).size(), 1, "une énigme d'alignement")
	for e in [TempsScript.Epoque.PRESENT, TempsScript.Epoque.PASSE]:
		T.ok(_tous(n, func(x: Node) -> bool: return x is EpochMember and x.epoque == e).size() >= 1, "membres de l'époque %d" % e)


func test_parcours_complet() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var porte: PorteTrompeuse = n.get_node("Couloir/PorteTrompeuse")
	var bonne: Node3D = n.get_node("Couloir/PhotoBonne")
	var mauvaise: Node3D = n.get_node("Couloir/PhotoRouge")

	# Sans regarder la bonne photo, le couloir boucle.
	j.teleport(Transform3D(Basis(), porte.global_position + Vector3(0, 0, 0.3)))
	_viser(j, mauvaise.global_position)
	j.set_meta("arrivee_ms", -100000)
	porte._corps_entre(j)
	T.ok(j.global_position.z > -4.0 and absf(j.global_position.x) < 2.0, "retour au début du couloir")

	# En regardant la bonne photo, on arrive au salon.
	j.teleport(Transform3D(Basis(), porte.global_position + Vector3(0, 0, 0.3)))
	_viser(j, bonne.global_position)
	j.set_meta("arrivee_ms", -100000)
	porte._corps_entre(j)
	T.ok(j.global_position.x > 25.0 and j.global_position.z > -10.0, "arrivé au salon")

	# Au présent, le mur du salon est solide ; dans le passé, il a une arche.
	var mur: CSGShape3D = n.get_node("Salon/MurPresent")
	T.ok(mur.use_collision, "mur solide au présent")
	T.ok(Temps.basculer(j), "bascule vers le passé")
	T.ok(not mur.use_collision, "mur absent dans le passé")

	# L'énigme d'alignement ouvre la sortie.
	var enigme: Alignement = n.get_node("Atelier/Horloge")
	var vue: Node3D = enigme.get_node(enigme.point_de_vue)
	j.teleport(Transform3D(Basis(), vue.global_position - Vector3(0, 1.6, 0)))
	j.rotation.y = 0.0
	j.head.rotation.x = 0.0
	await tree.physics_frame
	enigme.verifier(j.camera)
	T.ok(enigme.est_resolu, "horloge réalignée")
	var sortie: CSGShape3D = n.get_node("Atelier/PorteSortie")
	T.ok(not sortie.visible and not sortie.use_collision, "la sortie est ouverte")
