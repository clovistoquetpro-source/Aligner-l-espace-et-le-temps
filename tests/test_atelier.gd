extends RefCounted

## Le niveau 5 en formes simples : devenir le peintre, les mille toiles,
## peindre (qui ne marche jamais), poser le pinceau, et dehors.

const O := preload("res://tests/outils_niveau.gd")
const Atelier := preload("res://scripts/niveau/atelier.gd")
const DEHORS := Vector3(1000, 0, 0)

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	for a in ["avancer", "reculer", "gauche", "droite", "sauter", "fermer_les_yeux"]:
		Input.action_release(a)
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()
	Histoire.reinitialiser()
	Histoire.simuler = false


func _charger() -> Node3D:
	Histoire.simuler = true
	_niveau = load("res://scenes/atelier.tscn").instantiate()
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


## Devient le peintre et attend la fin de la transition.
func _peintre(n: Node3D) -> Player:
	var j: Player = n.get_node("Player")
	n.devenir_le_peintre()
	await _attendre(150, func() -> bool: return n.etat == Atelier.Etat.PEINTRE)
	return j


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.ok(n.get_tree().get_nodes_in_group("toiles_mille").size() > 30, "un labyrinthe de toiles (%d)" % n.get_tree().get_nodes_in_group("toiles_mille").size())
	T.ok(n.get_node("Labyrinthe/Petales").get_child_count() > 30, "un chemin de pétales")
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Passant).size(), 3, "trois passants dehors")
	T.ok(n.get_node("Coeur/Chevalet") is Support, "le chevalet")
	T.ok(not n.get_node("Dehors").visible, "dehors n'est pas encore là")


func test_en_s_approchant_on_devient_le_peintre() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	await _placer(j, Vector3(0, 0, 5.0), 0.0)
	Input.action_press("avancer")
	await _attendre(200, func() -> bool: return n.etat != Atelier.Etat.AVANT)
	Input.action_release("avancer")
	await _attendre(150, func() -> bool: return n.etat == Atelier.Etat.PEINTRE)
	T.eq(n.etat, Atelier.Etat.PEINTRE, "on devient lui")
	T.ok(not n.get_node("Antichambre/Peintre").visible, "le peintre, c'est nous")
	T.ok(j.held != null and j.held.name == "Pinceau", "le pinceau à la main")
	T.proche(j.head.position.y, Atelier.TETE_PEINTRE, "les yeux d'un vieil homme", 0.01)
	T.ok(j.facteur_vitesse < 0.7, "un pas plus lent")
	T.ok(j.camera.get_node_or_null("Mains") != null, "ses mains, en bas de l'écran")


func test_regarder_une_toile_aspire_vers_l_entree() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	# Dans la case (2, 1), face au nord : le mur est fermé.
	await _placer(j, Vector3(0, 0, -4.5), 0.0)
	await _attendre(60, func() -> bool: return n.aspirations > 0)
	T.eq(n.aspirations, 1, "la toile aspire Thomas")
	T.ok(j.global_position.distance_to(Vector3(0, 0, 1.0)) < 0.5, "à l'entrée du labyrinthe (%s)" % j.global_position)


func test_les_yeux_fermes_on_ne_voit_que_les_petales() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	await _placer(j, Vector3(0, 0, -4.5), 0.0)
	Input.action_press("fermer_les_yeux")
	await _attendre(60)
	T.eq(n.aspirations, 0, "les yeux fermés, aucune toile n'aspire")
	T.eq(j.camera.cull_mask, Atelier.COUCHE_VRAI, "on ne voit que ce qui est vrai")
	Input.action_release("fermer_les_yeux")
	await _attendre(2)
	T.ok(j.camera.cull_mask & Atelier.COUCHE_VRAI == 0, "les yeux ouverts, les pétales sont invisibles")


func test_on_traverse_le_labyrinthe_les_yeux_fermes_en_suivant_les_petales() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	await _placer(j, Vector3(0, 0, 1.0), 0.0)
	Input.action_press("fermer_les_yeux")
	var points := [Vector3(0, 0, -1.5)]
	for c in [[2, 1], [1, 1], [0, 1], [0, 2], [0, 3], [1, 3], [2, 3], [3, 3], [3, 2], [4, 2], [4, 3], [4, 4]]:
		points.append(Vector3(-6.0 + 3.0 * c[0], 0, -1.5 - 3.0 * c[1]))
	points.append(Vector3(6, 0, -17.0))
	Input.action_press("avancer")
	for p in points:
		for i in 400:
			var d: Vector3 = p - j.global_position
			d.y = 0.0
			if d.length() < 0.3:
				break
			j.rotation.y = atan2(-d.x, -d.z)
			await tree.physics_frame
	Input.action_release("avancer")
	Input.action_release("fermer_les_yeux")
	T.eq(n.aspirations, 0, "aucune aspiration")
	T.ok(j.global_position.z < -16.0, "au cœur (%s)" % j.global_position)


func test_peindre_ne_marche_jamais() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	await _placer(j, Vector3(6, 0, -18.5), 0.0)
	O.viser(j, n.get_node("Coeur/Chevalet").global_position + Vector3(0, 1.2, 0))
	j._interagir()
	T.eq(n.etat, Atelier.Etat.PEINT, "E sur le chevalet : on peint")
	T.ok(n.get_node("Coeur/Version_parfaite").visible, "la version parfaite apparaît")
	await _attendre(int(9.0 * 60), func() -> bool: return n.etat == Atelier.Etat.PEINTRE)
	T.eq(n.etat, Atelier.Etat.PEINTRE, "puis tout recommence")
	T.eq(n.tentatives, 1, "une tentative")
	T.ok(j.global_position.distance_to(Vector3(0, 0, 1.0)) < 0.5, "à l'entrée du labyrinthe (%s)" % j.global_position)
	T.ok(n.get_node("Antichambre/Tentative_1").visible, "de nouvelles toiles s'empilent")
	T.ok(j.held != null and j.held.name == "Pinceau", "le pinceau toujours en main")


func test_avant_d_avoir_peint_thomas_reprend_le_pinceau() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	j.poser()
	await _attendre(3)
	T.ok(j.held != null and j.held.name == "Pinceau", "il le reprend")
	T.ok(n._dit.has("reprend"), "« Non… Pas encore. »")
	T.eq(n.etat, Atelier.Etat.PEINTRE, "rien ne change")


func test_poser_le_pinceau_puis_dehors_puis_la_fin() -> void:
	var n: Node3D = await _charger()
	var j := await _peintre(n)
	n.tentatives = 1
	await _placer(j, Vector3(6, 0, -18.5), 0.0)
	O.viser(j, j.camera.global_position + Vector3(0, -1, -0.2))
	T.eq(n.action_possible(), "poser", "E : poser")
	j._interagir()
	await _attendre(3)
	T.eq(n.etat, Atelier.Etat.POSE, "il pose le pinceau")
	await _attendre(int(15.0 * 60), func() -> bool: return n.get_node("Coeur/Porte").visible)
	T.ok(n.get_node("Coeur/Vrai_souvenir").visible, "la toile montre Juliette qui rit, au lac")
	T.ok(n.get_node("Coeur/Porte").visible, "la porte d'entrée apparaît")
	T.ok(not n.get_node("Labyrinthe/Toile_0").visible, "les toiles sont tombées")
	await _attendre(5)
	await _placer(j, Vector3(3.0, 0, -24.0), 0.0)
	await _attendre(200, func() -> bool: return n.etat == Atelier.Etat.DEHORS and j.global_position.x > 900.0)
	await _attendre(5)
	T.eq(n.etat, Atelier.Etat.DEHORS, "dehors")
	T.ok(j.global_position.distance_to(DEHORS + Vector3(0, 0, 6)) < 1.0, "sur le chemin (%s)" % j.global_position)
	T.ok(n.get_node("Dehors").visible, "la nature en couleurs")
	# Dire bonjour à la jardinière.
	var jardiniere: Passant = n.get_node("Dehors/Jardiniere")
	await _placer(j, DEHORS + Vector3(2.5, 0, -12), -PI / 2)
	O.viser(j, jardiniere.global_position + Vector3(0, 1.0, 0))
	for i in 3:
		await tree.process_frame
	T.eq(n.action_possible(), "dire bonjour", "E : dire bonjour")
	j._interagir()
	T.ok(jardiniere.deja_salue and n.saluts == 1, "on s'est salués")
	T.eq(n.action_possible(), "", "plus rien à faire une fois salués")
	# Le sommet de la colline, puis le générique.
	await _placer(j, DEHORS + Vector3(0, 3.0, -67), 0.0)
	await _attendre(5)
	T.eq(n.etat, Atelier.Etat.GENERIQUE, "au sommet, le vent")
	await _attendre(int(20.0 * 60), func() -> bool: return n.get_node("Interface/Generique").visible)
	T.ok(n.get_node("Interface/Generique").visible, "le générique")
	T.eq(Histoire.chapitre, 6, "le jeu est fini")
