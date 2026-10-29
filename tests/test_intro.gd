extends RefCounted

## La cinématique du début : la maison sur Terre, le peintre de dos, la
## maison qui s'arrache du sol, les étoiles et le titre ; on peut la passer.

const Intro := preload("res://scripts/niveau/intro.gd")

var tree: SceneTree
var _scene: Node3D


func nettoyer() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(_scene):
		_scene.free()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_scene = load("res://scenes/intro.tscn").instantiate()
	tree.root.add_child(_scene)
	await tree.process_frame
	return _scene


func test_on_peut_la_passer() -> void:
	var n := await _charger()
	n.passer()
	T.eq(Histoire.scene_demandee, Intro.SUITE, "on passe au niveau 1")


func test_la_cinematique_jusqu_au_titre() -> void:
	var n := await _charger()
	T.eq(n.plan, "maison", "d'abord, la maison sur Terre")
	var plans := ["maison"]
	var titre_vu := false
	var de_dos := true
	# La cinématique dure environ 45 s : on l'accélère (au plus 20 s réelles).
	Engine.time_scale = 8.0
	var debut := Time.get_ticks_msec()
	while Time.get_ticks_msec() - debut < 20000:
		await tree.process_frame
		if plans[-1] != n.plan:
			plans.append(n.plan)
		if n.plan == "atelier":
			# La caméra reste derrière le peintre : on ne voit pas son visage.
			var peintre: Node3D = n.get_node("Atelier/Peintre")
			var vers_camera: Vector3 = n.get_node("Camera").global_position - peintre.global_position
			de_dos = de_dos and vers_camera.dot(peintre.global_basis.z) > 0.0
		titre_vu = titre_vu or (n.get_node("Interface/Titre") as Label).modulate.a > 0.9
		if n.fini:
			break
	Engine.time_scale = 1.0
	T.eq(plans, ["maison", "atelier", "envol", "etoiles"], "les quatre plans")
	T.ok(de_dos, "le peintre, toujours de dos")
	T.ok((n.get_node("Atelier/Toile/Nuit") as Node3D).visible, "il a peint la maison dans les étoiles")
	T.ok((n.get_node("Terre/Maison") as Node3D).position.y > 30.0, "la maison est partie dans les étoiles")
	T.ok(titre_vu, "le titre")
	T.eq(Histoire.scene_demandee, Intro.SUITE, "puis le niveau 1")
