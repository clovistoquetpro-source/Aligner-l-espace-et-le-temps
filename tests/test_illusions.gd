extends RefCounted

## Le prototype gris du musée des illusions : le couloir sans fin, la porte
## qui apparaît dans le dos, la salle du miroir et la chute dans les toiles.

const O := preload("res://tests/outils_niveau.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()


func _charger() -> Node3D:
	_niveau = load("res://scenes/illusions.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


func _marcher(action: String, images: int, arret := Callable()) -> void:
	Input.action_press(action)
	for i in images:
		await tree.physics_frame
		if arret.is_valid() and arret.call():
			break
	Input.action_release(action)


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Miroir).size(), 1, "un miroir")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is PassageReflet).size(), 1, "un passage dans le reflet")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is ChuteToiles).size(), 1, "la chute dans les toiles")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is BasculeFx).size(), 0, "pas de bascule d'époque")
	T.ok(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/illusions.tscn", "F5 lance le prototype")


func test_le_couloir_ne_mene_nulle_part() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	j.teleport(Transform3D(Basis(), Vector3(0, 0, -6)))
	await tree.physics_frame
	var plus_loin := 0.0
	Input.action_press("avancer")
	for i in 600:
		await tree.physics_frame
		plus_loin = minf(plus_loin, j.global_position.z)
	Input.action_release("avancer")
	T.ok(n.tours >= 2, "le couloir a ramené le joueur en arrière (%d fois)" % n.tours)
	T.ok(plus_loin > -34.0, "jamais au-delà du 8e tronçon (%.1f)" % plus_loin)
	T.ok(n.angoisse > 0.5, "l'angoisse monte (%.2f)" % n.angoisse)
	T.ok(j.camera.fov > 85.0, "le couloir s'étire (fov %.1f)" % j.camera.fov)
	await _marcher("reculer", 600, func() -> bool: return j.global_position.z > -2.0)
	T.ok(j.global_position.z > -2.0, "demi-tour : on revient au hall")


func test_la_porte_du_miroir_apparait_dans_le_dos() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var porte: CSGBox3D = n.get_node("Hall/PorteMiroir")
	j.teleport(Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(1, 0, 0)))
	await tree.physics_frame
	await tree.physics_frame
	T.ok(not n.porte_ouverte, "murée tant qu'on n'est pas allé dans le couloir")
	n.tours = 1
	await tree.physics_frame
	T.ok(not n.porte_ouverte and porte.use_collision, "rien ne change sous nos yeux")
	j.teleport(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(1, 0, 0)))
	await tree.physics_frame
	await tree.physics_frame
	T.ok(n.porte_ouverte, "elle s'ouvre quand on a le dos tourné")
	T.ok(not porte.visible and not porte.use_collision, "le mur a disparu")


func test_foncer_vers_le_mur_ne_suffit_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var chute: ChuteToiles = n.get_node("Interface/ChuteToiles")
	j.teleport(Transform3D(Basis(Vector3.UP, PI), Vector3(11.3, 0, 1.0)))
	await _marcher("avancer", 120)
	T.ok(not chute.en_cours(), "en regardant le mur, on se cogne")
	T.ok(j.global_position.z < 4.0, "le mur est solide (z %.2f)" % j.global_position.z)


func test_reculer_les_yeux_sur_le_miroir_fait_tomber_dans_les_toiles() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var chute: ChuteToiles = n.get_node("Interface/ChuteToiles")
	j.teleport(Transform3D(Basis(), Vector3(11.3, 0, 1.0)))
	await _marcher("reculer", 120, chute.en_cours)
	T.ok(chute.en_cours(), "la chute commence")
	for i in int((ChuteToiles.DUREE + 0.5) * 60):
		await tree.physics_frame
		if not chute.en_cours():
			break
	await tree.physics_frame
	T.ok(not chute.en_cours(), "la chute est finie")
	T.ok(j.global_position.distance_to(Vector3(0, 0, 61.5)) < 2.0, "on atterrit dans la suite (%s)" % j.global_position)
	T.ok(j.is_physics_processing(), "on peut de nouveau bouger")
