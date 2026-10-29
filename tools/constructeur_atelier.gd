extends "res://tools/constructeur_souvenir.gd"

## Construit scenes/atelier.tscn, le niveau 5 en formes simples (« L'atelier
## du peintre », puis dehors), lancé par construire_atelier.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Plan, vu de dessus (-Z vers le haut) :
##
##                  Le cœur (le chevalet, la dernière toile)
##                        |
##          Le labyrinthe des mille toiles (5 × 5 cases de 3 m)
##                        |
##          L'antichambre (le peintre, de dos, à l'entrée)
##
## Dehors, la nature, en x = 1000.

const COULEURS := {
	"sol": "3d3029", "mur": "4a4e69", "plafond": "2b2d42", "cadre": "b08d57", "cadre_toile": "b08d57", "toile": "e9dcc9",
	"route": "6c757d", "pluie_ciel": "4a4e69", "mob": "e63946", "robe": "f6bd60", "peau": "f2c6a0",
	"cheveux": "7f4f24", "blouse": "dcdcdc", "beret": "d1495b", "cheveux_gris": "c0c0c0",
	"pantalon": "2b2d42", "chevalet": "6f4518", "petale": "ff8fab", "fenetre": "a8dadc",
	"lac": "4ea8de", "ile": "2d6a4f", "nuit": "1b1f4a", "etoile": "fff3b0", "porte": "7a5c45",
	"poignee": "d4af37", "lumiere_porte": "fff1c9", "pinceau": "8d6346", "poils": "e63946",
	"main": "e0b48e", "herbe": "7cb518", "chemin": "e9d8a6", "tronc": "7f5539", "feuillage": "52b788",
	"feuillage_2": "95d5b2", "colline": "8ab17d", "banc": "a47148", "fleur_1": "ff006e", "fleur_2": "ffbe0b",
	"fleur_3": "fb5607", "fleur_4": "8338ec", "fleur_5": "3a86ff", "papillon_1": "ffbe0b", "papillon_2": "ff006e",
	"papillon_3": "3a86ff", "habit_1": "e76f51", "habit_2": "2a9d8f", "habit_3": "f4a261", "cerf_volant": "e63946",
	"tige": "386641",
}

## Couche visible seulement les yeux fermés : ce qui est vrai.
const COUCHE_VRAI := 8
const H := 3.2
const CASE := 3.0
const N := 5
## Les passages entre les cases du labyrinthe : [[i, j], [i, j]]. Le vrai
## chemin va de (2, 0) (l'entrée, au sud) à (4, 4) (la sortie, au nord).
const CHEMIN := [[2, 0], [2, 1], [1, 1], [0, 1], [0, 2], [0, 3], [1, 3], [2, 3], [3, 3], [3, 2], [4, 2], [4, 3], [4, 4]]
const IMPASSES := [
	[[2, 1], [3, 1]], [[3, 1], [4, 1]], [[4, 1], [4, 0]], [[3, 1], [3, 0]], [[2, 0], [1, 0]], [[1, 0], [0, 0]],
	[[1, 1], [1, 2]], [[1, 2], [2, 2]], [[0, 3], [0, 4]], [[0, 4], [1, 4]], [[1, 4], [2, 4]], [[2, 4], [3, 4]],
]
const COEUR := Vector3(6, 0, -20)
const DEHORS := Vector3(1000, 0, 0)


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Atelier"
	_racine.set_script(load("res://scripts/niveau/atelier.gd"))
	_environnement()
	_antichambre()
	_labyrinthe()
	_coeur()
	_dehors()
	_joueur_et_interface(Vector3(0, 0, 10), 0.0)
	_racine.get_node("BasculeFx").free()
	var ui := _racine.get_node("Interface")
	for r in [["Blanc", Color(1, 1, 1, 0.0)]]:
		var c := ColorRect.new()
		c.color = r[1]
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ajouter(ui, c, r[0])
	_ajouter(ui, Fissures.new(), "Fissures")
	_interface_souvenir()
	var generique := Label.new()
	generique.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	generique.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	generique.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	generique.add_theme_font_size_override("font_size", 34)
	generique.add_theme_color_override("font_color", Color.WHITE)
	generique.text = "Aligner l'espace et le temps\n\n\nUne histoire imaginée par clo\n\n\nFin"
	generique.visible = false
	generique.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, generique, "Generique")
	return _enregistrer("res://scenes/atelier.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["petale", "lumiere_porte", "etoile", "fenetre"]


func _motifs() -> Dictionary:
	return {
		# La route sous la pluie, Juliette qui part à mobylette.
		"pluie": { "fond": "pluie_ciel", "formes": [
			[0.0, 0.0, 1.0, 0.35, "route"], [0.55, 0.28, 0.16, 0.12, "mob"], [0.6, 0.38, 0.06, 0.16, "robe"],
			[0.61, 0.53, 0.05, 0.06, "peau"], [0.15, 0.6, 0.01, 0.3, "toile"], [0.35, 0.7, 0.01, 0.25, "toile"],
			[0.8, 0.55, 0.01, 0.3, "toile"],
		]},
		# La version parfaite : Juliette reste, à la fenêtre.
		"fenetre": { "fond": "mur", "formes": [
			[0.3, 0.3, 0.4, 0.5, "fenetre"], [0.45, 0.2, 0.1, 0.35, "robe"], [0.46, 0.55, 0.08, 0.1, "peau"],
		]},
		# Le vrai souvenir : Juliette qui rit, au bord du lac, la nuit.
		"lac": { "fond": "nuit", "formes": [
			[0.0, 0.0, 1.0, 0.4, "lac"], [0.25, 0.38, 0.5, 0.08, "ile"], [0.45, 0.4, 0.1, 0.3, "robe"],
			[0.46, 0.7, 0.08, 0.1, "peau"], [0.43, 0.72, 0.14, 0.1, "cheveux"], [0.1, 0.8, 0.02, 0.03, "etoile"],
			[0.8, 0.85, 0.02, 0.03, "etoile"], [0.65, 0.65, 0.02, 0.03, "etoile"],
		]},
	}


## L'atelier est sombre : un fond noir (les yeux fermés, on ne voit que ce
## qui est vrai, sur du noir). Dehors, le niveau change d'environnement.
func _environnement() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b0b12")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9b8a6")
	env.ambient_light_energy = 0.2
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")


func _forme(parent: Node, nom: String, forme: Shape3D, pos := Vector3.ZERO) -> CollisionShape3D:
	var c := CollisionShape3D.new()
	c.shape = forme
	c.position = pos
	return _ajouter(parent, c, nom)


func _boite_forme(taille: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = taille
	return b


## Une boîte dessinée seulement (un maillage, plus léger qu'une boîte CSG).
func _deco(parent: Node, nom: String, pos: Vector3, taille: Vector3, couleur: String) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = taille
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(couleur)
	return _ajouter(parent, mi, nom)


## Le vieux peintre : blouse, béret rouge, cheveux gris, un peu voûté.
func _peintre(parent: Node3D, nom: String) -> Node3D:
	var p := Node3D.new()
	_ajouter(parent, p, nom)
	var bas := CylinderMesh.new()
	bas.top_radius = 0.2
	bas.bottom_radius = 0.22
	bas.height = 0.8
	var b := MeshInstance3D.new()
	b.mesh = bas
	b.position = Vector3(0, 0.4, 0)
	b.material_override = _mat("pantalon")
	_ajouter(p, b, "Jambes")
	var blouse := CylinderMesh.new()
	blouse.top_radius = 0.3
	blouse.bottom_radius = 0.42
	blouse.height = 0.8
	var bl := MeshInstance3D.new()
	bl.mesh = blouse
	bl.position = Vector3(0, 1.1, 0.05)
	bl.rotation.x = 0.15
	bl.material_override = _mat("blouse")
	_ajouter(p, bl, "Blouse")
	var tete := SphereMesh.new()
	tete.radius = 0.13
	tete.height = 0.26
	var t := MeshInstance3D.new()
	t.mesh = tete
	t.position = Vector3(0, 1.6, -0.05)
	t.material_override = _mat("peau")
	_ajouter(p, t, "Tete")
	_deco(p, "Cheveux", Vector3(0, 1.62, 0.04), Vector3(0.27, 0.16, 0.2), "cheveux_gris")
	_deco(p, "Beret", Vector3(0.03, 1.74, -0.03), Vector3(0.3, 0.06, 0.3), "beret")
	var bras := _deco(p, "Bras", Vector3(0.3, 1.3, -0.25), Vector3(0.1, 0.1, 0.5), "blouse")
	bras.rotation.x = 0.6
	_deco(p, "Pinceau", Vector3(0.32, 1.5, -0.5), Vector3(0.02, 0.02, 0.35), "pinceau")
	return p


# --- L'antichambre -----------------------------------------------------------


## Une grande salle sombre, des toiles posées partout. Le peintre, de dos,
## face à l'entrée du labyrinthe. Des toiles de plus, cachées, apparaissent
## à chaque tentative de peindre.
func _antichambre() -> void:
	var g := _groupe("Antichambre")
	_sol_plafond(g, -6.3, 6.3, 0.0, 12.3, H, "sol", "plafond")
	_mur(g, "Mur_sud", true, 12.15, -6.3, 6.3, H, "mur")
	_mur(g, "Mur_ouest", false, -6.15, 0.0, 12.0, H, "mur")
	_mur(g, "Mur_est", false, 6.15, 0.0, 12.0, H, "mur")
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 1000
	for i in 10:
		var cote := -1 if i % 2 == 0 else 1
		var t := _toile(g, "Toile_%d" % i, Vector3(cote * 5.95, 1.2 + 0.6 * (i % 3), 2.0 + 1.0 * i), cote * -PI / 2, Vector2(1.2, 0.9), "pluie")
		t.rotation.z = hasard.randf_range(-0.15, 0.15)
	for k in 4:
		var pile := Node3D.new()
		pile.visible = false
		_ajouter(g, pile, "Tentative_%d" % (k + 1))
		for i in 6:
			var p := Vector3(hasard.randf_range(-5.0, 5.0), 0.5 + 0.1 * i, hasard.randf_range(3.0, 11.0))
			var t := _toile(pile, "Toile_%d" % i, p, hasard.randf_range(-PI, PI), Vector2(1.0, 0.75), "pluie")
			t.rotation.x = hasard.randf_range(-0.5, -0.2)
	var peintre := _peintre(g, "Peintre")
	peintre.position = Vector3(0, 0, 1.4)
	_zone(g, "Approche", Vector3(0, 1.0, 2.6), Vector3(2.4, 2.0, 1.4))
	_marque(g, "Place_du_peintre", Vector3(0, 0, 1.4), 0.0)
	_lampe(g, "Lampe", Vector3(0, 2.9, 5.0), 9.0, true, 0.9)
	_pensee(g, "PenseeToiles", Vector3(-5.95, 1.6, 4.0), "Des toiles… toutes les mêmes.", 6.0, 25.0)
	_pensee(g, "PenseePeintre", Vector3(0, 1.6, 1.4), "Quelqu'un peint, là-bas.", 9.0, 15.0)


# --- Le labyrinthe des mille toiles ------------------------------------------


static func centre_case(i: int, j: int) -> Vector3:
	return Vector3(-6.0 + CASE * i, 0, -1.5 - CASE * j)


func _ouvert(a: Array, b: Array) -> bool:
	for k in range(CHEMIN.size() - 1):
		if (CHEMIN[k] == a and CHEMIN[k + 1] == b) or (CHEMIN[k] == b and CHEMIN[k + 1] == a):
			return true
	for p in IMPASSES:
		if (p[0] == a and p[1] == b) or (p[0] == b and p[1] == a):
			return true
	return false


## Chaque mur est une toile (la même route sous la pluie), peinte des deux
## côtés. Les yeux fermés, on ne voit plus les toiles, seulement les pétales
## du vrai chemin.
func _labyrinthe() -> void:
	var g := _groupe("Labyrinthe")
	_sol_plafond(g, -7.5, 7.5, -15.0, 0.0, H, "sol", "plafond")
	var murs := []
	# Les murs entre deux cases voisines.
	for i in N:
		for j in N:
			if i + 1 < N and not _ouvert([i, j], [i + 1, j]):
				murs.append([centre_case(i, j) + Vector3(CASE / 2, 0, 0), false])
			if j + 1 < N and not _ouvert([i, j], [i, j + 1]):
				murs.append([centre_case(i, j) + Vector3(0, 0, -CASE / 2), true])
	# Le tour, avec l'entrée au sud de (2, 0) et la sortie au nord de (4, 4).
	for k in N:
		if k != 2:
			murs.append([centre_case(k, 0) + Vector3(0, 0, CASE / 2), true])
		if k != 4:
			murs.append([centre_case(k, N - 1) + Vector3(0, 0, -CASE / 2), true])
		murs.append([centre_case(0, k) + Vector3(-CASE / 2, 0, 0), false])
		murs.append([centre_case(N - 1, k) + Vector3(CASE / 2, 0, 0), false])
	for n in murs.size():
		_toile_mur(g, "Toile_%d" % n, murs[n][0], murs[n][1])
	# Les pétales du vrai chemin, tous les 75 cm.
	var petales := Node3D.new()
	_ajouter(g, petales, "Petales")
	var points := [centre_case(2, 0) + Vector3(0, 0, CASE / 2 + 0.5)]
	for c in CHEMIN:
		points.append(centre_case(c[0], c[1]))
	points.append(centre_case(4, 4) + Vector3(0, 0, -CASE / 2 - 1.0))
	var k := 0
	for p in range(points.size() - 1):
		var a: Vector3 = points[p]
		var b: Vector3 = points[p + 1]
		var n := int(a.distance_to(b) / 0.75)
		for q in n:
			var pos: Vector3 = a.lerp(b, float(q) / n) + Vector3(0, 0.02, 0)
			var petale := _deco(petales, "Petale_%d" % k, pos + Vector3(0.12 * sin(k * 2.3), 0, 0.1 * cos(k * 1.7)), Vector3(0.1, 0.01, 0.07), "petale")
			petale.rotation.y = k * 0.9
			petale.layers = COUCHE_VRAI
			petale.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			k += 1
	var sol_vrai := _deco(g, "Sol_vrai", Vector3(0, -0.005, -7.5), Vector3(15, 0.01, 15), "nuit")
	sol_vrai.layers = COUCHE_VRAI
	for l in 3:
		_lampe(g, "Lampe_%d" % l, Vector3(-4.5 + 4.5 * l, 2.9, -7.5), 8.0, false, 0.7)
	_marque(g, "Entree", Vector3(0, 0, 1.0), 0.0)


## Un mur-toile du labyrinthe : solide, la route sous la pluie peinte des deux
## côtés. `le_long_de_x` : le mur suit l'axe X.
func _toile_mur(g: Node3D, nom: String, centre: Vector3, le_long_de_x: bool) -> void:
	var corps := StaticBody3D.new()
	corps.position = centre + Vector3(0, H / 2, 0)
	corps.rotation.y = 0.0 if le_long_de_x else PI / 2
	corps.add_to_group("toiles_mille", true)
	_ajouter(g, corps, nom)
	_forme(corps, "CollisionShape3D", _boite_forme(Vector3(CASE + 0.1, H, 0.12)))
	_deco(corps, "Cadre", Vector3.ZERO, Vector3(CASE + 0.1, H, 0.1), "cadre")
	var m: Dictionary = _motifs()["pluie"]
	for cote in [-1, 1]:
		var face := Node3D.new()
		face.position = Vector3(0, 0, cote * 0.056)
		face.rotation.y = 0.0 if cote > 0 else PI
		_ajouter(corps, face, "Face_%s" % ("avant" if cote > 0 else "arriere"))
		var taille := Vector2(CASE - 0.3, H - 0.4)
		_deco(face, "Fond", Vector3.ZERO, Vector3(taille.x, taille.y, 0.004), m["fond"])
		var formes: Array = m["formes"]
		for i in formes.size():
			var f: Array = formes[i]
			var pos := Vector3((f[0] + f[2] / 2.0 - 0.5) * taille.x, (f[1] + f[3] / 2.0 - 0.5) * taille.y, 0.004 + 0.002 * i)
			_deco(face, "Forme_%d" % i, pos, Vector3(f[2] * taille.x, f[3] * taille.y, 0.002), f[4])


# --- Le cœur -----------------------------------------------------------------


## Le chevalet, face à la dernière toile, encore inachevée. La version
## parfaite (Juliette à la fenêtre) et le vrai souvenir (au lac) sont cachés.
func _coeur() -> void:
	var g := _groupe("Coeur")
	var c := COEUR
	_sol_plafond(g, c.x - 4.3, c.x + 4.3, c.z - 5.3, -15.0, H + 1.0, "sol", "plafond")
	_mur(g, "Mur_nord", true, c.z - 5.15, c.x - 4.3, c.x + 4.3, H + 1.0, "mur")
	_mur(g, "Mur_ouest", false, c.x - 4.15, c.z - 5.0, -15.0, H + 1.0, "mur")
	_mur(g, "Mur_est", false, c.x + 4.15, c.z - 5.0, -15.0, H + 1.0, "mur")
	# Le mur sud du cœur, avec le passage depuis la sortie du labyrinthe.
	_mur(g, "Mur_sud", true, -15.15, c.x - 4.3, c.x + 4.3, H + 1.0, "mur", [[6.0, 2.0, 2.6]])
	var derniere := _toile(g, "Derniere_toile", c + Vector3(0, 2.1, -4.95), 0.0, Vector2(3.2, 2.2), "pluie")
	var parfaite := _toile(g, "Version_parfaite", c + Vector3(0, 2.1, -4.92), 0.0, Vector2(3.2, 2.2), "fenetre")
	parfaite.visible = false
	var vraie := _toile(g, "Vrai_souvenir", c + Vector3(0, 2.1, -4.89), 0.0, Vector2(3.2, 2.2), "lac")
	vraie.visible = false
	var chevalet := Support.new()
	chevalet.position = c + Vector3(0, 0, -2.0) - g.position
	_ajouter(g, chevalet, "Chevalet")
	_forme(chevalet, "CollisionShape3D", _boite_forme(Vector3(1.0, 1.8, 0.4)), Vector3(0, 0.9, 0))
	_deco(chevalet, "Pied_g", Vector3(-0.35, 0.8, 0), Vector3(0.06, 1.6, 0.06), "chevalet")
	_deco(chevalet, "Pied_d", Vector3(0.35, 0.8, 0), Vector3(0.06, 1.6, 0.06), "chevalet")
	_deco(chevalet, "Barre", Vector3(0, 0.95, 0.02), Vector3(0.8, 0.05, 0.1), "chevalet")
	_deco(chevalet, "Toile", Vector3(0, 1.35, 0.04), Vector3(0.8, 0.6, 0.03), "toile")
	# La porte d'entrée de la maison, qui apparaît à la fin.
	var porte := _porte_dessinee(g, "Porte", c + Vector3(-3.0, 0, -4.97), 0.0)
	_boite(porte, "Rai", Vector3(0, 0.02, 0.06), Vector3(0.9, 0.03, 0.04), "lumiere_porte", false)
	porte.visible = false
	var sortie := _zone(g, "Sortie", c + Vector3(-3.0, 1.2, -4.5), Vector3(1.2, 2.4, 0.8))
	sortie.monitoring = false
	_lampe(g, "Lampe", c + Vector3(0, H, -1.0), 9.0, true, 1.0)
	_pensee(g, "PenseeDerniere", derniere.position + g.position, "Elle est encore là. Je peux encore la sauver.", 7.0, 20.0)


# --- Dehors ------------------------------------------------------------------


## La nature, en couleurs : un chemin qui monte vers une colline, des arbres,
## des fleurs, des papillons, et trois personnes sur le chemin.
func _dehors() -> void:
	var g := _groupe("Dehors", DEHORS)
	g.visible = false
	_boite(g, "Sol", Vector3(0, -0.25, -30), Vector3(80, 0.5, 90), "herbe")
	for m in [["Bord_ouest", Vector3(-40, 3, -30), Vector3(1, 8, 90)], ["Bord_est", Vector3(40, 3, -30), Vector3(1, 8, 90)],
			["Bord_sud", Vector3(0, 3, 15), Vector3(80, 8, 1)], ["Bord_nord", Vector3(0, 3, -75), Vector3(80, 8, 1)]]:
		_mur_invisible(g, m[0], DEHORS + m[1], m[2])
	# Le chemin, en zigzag jusqu'au pied de la colline.
	var points := [Vector3(0, 0, 4), Vector3(2, 0, -10), Vector3(-3, 0, -22), Vector3(1, 0, -34), Vector3(-2, 0, -46), Vector3(0, 0, -52)]
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var morceau := _deco(g, "Chemin_%d" % i, (a + b) / 2 + Vector3(0, 0.01, 0), Vector3(2.0, 0.02, a.distance_to(b) + 1.0), "chemin")
		morceau.rotation.y = atan2(-(b.x - a.x), -(b.z - a.z))
	# La colline : une pente, puis le sommet, avec un banc et un arbre.
	var pente := _boite(g, "Colline_pente", Vector3(0, 1.5, -58), Vector3(10, 0.4, 13.4), "colline")
	pente.rotation.x = atan2(3.0, 12.0)
	_boite(g, "Colline_sommet", Vector3(0, 1.5, -68), Vector3(14, 3.0, 8), "colline")
	_boite(g, "Banc", Vector3(2.5, 3.25, -68), Vector3(1.8, 0.5, 0.5), "banc")
	_deco(g, "Arbre_sommet_tronc", Vector3(-3, 4.5, -69), Vector3(0.6, 3.0, 0.6), "tronc")
	_deco(g, "Arbre_sommet_feuillage", Vector3(-3, 6.8, -69), Vector3(4.0, 2.4, 4.0), "feuillage")
	_zone(g, "Sommet", DEHORS + Vector3(0, 4.5, -67), Vector3(12, 3, 6))
	# Des arbres et des fleurs, au hasard, loin du chemin.
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 2026
	for i in 28:
		var x := hasard.randf_range(8.0, 36.0) * (-1.0 if i % 2 == 0 else 1.0)
		var z := hasard.randf_range(-60.0, 10.0)
		var h := hasard.randf_range(2.5, 4.5)
		_deco(g, "Arbre_%d_tronc" % i, Vector3(x, h / 2, z), Vector3(0.5, h, 0.5), "tronc")
		_deco(g, "Arbre_%d_feuillage" % i, Vector3(x, h + 1.0, z), Vector3(3.0, 2.2, 3.0), "feuillage" if i % 3 else "feuillage_2")
	for i in 160:
		var x := hasard.randf_range(-30.0, 30.0)
		if absf(x) < 3.5:
			x += 5.0 * signf(x + 0.01)
		var p := Vector3(x, 0, hasard.randf_range(-55.0, 10.0))
		_deco(g, "Tige_%d" % i, p + Vector3(0, 0.15, 0), Vector3(0.03, 0.3, 0.03), "tige")
		_deco(g, "Fleur_%d" % i, p + Vector3(0, 0.32, 0), Vector3(0.14, 0.07, 0.14), "fleur_%d" % (i % 5 + 1))
	# Les papillons (le niveau les fait voler).
	var papillons := Node3D.new()
	_ajouter(g, papillons, "Papillons")
	for i in 18:
		var p := Node3D.new()
		p.position = Vector3(hasard.randf_range(-12, 12), hasard.randf_range(0.8, 2.2), hasard.randf_range(-55, 5))
		_ajouter(papillons, p, "Papillon_%d" % i)
		for cote in [-1, 1]:
			var aile := _deco(p, "Aile_%s" % ("g" if cote < 0 else "d"), Vector3(cote * 0.06, 0, 0), Vector3(0.11, 0.01, 0.09), "papillon_%d" % (i % 3 + 1))
			aile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Les passants : [nom, position, couleur, répliques].
	var passants := [
		["Jardiniere", "La jardinière", Vector3(4.5, 0, -12), "habit_1", ["Oh, bonjour ! Belle journée, hein ?", "Les roses sont en avance, cette année."]],
		["Promeneur", "Le promeneur", Vector3(-5.0, 0, -28), "habit_2", ["Bonjour, monsieur.", "Vous allez sur la colline ? La vue est belle, d'en haut."]],
		["Enfant", "L'enfant", Vector3(3.5, 0, -42), "habit_3", ["Salut ! Tu veux voir mon cerf-volant ?", "Il vole tout seul quand il y a du vent !"]],
	]
	for p in passants:
		var corps := Passant.new()
		corps.position = p[2]
		# Tourné vers le chemin.
		corps.rotation.y = -PI / 2 if p[2].x < 0 else PI / 2
		corps.nom = p[1]
		corps.repliques.assign(p[4])
		_ajouter(g, corps, p[0])
		var enfant: bool = p[0] == "Enfant"
		var echelle := 0.7 if enfant else 1.0
		_forme(corps, "CollisionShape3D", _boite_forme(Vector3(0.6, 1.8 * echelle, 0.6)), Vector3(0, 0.9 * echelle, 0))
		_deco(corps, "Corps", Vector3(0, 0.75 * echelle, 0), Vector3(0.45, 1.3, 0.3) * echelle, p[3])
		_deco(corps, "Tete", Vector3(0, 1.6 * echelle, 0), Vector3(0.26, 0.28, 0.26) * echelle, "peau")
		var bras := _deco(corps, "Bras", Vector3(0.3, 1.25, 0) * echelle, Vector3(0.1, 0.5, 0.1) * echelle, p[3])
		bras.rotation.z = 0.0
		if enfant:
			var ficelle := _deco(corps, "Ficelle", Vector3(0.35, 3.0, -1.0), Vector3(0.02, 4.0, 0.02), "chemin")
			ficelle.rotation.x = 0.5
			var cv := _deco(corps, "Cerf_volant", Vector3(0.35, 5.0, -2.2), Vector3(0.9, 0.9, 0.05), "cerf_volant")
			cv.rotation.z = PI / 4
	_lampe(g, "Soleil_doux", DEHORS + Vector3(0, 30, -30), 120.0, false, 0.6)
	_marque(g, "Arrivee", DEHORS + Vector3(0, 0, 6), 0.0)
	_pensee(g, "PenseeArrivee", DEHORS + Vector3(0, 1.0, 6), "Dehors… Je n'étais pas sorti depuis si longtemps.", 2.0, 0.0, false)
	_pensee(g, "PenseeJardiniere", DEHORS + Vector3(4.5, 1.6, -12), "Je pourrais lui dire bonjour…", 6.0, 20.0)
