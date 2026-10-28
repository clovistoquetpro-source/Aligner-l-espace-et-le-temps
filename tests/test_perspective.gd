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


func _mur(z: float) -> StaticBody3D:
	var mur := StaticBody3D.new()
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(20, 20, 0.2)
	forme.shape = boite
	mur.add_child(forme)
	mur.position = Vector3(0, 0, z - 0.1)
	return _ajouter(mur)


func _cube(taille: float, pos: Vector3) -> ObjetPerspectif:
	var c: ObjetPerspectif = load("res://scenes/cube.tscn").instantiate()
	c.taille_depart = taille
	c.position = pos
	return _ajouter(c)


func _joueur() -> Player:
	var j: Player = load("res://scenes/player.tscn").instantiate()
	return _ajouter(j)


func test_taille_pour() -> void:
	T.proche(ObjetPerspectif.taille_pour(1.0 / 3.0, 6.0), 2.0, "1/3 à 6 m : 2 m")
	T.proche(ObjetPerspectif.taille_pour(1.0, 50.0), ObjetPerspectif.TAILLE_MAX, "plafond")
	T.proche(ObjetPerspectif.taille_pour(0.01, 1.0), ObjetPerspectif.TAILLE_MIN, "plancher")


func test_viser_loin_agrandit() -> void:
	_mur(-6.0)
	var j := _joueur()
	var cube := _cube(0.5, Vector3(0, 1.6, -1.5))
	await tree.physics_frame
	j.prendre(cube)
	await tree.physics_frame
	await tree.physics_frame
	var d := cube.global_position.distance_to(j.camera.global_position)
	T.ok(cube.taille > 1.4, "le cube grandit en visant un mur à 6 m (taille %.2f)" % cube.taille)
	T.proche(cube.taille / d, 0.5 / 1.5, "même taille à l'écran", 0.02)
	T.ok(cube.global_position.z - cube.taille / 2 >= -6.05, "il ne traverse pas le mur")


func test_viser_pres_rapetisse() -> void:
	_mur(-1.0)
	var j := _joueur()
	var cube := _cube(0.5, Vector3(0, 1.6, -0.75))
	await tree.physics_frame
	j.prendre(cube)
	await tree.physics_frame
	await tree.physics_frame
	T.ok(cube.taille < 0.5, "le cube rapetisse contre un mur proche (taille %.2f)" % cube.taille)


func test_poser_garde_la_taille() -> void:
	_mur(-6.0)
	var j := _joueur()
	var cube := _cube(0.5, Vector3(0, 1.6, -1.5))
	await tree.physics_frame
	j.prendre(cube)
	await tree.physics_frame
	var t := cube.taille
	j.poser()
	await tree.physics_frame
	T.proche(cube.taille, t, "la taille reste après l'avoir posé")
	T.ok(j.held == null, "plus porté")


func test_retour_au_depart_hors_zone() -> void:
	var cube := _cube(0.3, Vector3(1, 0.5, 1))
	cube.zone = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	await tree.physics_frame
	cube.taille = 2.0
	cube.global_position = Vector3(0, 0.5, -10)
	cube._physics_process(0.016)
	T.proche(cube.global_position, Vector3(1, 0.5, 1), "revient à sa place")
	T.proche(cube.taille, 0.3, "reprend sa taille")


func test_poisson_garde_ses_proportions() -> void:
	var p: ObjetPerspectif = _ajouter(load("res://scenes/poisson.tscn").instantiate())
	p.taille = 2.0
	var forme: CollisionShape3D = p.get_node("CollisionShape3D")
	T.proche((forme.shape as BoxShape3D).size, Vector3(2, 0.9, 0.6), "boîte du poisson agrandie")
	T.proche(p.get_node("Mesh").scale, Vector3.ONE * 2, "le dessin suit")
	T.ok(p.get_node("Mesh") is Node3D and not p.get_node("Mesh") is MeshInstance3D, "dessin fait de plusieurs formes")
