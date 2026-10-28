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
		# Jusqu'en haut des falaises (6 m) : on ne l'escalade pas avec le poisson.
		for y in [0.5, 1.5, 2.4, 3.5, 5.5]:
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


func test_poisson_perdu_dans_la_carriere() -> void:
	var n: Node3D = await _charger()
	var poisson: ObjetPerspectif = n.get_node("Carriere/Poisson")
	var depart := poisson.global_position
	# Lancé par-dessus le spinosaure ou les falaises, il ne doit pas rester
	# dans la carrière fermée : on ne pourrait plus le reprendre.
	for p in [Vector3(-52.7, 0.9, 0.5), Vector3(-49, 0.9, 2.5), Vector3(-45, 6.5, -13)]:
		poisson.global_position = p
		await tree.physics_frame
		await tree.physics_frame
		T.ok(poisson.global_position.distance_to(depart) < 1.0, "en %s, il revient au bord du Nil" % p)
	# Posé sur la pierre plate, il reste là.
	poisson.global_position = n.get_node("Carriere/ZoneAppat").global_position
	await tree.physics_frame
	await tree.physics_frame
	T.ok(poisson.global_position.distance_to(depart) > 5.0, "sur la pierre plate, il reste")


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


## Le joueur monte la rampe au clavier, de son pied à la terrasse, en
## basculant aux bons endroits : 1942 pour les trous, l'Antiquité pour les sacs.
func test_traversee_de_la_rampe_au_clavier() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	var t3 := _aabb(n.get_node("Rampe/Troncon3"))
	var t5 := _aabb(n.get_node("Rampe/Troncon5"))
	var terrasse := _aabb(n.get_node("Rampe/Terrasse"))
	var a := _sacs(n, "SacsA")
	var b := _sacs(n, "SacsB")
	var etapes := [
		[(t3.end.z + a.end.z) / 2, TempsScript.Epoque.PASSE],
		[(a.position.z + t3.position.z) / 2, TempsScript.Epoque.PRESENT],
		[(t5.end.z + b.end.z) / 2, TempsScript.Epoque.PASSE],
	]
	j.teleport(Transform3D(Basis(), Vector3(0, 0, -15)))
	await tree.physics_frame
	T.ok(Temps.basculer(j), "au pied de la rampe, on passe en 1942")
	Input.action_press("avancer")
	var arrive := false
	for i in 900:
		await tree.physics_frame
		var z := j.global_position.z
		if not etapes.is_empty() and z < etapes[0][0]:
			T.ok(Temps.basculer(j), "bascule en z = %.1f" % z)
			T.eq(Temps.courante, etapes[0][1], "époque après la bascule en z = %.1f" % z)
			etapes.pop_front()
		if z < terrasse.end.z - 1.0:
			arrive = true
			break
	Input.action_release("avancer")
	T.ok(arrive, "on arrive sur la terrasse (z = %.1f, y = %.1f)" % [j.global_position.z, j.global_position.y])
	T.ok(j.global_position.y > 7.8, "à 8 m de haut")


func test_on_ne_marche_pas_sur_les_parapets() -> void:
	var n: Node3D = await _charger()
	# En Antiquité (sans les sacs) : au-dessus des parapets des tronçons à
	# sacs de sable, un mur invisible empêche d'y sauter pour les contourner.
	for nom in ["Troncon3", "Troncon5"]:
		var b := _aabb(n.get_node("Rampe/" + nom))
		for k in 5:
			var z := lerpf(b.end.z - 0.5, b.position.z + 0.5, k / 4.0)
			var sol: Vector3 = _sous(n, 0, z).position
			for cote in [-1, 1]:
				for dy in [1.4, 2.5]:
					T.ok(_bloque(n, sol + Vector3(0, dy, 0), Vector3(cote, 0, 0), 2.0), "%s, z %.1f, côté %d, %.1f m : le parapet est fermé au-dessus" % [nom, z, cote, dy])


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


# --- Énigme 5 : le temple qui boucle ---------------------------------------------

## L'intérieur de la salle des colonnes (6 m de large, 20 m de long, 5 m de haut).
const SALLE := AABB(Vector3(27, 0, 32), Vector3(20, 5, 6))
## Tout le temple, murs, pylône et sanctuaire compris.
const TEMPLE := AABB(Vector3(24.4, 0, 31.4), Vector3(29.8, 5.5, 7.2))
## Le passage du pylône, dans le mur de l'entrée.
const ENTREE_TEMPLE := AABB(Vector3(26.4, 0, 34.0), Vector3(0.6, 4.6, 2.0))
const AXE_TEMPLE := Vector3(1, 0, 0)
const SYMBOLES := ["Scarabee", "Oeil", "Ankh", "Plume", "Soleil", "Serpent"]


func _zone(porte: PorteTrompeuse) -> AABB:
	var forme: CollisionShape3D = porte.get_child(0)
	var taille := (forme.shape as BoxShape3D).size
	return forme.global_transform * AABB(-taille / 2, taille)


## Vrai si le joueur, debout en `p`, serait dans un mur ou une colonne.
func _coince(n: Node3D, j: Player, p: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.transform = Transform3D(Basis(), p + Vector3(0, 0.95, 0))
	q.exclude = [j.get_rid()]
	return not n.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func test_temple_boucle() -> void:
	var n: Node3D = await _charger()
	var porte: PorteTrompeuse = n.get_node("Temple/Boucle")
	var scarabee: Node3D = n.get_node("Temple/DalleScarabee")
	var oeil := porte.global_position + Vector3(0, 1.6, 0)
	T.eq(_destination(porte, AXE_TEMPLE, scarabee.global_position), "Debut", "tout droit : retour au début de la salle")
	for s in SYMBOLES:
		var d: Node3D = n.get_node("Temple/Dalle" + s)
		T.ok(d.get_node_or_null("Symbole") is CSGShape3D, "%s porte son symbole" % d.name)
		var attendu := "Sanctuaire" if s == "Scarabee" else "Debut"
		T.eq(_destination(porte, (d.global_position - oeil).normalized(), scarabee.global_position), attendu, "en regardant %s" % d.name)
	T.ok(scarabee.global_position.x >= SALLE.position.x + SALLE.size.x * 2.0 / 3.0 and scarabee.global_position.x <= SALLE.end.x, "le scarabée est dans le dernier tiers")
	T.ok(minf(absf(scarabee.global_position.z - SALLE.position.z), absf(scarabee.global_position.z - SALLE.end.z)) < 0.6, "sur un mur latéral")
	var debut: Node3D = n.get_node("Temple/Debut")
	T.ok(debut.global_position.x < SALLE.position.x + 2.0, "Debut est à l'entrée de la salle")
	T.ok(debut.global_basis.is_equal_approx(porte.global_basis), "on repart dans le même sens")
	# En vrai : le joueur arrive à la porte (sans encore la toucher), tout
	# droit ou en regardant le scarabée. Entre les dernières colonnes, il
	# passe de z = 34,1 à 35,9.
	var j: Player = n.get_node("Player")
	for z in [34.1, 35.0, 35.9]:
		for vise in [false, true]:
			var avant := Vector3(porte.global_position.x - 0.6, 0, z)
			j.remove_meta("arrivee_ms")
			j.teleport(Transform3D(Basis(Vector3.UP, -PI / 2), avant))
			j.head.rotation.x = 0.0
			await tree.physics_frame
			if vise:
				O.viser(j, scarabee.global_position)
			porte._corps_entre(j)
			var p := j.global_position
			if vise:
				T.ok(p.distance_to(avant) < 0.05, "z %.1f, en regardant le scarabée : on passe (%s)" % [z, p])
			else:
				T.ok(p.distance_to(Vector3(debut.global_position.x - 0.6, 0, z)) < 0.05, "z %.1f, tout droit : retour au début (%s)" % [z, p])
				T.ok(not _coince(n, j, p), "z %.1f : on n'arrive pas dans une colonne" % z)
	var cartouche: Cartouche = n.get_node("Temple/Cartouche")
	T.eq(cartouche.zone, "temple", "le cartouche du temple")
	T.ok(cartouche.global_position.x > SALLE.end.x and TEMPLE.has_point(cartouche.global_position + Vector3(0, 1, 0)), "il est dans le sanctuaire")


func test_carte_seulement_en_1942() -> void:
	var n: Node3D = await _charger()
	var carte: Node3D = n.get_node("Temple/CarteSoldats")
	T.eq(O.epoque(carte), TempsScript.Epoque.PRESENT, "la carte des soldats n'existe qu'en 1942")
	var textes := O.tous(carte, func(x: Node) -> bool: return x is Label3D and "le scarabée" in (x as Label3D).text)
	T.eq(textes.size(), 1, "« Pour sortir : le scarabée »")
	T.ok(carte.get_node_or_null("Scarabee") != null and carte.get_node_or_null("Cercle") != null, "le scarabée entouré de rouge")
	T.ok(String(carte.get_parent().name) == "Temple" and SALLE.has_point(carte.global_position), "punaisée dans la salle")
	var dalles := O.tous(n.get_node("Temple"), func(x: Node) -> bool: return String(x.name).begins_with("Dalle"))
	T.eq(dalles.size(), SYMBOLES.size(), "six dalles")
	for d in dalles:
		T.eq(O.tous(d, func(x: Node) -> bool: return x is EpochMember).size(), 0, "%s est là dans les deux époques" % d.name)


## Vrai si le rayon de `a` vers `dir` (normé) sort du temple ailleurs que par
## l'entrée ou par la porte qui boucle.
func _fuite(espace: PhysicsDirectSpaceState3D, a: Vector3, dir: Vector3, porte: AABB) -> bool:
	var touche := espace.intersect_ray(PhysicsRayQueryParameters3D.create(a, a + dir * 80))
	var dist := INF
	if not touche.is_empty():
		var p: Vector3 = touche.position
		if TEMPLE.grow(0.05).has_point(p):
			return false
		dist = a.distance_to(p)
	for passage: AABB in [porte, ENTREE_TEMPLE]:
		if absf(dir.x) < 1e-4:
			continue
		var t := (passage.get_center().x - a.x) / dir.x
		var c := a + dir * t
		if t > 0 and t < dist and c.y >= passage.position.y and c.y <= passage.end.y and c.z >= passage.position.z and c.z <= passage.end.z:
			return false
	return true


func test_salle_fermee() -> void:
	var n: Node3D = await _charger()
	var porte := _zone(n.get_node("Temple/Boucle"))
	T.ok(porte.position.z <= SALLE.position.z and porte.end.z >= SALLE.end.z, "la porte couvre toute la largeur")
	T.ok(porte.position.y <= 0.0 and porte.end.y >= SALLE.end.y, "et toute la hauteur")
	var espace := n.get_world_3d().direct_space_state
	var fuites: Array[String] = []
	var departs := [Vector3(28.3, 0, 35), Vector3(32.5, 0, 35), Vector3(36.5, 0, 34.5), Vector3(40.5, 0, 33), Vector3(42.95, 0, 35),
		Vector3(44.5, 0, 35), Vector3(46.5, 0, 32.6), Vector3(46.5, 0, 37.4), Vector3(50.5, 0, 33), Vector3(52.5, 0, 37)]
	for depart: Vector3 in departs:
		for y in [0.3, 1.7, 3.5, 4.8]:
			for i in 24:
				for elev in [0.0, 0.6]:
					var dir := Vector3(cos(TAU * i / 24.0) * cos(elev), sin(elev), sin(TAU * i / 24.0) * cos(elev))
					if _fuite(espace, depart + Vector3(0, y, 0), dir, porte):
						fuites.append("%s y %.1f dir %d/%.1f" % [depart, y, i, elev])
		if _fuite(espace, depart + Vector3(0, 1, 0), Vector3.UP, porte):
			fuites.append("%s vers le haut" % depart)
	T.ok(fuites.is_empty(), "pas d'autre sortie (%d fuites : %s)" % [fuites.size(), ", ".join(fuites.slice(0, 6))])


# --- Énigme 6 : la pyramide --------------------------------------------------------

const FIN_TEXTE := "Époque réparée ! Bientôt : le château…"


func _message(n: Node3D) -> String:
	return (n.get_node("Interface/Message") as Label).text


## Pose le joueur sur la tête du sphinx et le fait regarder la pyramide.
func _au_point_de_vue(n: Node3D) -> Player:
	var j: Player = n.get_node("Player")
	var vue: Node3D = n.get_node("Chantier/PointDeVue")
	j.teleport(Transform3D(Basis(), vue.global_position - Vector3(0, 1.6, 0)))
	j.velocity = Vector3.ZERO
	O.viser(j, vue.global_position - vue.global_basis.z)
	for i in 4:
		await tree.physics_frame
	return j


## Pose le joueur dans le passage de la fin.
func _dans_la_fin(n: Node3D, j: Player) -> void:
	var fin: Node3D = n.get_node("Chantier/Fin")
	j.teleport(Transform3D(Basis(), fin.global_position))
	j.velocity = Vector3.ZERO
	for i in 4:
		await tree.physics_frame


func test_on_monte_sur_le_sphinx() -> void:
	var n: Node3D = await _charger()
	var escalier: Node3D = n.get_node("Chantier/EscalierSphinx")
	var vue: Node3D = n.get_node("Chantier/PointDeVue")
	var pied := vue.global_position - Vector3(0, 1.6, 0)
	# Le long de l'escalier, puis tout droit jusqu'au point de vue : une montée
	# sans marche, puis un palier à la hauteur de la tête.
	var points: Array[Vector3] = []
	var haut := escalier.global_transform * Vector3(0, 0, -20)
	for k in 60:
		var p := escalier.global_transform * Vector3(0, 0, 0.5 - 0.25 * k)
		var sol: Dictionary = _sous(n, p.x, p.z)
		if not sol.is_empty() and sol.position.y > pied.y - 0.05:
			haut = p
			break
		points.append(p)
	var plat := Vector3(pied.x - haut.x, 0, pied.z - haut.z)
	for k in int(plat.length() / 0.25) + 1:
		points.append(haut + plat.normalized() * 0.25 * k)
	var y_avant := 0.0
	var marches: Array[String] = []
	for p in points:
		var sol: Dictionary = _sous(n, p.x, p.z)
		var y: float = sol.position.y if not sol.is_empty() else -INF
		if y - y_avant > 0.2 or y < y_avant - 0.05:
			marches.append("%s : %.2f → %.2f" % [p, y_avant, y])
		y_avant = y
	T.ok(marches.is_empty(), "montée sans marche jusqu'à la tête : %s" % ", ".join(marches.slice(0, 4)))
	T.ok(absf(y_avant - pied.y) < 0.05, "on arrive au point de vue (%.2f)" % y_avant)
	T.ok(vue.global_position.z > 15.0 and absf(vue.global_position.x) < 1.0, "le sphinx est au sud du chantier")


func test_chaque_degre_a_sa_zone() -> void:
	var n: Node3D = await _charger()
	var pyramide: Alignement = n.get_node("Chantier/Pyramide")
	var vue: Node3D = n.get_node("Chantier/PointDeVue")
	var hauteurs := {}
	var hors_rayon: Array[String] = []
	for b in pyramide.get_children():
		if not b is CSGShape3D:
			continue
		var image: Vector3 = b.get_meta("image")
		var zone: String = b.get_meta("zone", "")
		if not hauteurs.has(zone):
			hauteurs[zone] = []
		hauteurs[zone].append(image.y)
		var d := rad_to_deg((b.global_position - vue.global_position).angle_to(image - vue.global_position))
		if d > 0.1:
			hors_rayon.append(b.name)
		T.ok(_aabb(b).position.y > 0.2, "%s flotte au-dessus du sol" % b.name)
	T.eq(hauteurs.size(), 4, "quatre zones")
	for zone: String in Chantier.ZONES:
		T.eq(hauteurs.get(zone, []).size(), 10, "10 blocs pour %s" % zone)
	for i in 3:
		var bas: Array = hauteurs.get(Chantier.ZONES[i], [0.0])
		var dessus: Array = hauteurs.get(Chantier.ZONES[i + 1], [0.0])
		T.ok(bas.max() < dessus.min(), "%s est sous %s" % [Chantier.ZONES[i], Chantier.ZONES[i + 1]])
	T.ok(hors_rayon.is_empty(), "chaque bloc est sur son rayon : %s" % ", ".join(hors_rayon))


func test_pyramide_incomplete() -> void:
	var n: Node3D = await _charger()
	var nuage: Chantier = n.get_node("Chantier/Nuage")
	for zone in ["carriere", "rampe", "camp"]:
		nuage.zone_reussie(zone)
	var j := await _au_point_de_vue(n)
	T.eq(_message(n), "Il manque encore des blocs…", "au belvédère avec 3 groupes")
	var pyramide: Alignement = n.get_node("Chantier/Pyramide")
	pyramide.verifier(j.camera)
	T.ok(not pyramide.est_resolu, "pas d'alignement avec 3 groupes")
	T.ok(not (n.get_node("Chantier/PyramideSolide") as CSGShape3D).visible, "pas encore de pyramide")
	await _dans_la_fin(n, j)
	T.ok(_message(n) != FIN_TEXTE, "la fin ne marche pas avant la pyramide")


func test_parcours_complet() -> void:
	var n: Node3D = await _charger()
	n.set("duree_recollage", 0.05)
	n.set("duree_porte", 0.05)
	var nuage: Chantier = n.get_node("Chantier/Nuage")
	nuage.duree_vol = 0.05
	var j: Player = n.get_node("Player")
	for g in ["Carriere", "Rampe", "Camp", "Temple"]:
		(n.get_node(g + "/Cartouche") as Cartouche)._corps_entre(j)
	T.eq(nuage.revenus(), 4, "les 4 groupes reviennent")
	T.eq(_message(n), "Un groupe de blocs rejoint la pyramide ! (4/4)", "message du 4e groupe")
	await tree.create_timer(0.3).timeout
	T.ok(nuage.est_complet(), "le nuage est complet")
	T.eq(_message(n), "Tous les blocs sont là ! Regarde-les depuis la tête du sphinx.", "on dit où aller")
	j = await _au_point_de_vue(n)
	var pyramide: Alignement = n.get_node("Chantier/Pyramide")
	pyramide.verifier(j.camera)
	T.ok(pyramide.est_resolu, "vue du sphinx, la pyramide est alignée")
	await tree.create_timer(0.5).timeout
	var solide: CSGShape3D = n.get_node("Chantier/PyramideSolide")
	T.ok(solide.visible and solide.use_collision, "la pyramide est visible et solide")
	T.ok(_bloque(n, Vector3(5, 1, 12), Vector3.FORWARD, 8), "on bute sur la pyramide")
	T.ok(not _bloque(n, Vector3(0, 1, 12), Vector3.FORWARD, 6), "la porte est ouverte")
	T.eq(_message(n), "La réalité se recolle…", "message de la pyramide")
	await _dans_la_fin(n, j)
	T.eq(_message(n), FIN_TEXTE, "message de fin")


func test_la_pyramide_n_enferme_pas_le_joueur() -> void:
	var n: Node3D = await _charger()
	var j: Player = n.get_node("Player")
	for p in [Vector3(3, 0.06, -3), Vector3(-6, 2.56, 1)]:
		j.teleport(Transform3D(Basis(), p))
		n.call("_pyramide_solide")
		await tree.physics_frame
		await tree.physics_frame
		T.ok(j.global_position.z > 8.3 and j.global_position.y < 0.5, "en %s : posé devant la pyramide (%s)" % [p, j.global_position])
		T.ok(not _coince(n, j, j.global_position), "en %s : le joueur n'est pas coincé" % p)


func test_messages_des_enigmes() -> void:
	var n: Node3D = await _charger()
	(n.get_node("Carriere/Spinosaure") as Spinosaure).renifle.emit()
	T.eq(_message(n), "Trop petit…", "le spinosaure renifle")
	(n.get_node("Camp/Sentinelle") as Sentinelle).refuse.emit()
	T.eq(_message(n), "Halte ! Le mot de passe ?", "la sentinelle refuse")
