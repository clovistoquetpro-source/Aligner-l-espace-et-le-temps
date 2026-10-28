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
