extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


func _ajouter(n: Node) -> Node:
	tree.root.add_child(n)
	_noeuds.append(n)
	return n


func test_touche_une_seule_fois() -> void:
	var c: Cartouche = _ajouter(load("res://scenes/cartouche.tscn").instantiate())
	c.zone = "carriere"
	var recus := []
	c.touche.connect(func(z: String) -> void: recus.append(z))
	var joueur: Player = _ajouter(load("res://scenes/player.tscn").instantiate())
	T.ok(not c.est_touche, "pas encore touché")
	c._corps_entre(joueur)
	c._corps_entre(joueur)
	T.eq(recus, ["carriere"], "un seul signal, avec sa zone")
	T.ok(c.est_touche, "touché")


func test_seul_le_joueur_le_touche() -> void:
	var c: Cartouche = _ajouter(load("res://scenes/cartouche.tscn").instantiate())
	var cube: Node3D = _ajouter(load("res://scenes/cube.tscn").instantiate())
	c._corps_entre(cube)
	T.ok(not c.est_touche, "un cube ne compte pas")


func test_s_eteint_une_fois_touche() -> void:
	var c: Cartouche = _ajouter(load("res://scenes/cartouche.tscn").instantiate())
	var visuel: Node3D = c.get_node("Visuel")
	c._process(1.0)
	var angle := visuel.rotation.y
	T.ok(angle != 0.0, "il tourne")
	c._corps_entre(_ajouter(load("res://scenes/player.tscn").instantiate()))
	c._process(1.0)
	T.proche(visuel.rotation.y, angle, "il ne tourne plus")
