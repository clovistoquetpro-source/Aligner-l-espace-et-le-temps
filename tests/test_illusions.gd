extends RefCounted

## Le niveau 1 en formes simples : le réveil, le couloir de la porte
## d'entrée, la porte qui apparaît dans le dos, la salle de bain et son
## miroir, la chute dans les toiles, la galerie, la toile tournante et la fin.

const O := preload("res://tests/outils_niveau.gd")
const Illusions := preload("res://scripts/niveau/illusions.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/illusions.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


func _attendre(images: int, arret := Callable()) -> void:
	for i in images:
		await tree.physics_frame
		if arret.is_valid() and arret.call():
			return


func _marcher(action: String, images: int, arret := Callable()) -> void:
	Input.action_press(action)
	await _attendre(images, arret)
	Input.action_release(action)


func _placer(j: Player, pos: Vector3, rot_y: float) -> void:
	j.teleport(Transform3D(Basis(Vector3.UP, rot_y), pos))
	j.head.rotation.x = 0.0
	await tree.physics_frame


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Miroir).size(), 1, "un miroir")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is PassageReflet).size(), 1, "un passage dans le reflet")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is ChuteToiles).size(), 1, "la chute dans les toiles")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is ToileTournante).size(), 1, "une toile tournante")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is ObjetPerspectif).size(), 1, "le cube")
	T.ok(O.tous(n, func(x: Node) -> bool: return x is Pensee).size() >= 12, "des pensées partout")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is BasculeFx).size(), 0, "pas de bascule d'époque")
	T.ok(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/illusions.tscn", "F5 lance ce niveau")


func test_murs_et_sols_ne_se_superposent_pas() -> void:
	var n: Node3D = await _charger()
	var boites := O.boites(n, ["Mur", "Sol", "Plafond", "Balcon", "PorteSdb"]).filter(func(b: Node) -> bool: return b.name != "MurReflet")
	# Deux boîtes qui se touchent tout juste (à 1 mm près) ne comptent pas.
	var res: Array[String] = []
	for i in boites.size():
		for k in range(i + 1, boites.size()):
			var inter := O.boite(boites[i]).intersection(O.boite(boites[k]))
			if minf(inter.size.x, minf(inter.size.y, inter.size.z)) > 0.001:
				res.append("%s / %s" % [boites[i].name, boites[k].name])
	T.ok(res.is_empty(), "chevauchements : %s" % ", ".join(res))


func test_on_se_reveille_dans_la_chambre() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var noir: ColorRect = n.get_node("Interface/Noir")
	T.ok(j.global_position.distance_to(Vector3(-1.2, 0, 7.6)) < 0.5, "dans la chambre")
	T.ok(noir.color.a > 0.9, "les yeux fermés")
	await _attendre(int((0.5 + Illusions.DUREE_REVEIL + 0.5) * 60))
	T.ok(noir.color.a < 0.05, "les yeux ouverts")
	T.ok(n.get_node("Interface/Message").text.contains("drôle de rêve"), "première pensée")


func test_la_porte_d_entree_recule_et_le_couloir_ne_mene_nulle_part() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var porte: Node3D = n.get_node("Couloir/PorteEntree")
	await _placer(j, Vector3(0, 0, -6), 0.0)
	var plus_loin := 0.0
	var ecart_max := 0.0
	Input.action_press("avancer")
	for i in 600:
		await tree.physics_frame
		plus_loin = minf(plus_loin, j.global_position.z)
		if j.global_position.z < -6.0:
			ecart_max = maxf(ecart_max, absf(j.global_position.z - porte.global_position.z - Illusions.RECUL_PORTE))
	Input.action_release("avancer")
	T.ok(n.tours >= 2, "le couloir a ramené le joueur en arrière (%d fois)" % n.tours)
	T.ok(plus_loin > -34.0, "jamais au-delà du 8e tronçon (%.1f)" % plus_loin)
	T.ok(ecart_max < 0.5, "la porte reste à %d m (écart %.2f)" % [Illusions.RECUL_PORTE, ecart_max])
	T.ok(n.angoisse > 0.5, "l'angoisse monte (%.2f)" % n.angoisse)
	T.ok(j.camera.fov > 85.0, "le couloir s'étire (fov %.1f)" % j.camera.fov)
	T.ok(n._pensees_couloir >= 1, "« Elle ne se rapproche pas… »")
	await _marcher("reculer", 600, func() -> bool: return j.global_position.z > -2.0)
	T.ok(j.global_position.z > -2.0, "demi-tour : on revient dans l'entrée")


func test_la_porte_de_la_salle_de_bain_apparait_dans_le_dos() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var porte: CSGBox3D = n.get_node("Salon/PorteSdb")
	await _placer(j, Vector3(8, 0, 0), -PI / 2)
	await tree.physics_frame
	T.ok(not n.porte_ouverte, "murée tant qu'on n'est pas allé dans le couloir")
	n.tours = 1
	await tree.physics_frame
	T.ok(not n.porte_ouverte and porte.use_collision, "rien ne change sous nos yeux")
	await _placer(j, Vector3(8, 0, 0), PI / 2)
	await tree.physics_frame
	T.ok(n.porte_ouverte, "elle s'ouvre quand on a le dos tourné")
	T.ok(not porte.visible and not porte.use_collision, "le mur a disparu")
	T.ok(n.get_node("Salon/PenseePorte").active, "« Cette porte… elle n'était pas là. »")


func test_foncer_vers_le_mur_ne_suffit_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var chute: ChuteToiles = n.get_node("Interface/ChuteToiles")
	await _placer(j, Vector3(16.8, 0, 0.5), PI)
	await _marcher("avancer", 120)
	T.ok(not chute.en_cours(), "en regardant le mur, on se cogne")
	T.ok(j.global_position.z < 2.9, "le mur est solide (z %.2f)" % j.global_position.z)


func test_reculer_les_yeux_sur_le_miroir_mene_a_la_galerie() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var chute: ChuteToiles = n.get_node("Interface/ChuteToiles")
	await _placer(j, Vector3(16.8, 0, 0.5), 0.0)
	await _marcher("reculer", 120, chute.en_cours)
	T.ok(chute.en_cours(), "la chute commence")
	await _attendre(int((ChuteToiles.DUREE + 0.5) * 60), func() -> bool: return not chute.en_cours())
	await tree.physics_frame
	T.ok(not chute.en_cours(), "la chute est finie")
	T.ok(j.global_position.distance_to(Vector3(0, 0, 86)) < 1.5, "on atterrit dans la galerie (%s)" % j.global_position)
	T.ok(j.is_physics_processing(), "on peut de nouveau bouger")


func test_tourner_la_toile_fait_tourner_la_chambre_peinte() -> void:
	var n: Node3D = await _charger()
	var toile: ToileTournante = n.get_node("Galerie/ToileTournante")
	var piece: Node3D = n.get_node("ToilePeinte/Chambre")
	var cube: ObjetPerspectif = n.get_node("ToilePeinte/Chambre/Cube")
	T.ok(cube.global_position.y > 5.0, "le cube est en haut de l'étagère (%.2f)" % cube.global_position.y)
	toile.activer()
	toile.activer()
	T.eq(toile.quarts, 1, "pas de second quart de tour pendant le premier")
	await _attendre(int((ToileTournante.DUREE + 0.2) * 60))
	T.proche(piece.rotation.z, -PI / 2, "un quart de tour")
	T.ok(cube.global_position.y < 1.0, "le mur est devenu le sol : le cube est en bas (%.2f)" % cube.global_position.y)


func test_entrer_dans_la_toile_et_en_ressortir() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(6.0, 0, 80), -PI / 2)
	await _marcher("avancer", 120, func() -> bool: return j.global_position.x > 30.0)
	T.ok(j.global_position.distance_to(Vector3(40, 0, 81.5)) < 1.0, "dans la chambre d'enfant (%s)" % j.global_position)
	await _attendre(30)
	await _marcher("reculer", 120, func() -> bool: return j.global_position.x < 30.0)
	T.ok(j.global_position.x < 8.0 and absf(j.global_position.z - 80.0) < 1.5, "de retour dans la galerie (%s)" % j.global_position)


func test_le_cube_n_est_a_portee_que_si_la_chambre_a_tourne() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var cube: ObjetPerspectif = n.get_node("ToilePeinte/Chambre/Cube")
	for x in [40.0, 41.5, 42.2]:
		await _placer(j, Vector3(x, 0, 80), -PI / 2)
		O.viser(j, cube.global_position)
		j._interagir()
		T.ok(j.held == null, "hors de portée depuis x = %.1f" % x)
		j.poser()
	n.get_node("Galerie/ToileTournante").activer()
	await _attendre(int((ToileTournante.DUREE + 0.2) * 60))
	await _placer(j, Vector3(40.5, 0, 80), -PI / 2)
	O.viser(j, cube.global_position + Vector3(0, 0.2, 0))
	j._interagir()
	T.ok(j.held == cube, "à portée une fois la chambre tournée")
	await tree.physics_frame
	T.ok(cube.get_parent() == n, "le cube ne tourne plus avec la chambre")


func test_la_porte_d_entree_ramene_dans_la_chambre() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(1.0, 4.05, 73.3), 0.0)
	await _marcher("avancer", 60, func() -> bool: return n.fini)
	T.ok(n.fini, "on passe la porte")
	T.ok(j.global_position.distance_to(Vector3(-1.2, 0, 7.6)) < 2.0, "de retour dans la chambre (%s)" % j.global_position)
	T.ok(n.get_node("Chambre/Toile_lit_fin").visible and not n.get_node("Chambre/Toile_lit").visible, "la toile au-dessus du lit a changé")


func test_les_pensees_viennent_du_regard() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var pensee: Pensee = n.get_node("Salon/PenseeJardin")
	T.ok(not n._visible(Vector3(3.5, 1.6, -2.0), pensee.global_position), "le mur de l'entrée cache la toile")
	await _placer(j, Vector3(6.5, 0, -1.0), PI / 2)
	O.viser(j, Vector3(3.0, 1.6, -1.0))
	await tree.physics_frame
	T.ok(not pensee.dite, "pas en regardant à côté")
	O.viser(j, pensee.global_position)
	await tree.physics_frame
	await tree.physics_frame
	T.ok(pensee.dite, "en regardant la toile")
	T.ok(n._file.has(pensee.texte) or n.get_node("Interface/Message").text.contains("jardin"), "la pensée s'affiche")


func test_le_vide_du_balcon_ne_se_saute_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(-7.6, 4.05, 73.0), -PI / 2)
	Input.action_press("avancer")
	await _attendre(40, func() -> bool: return j.global_position.x > -6.7)
	Input.action_press("sauter")
	await _attendre(90)
	Input.action_release("sauter")
	Input.action_release("avancer")
	T.ok(j.global_position.y < 2.0, "on tombe dans le vide (%s)" % j.global_position)


func test_un_grand_cube_fait_un_pont_jusqu_au_balcon() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var cube: ObjetPerspectif = n.get_node("ToilePeinte/Chambre/Cube")
	n.get_node("Galerie/ToileTournante").activer()
	await _attendre(int((ToileTournante.DUREE + 0.2) * 60))
	# On prend le cube de près, puis on le vise loin, à mi-hauteur du vide.
	await _placer(j, Vector3(41.6, 0, 80), -PI / 2)
	O.viser(j, cube.global_position + Vector3(0, 0.2, 0))
	j._interagir()
	T.ok(j.held == cube, "le cube est pris")
	await _placer(j, Vector3(-3.75, 0, 87), 0.0)
	O.viser(j, Vector3(-3.75, 2.2, 72.1))
	await _attendre(3)
	T.ok(cube.taille >= 3.2, "visé loin, il grandit (%.2f m)" % cube.taille)
	j.poser()
	await _attendre(90)
	var haut := cube.global_position.y + cube.taille / 2
	T.ok(haut > 3.1 and haut < 4.2, "posé dans le vide, son dessus est presque au niveau du balcon (%.2f)" % haut)
	# Du palier, on marche sur le cube, puis on saute sur le balcon.
	await _placer(j, Vector3(-7.6, 4.05, 73.0), -PI / 2)
	Input.action_press("avancer")
	await _attendre(150, func() -> bool: return j.global_position.x > cube.global_position.x + cube.taille / 2 - 0.5)
	Input.action_press("sauter")
	await _attendre(60, func() -> bool: return n.fini or (j.global_position.x > -0.5 and j.is_on_floor()))
	Input.action_release("sauter")
	Input.action_release("avancer")
	await _attendre(5)
	T.ok(n.fini or (j.global_position.y > 3.9 and j.global_position.x > -1.0), "sur le balcon, jusqu'à la porte (%s)" % j.global_position)


func test_apres_la_fin_la_toile_de_l_enfant_mene_au_niveau_2() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var toile: Node3D = n.get_node("Salon/Toile_enfant")
	await _placer(j, Vector3(10.4, 0, -2.0), 0.0)
	O.viser(j, toile.global_position)
	await _attendre(10)
	T.ok(not n.get_node("Interface/ChuteToiles").en_cours(), "avant la fin du niveau 1, ce n'est qu'une toile")
	n.fini = true
	n.ouvrir_la_toile_de_l_enfant()
	await _attendre(5)
	T.ok(n.get_node("Interface/ChuteToiles").en_cours(), "on tombe dans la toile")
	await _attendre(int((ChuteToiles.DUREE + 0.5) * 60), func() -> bool: return Histoire.scene_demandee != "")
	T.eq(Histoire.scene_demandee, "res://scenes/enfance.tscn", "vers l'enfance")
	T.eq(Histoire.chapitre, 2, "niveau 2")


func test_au_retour_de_l_enfance_la_maison_s_abime() -> void:
	Histoire.chapitre = 3
	Histoire.corrections = 1
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	T.ok(j.global_position.distance_to(Vector3(10.4, 0, -1.2)) < 0.5, "au salon (%s)" % j.global_position)
	T.ok(not n.get_node("Salon/Mur_nord").visible, "le mur du salon s'est envolé")
	T.ok(n.get_node("Salon/Canape").position.y > 1.5, "les meubles flottent")
	T.ok(n.porte_ouverte and n.fini, "le niveau 1 est fait")
	await _marcher("avancer", 90)
	T.ok(j.global_position.z > -4.0, "on ne tombe pas dans le vide (%s)" % j.global_position)
