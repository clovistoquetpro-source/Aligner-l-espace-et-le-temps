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
