extends RefCounted

## Le niveau 3 en formes simples : l'été au lac. La journée en boucle, le
## tableau à finir au coucher du soleil, le pont qui n'existe que dans le
## reflet, le moment parfait et le vrai soir.

const O := preload("res://tests/outils_niveau.gd")
const Ete := preload("res://scripts/niveau/ete.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer", "sauter"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/ete.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


func _attendre(images: int, arret := Callable()) -> void:
	for i in images:
		await tree.physics_frame
		if arret.is_valid() and arret.call():
			return


func _placer(j: Player, pos: Vector3, rot_y: float) -> void:
	j.teleport(Transform3D(Basis(Vector3.UP, rot_y), pos))
	j.head.rotation.x = 0.0
	await tree.physics_frame


func _prendre_le_tableau(n: Node3D) -> RigidBody3D:
	var j: Player = n.get_node("Player")
	var t: RigidBody3D = n.get_node("Ponton/Tableau")
	j.prendre(t)
	return t


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	T.ok(n.get_node("Ponton/Tableau") is RigidBody3D, "le tableau sur le chevalet")
	T.ok(n.get_node("Lac/Eau") is Miroir, "le lac reflète")
	T.ok(n.get_node("Juliette/Mobylette/Juliette") != null, "Juliette, à mobylette")
	T.eq(n.journee, 1, "le premier jour")
	T.ok(not n.get_node("Pont/Reflet").visible, "le premier jour, le pont est vraiment cassé")
	T.proche(j.head.position.y, Ete.TETE_ADO, "à hauteur d'adolescent", 0.01)
	var tableau := j.get_node("../Ponton/Tableau") as RigidBody3D
	O.viser(j, tableau.global_position)
	j._interagir()
	T.ok(j.held == tableau, "on prend le tableau depuis le départ")


func test_le_soleil_descend_vers_l_ile() -> void:
	var haut := Ete.direction_soleil(0.0)
	var bas := Ete.direction_soleil(Ete.DUREE_JOUR)
	T.ok(haut.y > 0.5, "l'après-midi, le soleil est haut")
	T.ok(absf(bas.y) < 0.05, "le soir, il est sur l'horizon")
	T.ok(bas.z < -0.8, "au nord, derrière l'île")


func test_juliette_donne_rendez_vous_puis_va_sur_l_ile() -> void:
	var n: Node3D = await _charger()
	n.temps = Ete.PAROLES - 0.1
	await _attendre(10)
	T.ok(n._file.any(func(l: String) -> bool: return l.contains("au coucher du soleil")) \
		or n.get_node("Interface/Message").text.contains("il manque le ciel"), "elle donne rendez-vous")
	T.ok(not n.get_node("Juliette/Debout").visible, "pas encore sur l'île")
	n.temps = Ete.SUR_L_ILE + 0.1
	await _attendre(3)
	T.ok(n.get_node("Juliette/Debout").visible, "elle attend sur l'île")
	T.ok(not n.get_node("Juliette/Mobylette").visible, "la mobylette est partie")


func test_au_coucher_du_soleil_la_journee_recommence() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(16, 0.3, 6), 0.0)
	n.temps = Ete.DUREE_JOUR - 0.05
	await _attendre(int((Ete.DUREE_REPEINT * 2 + 0.3) * 60))
	T.eq(n.journee, 2, "le deuxième jour")
	T.ok(n.temps < 3.0, "le jour recommence (%.1f s)" % n.temps)
	T.ok(j.global_position.distance_to(Vector3(-8, 0.5, -3.6)) < 0.5, "au ponton (%s)" % j.global_position)
	T.ok(n.get_node("Pont/Reflet").visible, "le peintre a repeint le pont… dans le reflet")


func test_on_finit_le_tableau_au_coucher_face_au_soleil() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var t := _prendre_le_tableau(n)
	var soleil := j.camera.global_position + Ete.direction_soleil(Ete.COUCHER + 5.0) * 10.0
	O.viser(j, soleil)
	n.temps = 50.0
	await _attendre(5)
	T.ok(not n.tableau_fini, "l'après-midi, la lumière n'est pas la bonne")
	n.temps = Ete.COUCHER + 5.0
	O.viser(j, j.camera.global_position + Vector3(1, 0, 0))
	await _attendre(5)
	T.ok(not n.tableau_fini, "il faut regarder le soleil")
	O.viser(j, soleil)
	await _attendre(5)
	T.ok(n.tableau_fini, "au coucher, face au soleil, le ciel se peint")
	T.ok(t.get_node("Peinture/Ciel").visible, "le ciel est sur le tableau")


func test_le_tableau_tenu_passe_dans_la_journee_suivante() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var t := _prendre_le_tableau(n)
	n.finir_le_tableau()
	n.temps = Ete.DUREE_JOUR - 0.05
	await _attendre(int((Ete.DUREE_REPEINT * 2 + 0.3) * 60))
	T.eq(n.journee, 2, "le deuxième jour")
	T.ok(j.held == t, "le tableau est encore dans les mains")
	T.ok(n.tableau_fini, "et il est toujours fini")


func test_un_tableau_pose_revient_sur_le_chevalet() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var t := _prendre_le_tableau(n)
	n.finir_le_tableau()
	j.poser()
	await _attendre(5)
	n.temps = Ete.DUREE_JOUR - 0.05
	await _attendre(int((Ete.DUREE_REPEINT * 2 + 0.3) * 60))
	T.ok(not n.tableau_fini, "posé, il est repeint : le ciel est de nouveau blanc")
	T.proche(t.global_position, Vector3(-8, 1.42, -4.6), "sur le chevalet", 0.01)


func test_l_eau_trempe_le_tableau_et_ralentit() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	_prendre_le_tableau(n)
	await _placer(j, Vector3(0, -1.3, -12), 0.0)
	await _attendre(5)
	T.ok(n.tableau_mouille, "dans l'eau, le tableau est trempé")
	T.ok(j.facteur_vitesse < 0.6, "on nage lentement")
	await _placer(j, Vector3(16, 0.3, 6), 0.0)
	await _attendre(3)
	T.ok(j.facteur_vitesse > 0.99, "sur la rive, on marche")


func test_sur_l_ile_on_n_est_pas_dans_l_eau() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	_prendre_le_tableau(n)
	await _placer(j, Vector3(-1, 0.3, -27), 0.0)
	await _attendre(5)
	T.ok(not n.tableau_mouille, "l'île est au sec")


func _au_bout_du_pont(n: Node3D) -> Player:
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(4.0, 1.0, -6.5), 0.0)
	return j


func test_le_premier_jour_on_tombe_dans_le_trou() -> void:
	var n: Node3D = await _charger()
	var j := await _au_bout_du_pont(n)
	O.viser(j, Vector3(4.0, 0, -11))
	Input.action_press("avancer")
	await _attendre(150, func() -> bool: return j.global_position.y < 0.0)
	Input.action_release("avancer")
	T.ok(j.global_position.y < 0.0, "pas de planches : on tombe à l'eau (%s)" % j.global_position)


func test_le_pont_du_reflet_porte_si_on_regarde_l_eau() -> void:
	var n: Node3D = await _charger()
	n.journee = 2
	n._commencer_la_journee()
	var j := await _au_bout_du_pont(n)
	# On traverse en gardant les yeux sur le reflet des planches.
	Input.action_press("avancer")
	for i in 240:
		var cible := Vector3(4.0, 0, minf(j.global_position.z - 2.5, -8.5))
		O.viser(j, cible)
		await tree.physics_frame
		if j.global_position.z < -15.0:
			break
	Input.action_release("avancer")
	T.ok(j.global_position.z < -15.0 and j.global_position.y > 0.7, "de l'autre côté du trou, au sec (%s)" % j.global_position)


func test_lever_les_yeux_sur_le_pont_du_reflet_fait_tomber() -> void:
	var n: Node3D = await _charger()
	n.journee = 2
	n._commencer_la_journee()
	var j := await _au_bout_du_pont(n)
	Input.action_press("avancer")
	for i in 240:
		if j.global_position.z > -10.0:
			O.viser(j, Vector3(4.0, 0, j.global_position.z - 2.5))
		else:
			O.viser(j, j.camera.global_position + Vector3(0, 0, -10))
		await tree.physics_frame
		if j.global_position.y < 0.0:
			break
	Input.action_release("avancer")
	T.ok(j.global_position.y < 0.0, "en levant les yeux, on tombe à l'eau (%s)" % j.global_position)


func test_le_rendez_vous_trop_tot_trempe_ou_sans_ciel() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.temps = Ete.SUR_L_ILE + 1.0
	await _attendre(2)
	_prendre_le_tableau(n)
	await _placer(j, Vector3(-1, 0.3, -27.5), PI)
	await _attendre(3)
	T.ok(n._dit.has("pas_fini"), "« Il manque toujours le ciel… »")
	n.finir_le_tableau()
	await _attendre(3)
	T.ok(n._dit.has("trop_tot"), "« Le soleil n'est pas encore couché. »")
	T.eq(n.etat, Ete.Etat.JOURNEE, "pas encore le moment")
	n.tableau_mouille = true
	n.temps = Ete.COUCHER + 1.0
	await _attendre(3)
	T.ok(n._dit.has("mouille"), "trempé : « Tu es venu à la nage ?! »")
	T.eq(n.etat, Ete.Etat.JOURNEE, "le peintre refuse")


func test_le_moment_parfait_puis_le_vrai_soir_puis_la_maison() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.temps = Ete.COUCHER + 1.0
	await _attendre(2)
	_prendre_le_tableau(n)
	n.finir_le_tableau()
	await _placer(j, Vector3(-1, 0.3, -27.5), PI)
	await _attendre(3)
	T.eq(n.etat, Ete.Etat.PARFAIT, "le moment parfait")
	T.eq(Histoire.corrections, 1, "c'est une correction du peintre")
	T.ok(n.get_node("Ile/Fleurs").visible, "des fleurs partout")
	await _attendre(int(18.0 * 60), func() -> bool: return n.etat == Ete.Etat.VRAI)
	T.eq(n.etat, Ete.Etat.VRAI, "puis le vrai soir")
	T.ok(n.get_node("Nuit").visible, "la nuit")
	T.ok(j.global_position.y < 0.0, "Thomas est dans l'eau (%s)" % j.global_position)
	await _placer(j, Vector3(-3, 0.3, -21.0), PI)
	await _attendre(3)
	T.eq(n.etat, Ete.Etat.FIN, "il rejoint Juliette")
	await _attendre(int((9.0 + ChuteToiles.DUREE + 0.5) * 60), func() -> bool: return Histoire.scene_demandee != "")
	T.eq(Histoire.scene_demandee, "res://scenes/illusions.tscn", "retour dans la maison des étoiles")
	T.eq(Histoire.chapitre, 4, "le niveau 3 est fini")


func test_la_mobylette_suit_la_journee_meme_si_on_saute_dans_le_temps() -> void:
	var n: Node3D = await _charger()
	var mob: Node3D = n.get_node("Juliette/Mobylette")
	n.temps = Ete.PAROLES
	await _attendre(2)
	T.ok(mob.global_position.distance_to(Vector3(-6.5, 0.32, 2.0)) < 0.3, "près du ponton pendant qu'elle parle (%s)" % mob.global_position)
	n.temps = Ete.DEPART + 7.9
	await _attendre(2)
	T.ok(mob.global_position.x > 30.0, "repartie vers l'est (%s)" % mob.global_position)
