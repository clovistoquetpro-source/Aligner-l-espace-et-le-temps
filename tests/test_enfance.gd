extends RefCounted

## Le niveau 2 en formes simples : la cour (la peur grossit tout), la maison
## d'enfance (les invitations, la table sans fin) et le grenier qui grandit.

const O := preload("res://tests/outils_niveau.gd")
const Enfance := preload("res://scripts/niveau/enfance.gd")
const MAISON := Vector3(500, 0, 0)
const GRENIER := Vector3(1000, 0, 0)

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer", "sauter", "fermer_les_yeux"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/enfance.tscn").instantiate()
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


## Va directement à la maison, sans les scènes de la cour.
func _a_la_maison(n: Node3D) -> void:
	n.etape = Enfance.Etape.MAISON
	n.peur = 0.0
	await _placer(n.get_node("Player"), MAISON + Vector3(0, 0, 17.5), 0.0)


func _poster_tout(n: Node3D) -> void:
	for e in n.get_tree().get_nodes_in_group("invitations").duplicate():
		if n.is_ancestor_of(e):
			n.poster(e)


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.eq(n.get_tree().get_nodes_in_group("enfants").size(), 8, "huit enfants")
	T.eq(n.get_tree().get_nodes_in_group("invitations").size(), 3, "trois invitations")
	T.eq(n.get_tree().get_nodes_in_group("invites").size(), 6, "six invités peints")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is ObjetPerspectif).size(), 2, "deux cubes de bois")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Miroir).size(), 1, "un miroir")
	T.ok(O.tous(n, func(x: Node) -> bool: return x is Decrochable).size() >= 9, "des dessins au grenier")
	T.ok(n.get_tree().get_nodes_in_group("invites").all(func(i: Node3D) -> bool: return not i.visible), "les invités ne sont pas encore là")
	T.proche(n.get_node("Player").head.position.y, Enfance.TETE_ENFANT, "à hauteur d'enfant", 0.05)


func test_murs_et_sols_ne_se_superposent_pas() -> void:
	var n: Node3D = await _charger()
	var boites := O.boites(n, ["Mur", "Sol", "Plafond", "Jardin", "Cloture"])
	var res: Array[String] = []
	for i in boites.size():
		for k in range(i + 1, boites.size()):
			var inter := O.boite(boites[i]).intersection(O.boite(boites[k]))
			if minf(inter.size.x, minf(inter.size.y, inter.size.z)) > 0.001:
				res.append("%s / %s" % [boites[i].get_path(), boites[k].get_path()])
	T.ok(res.is_empty(), "chevauchements : %s" % ", ".join(res))


# --- La cour -----------------------------------------------------------------


func test_l_ombre_d_un_enfant_fait_peur() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	T.ok(n.dans_l_ombre(), "au départ, Thomas est dans l'ombre d'un enfant")
	await _attendre(60)
	T.ok(n.peur > 0.8, "la peur monte (%.2f)" % n.peur)
	T.ok(j.facteur_vitesse < 0.4, "elle le ralentit (%.2f)" % j.facteur_vitesse)
	T.ok(j.head.position.y < 0.8, "il se sent petit (%.2f)" % j.head.position.y)
	T.ok(n.get_node("Interface/Flou").visible, "sa vue se brouille")
	# Entre deux ombres, à 6 m de la lampe (à 100° du mur de l'école).
	await _placer(j, Vector3(5.9, 0, 2.0), 0.0)
	T.ok(not n.dans_l_ombre(), "hors de l'ombre")
	await _attendre(150)
	T.ok(n.peur < 0.1, "la peur retombe (%.2f)" % n.peur)


func test_on_ne_traverse_pas_les_ombres_tout_droit() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	# Droit vers la lampe depuis le mur : l'ombre d'un enfant est sur le chemin.
	var lampe: Vector3 = n.get_node("Cour/Lampe").global_position
	j.rotation.y = atan2(-(lampe.x - j.global_position.x), -(lampe.z - j.global_position.z))
	await _marcher("avancer", 180)
	T.ok(j.global_position.distance_to(Vector3(lampe.x, 0, lampe.z)) > 3.0, "la peur l'arrête avant la lampe (%.1f m)" % j.global_position.distance_to(Vector3(lampe.x, 0, lampe.z)))


func test_porter_la_lampe_ne_suffit_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var lampe: RigidBody3D = n.get_node("Cour/Lampe")
	await _placer(j, Vector3(7.5, 4.05, -3.0), PI / 2)
	j.prendre(lampe)
	await _attendre(30)
	T.ok(not n.ombres_vaincues, "tant qu'on la tient, les ombres restent géantes")


func test_la_lampe_en_haut_de_la_tour_montre_les_enfants() -> void:
	var n: Node3D = await _charger()
	var lampe: RigidBody3D = n.get_node("Cour/Lampe")
	lampe.global_position = Vector3(7.5, 4.4, -3.0)
	await _attendre(60, func() -> bool: return n.ombres_vaincues)
	T.ok(n.ombres_vaincues, "la lumière tombe d'en haut")
	var e: Node3D = n.get_node("Cour/Enfant_1")
	T.ok(e.get_node("Corps").visible and not e.get_node("Ombre").visible, "les enfants apparaissent")
	T.ok(not n.dans_l_ombre() or n.peur < 0.05, "plus de peur")


func test_on_monte_la_tour_par_l_escalier() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.ombres_vaincues = true
	await _placer(j, Vector3(1.5, 0, -3.0), -PI / 2)
	await _marcher("avancer", 240, func() -> bool: return j.global_position.y > 3.9)
	T.ok(j.global_position.y > 3.9, "en haut de la tour (%s)" % j.global_position)


func test_de_la_cour_a_la_maison() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	n.rentrer_a_la_maison()
	await _attendre(90)
	T.eq(n.etape, Enfance.Etape.MAISON, "à la maison")
	T.ok(j.global_position.distance_to(MAISON + Vector3(0, 0, 17.5)) < 1.0, "dans le jardin (%s)" % j.global_position)


# --- La maison ---------------------------------------------------------------


func test_l_invitation_du_miroir_ne_se_voit_que_dans_le_reflet() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var e: RigidBody3D = n.get_node("Maison/Invitation_reflet")
	var m: MeshInstance3D = e.get_node("Mesh")
	T.eq(m.layers, Miroir.COUCHE_REFLET, "invisible en vrai")
	T.eq(j.camera.cull_mask & Miroir.COUCHE_REFLET, 0, "la caméra du joueur ne la voit pas")
	await _a_la_maison(n)
	await _placer(j, MAISON + Vector3(7.8, 0, 4.4), PI)
	O.viser(j, e.global_position)
	j._interagir()
	T.ok(j.held == e, "on la prend en visant là où le reflet la montre")
	await tree.physics_frame
	T.eq(m.layers, 1, "elle devient visible")


func test_l_invitation_de_l_armoire_est_trop_haute_pour_un_enfant() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var e: RigidBody3D = n.get_node("Maison/Invitation_armoire")
	await _a_la_maison(n)
	await _placer(j, MAISON + Vector3(-9.6, 0, 1.0), PI / 2)
	O.viser(j, e.global_position)
	j._interagir()
	T.ok(j.held == null, "depuis le sol, on ne la voit pas")
	# Debout sur un cube agrandi à 1,2 m.
	j.set_physics_process(false)
	j.teleport(Transform3D(Basis(Vector3.UP, PI / 2), MAISON + Vector3(-9.6, 1.25, 1.0)))
	O.viser(j, e.global_position)
	j._interagir()
	j.set_physics_process(true)
	T.ok(j.held == e, "debout sur un cube, on l'attrape")


func test_poster_les_invitations_fait_venir_les_invites_peints() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _a_la_maison(n)
	var e: RigidBody3D = n.get_node("Maison/Invitation_bureau")
	j.prendre(e)
	await _placer(j, MAISON + Vector3(2.5, 0, 17.2), PI)
	O.viser(j, MAISON + Vector3(2.5, 1.3, 18.5))
	await _attendre(3)
	j.poser()
	await _attendre(60, func() -> bool: return n.invitations > 0)
	T.eq(n.invitations, 1, "posée sur la boîte aux lettres, elle est postée")
	T.ok(not n.invites_venus, "pas encore les invités")
	_poster_tout(n)
	T.eq(n.invitations, 3, "les trois")
	T.ok(n.invites_venus, "les invités sont venus")
	T.eq(Histoire.corrections, 1, "c'est une correction du peintre")
	T.ok(n.get_tree().get_nodes_in_group("invites").all(func(i: Node3D) -> bool: return i.visible), "ils sont à table")


func test_sans_invites_le_gateau_reste_a_sa_place() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _a_la_maison(n)
	await _placer(j, MAISON + Vector3(2.0, 0, -3.0), 0.0)
	await _marcher("avancer", 180, func() -> bool: return n._pensee_gateau)
	T.ok(n._pensee_gateau, "on atteint le gâteau : « Pas sans les autres »")
	T.ok(not n.voeu_fait, "pas de vœu")
	T.proche(n.get_node("SalleAManger/Fin").position.z, Enfance.FIN_TABLE, "la table a sa longueur")


func test_la_table_sans_fin_et_les_yeux_fermes() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var fin: Node3D = n.get_node("SalleAManger/Fin")
	await _a_la_maison(n)
	_poster_tout(n)
	await _placer(j, MAISON + Vector3(2.0, 0, -3.0), 0.0)
	var ecart_max := 0.0
	Input.action_press("avancer")
	for i in 480:
		await tree.physics_frame
		if j.global_position.z < -8.0:
			ecart_max = maxf(ecart_max, absf(j.global_position.z - Enfance.RECUL_GATEAU - fin.global_position.z))
	T.ok(not n.voeu_fait, "les yeux ouverts, on n'atteint jamais le gâteau")
	T.ok(j.global_position.z > -30.0, "la boucle ramène en arrière (%.1f)" % j.global_position.z)
	T.ok(ecart_max < 0.5, "le gâteau reste à %d m (écart %.2f)" % [Enfance.RECUL_GATEAU, ecart_max])
	T.ok(n._pensee_table, "« La table… elle n'en finit pas. »")
	Input.action_press("fermer_les_yeux")
	await _attendre(150, func() -> bool: return n.voeu_fait)
	Input.action_release("fermer_les_yeux")
	Input.action_release("avancer")
	T.ok(n.voeu_fait, "les yeux fermés, on y arrive")
	T.proche(fin.position.z, Enfance.FIN_TABLE, "la table reprend sa longueur")
	await _attendre(int(18.0 * 60), func() -> bool: return n.etape == Enfance.Etape.GRENIER and j.global_position.x > 900.0)
	await _attendre(90)
	T.eq(n.etape, Enfance.Etape.GRENIER, "puis on monte au grenier")
	T.ok(j.global_position.distance_to(GRENIER + Vector3(0, 0, 1.8)) < 1.0, "dans le grenier (%s)" % j.global_position)
	var inv: Node3D = n.get_node("SalleAManger/Invite_1")
	T.ok(absf(inv.rotation.x) > 1.0, "les invités en carton sont tombés")


# --- Le grenier --------------------------------------------------------------


func _au_grenier(n: Node3D) -> Player:
	var j: Player = n.get_node("Player")
	n.etape = Enfance.Etape.GRENIER
	await _placer(j, GRENIER + Vector3(0, 0, 1.8), 0.0)
	return j


func test_le_grenier_grandit_quand_on_regarde_ses_dessins() -> void:
	var n: Node3D = await _charger()
	var j := await _au_grenier(n)
	var dessin: Node3D = n.get_node("Grenier/Dessin_mur_3")
	O.viser(j, dessin.global_position)
	var local_avant: Vector3 = n.get_node("Grenier").global_transform.affine_inverse() * j.global_position
	await _attendre(120)
	T.ok(n.echelle > 1.15, "il grandit (%.2f)" % n.echelle)
	var local_apres: Vector3 = n.get_node("Grenier").global_transform.affine_inverse() * j.global_position
	T.proche(local_apres, local_avant, "Thomas reste au même endroit de la pièce", 0.05)
	T.ok(absf(j.global_position.y) < 0.05, "le plancher reste sous ses pieds (%.3f)" % j.global_position.y)
	O.viser(j, j.camera.global_position + Vector3(0, -1, 0.3))
	await _attendre(240)
	T.ok(n.echelle < 1.05, "puis il revient à sa taille (%.2f)" % n.echelle)


func test_la_lucarne_couverte_ne_fait_pas_retrecir() -> void:
	var n: Node3D = await _charger()
	var j := await _au_grenier(n)
	O.viser(j, n.get_node("Grenier/Lucarne").global_position)
	await _attendre(60)
	T.ok(n.echelle > 1.0, "couverte de dessins, la lucarne fait grandir (%.2f)" % n.echelle)


func test_decrocher_les_dessins_puis_regarder_dehors() -> void:
	var n: Node3D = await _charger()
	var j := await _au_grenier(n)
	await _placer(j, GRENIER + Vector3(0, 0, -1.0), 0.0)
	for d in n.get_tree().get_nodes_in_group("dessins_lucarne"):
		O.viser(j, d.global_position)
		j._interagir()
		T.ok(not d.accroche, "%s décroché avec E" % d.name)
	# On regarde ses pieds : le grenier revient à sa taille.
	O.viser(j, j.global_position + Vector3(0, 0, -0.3))
	await _attendre(240, func() -> bool: return absf(n.echelle - 1.0) < 0.01)
	var lucarne: Area3D = n.get_node("Grenier/Lucarne")
	T.ok(lucarne.global_position.y > 3.0, "la lucarne est trop haute (%.2f)" % lucarne.global_position.y)
	await _placer(j, GRENIER + Vector3(0, 0, -1.5), 0.0)
	for i in 300:
		O.viser(j, lucarne.global_position)
		await tree.physics_frame
		if n.echelle <= Enfance.ECHELLE_MIN + 0.01:
			break
	T.ok(n.echelle < 0.6, "regarder dehors fait rétrécir (%.2f)" % n.echelle)
	T.ok(lucarne.global_position.y < 2.0, "la lucarne descend (%.2f)" % lucarne.global_position.y)
	# On s'approche du mur et on saute vers la lucarne, en la regardant.
	Input.action_press("avancer")
	for i in 120:
		O.viser(j, lucarne.global_position)
		await tree.physics_frame
		if i == 40:
			Input.action_press("sauter")
		if n.etape == Enfance.Etape.FIN:
			break
	Input.action_release("sauter")
	Input.action_release("avancer")
	T.eq(n.etape, Enfance.Etape.FIN, "on sort par la lucarne")
	await _attendre(int((7.0 + ChuteToiles.DUREE + 0.5) * 60), func() -> bool: return Histoire.scene_demandee != "")
	T.eq(Histoire.scene_demandee, "res://scenes/illusions.tscn", "retour dans la maison des étoiles")
	T.eq(Histoire.chapitre, 3, "le niveau 2 est fini")


func test_une_invitation_posee_sur_la_table_reste_sur_la_table() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _a_la_maison(n)
	var e: RigidBody3D = n.get_node("Maison/Invitation_bureau")
	await _placer(j, MAISON + Vector3(0.9, 0, -4.5), 0.0)
	j.prendre(e)
	# On vise le milieu de la table, presque au ras : sans obstacle, l'objet
	# serait sous la table.
	O.viser(j, MAISON + Vector3(-0.1, 0.4, -4.8))
	await _attendre(3)
	T.ok(e.global_position.y > 0.76, "tenue au-dessus de la table, pas à travers (%.2f)" % e.global_position.y)
	j.poser()
	await _attendre(120)
	T.ok(e.global_position.y > 0.74 and e.global_position.y < 1.0, "posée sur la table (%.2f)" % e.global_position.y)


func test_une_invitation_tombee_revient_a_sa_place() -> void:
	var n: Node3D = await _charger()
	await _a_la_maison(n)
	var e: RigidBody3D = n.get_node("Maison/Invitation_bureau")
	var depart := e.global_position
	e.freeze = false
	e.global_position = MAISON + Vector3(0, -10, 0)
	await _attendre(3)
	T.proche(e.global_position, depart, "de retour sur le bureau", 0.01)


func test_l_invitation_de_l_armoire_se_voit_depuis_un_cube() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var e: RigidBody3D = n.get_node("Maison/Invitation_armoire")
	await _a_la_maison(n)
	# Les yeux à 2,15 m (debout sur un cube de 1 m) : rien ne cache l'invitation.
	j.set_physics_process(false)
	j.teleport(Transform3D(Basis(Vector3.UP, PI / 2), MAISON + Vector3(-8.5, 1.0, 1.0)))
	T.ok(n._visible(j.camera.global_position, e.global_position + Vector3(0, 0.08, 0)), "on voit le haut de l'invitation")
	j.teleport(Transform3D(Basis(Vector3.UP, PI / 2), MAISON + Vector3(-8.5, 0, 1.0)))
	T.ok(not n._visible(j.camera.global_position, e.global_position), "depuis le sol, l'armoire la cache")
	j.set_physics_process(true)
