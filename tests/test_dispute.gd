extends RefCounted

## Le niveau 4 en formes simples : la dispute à l'atelier (le temps à
## rebours), la course-poursuite, la chute et la vérité.

const O := preload("res://tests/outils_niveau.gd")
const Dispute := preload("res://scripts/niveau/dispute.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer", "gauche", "droite", "sauter", "rembobiner"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/dispute.tscn").instantiate()
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


## Remonte le temps jusqu'à l'instant `t` (R maintenu).
func _remonter_jusqu_a(n: Node3D, t: float) -> void:
	Input.action_press("rembobiner")
	await _attendre(3000, func() -> bool: return n.moment <= t)
	Input.action_release("rembobiner")


func test_ligne_du_temps_interpolee() -> void:
	var cles := [[0.0, Vector3.ZERO, Vector3.ZERO, true], [10.0, Vector3(10, 0, 0), Vector3.ZERO, true], [11.0, Vector3(10, 0, 0), Vector3.ZERO, false]]
	T.proche(ObjetTemporel.etat(cles, 5.0)[0], Vector3(5, 0, 0), "à mi-chemin")
	T.ok(ObjetTemporel.etat(cles, 10.5)[2], "encore visible")
	T.ok(not ObjetTemporel.etat(cles, 12.0)[2], "puis caché")
	T.proche(ObjetTemporel.etat(cles, -3.0)[0], Vector3.ZERO, "avant le début")
	T.eq(Dispute.a_l_envers("Va-t'en !"), "! ne't-aV", "les phrases à l'envers")


func test_la_pluie_suit_le_temps() -> void:
	var h := Pluie.hauteur(0.3, 2.0, 9.0, 9.0)
	T.proche(Pluie.hauteur(0.3, 2.0, 9.0, 9.0), h, "même temps, même goutte")
	T.ok(Pluie.hauteur(0.3, 2.1, 9.0, 9.0) < h, "le temps avance : elle descend")
	T.ok(Pluie.hauteur(0.3, 1.9, 9.0, 9.0) > h, "le temps recule : elle remonte")


func test_on_arrive_a_la_fin_du_souvenir_fige() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	T.proche(n.moment, Dispute.DUREE, "à la fin de la dispute")
	T.ok(j.global_position.y > 2.5, "sur la mezzanine (%s)" % j.global_position)
	var pluie: Pluie = n.get_node("Rue/Pluie")
	var avant := pluie.temps
	await _attendre(30)
	T.proche(pluie.temps, avant, "la pluie est suspendue")
	T.ok(not n.get_node("Souvenir/Juliette").visible, "Juliette est partie")
	T.ok(n.get_node("Interface/Touches").text.contains("R (maintenu) : remonter le temps"), "le panneau parle de R")


func test_r_remonte_le_temps_et_lacher_le_fait_repartir() -> void:
	var n: Node3D = await _charger()
	var etagere: Node3D = n.get_node("Escalier/Etagere")
	T.ok(etagere.rotation.x < -1.0, "l'étagère est tombée sur l'escalier")
	await _remonter_jusqu_a(n, 26.0)
	T.ok(n.moment <= 26.0, "le temps a reculé (%.1f)" % n.moment)
	T.proche(etagere.rotation.x, 0.0, "l'étagère est revenue au mur", 0.01)
	T.ok(n.get_node("Souvenir/Juliette").visible, "Juliette est là")
	var avant: float = n.moment
	await _attendre(60)
	T.ok(n.moment > avant + 0.8, "on lâche R : le souvenir repart (%.1f)" % n.moment)


func test_l_etagere_bloque_l_escalier_puis_on_passe_dans_le_passe() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	# En haut de l'escalier, vers le bas.
	await _placer(j, Vector3(5.2, 2.8, -1.8), PI)
	Input.action_press("avancer")
	await _attendre(150)
	Input.action_release("avancer")
	T.ok(j.global_position.z < 3.0, "l'étagère barre le bas de l'escalier (%s)" % j.global_position)
	await _placer(j, Vector3(5.2, 2.8, -1.8), PI)
	await _remonter_jusqu_a(n, 15.0)
	Input.action_press("avancer")
	await _attendre(150, func() -> bool: return j.global_position.z > 3.8)
	Input.action_release("avancer")
	T.ok(j.global_position.z > 3.8 and j.global_position.y < 0.3, "avant la dispute, on descend (%s)" % j.global_position)


func test_le_casque_pris_dans_le_passe_reste_dans_les_mains() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var casque: RigidBody3D = n.get_node("Atelier/Casque")
	T.ok(not casque.visible, "à la fin, le casque est sous la grille")
	await _remonter_jusqu_a(n, 12.0)
	T.ok(casque.visible and casque.global_position.y > 1.3, "avant, il est au portemanteau")
	await _placer(j, Vector3(-4.8, 0, 3.2), 0.0)
	O.viser(j, casque.global_position)
	j._interagir()
	T.ok(j.held == casque, "on le prend")
	await _attendre(60)
	T.ok(n.moment > 12.5, "le temps avance")
	Input.action_press("rembobiner")
	await _attendre(60)
	Input.action_release("rembobiner")
	T.ok(j.held == casque and casque.visible, "même en remontant le temps, on le garde")
	T.ok(casque.get_node("Temps").hors_du_temps, "il est sorti du temps")
	await _attendre(int(10.0 * 60), func() -> bool: return n.moment > 22.0)
	T.ok(j.held == casque, "il ne tombe plus sous la grille")


func test_on_ne_sort_que_quand_juliette_part() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var casque: RigidBody3D = n.get_node("Atelier/Casque")
	await _placer(j, Vector3(-3.0, 0, 3.8), 0.0)
	Input.action_press("reculer")
	await _attendre(60)
	Input.action_release("reculer")
	T.ok(j.global_position.z < 5.0, "porte fermée à clé : on reste dedans (%s)" % j.global_position)
	await _remonter_jusqu_a(n, 31.0)
	T.ok(n.porte_ouverte(), "elle part, la porte est ouverte")
	n.moment = 31.0
	j.prendre(casque)
	await _placer(j, Vector3(-3.0, 0, 4.0), PI)
	Input.action_press("avancer")
	await _attendre(90, func() -> bool: return n.etat == Dispute.Etat.COURSE)
	Input.action_release("avancer")
	T.eq(n.etat, Dispute.Etat.COURSE, "le casque à la main, on la suit dehors")
	T.eq(Histoire.corrections, 1, "c'est la correction du peintre")
	T.ok(j.avance_auto, "Thomas court tout seul")


func test_sans_casque_on_ne_la_suit_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.moment = 31.0
	n._appliquer_le_moment()
	await _placer(j, Vector3(-3.0, 0, 4.0), PI)
	Input.action_press("avancer")
	await _attendre(60)
	Input.action_release("avancer")
	T.eq(n.etat, Dispute.Etat.ATELIER, "pas de course sans le casque")
	T.ok(n._dit.has("sans_casque"), "« Il faut que je lui donne son casque. »")


func _en_course(n: Node3D, z: float) -> Player:
	var j: Player = n.get_node("Player")
	n.commencer_la_course()
	await _placer(j, Vector3(500, 0, z), 0.0)
	j.set_anchor(Transform3D(Basis(), Vector3(500, 0, z)))
	return j


func test_dans_la_course_on_avance_tout_seul() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, 8.0)
	await _attendre(60)
	T.ok(j.global_position.z < 2.0, "Thomas avance sans touche (%s)" % j.global_position)
	var moto: Node3D = n.get_node("Course/Mobylette")
	T.ok(moto.global_position.z < j.global_position.z - 5.0, "la mobylette est devant")


func test_une_barriere_se_saute() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -12.0)
	await _attendre(30, func() -> bool: return j.global_position.z < -17.0)
	Input.action_press("sauter")
	await _attendre(40)
	Input.action_release("sauter")
	await _attendre(20)
	T.ok(j.global_position.z < -22.0, "par-dessus la barrière (%s)" % j.global_position)


func test_un_mur_s_evite_par_le_cote() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -28.0)
	# À -35 m, les voies de gauche et du milieu sont bloquées.
	await _attendre(60)
	T.ok(j.global_position.z > -35.0, "tout droit, on bute contre le mur (%s)" % j.global_position)
	Input.action_press("droite")
	await _attendre(60)
	Input.action_release("droite")
	await _attendre(30)
	T.ok(j.global_position.z < -36.0, "par la droite, on passe (%s)" % j.global_position)


func test_tomber_dans_un_trou_fait_repartir_du_repere() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -56.0)
	await _attendre(240, func() -> bool: return j.global_position.z > -60.0 and j.global_position.y > -0.5 and n._dit.has("tombe"))
	T.ok(n._dit.has("tombe"), "on est tombé dans le trou")
	T.ok(j.global_position.y > -0.5, "on repart du dernier repère (%s)" % j.global_position)


func test_au_bout_de_la_route_la_chute_et_espace() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -322.0)
	await _attendre(120, func() -> bool: return n.etat == Dispute.Etat.CHUTE)
	T.eq(n.etat, Dispute.Etat.CHUTE, "au bout de la route, le vide")
	T.ok(not j.avance_auto, "on ne court plus")
	for i in 40:
		n.appuyer()
		await tree.physics_frame
		if n.rattrapee:
			break
	T.ok(n.rattrapee, "en tapant vite sur Espace, on la rattrape")
	await _attendre(int(10.0 * 60), func() -> bool: return n.etat == Dispute.Etat.VERITE)
	T.eq(n.etat, Dispute.Etat.VERITE, "mais elle glisse ; puis la vérité")


func test_sans_taper_elle_tombe_aussi() -> void:
	var n: Node3D = await _charger()
	await _en_course(n, -322.0)
	await _attendre(120, func() -> bool: return n.etat == Dispute.Etat.CHUTE)
	await _attendre(int(16.0 * 60), func() -> bool: return n.etat == Dispute.Etat.VERITE)
	T.ok(not n.rattrapee, "sans la rattraper")
	T.eq(n.etat, Dispute.Etat.VERITE, "elle tombe dans tous les cas")


func test_la_verite_puis_la_maison() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.verite()
	await _attendre(3)
	T.ok(j.global_position.distance_to(Vector3(-1.0, 0, 2.2)) < 0.5, "dans l'atelier, après (%s)" % j.global_position)
	T.ok(n.get_node("Atelier/Telephone").visible, "le téléphone")
	Input.action_press("rembobiner")
	await _attendre(10)
	Input.action_release("rembobiner")
	T.ok(n._dit.has("pas_de_retour"), "« On ne remonte pas le temps. »")
	T.proche(n.moment, Dispute.DUREE, "le temps ne recule plus")
	await _attendre(int((16.0 + ChuteToiles.DUREE + 0.5) * 60), func() -> bool: return Histoire.scene_demandee != "")
	T.eq(Histoire.scene_demandee, "res://scenes/illusions.tscn", "retour dans la maison des étoiles")
	T.eq(Histoire.chapitre, 5, "le niveau 4 est fini")
