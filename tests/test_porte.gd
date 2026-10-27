extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


func test_choisir_selon_le_regard() -> void:
	var vers_cible := Vector3(0, 0, -1)
	var a10 := Basis(Vector3.UP, deg_to_rad(10)) * vers_cible
	var a20 := Basis(Vector3.UP, deg_to_rad(20)) * vers_cible
	T.eq(PorteTrompeuse.choisir(a10, vers_cible, 15.0, 1, 0), 1, "à 10° : on regarde la photo")
	T.eq(PorteTrompeuse.choisir(a20, vers_cible, 15.0, 1, 0), 0, "à 20° : on ne la regarde pas")


func test_transfert_garde_la_position_relative() -> void:
	var entree := Transform3D(Basis(), Vector3(0, 0, 0))
	var sortie := Transform3D(Basis(Vector3.UP, PI), Vector3(20, 0, 5))
	var joueur := Transform3D(Basis(Vector3.UP, 0.3), Vector3(0, 0, 1))
	var res := PorteTrompeuse.transfert(entree, sortie, joueur)
	T.proche(res.origin, Vector3(20, 0, 4), "1 m devant la sortie, du même côté")
	T.proche(res.basis.get_euler().y, wrapf(PI + 0.3, -PI, PI), "même orientation relative")


func test_traverser_en_portant_un_objet() -> void:
	var monde := Node3D.new()
	tree.root.add_child(monde)
	_noeuds.append(monde)
	var porte: PorteTrompeuse = load("res://scenes/porte_trompeuse.tscn").instantiate()
	monde.add_child(porte)
	var photo := Marker3D.new()
	photo.position = Vector3(0, 1.6, -10)
	monde.add_child(photo)
	var ici := Marker3D.new()
	monde.add_child(ici)
	var ailleurs := Marker3D.new()
	ailleurs.position = Vector3(50, 0, 0)
	monde.add_child(ailleurs)
	porte.destinations = [porte.get_path_to(ici), porte.get_path_to(ailleurs)]
	porte.cible_regard = porte.get_path_to(photo)
	var joueur: Player = load("res://scenes/player.tscn").instantiate()
	monde.add_child(joueur)
	var objet := RigidBody3D.new()
	monde.add_child(objet)
	joueur.prendre(objet)
	joueur.global_position = Vector3(0, 0, 0.5)
	porte._corps_entre(joueur)
	T.proche(joueur.global_position, Vector3(50, 0, 0.5), "on regarde la photo : on arrive ailleurs")
	var cam: Camera3D = joueur.get_node("Head/Camera3D")
	T.proche(objet.global_position, cam.global_position - cam.global_basis.z * Player.HOLD_DIST, "l'objet a suivi")
