extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func _joueur() -> Player:
	var j: Player = load("res://scenes/player.tscn").instantiate()
	tree.root.add_child(j)
	_noeuds.append(j)
	return j


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.queue_free()


func test_wish_direction_tout_droit() -> void:
	T.proche(Player.wish_direction(Vector2(0, -1), 0.0), Vector3(0, 0, -1), "avancer sans rotation")


func test_wish_direction_tourne() -> void:
	T.proche(Player.wish_direction(Vector2(0, -1), PI / 2), Vector3(-1, 0, 0), "avancer après un quart de tour")


func test_respawn_sous_kill_y() -> void:
	var j := _joueur()
	j.set_anchor(Transform3D(Basis(), Vector3(2, 1, 3)))
	j.global_position = Vector3(0, -25, 0)
	j._physics_process(0.016)
	T.proche(j.global_position, Vector3(2, 1, 3), "retour au point d'ancrage")
	T.proche(j.velocity, Vector3.ZERO, "vitesse remise à zéro")


func test_teleport_garde_objet_porte() -> void:
	var j := _joueur()
	var objet := RigidBody3D.new()
	tree.root.add_child(objet)
	_noeuds.append(objet)
	j.prendre(objet)
	j.teleport(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(10, 0, 10)))
	var cam: Camera3D = j.get_node("Head/Camera3D")
	var attendu := cam.global_position - cam.global_basis.z * Player.HOLD_DIST
	T.proche(objet.global_position, attendu, "l'objet reste à 1,5 m devant")
	T.eq(j.held, objet, "toujours porté")
