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


func _poisson(taille: float, pos: Vector3) -> ObjetPerspectif:
	var p: ObjetPerspectif = load("res://scenes/poisson.tscn").instantiate()
	p.taille_depart = taille
	p.position = pos
	p.freeze = true
	return _ajouter(p)


## Un spinosaure endormi à l'origine, une zone d'appât en (0, 0, 4) et le
## point où il se recouche en (6, 0, 8).
func _monde() -> Spinosaure:
	var monde: Node3D = _ajouter(Node3D.new())
	var zone := Area3D.new()
	zone.name = "ZoneAppat"
	zone.position = Vector3(0, 0, 4)
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(3, 3, 3)
	forme.shape = boite
	zone.add_child(forme)
	monde.add_child(zone)
	var repas := Marker3D.new()
	repas.name = "Repas"
	repas.position = Vector3(6, 0, 8)
	monde.add_child(repas)
	var dino := Spinosaure.new()
	dino.zone_appat = NodePath("../ZoneAppat")
	dino.arrivee = NodePath("../Repas")
	dino.duree_marche = 0.05
	monde.add_child(dino)
	return dino


func _attendre(images: int) -> void:
	for i in images:
		await tree.physics_frame


func test_appat_valable() -> void:
	var cube: ObjetPerspectif = load("res://scenes/cube.tscn").instantiate()
	_ajouter(cube)
	cube.taille = 2.0
	T.ok(Spinosaure.appat_valable(cube, 1.5), "gros cube posé")
	cube.taille = 1.0
	T.ok(not Spinosaure.appat_valable(cube, 1.5), "trop petit")
	cube.taille = 2.0
	cube.porte = true
	T.ok(not Spinosaure.appat_valable(cube, 1.5), "encore dans la main du joueur")
	var rien: Node3D = _ajouter(Node3D.new())
	T.ok(not Spinosaure.appat_valable(rien, 1.5), "pas un objet perspectif")


func test_petit_poisson_renifle() -> void:
	var dino := _monde()
	var fois := [0]
	dino.renifle.connect(func() -> void: fois[0] += 1)
	_poisson(0.5, Vector3(0, 0.5, 4))
	await _attendre(4)
	T.eq(fois[0], 1, "il renifle une fois")
	T.eq(dino.etat, Spinosaure.Etat.DORT, "il se rendort")


func test_poisson_tenu_ne_reveille_pas() -> void:
	var dino := _monde()
	var p := _poisson(2.0, Vector3(0, 0.5, 4))
	p.porte = true
	await _attendre(4)
	T.eq(dino.etat, Spinosaure.Etat.DORT, "il dort tant qu'on tient le poisson")
	p.porte = false
	await _attendre(4)
	T.ok(dino.etat != Spinosaure.Etat.DORT, "posé : il se réveille")


func test_gros_poisson_reveille() -> void:
	var dino := _monde()
	var fois := [0]
	var p := _poisson(2.0, Vector3(0, 0.5, 4))
	var couche := [-1]
	dino.reveille.connect(func() -> void:
		fois[0] += 1
		couche[0] = p.collision_layer)
	await _attendre(4)
	T.eq(fois[0], 1, "il se réveille")
	T.eq(couche[0], 0, "on ne peut plus reprendre le poisson")
	await _attendre(30)
	T.eq(dino.etat, Spinosaure.Etat.REPU, "repu")
	T.proche(dino.global_position, Vector3(6, 0, 8), "couché plus loin")
	T.ok(not is_instance_valid(p) or p.is_queued_for_deletion(), "poisson mangé")
