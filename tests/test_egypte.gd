extends RefCounted

const TempsScript := preload("res://scripts/time/temps.gd")
const O := preload("res://tests/outils_niveau.gd")

var tree: SceneTree
var _niveau: Node3D


func nettoyer() -> void:
	if is_instance_valid(_niveau):
		_niveau.free()
	Temps.reinitialiser()


func _charger() -> Node3D:
	_niveau = load("res://scenes/egypte.tscn").instantiate()
	tree.root.add_child(_niveau)
	await tree.physics_frame
	await tree.physics_frame
	return _niveau


## Hauteur des maillages sous `n` (dans le monde), sans les morceaux cachés.
func _hauteur(n: Node) -> float:
	var b := AABB()
	var vide := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue
		var m := mi.global_transform * mi.get_aabb()
		b = m if vide else b.merge(m)
		vide = false
	return b.size.y


func test_contenu() -> void:
	var n: Node3D = await _charger()
	T.eq(O.tous(n, func(x: Node) -> bool: return x is Player).size(), 1, "un joueur")
	T.eq(Temps.courante, TempsScript.Epoque.PASSE, "on arrive dans l'Antiquité")
	for g in ["Mirage", "Carriere", "Rampe", "Camp", "Temple", "Chantier"]:
		T.ok(n.has_node(g), "groupe %s" % g)
	var env: Environment = n.get_node("WorldEnvironment").environment
	T.eq(env.background_color, Color("3ee6d0"), "ciel turquoise de l'Antiquité")


func test_les_murs_ne_se_chevauchent_pas() -> void:
	var n: Node3D = await _charger()
	var c := O.chevauchements(O.boites(n, O.STRUCTURE))
	T.ok(c.is_empty(), "chevauchements : %s" % ", ".join(c))


func test_modeles_cartoon() -> void:
	var n: Node3D = await _charger()
	T.ok(O.tous(n, func(x: Node) -> bool: return x is HabillageCartoon).size() >= 1, "des modèles importés")
	var soldats := O.tous(n, func(x: Node) -> bool: return String(x.name).begins_with("Soldat"))
	T.ok(soldats.size() >= 1, "au moins un soldat")
	for s in soldats:
		var h := _hauteur(s)
		T.ok(h > 1.6 and h < 2.0, "%s mesure %.2f m" % [s.name, h])
		T.ok(not s.find_child("AK", true, false).visible, "%s n'a pas d'arme" % s.name)


# --- Énigme 1 : le mirage -------------------------------------------------------

const AXE_CHEMIN := Vector3(0, 0, -1)


func _destination(porte: PorteTrompeuse, dir: Vector3, cible: Vector3) -> String:
	var oeil := porte.global_position + Vector3(0, 1.6, 0)
	var i := PorteTrompeuse.choisir(dir, cible - oeil, porte.angle_max_deg, porte.index_si_regard, porte.index_sinon)
	return String(porte.get_node(porte.destinations[i]).name)


func test_mirage_boucle_sans_regarder() -> void:
	var n: Node3D = await _charger()
	var porte: PorteTrompeuse = n.get_node("Mirage/Porte")
	var bout: Node3D = n.get_node("Mirage/BoutOmbre")
	T.eq(_destination(porte, AXE_CHEMIN, bout.global_position), "Retour", "tout droit : retour au départ")


func test_mirage_s_ouvre_en_regardant_l_ombre() -> void:
	var n: Node3D = await _charger()
	var porte: PorteTrompeuse = n.get_node("Mirage/Porte")
	var bout: Node3D = n.get_node("Mirage/BoutOmbre")
	var vers := bout.global_position - (porte.global_position + Vector3(0, 1.6, 0))
	T.eq(_destination(porte, vers.normalized(), bout.global_position), "Sortie", "en regardant le bout de l'ombre")
	T.ok(rad_to_deg(AXE_CHEMIN.angle_to(vers)) >= 25.0, "il faut tourner la tête (%.0f°)" % rad_to_deg(AXE_CHEMIN.angle_to(vers)))
	var obelisque: Node3D = n.get_node("Mirage/Obelisque")
	var ombre := bout.global_position - obelisque.global_position
	ombre.y = 0
	var soleil := -(n.get_node("Soleil") as Node3D).global_basis.z
	soleil.y = 0
	T.ok(rad_to_deg(ombre.angle_to(soleil)) < 3.0, "l'ombre suit le soleil")


func _boite_statique(corps: StaticBody3D) -> AABB:
	var forme: CollisionShape3D = corps.get_child(0)
	var taille := (forme.shape as BoxShape3D).size
	return forme.global_transform * AABB(-taille / 2, taille)


func test_pas_de_contournement() -> void:
	var n: Node3D = await _charger()
	var porte: PorteTrompeuse = n.get_node("Mirage/Porte")
	var forme: CollisionShape3D = porte.get_child(0)
	var taille := (forme.shape as BoxShape3D).size
	var p := forme.global_transform * AABB(-taille / 2, taille)
	var ouest := _boite_statique(n.get_node("Mirage/Bords/CheminOuest"))
	var est := _boite_statique(n.get_node("Mirage/Bords/CheminEst"))
	T.ok(p.position.x <= ouest.end.x and p.end.x >= est.position.x, "la porte barre tout le chemin")
	T.ok(ouest.position.z <= p.position.z and ouest.end.z >= p.end.z, "les bords longent la porte")
	# Depuis l'arrivée, seule la direction du chemin ne bute sur rien.
	var espace := n.get_world_3d().direct_space_state
	var depart := Vector3(0, 1, 70)
	for k in range(1, 16):
		var a := TAU * k / 16.0
		var r := PhysicsRayQueryParameters3D.create(depart, depart + Vector3(sin(a), 0, -cos(a)) * 80)
		T.ok(not espace.intersect_ray(r).is_empty(), "l'arrivée est fermée (direction %d/16)" % k)


# --- Énigme 2 : le spinosaure ---------------------------------------------------

## Ce que touche un rayon horizontal qui traverse l'entrée de la carrière à
## la hauteur `y` et au décalage `z`.
func _a_travers_l_entree(n: Node3D, y: float, z: float) -> Object:
	var r := PhysicsRayQueryParameters3D.create(Vector3(-24, y, z), Vector3(-50, y, z))
	var touche := n.get_world_3d().direct_space_state.intersect_ray(r)
	return touche.get("collider")


func _basculer_sans_joueur(ep: int) -> void:
	Temps.courante = ep
	Temps.epoque_changee.emit(ep)
	await tree.physics_frame
	await tree.physics_frame


func test_le_spinosaure_bloque_l_entree() -> void:
	var n: Node3D = await _charger()
	var dino: Node = n.get_node("Carriere/Spinosaure")
	for ep in [TempsScript.Epoque.PASSE, TempsScript.Epoque.PRESENT]:
		await _basculer_sans_joueur(ep)
		for y in [0.5, 1.5, 2.4]:
			for z in [-1.8, 0.0, 1.8]:
				T.eq(_a_travers_l_entree(n, y, z), dino, "époque %d, y %.1f, z %.1f : le spinosaure barre l'entrée" % [ep, y, z])


func test_trajet_du_spinosaure() -> void:
	var n: Node3D = await _charger()
	var dino: Node3D = n.get_node("Carriere/Spinosaure")
	var appat: Node3D = n.get_node("Carriere/ZoneAppat")
	var repas: Node3D = n.get_node("Carriere/Repas")
	var entree := Vector3(-37, 0, 0)
	# Il s'éloigne de l'entrée pour aller manger, puis ne repasse pas devant.
	var avant := Vector2(dino.global_position.x - entree.x, dino.global_position.z - entree.z).length()
	var p1 := Geometry3D.get_closest_point_to_segment(entree, dino.global_position, appat.global_position)
	T.ok(p1.distance_to(entree) >= avant - 0.01, "il part en s'éloignant de l'entrée")
	var p2 := Geometry3D.get_closest_point_to_segment(entree, appat.global_position, repas.global_position)
	T.ok(Vector2(p2.x - entree.x, p2.z - entree.z).length() > 6.0, "il va se coucher loin de l'entrée")


func test_poisson_qui_s_echappe() -> void:
	var n: Node3D = await _charger()
	var poisson: ObjetPerspectif = n.get_node("Carriere/Poisson")
	var depart := poisson.global_position
	poisson.global_position = Vector3(0, 1, 500)
	await tree.physics_frame
	await tree.physics_frame
	T.ok(poisson.global_position.distance_to(depart) < 1.0, "le poisson revient au bord du Nil")
	poisson.global_position = Vector3(-30, 1, 23)
	await tree.physics_frame
	await tree.physics_frame
	T.ok(poisson.global_position.distance_to(depart) < 1.0, "jeté dans le Nil, il revient aussi")


func test_carriere_resolue() -> void:
	var n: Node3D = await _charger()
	var dino: Spinosaure = n.get_node("Carriere/Spinosaure")
	dino.duree_marche = 0.05
	var poisson: ObjetPerspectif = n.get_node("Carriere/Poisson")
	var zone: Area3D = n.get_node("Carriere/ZoneAppat")
	poisson.taille = 2.0
	poisson.global_position = zone.global_position
	for i in 40:
		await tree.physics_frame
	T.eq(dino.etat, Spinosaure.Etat.REPU, "il a mangé")
	for y in [0.5, 1.5]:
		for z in [-1.0, 0.0, 1.0]:
			T.eq(_a_travers_l_entree(n, y, z), null, "l'entrée est libre (y %.1f, z %.1f)" % [y, z])
	var cartouche: Cartouche = n.get_node("Carriere/Cartouche")
	T.eq(cartouche.zone, "carriere", "le cartouche de la carrière")
	T.ok(cartouche.global_position.x < -40.0, "il est au fond de la carrière")


# --- Énigme 3 : la rampe ----------------------------------------------------------

func _aabb(v: VisualInstance3D) -> AABB:
	return v.global_transform * v.get_aabb()


## Ce que touche un rayon vertical qui descend en (x, z) : { position, collider }.
func _sous(n: Node3D, x: float, z: float) -> Dictionary:
	var r := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -5, z))
	return n.get_world_3d().direct_space_state.intersect_ray(r)


## La forme solide des sacs de sable, dans le monde.
func _sacs(n: Node3D, nom: String) -> AABB:
	return n.get_node("Rampe/%s/EpochMember" % nom).aabbs_solides()[0]


func test_rampe_trouee_dans_l_antiquite() -> void:
	var n: Node3D = await _charger()
	for nom in ["Troncon1", "Troncon3", "Troncon5", "Terrasse"]:
		T.eq(O.epoque(n.get_node("Rampe/" + nom)), -1, "%s existe dans les deux époques" % nom)
	for nom in ["Troncon2", "Troncon4"]:
		var t: CSGShape3D = n.get_node("Rampe/" + nom)
		T.eq(O.epoque(t), TempsScript.Epoque.PRESENT, "%s n'existe qu'en 1942" % nom)
		var long := _aabb(t).size.z
		T.ok(long >= 5.5, "%s : un trou de %.1f m, trop long pour un saut" % [nom, long])
	T.proche(O.boite(n.get_node("Rampe/Terrasse")).end.y, 8.0, "la terrasse est à 8 m", 0.01)


func test_rampe_continue_en_1942() -> void:
	var n: Node3D = await _charger()
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var sacs := [_sacs(n, "SacsA"), _sacs(n, "SacsB")]
	var debut := O.boite(n.get_node("Rampe/Terrasse")).end.z
	var avant := Vector2(-18.5, _sous(n, 0, -18.5)["position"].y)
	var z := -19.0
	while z > debut:
		var sur_les_sacs := sacs.any(func(s: AABB) -> bool: return z > s.position.z - 0.1 and z < s.end.z + 0.1)
		var h: float = _sous(n, 0, z).get("position", Vector3.DOWN).y
		if not sur_les_sacs:
			var montee := (h - avant.y) / (avant.x - z)
			T.ok(montee > 0.0 and montee < 0.3, "z %.1f : la pente monte sans marche (%.2f puis %.2f)" % [z, avant.y, h])
			avant = Vector2(z, h)
		z -= 0.5
	T.ok(avant.y > 7.8, "on arrive en haut (%.2f m)" % avant.y)


func test_sacs_de_sable_en_1942() -> void:
	var n: Node3D = await _charger()
	for paire in [["SacsA", "Troncon3"], ["SacsB", "Troncon5"]]:
		T.eq(O.epoque(n.get_node("Rampe/" + paire[0])), TempsScript.Epoque.PRESENT, "%s n'existe qu'en 1942" % paire[0])
		var s := _sacs(n, paire[0])
		var t := _aabb(n.get_node("Rampe/" + paire[1]))
		T.ok(s.size.y >= 1.2, "%s : %.2f m de haut, trop haut pour un saut" % [paire[0], s.size.y])
		T.ok(s.position.x <= -1.5 and s.end.x >= 1.5, "%s barre toute la largeur" % paire[0])
		T.ok(s.position.z - t.position.z >= 2.0 and t.end.z - s.end.z >= 2.0, "%s : de la place de chaque côté sur %s" % paire)


## Le joueur debout sur la rampe en (0, z) peut basculer dans les deux sens.
func _peut_basculer(n: Node3D, z: float) -> bool:
	var pied: Vector3 = _sous(n, 0, z)["position"]
	var boite := AABB(pied - Vector3(0.35, 0, 0.35), Temps.TAILLE_JOUEUR).grow(-Temps.MARGE)
	return TempsScript.bascule_possible(boite, O.solides_de(n, TempsScript.Epoque.PASSE)) \
		and TempsScript.bascule_possible(boite, O.solides_de(n, TempsScript.Epoque.PRESENT))


func test_on_peut_basculer_avant_les_sacs() -> void:
	var n: Node3D = await _charger()
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var t3 := _aabb(n.get_node("Rampe/Troncon3"))
	var t5 := _aabb(n.get_node("Rampe/Troncon5"))
	var a := _sacs(n, "SacsA")
	var b := _sacs(n, "SacsB")
	T.ok(_peut_basculer(n, (t3.end.z + a.end.z) / 2), "avant les sacs A (vers l'Antiquité)")
	T.ok(_peut_basculer(n, (a.position.z + t3.position.z) / 2), "après les sacs A (retour en 1942)")
	T.ok(_peut_basculer(n, (t5.end.z + b.end.z) / 2), "avant les sacs B (vers l'Antiquité)")


func test_chute_sur_le_sable() -> void:
	var n: Node3D = await _charger()
	var sol: Node = n.get_node("Sol")
	for nom in ["Troncon2", "Troncon4"]:
		var c := _aabb(n.get_node("Rampe/" + nom)).get_center()
		T.eq(_sous(n, 0, c.z).get("collider"), sol, "%s en Antiquité : on tombe sur le sable" % nom)
		for cote in [-1, 1]:
			var r := PhysicsRayQueryParameters3D.create(Vector3(0, 1, c.z), Vector3(12 * cote, 1, c.z))
			T.eq(n.get_world_3d().direct_space_state.intersect_ray(r).get("collider"), null, "%s : on ressort sur le côté" % nom)
	var cartouche: Cartouche = n.get_node("Rampe/Cartouche")
	T.eq(cartouche.zone, "rampe", "le cartouche de la rampe")
	T.ok(cartouche.global_position.y > 7.9, "il est sur la terrasse")


# --- Énigme 4 : la sentinelle -----------------------------------------------------

const OUVERTURE := AABB(Vector3(31.7, 0, -1), Vector3(0.6, 3, 2))


## Ce que touche un rayon qui traverse l'entrée du camp, d'ouest en est.
func _a_travers_le_camp(n: Node3D, y: float, z: float) -> Object:
	var r := PhysicsRayQueryParameters3D.create(Vector3(28, y, z), Vector3(36, y, z))
	return n.get_world_3d().direct_space_state.intersect_ray(r).get("collider")


func test_entree_fermee_dans_les_deux_epoques() -> void:
	var n: Node3D = await _charger()
	var gardiens := {TempsScript.Epoque.PRESENT: n.get_node("Camp/Sentinelle"), TempsScript.Epoque.PASSE: n.get_node("Camp/PorteAntique")}
	for ep in gardiens:
		await _basculer_sans_joueur(ep)
		for y in [0.3, 1.5, 2.8]:
			for z in [-0.9, 0.0, 0.9]:
				T.eq(_a_travers_le_camp(n, y, z), gardiens[ep], "époque %d, y %.1f, z %.1f : l'entrée est fermée" % [ep, y, z])
	# L'enceinte n'a pas d'autre ouverture (en Antiquité, le camp est vide).
	await _basculer_sans_joueur(TempsScript.Epoque.PASSE)
	var espace := n.get_world_3d().direct_space_state
	for i in 36:
		var dir := Vector3(cos(TAU * i / 36.0), 0, sin(TAU * i / 36.0))
		for y in [0.5, 2.8]:
			var depart := Vector3(42, y, 0)
			var touche := espace.intersect_ray(PhysicsRayQueryParameters3D.create(depart, depart + dir * 30))
			T.ok(not touche.is_empty(), "l'enceinte est close (direction %d, y %.1f)" % [i, y])


## Vrai si un rayon horizontal de `depart` dans la direction `dir` touche
## quelque chose avant `longueur` m.
func _bloque(n: Node3D, depart: Vector3, dir: Vector3, longueur: float) -> bool:
	var r := PhysicsRayQueryParameters3D.create(depart, depart + dir * longueur)
	return not n.get_world_3d().direct_space_state.intersect_ray(r).is_empty()


func test_on_ne_saute_pas_du_mirador_dans_le_camp() -> void:
	var n: Node3D = await _charger()
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var vue: Node3D = n.get_node("Camp/PointDeVueAnkh")
	T.ok(vue.global_position.y >= 7.59, "plateforme à 6 m")
	# La cabine est fermée vers le camp et sur les côtés, jusqu'au toit ; entre
	# 0,3 et 1,8 m, une fente trop basse pour le joueur (1,8 m) laisse voir.
	var pied := vue.global_position - Vector3(0, 1.6, 0)
	for y in [0.3, 1.8]:
		for dir in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3(1, 0, 1).normalized(), Vector3(-1, 0, 1).normalized()]:
			T.ok(_bloque(n, pied + Vector3(0, y, 0), dir, 1.6), "cabine fermée (y %.1f, direction %s)" % [y, dir])
	# L'escalier a les côtés fermés.
	var escalier: Node3D = n.get_node("Camp/EscalierMirador")
	for f in [0.3, 0.6, 0.9]:
		var p := escalier.global_transform * Vector3(0, 6.0 * f + 0.5, -10.0 * f)
		for dir in [Vector3.LEFT, Vector3.RIGHT]:
			T.ok(_bloque(n, p, dir, 1.2), "escalier fermé à %d %%" % int(f * 100))
	# En haut, la bascule vers l'Antiquité est refusée (on tomberait sur le mur).
	for point in [pied, escalier.global_transform * Vector3(0, 3.3, -5.5)]:
		var boite := AABB(point - Vector3(0.35, 0, 0.35), Temps.TAILLE_JOUEUR).grow(-Temps.MARGE)
		T.ok(not TempsScript.bascule_possible(boite, O.solides_de(n, TempsScript.Epoque.PASSE)), "pas de bascule en %s" % point)
	var au_sol := AABB(Vector3(44, 0, -27) - Vector3(0.35, 0, 0.35), Temps.TAILLE_JOUEUR).grow(-Temps.MARGE)
	T.ok(TempsScript.bascule_possible(au_sol, O.solides_de(n, TempsScript.Epoque.PASSE)), "au pied de l'escalier, on bascule")


func test_l_ankh_s_aligne_du_mirador() -> void:
	var n: Node3D = await _charger()
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var j: Player = n.get_node("Player")
	var ankh: Alignement = n.get_node("Camp/Ankh")
	var vue: Node3D = n.get_node("Camp/PointDeVueAnkh")
	var morceaux := ankh.get_children().filter(func(x: Node) -> bool: return x is CSGPolygon3D)
	T.ok(morceaux.size() >= 6 and morceaux.size() <= 8, "%d morceaux" % morceaux.size())
	var espace := n.get_world_3d().direct_space_state
	for m: CSGPolygon3D in morceaux:
		# Peint sur une caisse : juste dessous, une caisse.
		var a_cote := m.global_position + Vector3(0.11, 0, 0.13)  # pas pile entre deux caisses
		var r := PhysicsRayQueryParameters3D.create(a_cote, a_cote + Vector3.DOWN * 0.3)
		var dessous: Object = espace.intersect_ray(r).get("collider")
		T.ok(dessous != null and String(dessous.name).begins_with("Caisse"), "%s est sur une caisse (%s)" % [m.name, dessous])
		# Vu du mirador, rien ne le cache, même pas une autre pile.
		var vus := 0
		for coin in m.polygon:
			# Le dessous du morceau, posé sur la caisse (il n'a pas de collision).
			var cible := m.global_transform * Vector3(coin.x * 0.9, coin.y * 0.9, -m.depth)
			var touche := espace.intersect_ray(PhysicsRayQueryParameters3D.create(vue.global_position, cible + (cible - vue.global_position).normalized() * 0.1))
			# Caché si le rayon touche quelque chose avant d'y arriver.
			var avant: float = vue.global_position.distance_to(touche.get("position", Vector3.INF))
			if avant >= vue.global_position.distance_to(cible) - 0.03:
				vus += 1
		T.eq(vus, m.polygon.size(), "%s : on voit tous ses coins du mirador" % m.name)
	j.teleport(Transform3D(Basis(), vue.global_position - Vector3(0, 1.6, 0)))
	O.viser(j, vue.global_position - vue.global_basis.z)
	await tree.physics_frame
	await tree.physics_frame
	ankh.verifier(j.camera)
	T.ok(ankh.est_resolu, "vu du mirador, l'ânkh est entier")
	T.ok(j.global_position.distance_to(vue.global_position - Vector3(0, 1.6, 0)) < 0.1, "le joueur tient debout sur le repère")


func test_le_camp_s_ouvre() -> void:
	var n: Node3D = await _charger()
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var s: Sentinelle = n.get_node("Camp/Sentinelle")
	T.ok(s.ecart.x > 0.0, "elle recule vers l'intérieur, loin du joueur")
	s.duree = 0.05
	(n.get_node("Camp/Ankh") as Alignement).resolu.emit()
	await tree.create_timer(0.3).timeout
	for ep in [TempsScript.Epoque.PRESENT, TempsScript.Epoque.PASSE]:
		await _basculer_sans_joueur(ep)
		for y in [0.3, 1.5, 2.8]:
			for z in [-0.9, 0.0, 0.9]:
				T.eq(_a_travers_le_camp(n, y, z), null, "époque %d, y %.1f, z %.1f : on entre" % [ep, y, z])
	await _basculer_sans_joueur(TempsScript.Epoque.PRESENT)
	var b: AABB = s.get_node("EpochMember").aabbs_solides()[0]
	T.ok(not b.intersects(OUVERTURE), "la sentinelle s'est rangée hors du passage")
	var cartouche: Cartouche = n.get_node("Camp/Cartouche")
	T.eq(cartouche.zone, "camp", "le cartouche du camp")
	T.eq(O.epoque(cartouche), -1, "il est là dans les deux époques")
	T.ok(cartouche.global_position.x > 45.0, "au fond de l'enceinte")
