extends RefCounted

const TempsScript := preload("res://scripts/time/temps.gd")

var tree: SceneTree
var _noeuds: Array[Node] = []
var _recus: Array = []


func _ajouter(n: Node) -> Node:
	tree.root.add_child(n)
	_noeuds.append(n)
	return n


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()
	Temps.reinitialiser()


func _boite_du_passe(pos: Vector3) -> CSGBox3D:
	var boite := CSGBox3D.new()
	boite.size = Vector3(2, 2, 2)
	boite.use_collision = true
	boite.position = pos
	var membre := EpochMember.new()
	membre.name = "EpochMember"
	membre.epoque = TempsScript.Epoque.PASSE
	boite.add_child(membre)
	_ajouter(boite)
	return boite


func test_basculer_passe_au_passe() -> void:
	Temps.reinitialiser()
	var joueur: Node3D = _ajouter(Node3D.new())
	Temps.epoque_changee.connect(func(e: int) -> void: _recus.append(e))
	T.ok(Temps.basculer(joueur), "bascule acceptée")
	T.eq(Temps.courante, TempsScript.Epoque.PASSE, "on est dans le passé")
	T.eq(_recus, [TempsScript.Epoque.PASSE], "signal epoque_changee(1)")
	Temps.basculer(joueur)
	T.eq(Temps.courante, TempsScript.Epoque.PRESENT, "retour au présent")


func test_reinitialiser_dans_le_passe() -> void:
	Temps.reinitialiser(Temps.Epoque.PASSE)
	T.eq(Temps.courante, Temps.Epoque.PASSE, "on démarre dans le passé")
	Temps.reinitialiser()
	T.eq(Temps.courante, Temps.Epoque.PRESENT, "par défaut, le présent")


func test_membre_du_passe_cache_au_present() -> void:
	Temps.reinitialiser()
	var boite := _boite_du_passe(Vector3(10, 0, 0))
	T.ok(not boite.visible, "caché au présent")
	T.ok(not boite.use_collision, "pas solide au présent")
	Temps.basculer(_ajouter(Node3D.new()))
	T.ok(boite.visible, "visible dans le passé")
	T.ok(boite.use_collision, "solide dans le passé")


func test_bascule_possible_pure() -> void:
	var joueur := AABB(Vector3(0, 0, 0), Vector3(0.7, 1.8, 0.7))
	var loin: Array[AABB] = [AABB(Vector3(5, 0, 5), Vector3(1, 1, 1))]
	var dedans: Array[AABB] = [AABB(Vector3(0, 0, 0), Vector3(1, 1, 1))]
	T.ok(TempsScript.bascule_possible(joueur, loin), "rien autour : possible")
	T.ok(not TempsScript.bascule_possible(joueur, dedans), "mur sur le joueur : refusé")


func test_bascule_refusee_si_mur_apparait_sur_le_joueur() -> void:
	Temps.reinitialiser()
	_boite_du_passe(Vector3(0, 1, 0))
	await tree.process_frame
	var joueur: Node3D = _ajouter(Node3D.new())
	joueur.global_position = Vector3(0, 0, 0)
	var refus := [0]
	Temps.bascule_refusee.connect(func() -> void: refus[0] += 1)
	T.ok(not Temps.basculer(joueur), "bascule refusée")
	T.eq(Temps.courante, TempsScript.Epoque.PRESENT, "on reste au présent")
	T.eq(refus[0], 1, "signal bascule_refusee")


func test_decor_non_solide_ne_bloque_pas_la_bascule() -> void:
	Temps.reinitialiser()
	var deco := CSGBox3D.new()
	deco.size = Vector3(2, 2, 2)
	deco.position = Vector3(0, 1, 0)
	deco.use_collision = false
	var membre := EpochMember.new()
	membre.epoque = TempsScript.Epoque.PASSE
	deco.add_child(membre)
	_ajouter(deco)
	await tree.process_frame
	var joueur: Node3D = _ajouter(Node3D.new())
	T.ok(Temps.basculer(joueur), "un décor sans collision ne bloque pas la bascule")


func test_decor_non_solide_reste_non_solide() -> void:
	Temps.reinitialiser()
	var boite := CSGBox3D.new()
	boite.use_collision = false
	var membre := EpochMember.new()
	membre.epoque = TempsScript.Epoque.PASSE
	boite.add_child(membre)
	_ajouter(boite)
	Temps.basculer(_ajouter(Node3D.new()))
	T.ok(boite.visible, "visible dans le passé")
	T.ok(not boite.use_collision, "toujours sans collision")
