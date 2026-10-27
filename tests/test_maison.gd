extends RefCounted

const TempsScript := preload("res://scripts/time/temps.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()


func _charger() -> Node3D:
	_niveau = load("res://scenes/maison.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


func _tous(racine: Node, filtre: Callable) -> Array[Node]:
	var res: Array[Node] = []
	for n in racine.find_children("*", "", true, false):
		if filtre.call(n):
			res.append(n)
	return res


## Tourne le joueur pour que sa caméra vise ce point.
func _viser(j: Player, cible: Vector3) -> void:
	var d := cible - j.camera.global_position
	j.rotation.y = atan2(-d.x, -d.z)
	j.head.rotation.x = asin(d.normalized().y)


func test_contenu_du_niveau() -> void:
	var n: Node3D = await _charger()
	T.eq(_tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.ok(_tous(n, func(x: Node) -> bool: return x is PorteTrompeuse).size() >= 1, "une porte trompeuse")
	T.eq(_tous(n, func(x: Node) -> bool: return x is Alignement).size(), 1, "une énigme d'alignement")
	for e in [TempsScript.Epoque.PRESENT, TempsScript.Epoque.PASSE]:
		T.ok(_tous(n, func(x: Node) -> bool: return x is EpochMember and x.epoque == e).size() >= 1, "membres de l'époque %d" % e)


func test_marcher_tout_droit_fait_boucler() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	j.teleport(Transform3D(Basis(), Vector3(0, 0, -8)))
	await tree.physics_frame
	Input.action_press("avancer")
	var boucle := false
	for i in 120:
		var z_avant := j.global_position.z
		await tree.physics_frame
		if j.global_position.z - z_avant > 5.0:
			boucle = true
			break
	Input.action_release("avancer")
	T.ok(boucle, "sans viser la bonne photo, le couloir boucle")
	T.ok(j.global_position.x < 5.0, "pas arrivé au salon")


func test_objet_a_prendre_dans_le_hall() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var objets := _tous(n, func(x: Node) -> bool: return x is RigidBody3D)
	T.ok(objets.size() >= 1, "au moins un objet à porter")
	if objets.is_empty():
		return
	var objet: RigidBody3D = objets[0]
	j.teleport(Transform3D(Basis(), objet.global_position + Vector3(0, 0, 1.5) - Vector3(0, objet.global_position.y, 0)))
	_viser(j, objet.global_position)
	await tree.physics_frame
	j._interagir()
	T.eq(j.held, objet, "E prend l'objet")


func test_horloge_se_vise_un_peu_au_dessus_du_centre() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var enigme: Alignement = n.get_node("Atelier/Horloge")
	var vue: Node3D = enigme.get_node(enigme.point_de_vue)
	j.teleport(Transform3D(Basis(), vue.global_position - Vector3(0, 1.6, 0)))
	var vers_centre := enigme.global_position - j.camera.global_position
	var vise := j.camera.global_position + Basis(Vector3.RIGHT, deg_to_rad(3)) * vers_centre
	_viser(j, vise)
	await tree.physics_frame
	enigme.verifier(j.camera)
	T.ok(enigme.est_resolu, "3° au-dessus du centre de l'horloge : aligné")


const SAUT_MAX := Player.JUMP * Player.JUMP / (2.0 * 9.8)


func test_estrade_demande_d_agrandir_le_cube() -> void:
	var n: Node3D = await _charger()
	var estrade: CSGBox3D = n.get_node("Hall/Estrade")
	var cube: ObjetPerspectif = n.get_node("Hall/Cube")
	var hauteur := estrade.global_position.y + estrade.size.y / 2
	T.ok(hauteur > SAUT_MAX + 0.2, "trop haute pour un saut (%.2f m)" % hauteur)
	T.ok(hauteur < 2 * SAUT_MAX - 0.15, "atteignable depuis un cube grimpable")
	T.ok(cube.taille_depart + SAUT_MAX < hauteur, "le cube de départ est trop petit")


## Le joueur saute en avançant vers -Z ; renvoie sa position après 2 s.
func _sauter_en_avant(j: Player) -> Vector3:
	for i in 10:
		await tree.physics_frame
	Input.action_press("avancer")
	Input.action_press("sauter")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release("sauter")
	for i in 120:
		await tree.physics_frame
	Input.action_release("avancer")
	return j.global_position


func test_sans_cube_on_ne_monte_pas() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	j.teleport(Transform3D(Basis(), Vector3(-1.5, 0, 2.3)))
	var pos: Vector3 = await _sauter_en_avant(j)
	T.ok(pos.z > 1.4, "bloqué par l'estrade (z = %.2f)" % pos.z)


func test_avec_un_cube_agrandi_on_monte() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var cube: ObjetPerspectif = n.get_node("Hall/Cube")
	cube.taille = 0.8
	cube.global_position = Vector3(0, 0.4, 1.95)
	j.teleport(Transform3D(Basis(), Vector3(0, 0.85, 2.1)))
	var pos: Vector3 = await _sauter_en_avant(j)
	T.ok(pos.z < 1.0, "monté sur l'estrade ou passé dans le couloir (z = %.2f)" % pos.z)


func test_parcours_complet() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var porte: PorteTrompeuse = n.get_node("Couloir/PorteTrompeuse")
	var bonne: Node3D = n.get_node("Couloir/PhotoBonne")
	var mauvaise: Node3D = n.get_node("Couloir/PhotoRouge")

	# Sans regarder la bonne photo, le couloir boucle.
	j.teleport(Transform3D(Basis(), porte.global_position + Vector3(0, 0, 0.3)))
	_viser(j, mauvaise.global_position)
	j.set_meta("arrivee_ms", -100000)
	porte._corps_entre(j)
	T.ok(j.global_position.z > -4.0 and absf(j.global_position.x) < 2.0, "retour au début du couloir")

	# En regardant la bonne photo, on arrive au salon.
	j.teleport(Transform3D(Basis(), porte.global_position + Vector3(0, 0, 0.3)))
	_viser(j, bonne.global_position)
	j.set_meta("arrivee_ms", -100000)
	porte._corps_entre(j)
	T.ok(j.global_position.x > 25.0 and j.global_position.z > -10.0, "arrivé au salon")

	# Au présent, le mur du salon est solide ; dans le passé, il a une arche.
	var mur: CSGShape3D = n.get_node("Salon/MurPresent")
	T.ok(mur.use_collision, "mur solide au présent")
	T.ok(Temps.basculer(j), "bascule vers le passé")
	T.ok(not mur.use_collision, "mur absent dans le passé")

	# L'énigme d'alignement ouvre la sortie.
	var enigme: Alignement = n.get_node("Atelier/Horloge")
	var vue: Node3D = enigme.get_node(enigme.point_de_vue)
	j.teleport(Transform3D(Basis(), vue.global_position - Vector3(0, 1.6, 0)))
	_viser(j, enigme.global_position)
	await tree.physics_frame
	enigme.verifier(j.camera)
	T.ok(enigme.est_resolu, "horloge réalignée")
	var sortie: CSGShape3D = n.get_node("Atelier/PorteSortie")
	T.ok(not sortie.visible and not sortie.use_collision, "la sortie est ouverte")


## Bas d'un plafond (boîte CSG), en coordonnées du monde.
func _bas(plafond: CSGBox3D) -> float:
	return plafond.global_position.y - plafond.size.y / 2


func test_chaque_piece_a_un_plafond_solide_sans_ombre() -> void:
	var n: Node3D = await _charger()
	for chemin in ["Hall/Plafond", "Couloir/Plafond", "Salon/Plafond"]:
		var p := n.get_node_or_null(chemin) as CSGBox3D
		T.ok(p != null, "%s existe" % chemin)
		if p == null:
			continue
		T.ok(p.use_collision, "%s solide" % chemin)
		# Le plafond ne cache pas le soleil : les pièces restent lumineuses.
		T.eq(p.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s sans ombre" % chemin)


func test_debout_sur_l_estrade_on_passe_sous_les_plafonds() -> void:
	var n: Node3D = await _charger()
	var estrade: CSGBox3D = n.get_node("Hall/Estrade")
	var tete := estrade.global_position.y + estrade.size.y / 2 + 1.8
	for chemin in ["Hall/Plafond", "Couloir/Plafond"]:
		var p := n.get_node_or_null(chemin) as CSGBox3D
		T.ok(p != null and _bas(p) > tete + 0.3, "%s assez haut pour passer depuis l'estrade" % chemin)


func test_le_plafond_ne_coupe_pas_l_horloge() -> void:
	var n: Node3D = await _charger()
	var p := n.get_node_or_null("Salon/Plafond") as CSGBox3D
	T.ok(p != null, "plafond du salon")
	if p == null:
		return
	for morceau in n.get_node("Atelier/Horloge").get_children():
		var b := morceau as CSGBox3D
		var boite: AABB = b.global_transform * AABB(-b.size / 2, b.size)
		T.ok(boite.end.y < _bas(p), "%s sous le plafond" % b.name)


func test_les_fenetres_ont_une_vitre_solide() -> void:
	var n: Node3D = await _charger()
	var vitres := _tous(n, func(x: Node) -> bool: return x is CSGBox3D and String(x.name).begins_with("Vitre"))
	T.ok(vitres.size() >= 3, "au moins 3 fenêtres (%d)" % vitres.size())
	for v in vitres:
		T.ok((v as CSGBox3D).use_collision, "%s bloque le passage" % v.name)


func _membres(n: Node, e: int) -> Array[Node]:
	return _tous(n, func(x: Node) -> bool: return x is HabillageCartoon and x.get_node_or_null("EpochMember") != null and x.get_node("EpochMember").epoque == e)


func test_la_maison_est_meublee_avec_les_packs() -> void:
	var n: Node3D = await _charger()
	var modeles := _tous(n, func(x: Node) -> bool: return x is HabillageCartoon)
	T.ok(modeles.size() >= 40, "au moins 40 modèles importés (%d)" % modeles.size())
	T.ok(_membres(n, TempsScript.Epoque.PRESENT).size() >= 8, "un salon meublé au présent")
	T.ok(_membres(n, TempsScript.Epoque.PASSE).size() >= 8, "une salle de château dans le passé")
	if modeles.is_empty():
		return
	var mi := modeles[0].find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var m := mi.get_surface_override_material(0) as BaseMaterial3D
	T.ok(m != null and m.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "habillés en cartoon")


func test_dans_le_passe_on_traverse_le_salon_jusqu_a_l_atelier() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	j.teleport(Transform3D(Basis(), Vector3(30, 0, -1.5)))
	await tree.physics_frame
	T.ok(Temps.basculer(j), "on peut basculer à l'arrivée dans le salon")
	Input.action_press("avancer")
	for i in 150:
		await tree.physics_frame
	Input.action_release("avancer")
	T.ok(j.global_position.z < -11.0, "passé sous l'arche (z = %.2f)" % j.global_position.z)
	T.ok(Temps.basculer(j), "on peut revenir au présent dans l'atelier")


## Murs, sols, plafonds… : deux de ces boîtes ne doivent jamais occuper le
## même volume (leurs faces se superposent et scintillent).
const STRUCTURE := ["Mur", "Plafond", "Sol", "Estrade", "Colonne", "Arche", "PorteSortie"]


func _boite(b: CSGBox3D) -> AABB:
	return b.global_transform * AABB(-b.size / 2, b.size)


func _epoque(n: Node) -> int:
	var e := n.get_node_or_null("EpochMember")
	return e.epoque if e != null else -1


func _boites(n: Node, prefixes: Array) -> Array[Node]:
	return _tous(n, func(x: Node) -> bool:
		return x is CSGBox3D and not (x.get_parent() is CSGShape3D) \
			and prefixes.any(func(p: String) -> bool: return String(x.name).begins_with(p)))


func _chevauchements(boites: Array[Node]) -> Array[String]:
	var res: Array[String] = []
	for i in boites.size():
		for k in range(i + 1, boites.size()):
			var a: CSGBox3D = boites[i]
			var b: CSGBox3D = boites[k]
			if _epoque(a) >= 0 and _epoque(b) >= 0 and _epoque(a) != _epoque(b):
				continue
			var inter := _boite(a).intersection(_boite(b))
			if inter.size.x * inter.size.y * inter.size.z > 1e-6:
				res.append("%s / %s" % [a.get_path(), b.get_path()])
	return res


func test_les_murs_ne_se_chevauchent_pas() -> void:
	var n: Node3D = await _charger()
	var c := _chevauchements(_boites(n, STRUCTURE))
	T.ok(c.is_empty(), "chevauchements : %s" % ", ".join(c))


func test_les_plinthes_touchent_un_mur_sans_se_chevaucher() -> void:
	var n: Node3D = await _charger()
	var plinthes := _boites(n, ["Plinthe"])
	var murs := _boites(n, ["Mur"])
	T.ok(plinthes.size() >= 8, "des plinthes")
	for p in plinthes:
		var colle := murs.any(func(m: Node) -> bool: return _boite(m).grow(0.005).intersects(_boite(p)))
		T.ok(colle, "%s contre un mur" % p.get_path())
	var c := _chevauchements(plinthes)
	T.ok(c.is_empty(), "plinthes qui se chevauchent : %s" % ", ".join(c))


func test_le_cadre_des_fenetres_ne_colle_pas_au_trou_du_mur() -> void:
	# Le bord intérieur du cadre doit être un peu dans l'ouverture : sinon ses
	# faces tombent pile sur celles du trou et scintillent.
	var n: Node3D = await _charger()
	var vitres := _tous(n, func(x: Node) -> bool: return x is CSGBox3D and String(x.name).begins_with("Vitre"))
	for v: CSGBox3D in vitres:
		var cadre := v.get_parent().get_node("Fenetre" + String(v.name).trim_prefix("Vitre"))
		for b in cadre.get_children():
			if not (b is CSGBox3D) or not is_equal_approx(b.size.z, 0.3):
				continue
			if absf(b.position.x) > 0.01:
				T.ok(absf(b.position.x) - b.size.x / 2 < v.size.x / 2 - 0.005, "%s : montant en retrait" % cadre.name)
			if absf(b.position.y) > 0.01:
				T.ok(absf(b.position.y) - b.size.y / 2 < v.size.y / 2 - 0.005, "%s : traverse en retrait" % cadre.name)
