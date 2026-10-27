extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


func test_regarde() -> void:
	T.ok(PassageTemporel.regarde(Vector3.FORWARD, Vector3(0, 0, -5), 20.0), "droit sur la cible")
	T.ok(not PassageTemporel.regarde(Vector3.FORWARD, Vector3(5, 0, 0), 20.0), "cible sur le côté")


func _monde() -> Node3D:
	var monde := Node3D.new()
	tree.root.add_child(monde)
	_noeuds.append(monde)
	return monde


func test_franchi_seulement_en_regardant() -> void:
	var monde := _monde()
	var passage: PassageTemporel = load("res://scenes/passage_temporel.tscn").instantiate()
	monde.add_child(passage)
	var cible := Marker3D.new()
	cible.position = Vector3(0, 1.6, -10)
	monde.add_child(cible)
	passage.cible_regard = passage.get_path_to(cible)
	var recus := []
	passage.franchi.connect(func() -> void: recus.append(true))
	var joueur: Player = load("res://scenes/player.tscn").instantiate()
	monde.add_child(joueur)
	joueur.rotation.y = PI
	passage._corps_entre(joueur)
	T.eq(recus.size(), 0, "dos à la cible : rien")
	joueur.rotation.y = 0.0
	passage._corps_entre(joueur)
	T.eq(recus.size(), 1, "face à la cible : franchi")


func test_sans_cible_toujours_franchi() -> void:
	var monde := _monde()
	var passage: PassageTemporel = load("res://scenes/passage_temporel.tscn").instantiate()
	monde.add_child(passage)
	var recus := []
	passage.franchi.connect(func() -> void: recus.append(true))
	var objet := Node3D.new()
	passage._corps_entre(objet)
	objet.free()
	T.eq(recus.size(), 0, "un objet qui n'est pas le joueur : rien")
	var joueur: Player = load("res://scenes/player.tscn").instantiate()
	monde.add_child(joueur)
	passage._corps_entre(joueur)
	T.eq(recus.size(), 1, "le joueur passe")
