extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


func test_aligne_pur() -> void:
	var vue := Vector3(0, 1.6, 5)
	var dir := Vector3(0, 0, -1)
	var a3 := Basis(Vector3.UP, deg_to_rad(3)) * dir
	var a10 := Basis(Vector3.UP, deg_to_rad(10)) * dir
	T.ok(Alignement.aligne(vue + Vector3(0.3, 0, 0), a3, vue, dir, 0.6, 6.0), "0,3 m et 3° : aligné")
	T.ok(not Alignement.aligne(vue + Vector3(1, 0, 0), dir, vue, dir, 0.6, 6.0), "1 m : trop loin")
	T.ok(not Alignement.aligne(vue, a10, vue, dir, 0.6, 6.0), "10° : mauvais angle")
	T.ok(not Alignement.aligne(vue, -dir, vue, dir, 0.6, 6.0), "de dos : non")


## Monde de test : énigme à l'origine, point de vue à 5 m, caméra posée dessus.
func _monde(avec_mur: bool) -> Array:
	var monde := Node3D.new()
	tree.root.add_child(monde)
	_noeuds.append(monde)
	var enigme := Alignement.new()
	monde.add_child(enigme)
	enigme.set_physics_process(false)
	var vue := Marker3D.new()
	vue.position = Vector3(0, 0, 5)
	monde.add_child(vue)
	enigme.point_de_vue = enigme.get_path_to(vue)
	if avec_mur:
		var mur := StaticBody3D.new()
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = Vector3(4, 4, 0.2)
		forme.shape = boite
		mur.add_child(forme)
		mur.position = Vector3(0, 0, 2.5)
		monde.add_child(mur)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 5)
	monde.add_child(cam)
	await tree.physics_frame
	await tree.physics_frame
	return [enigme, cam]


func test_resolu_une_seule_fois() -> void:
	var r: Array = await _monde(false)
	var enigme: Alignement = r[0]
	var fois := [0]
	enigme.resolu.connect(func() -> void: fois[0] += 1)
	enigme.verifier(r[1])
	enigme.verifier(r[1])
	T.ok(enigme.est_resolu, "énigme résolue")
	T.eq(fois[0], 1, "signal resolu une seule fois")


func test_pas_a_travers_un_mur() -> void:
	var r: Array = await _monde(true)
	var enigme: Alignement = r[0]
	enigme.verifier(r[1])
	T.ok(not enigme.est_resolu, "un mur cache les morceaux : pas résolu")
