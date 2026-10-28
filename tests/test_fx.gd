extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()
	Temps.reinitialiser()


func _fx() -> BasculeFx:
	var fx: BasculeFx = load("res://scenes/bascule_fx.tscn").instantiate()
	tree.root.add_child(fx)
	_noeuds.append(fx)
	return fx


func test_intensite_au_repos_puis_apres_bascule() -> void:
	Temps.reinitialiser()
	var fx := _fx()
	fx._process(1.0)
	T.eq(fx.intensite(), 0.0, "au repos")
	Temps.epoque_changee.emit(1)
	T.ok(fx.intensite() > 0.0, "juste après la bascule")
	fx._process(0.6)
	T.eq(fx.intensite(), 0.0, "fini après 0,5 s")


func test_secousse_si_bascule_refusee() -> void:
	var fx := _fx()
	Temps.bascule_refusee.emit()
	T.ok(fx.secousse() > 0.0, "secousse")
	fx._process(0.2)
	T.eq(fx.secousse(), 0.0, "finie après 0,15 s")


func test_couleurs_par_epoque() -> void:
	Temps.reinitialiser()
	var fx := _fx()
	var env := Environment.new()
	fx.environnement = env
	Temps.epoque_changee.emit(1)
	fx._process(1.0)
	T.eq(env.background_color, BasculeFx.PALETTES[1]["ciel"], "ciel du passé")
	T.eq(env.fog_light_color, BasculeFx.PALETTES[1]["ciel"], "brouillard de la couleur du ciel")


func test_palettes_du_niveau() -> void:
	Temps.reinitialiser()
	var fx := _fx()
	fx.palettes = {
		0: { "ciel": Color.RED, "ambiance": Color.BLUE },
		1: { "ciel": Color.GREEN, "ambiance": Color.YELLOW },
	}
	var env := Environment.new()
	fx.environnement = env
	T.eq(env.background_color, Color.RED, "ciel du niveau au présent")
	T.eq(env.ambient_light_color, Color.BLUE, "ambiance du niveau au présent")
	Temps.epoque_changee.emit(1)
	fx._process(1.0)
	T.eq(env.background_color, Color.GREEN, "ciel du niveau au passé")
