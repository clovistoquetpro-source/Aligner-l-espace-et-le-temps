extends RefCounted

## Le niveau 4 en formes simples : la dispute à l'atelier (le temps à
## rebours), la course-poursuite, la chute et la vérité.

const O := preload("res://tests/outils_niveau.gd")
const Dispute := preload("res://scripts/niveau/dispute.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer", "gauche", "droite", "sauter", "rembobiner", "fermer_les_yeux"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


## Charge le niveau et passe le prologue (le bonheur), sauf `au_debut`.
func _charger(au_debut := false) -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/dispute.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	if not au_debut:
		_niveau.commencer_la_dispute(false)
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


## Lance la course, et place Thomas en `z` (après les premières toiles, il
## ne s'y arrête plus).
func _en_course(n: Node3D, z: float) -> Player:
	var j: Player = n.get_node("Player")
	if z < Dispute.PREMIERES_TOILES + Dispute.CHUTE_TOILES[1]:
		n._dit["arret_toiles"] = true
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


func test_se_cogner_a_un_mur_arrete_le_temps_et_r_le_remonte() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -28.0)
	# À -35 m, les voies de gauche et du milieu sont bloquées.
	await _attendre(90, func() -> bool: return n.course_figee)
	T.ok(n.course_figee, "on se cogne au mur : le temps s'arrête")
	var z := j.global_position.z
	T.ok(z > -35.0, "contre le mur (%s)" % j.global_position)
	await _attendre(30)
	T.proche(j.global_position.z, z, "rien ne bouge", 0.01)
	T.eq(n.get_node("Interface/Action").text, "R (maintenu) : remonter le temps", "ce que fait R")
	Input.action_press("rembobiner")
	await _attendre(60)
	Input.action_release("rembobiner")
	T.ok(j.global_position.z > z + 3.0, "R remonte la course (%s)" % j.global_position)
	await _attendre(2)
	T.ok(not n.course_figee, "on repart")
	Input.action_press("droite")
	await _attendre(60)
	Input.action_release("droite")
	await _attendre(30)
	T.ok(j.global_position.z < -36.0 and not n.course_figee, "par la droite, on passe (%s)" % j.global_position)


func test_apres_un_echec_il_faut_remonter_un_peu() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -28.0)
	await _attendre(90, func() -> bool: return n.course_figee)
	Input.action_press("rembobiner")
	await _attendre(5)
	Input.action_release("rembobiner")
	await _attendre(5)
	T.ok(n.course_figee, "trop peu : on reste arrêté (recul de %.0f images)" % n.recul())
	T.ok(j.global_position.z > -35.0, "toujours devant le mur")


func test_r_pendant_la_course_la_remonte_aussi() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, 8.0)
	await _attendre(60)
	var z := j.global_position.z
	Input.action_press("rembobiner")
	await _attendre(30)
	T.ok(n.course_figee, "R arrête la course")
	T.ok(j.global_position.z > z + 2.0, "et la remonte (%s)" % j.global_position)
	var moto: Node3D = n.get_node("Course/Mobylette")
	T.ok(moto.global_position.z < j.global_position.z - 5.0, "la mobylette recule avec lui")
	Input.action_release("rembobiner")
	await _attendre(3)
	T.ok(not n.course_figee, "on lâche R : on repart")


func test_tomber_dans_un_trou_arrete_le_temps_et_r_le_remonte() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -56.0)
	await _attendre(240, func() -> bool: return n.course_figee)
	T.ok(n.course_figee, "on tombe dans le trou : le temps s'arrête")
	T.ok(j.global_position.y < -1.0, "dans le trou (%s)" % j.global_position)
	Input.action_press("rembobiner")
	await _attendre(60)
	Input.action_release("rembobiner")
	await _attendre(2)
	T.ok(j.global_position.y > -0.5 and j.global_position.z > -62.0, "on remonte avant le trou (%s)" % j.global_position)
	T.ok(not n.course_figee, "on repart")


func test_la_rue_inondee_ne_se_voit_que_dans_l_eau() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -175.0)
	await _attendre(5)
	var mur: GeometryInstance3D = n.get_node("Course/Mur_188_1")
	T.eq(mur.layers & j.camera.cull_mask, 0, "le vrai mur ne se voit pas")
	var reflet: GeometryInstance3D = n.get_node("Course/Reflets/Reflet_Mur_188_1")
	T.ok(reflet.global_position.y < 0.0 and reflet.layers & j.camera.cull_mask != 0, "son reflet se voit, dans l'eau")
	T.ok(n._env_pluie.background_energy_multiplier < 0.1, "il fait nuit")
	var moto: GeometryInstance3D = n.get_node("Course/Mobylette/Cadre")
	T.eq(moto.layers & j.camera.cull_mask, 0, "Juliette non plus ne se voit pas…")
	T.ok(n.get_node("Course/Reflets/Mobylette").visible, "…seulement son reflet")
	await _attendre(150, func() -> bool: return n.course_figee)
	T.ok(n.course_figee and j.global_position.z > -188.0, "le mur qu'on ne voit pas arrête Thomas (%s)" % j.global_position)


func test_hauteur_des_toiles() -> void:
	T.proche(Dispute.hauteur_toile(30.0), Dispute.HAUT_TOILES, "loin devant, en l'air")
	var h := Dispute.hauteur_toile(11.5)
	T.ok(h > 0.0 and h < Dispute.HAUT_TOILES, "elle tombe (%.1f m)" % h)
	T.proche(Dispute.hauteur_toile(5.0), 0.0, "posée sur la route")


func test_les_toiles_barrent_la_route_et_les_yeux_fermes_montrent_les_vrais_murs() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -318.0)
	await _attendre(180, func() -> bool: return n.arret_toiles)
	T.ok(n.arret_toiles, "devant les toiles, Thomas s'arrête")
	for v in 3:
		T.proche((n.get_node("Course/Toile_335_%d" % v) as Node3D).position.y, 0.0, "la toile %d est tombée" % v, 0.01)
	var mur: GeometryInstance3D = n.get_node("Course/Vrai_mur_335_0")
	T.eq(mur.layers & j.camera.cull_mask, 0, "les yeux ouverts, on ne voit pas les vrais murs")
	await _attendre(30)
	T.ok(n.arret_toiles, "il attend")
	T.eq(n.get_node("Interface/Action").text, "F (maintenu) : fermer les yeux", "ce que fait F")
	Input.action_press("fermer_les_yeux")
	await _attendre(3)
	T.eq(j.camera.cull_mask, Souvenir.COUCHE_VRAI, "les yeux fermés, on ne voit que ce qui est vrai")
	T.ok(mur.layers & j.camera.cull_mask != 0, "les vrais murs")
	var peinture: GeometryInstance3D = n.get_node("Course/Toile_335_2/Peinture")
	T.eq(peinture.layers & j.camera.cull_mask, 0, "pas les toiles")
	await _attendre(60, func() -> bool: return not n.arret_toiles)
	T.ok(not n.arret_toiles, "Thomas repart")
	Input.action_press("droite")
	await _attendre(50)
	Input.action_release("droite")
	await _attendre(60)
	Input.action_release("fermer_les_yeux")
	T.ok(j.global_position.z < -336.0 and not n.course_figee, "par la voie libre, à travers la toile (%s)" % j.global_position)


func test_derriere_une_toile_un_vrai_mur() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -345.0)
	# À -355 m, les voies du milieu et de droite sont bloquées.
	await _attendre(150, func() -> bool: return n.course_figee)
	T.ok(n.course_figee, "on se cogne au vrai mur")
	T.ok(not (n.get_node("Course/Toile_355_1") as Node3D).visible, "la toile s'est déchirée")
	var mur: GeometryInstance3D = n.get_node("Course/Vrai_mur_355_1")
	T.ok(mur.layers & j.camera.cull_mask != 0, "derrière, on voit le vrai mur")


func test_au_bout_de_la_route_la_chute_et_espace() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, Dispute.FIN_COURSE + 9.0)
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
	await _en_course(n, Dispute.FIN_COURSE + 9.0)
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


func test_la_mobylette_ne_traverse_aucun_obstacle() -> void:
	# On rejoue le trajet de la mobylette, mètre par mètre, comme le jeu.
	var x := 0.0
	var z := -4.0
	var trajet := {}
	while z > Dispute.FIN_COURSE:
		x = Dispute.pas_moto(x, z - 0.25, 0.25)
		z -= 0.25
		trajet[snappedf(z, 0.25)] = x
	for o in Dispute.OBSTACLES:
		var oz: float = o[0]
		match o[1]:
			"mur", "toiles":
				var xo: float = trajet[snappedf(oz, 0.25)]
				for v in o[2]:
					T.ok(absf(xo - Dispute.VOIES[v]) > 1.8, "au mur de %d m, elle n'est pas dans la voie %d (x = %.2f)" % [int(oz), v, xo])
			"barriere":
				T.ok(Dispute.hauteur_moto(oz) > 0.8, "elle saute la barrière de %d m" % int(oz))
			"trou":
				for k in 5:
					var zk: float = oz - o[2] * k / 4.0
					T.ok(Dispute.hauteur_moto(zk) > 0.1, "elle passe au-dessus du trou de %d m" % int(oz))
	T.ok(Dispute.hauteur_moto(Dispute.FIN_COURSE - 3.0) < -3.0, "au bout de la route, elle tombe")


func test_les_immeubles_n_entrent_jamais_dans_la_route() -> void:
	var n: Node3D = await _charger()
	var route: Node3D = n.get_node("Course")
	var fautes: Array[String] = []
	var immeubles := O.tous(route, func(x: Node) -> bool: return x is CSGBox3D and (String(x.name) == "Etages" or String(x.name).ends_with("_rez")))
	T.ok(immeubles.size() > 100, "des immeubles des deux côtés (%d morceaux)" % immeubles.size())
	for b in immeubles:
		var a := O.boite(b)
		var local := AABB(a.position - route.global_position, a.size)
		var dans_la_route := local.position.x < 4.5 and local.end.x > -4.5
		if dans_la_route and local.position.y < 3.5:
			fautes.append("%s (x %.1f à %.1f, y dès %.1f)" % [b.get_path(), local.position.x, local.end.x, local.position.y])
	T.ok(fautes.is_empty(), "rien de solide ni de visible à hauteur de Thomas sur la route : %s" % ", ".join(fautes))


func test_on_ne_traverse_pas_les_immeubles() -> void:
	var n: Node3D = await _charger()
	var j := await _en_course(n, -165.0)
	Input.action_press("gauche")
	await _attendre(90)
	Input.action_release("gauche")
	T.ok(j.global_position.x > 500.0 - 4.6, "le bord de la route arrête Thomas (x = %.2f)" % j.global_position.x)


func test_on_commence_par_le_bonheur() -> void:
	var n: Node3D = await _charger(true)
	var j: Player = n.get_node("Player")
	T.eq(n.etat, Dispute.Etat.BONHEUR, "le prologue heureux")
	T.ok(j.global_position.distance_to(Vector3(-498.5, 0, 2.0)) < 0.5, "dans l'atelier au soleil (%s)" % j.global_position)
	T.ok(n.get_node("Bonheur/Juliette").visible, "Juliette est là")
	T.eq((n.get_node("WorldEnvironment") as WorldEnvironment).environment.background_mode, Environment.BG_SKY, "un ciel de beau temps")


func test_les_cles_ne_se_voient_que_dans_le_miroir() -> void:
	var n: Node3D = await _charger(true)
	var j: Player = n.get_node("Player")
	var cles: RigidBody3D = n.get_node("Bonheur/Cles")
	T.eq((cles.get_node("Anneau") as MeshInstance3D).layers, Miroir.COUCHE_REFLET, "invisibles en vrai")
	await _placer(j, Vector3(-504.0, 0, 1.7), -PI / 2)
	O.viser(j, cles.global_position)
	j._interagir()
	T.ok(j.held == cles, "on les prend là où le miroir les montre")
	await _attendre(3)
	T.ok(n.cles_trouvees, "trouvées")
	T.eq((cles.get_node("Anneau") as MeshInstance3D).layers, 1, "visibles une fois prises")
	T.ok(n.get_node("Bonheur/Mobylette/Juliette").visible, "Juliette attend sur la moto")


func test_sans_les_cles_pas_de_balade() -> void:
	var n: Node3D = await _charger(true)
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(-501.0, 0, 6.5), 0.0)
	await _attendre(5)
	T.eq(n.etat, Dispute.Etat.BONHEUR, "toujours dans l'atelier")
	T.ok(n._dit.has("sans_cles"), "« Les clés… Elle les a cachées. »")


func test_la_balade_puis_le_soir_de_la_dispute() -> void:
	var n: Node3D = await _charger(true)
	var j: Player = n.get_node("Player")
	j.prendre(n.get_node("Bonheur/Cles"))
	await _attendre(3)
	await _placer(j, Vector3(-501.0, 0, 6.0), 0.0)
	await _attendre(5, func() -> bool: return n.etat == Dispute.Etat.BALADE)
	T.eq(n.etat, Dispute.Etat.BALADE, "on monte derrière Juliette")
	var depart := j.global_position
	await _attendre(60)
	T.ok(j.global_position.distance_to(depart) > 6.0, "la moto avance (%.1f m)" % j.global_position.distance_to(depart))
	T.ok(not j.is_physics_processing(), "on ne conduit pas")
	var moto: Node3D = n.get_node("Balade/Mobylette")
	T.ok(j.global_position.distance_to(moto.global_position) < 1.0, "assis derrière elle")
	n.temps_balade = Dispute.LONGUEUR_BALADE / Dispute.VITESSE_BALADE - 0.1
	await _attendre(200, func() -> bool: return n.etat == Dispute.Etat.ATELIER and j.global_position.y > 2.5)
	T.eq(n.etat, Dispute.Etat.ATELIER, "des années plus tard, le soir de la dispute")
	T.ok(j.global_position.y > 2.5, "sur la mezzanine (%s)" % j.global_position)
	T.eq((n.get_node("WorldEnvironment") as WorldEnvironment).environment.fog_enabled, true, "sous la pluie")
