extends RefCounted

## Les monuments égyptiens en formes simples (CSG), à la taille des modèles
## du Low Poly Egypt Pack, pour quand le pack n'est pas dans le dépôt (voir
## meubles.gd `egypte()`). La base de chaque forme est posée sur `pos`, et
## sa face regarde vers +Z.

var _m  # meubles (tools/meubles.gd)


func _init(meubles) -> void:
	_m = meubles


func construire(parent: Node, nom: String, modele_nom: String, pos: Vector3, rot_y := 0.0, echelle := 1.0, solide := true, epoque := -1) -> Node3D:
	var p: CSGCombiner3D = _m.prop(parent, nom, pos, rot_y, solide, epoque)
	p.scale = Vector3.ONE * echelle
	match modele_nom:
		"obelisk":
			_obelisque(p)
		"column_papyrus":
			_colonne(p)
		"hieroglyph_slab":
			_m.cube(p, Vector3(0, 1.1, 0), Vector3(1.4, 2.2, 0.34), "ocre")
			_m.cube(p, Vector3(0, 2.0, 0.18), Vector3(1.2, 0.12, 0.04), "lapis")
		"temple_gate_pylon":
			_pylone(p)
		"sphinx":
			_sphinx(p)
		"palm_tree":
			_palmier(p)
		"papyrus_reeds":
			for i in 5:
				var a := TAU * i / 5.0
				var h := 2.2 + 0.12 * i
				var pied := Vector3(cos(a), 0, sin(a)) * 0.22
				_m.cyl(p, pied + Vector3(0, h / 2, 0), 0.03, h, "papyrus", 5)
				_m.cyl(p, pied + Vector3(0, h + 0.15, 0), 0.14, 0.3, "palme", 6, true, Vector3(PI, 0, 0))
		"desert_rock":
			_m.cube(p, Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 1.3), "rocher", Vector3(0.1, 0.4, -0.08))
			_m.cube(p, Vector3(0.5, 1.05, 0.1), Vector3(0.9, 0.8, 0.9), "rocher", Vector3(-0.2, 0.9, 0.15))
		"pharaoh_statue":
			_m.cube(p, Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 1.6), "ocre_fonce")
			_m.cube(p, Vector3(0, 1.35, -0.1), Vector3(0.9, 1.7, 0.9), "ocre")
			_m.cube(p, Vector3(0, 2.6, -0.1), Vector3(0.5, 0.8, 0.5), "ocre")
			_m.cube(p, Vector3(0, 2.75, -0.2), Vector3(0.9, 0.9, 0.4), "lapis")
			_m.cube(p, Vector3(0, 3.4, -0.1), Vector3(0.35, 0.5, 0.35), "or")
		_:
			push_error("decor_egypte : pas de forme pour « %s »" % modele_nom)
	return p


## 6,7 m : socle, fût et pointe dorée.
func _obelisque(p: Node) -> void:
	_m.cube(p, Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.4), "ocre_fonce")
	_m.cube(p, Vector3(0, 3.1, 0), Vector3(0.9, 5.4, 0.9), "ocre")
	_m.cyl(p, Vector3(0, 6.25, 0), 0.64, 0.9, "or", 4, true, Vector3(0, PI / 4, 0))


## 4,9 m : colonne papyriforme, chapiteau évasé.
func _colonne(p: Node) -> void:
	_m.cyl(p, Vector3(0, 0.15, 0), 0.62, 0.3, "ocre_fonce", 10)
	_m.cyl(p, Vector3(0, 2.25, 0), 0.45, 3.9, "ocre", 10)
	_m.cyl(p, Vector3(0, 3.75, 0), 0.47, 0.25, "turquoise", 10)
	_m.cyl(p, Vector3(0, 4.3, 0), 0.66, 0.6, "ocre", 10, true, Vector3(PI, 0, 0))
	_m.cube(p, Vector3(0, 4.81, 0), Vector3(0.8, 0.24, 0.8), "ocre_fonce")


## 6 × 5,2 m : deux tours et un linteau, passage de 1,6 m au milieu.
func _pylone(p: Node) -> void:
	for x in [-1.9, 1.9]:
		_m.cube(p, Vector3(x, 2.4, 0), Vector3(2.2, 4.8, 1.6), "ocre")
		_m.cube(p, Vector3(x, 4.95, 0), Vector3(2.3, 0.3, 1.7), "ocre_fonce")
		_m.cube(p, Vector3(x, 3.6, 0.81), Vector3(1.6, 0.25, 0.02), "lapis")
	_m.cube(p, Vector3(0, 4.35, 0), Vector3(1.6, 0.9, 1.4), "ocre")
	_m.cube(p, Vector3(0, 4.35, 0.71), Vector3(0.7, 0.4, 0.02), "or")


## 2,4 × 2,6 × 6,4 m : socle, corps couché, pattes, tête et coiffe rayée.
func _sphinx(p: Node) -> void:
	_m.cube(p, Vector3(0, 0.25, 0), Vector3(2.4, 0.5, 6.4), "ocre_fonce")
	_m.cube(p, Vector3(0, 1.0, -0.9), Vector3(1.9, 1.0, 4.2), "ocre")
	for x in [-0.6, 0.6]:
		_m.cube(p, Vector3(x, 0.7, 2.25), Vector3(0.5, 0.4, 1.7), "ocre")
	_m.cube(p, Vector3(0, 1.8, 1.0), Vector3(1.3, 1.4, 0.9), "lapis")
	_m.cube(p, Vector3(0, 2.0, 1.3), Vector3(0.7, 0.9, 0.7), "ocre")
	_m.cube(p, Vector3(0, 2.55, 1.0), Vector3(0.9, 0.1, 0.9), "or")


## 4 m : tronc un peu penché, six palmes.
func _palmier(p: Node) -> void:
	_m.cyl(p, Vector3(0.15, 1.85, 0), 0.18, 3.7, "tronc", 6, false, Vector3(0, 0, -0.08))
	for i in 6:
		var a := TAU * i / 6.0
		var dir := Vector3(cos(a), 0, sin(a))
		_m.cube(p, Vector3(0.3, 3.75, 0) + dir * 0.75, Vector3(1.6, 0.08, 0.45), "palme", Vector3(0, -a, -0.35))
