extends "res://tools/constructeur_souvenir.gd"

## Construit scenes/intro.tscn, la cinématique du début (en formes simples),
## lancé par construire_intro.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Deux lieux : la maison sur Terre, son jardin et sa colline, autour de
## l'origine ; l'atelier du peintre, en x = 300. La maison s'arrache du sol
## avec son morceau de terre, jusque dans les étoiles.

const COULEURS := {
	"herbe": "7cb518", "chemin": "e9d8a6", "facade": "e9dcc9", "toit": "9d4edd", "porte": "7a5c45",
	"fenetre": "ffd166", "cheminee": "6c757d", "tronc": "7f5539", "feuillage": "52b788",
	"feuillage_2": "95d5b2", "barriere": "f1faee", "fleur_1": "ff006e", "fleur_2": "ffbe0b", "fleur_3": "3a86ff",
	"roche": "7f5539", "terre": "5e4b3c", "trou": "1b1b1b",
	"sol": "3d3029", "mur": "4a4e69", "plafond": "2b2d42", "chevalet": "6f4518", "cadre": "b08d57",
	"ciel_toile": "4ea8de", "nuit_toile": "1b1f4a", "etoile": "fff3b0", "blouse": "dcdcdc", "beret": "d1495b",
	"cheveux_gris": "c0c0c0", "pantalon": "2b2d42", "peau": "f2c6a0", "pinceau": "8d6346", "poils": "e63946",
	"toile": "e9dcc9",
}
const ATELIER := Vector3(300, 0, 0)


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Intro"
	_racine.set_script(load("res://scripts/niveau/intro.gd"))
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1c9")
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")
	_terre()
	_atelier()
	var camera := Camera3D.new()
	camera.fov = 60.0
	camera.far = 600.0
	camera.position = Vector3(0, 3, 30)
	_ajouter(_racine, camera, "Camera")
	_interface()
	return _enregistrer("res://scenes/intro.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["fenetre", "etoile"]


## Une boîte dessinée seulement (un maillage, plus léger qu'une boîte CSG).
func _deco(parent: Node, nom: String, pos: Vector3, taille: Vector3, couleur: String) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = taille
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(couleur)
	return _ajouter(parent, mi, nom)


## La maison sur Terre, son jardin, la colline ; sous elle, le morceau de
## terre qui partira avec elle (caché dans le sol).
func _terre() -> void:
	var g := _groupe("Terre")
	_deco(g, "Sol", Vector3(0, -0.5, 0), Vector3(300, 1.0, 300), "herbe")
	var trou := CylinderMesh.new()
	trou.top_radius = 6.5
	trou.bottom_radius = 6.5
	trou.height = 0.04
	var mt := MeshInstance3D.new()
	mt.mesh = trou
	mt.position = Vector3(0, 0.02, 0)
	mt.material_override = _mat("trou")
	mt.visible = false
	_ajouter(g, mt, "Trou")
	var maison := Node3D.new()
	_ajouter(g, maison, "Maison")
	_deco(maison, "Murs", Vector3(0, 2.0, 0), Vector3(8.0, 4.0, 6.0), "facade")
	for cote in [-1, 1]:
		var pan := _deco(maison, "Toit_%s" % ("g" if cote < 0 else "d"), Vector3(cote * 2.1, 5.2, 0), Vector3(5.0, 0.3, 6.6), "toit")
		pan.rotation.z = -cote * 0.6
	_deco(maison, "Pignon", Vector3(0, 5.0, 0), Vector3(4.6, 2.2, 5.8), "facade").rotation.z = PI / 4
	_deco(maison, "Cheminee", Vector3(2.4, 6.4, -1.2), Vector3(0.6, 1.6, 0.6), "cheminee")
	_deco(maison, "Porte", Vector3(0, 1.1, 3.02), Vector3(1.1, 2.2, 0.06), "porte")
	for f in [Vector3(-2.6, 2.4, 3.02), Vector3(2.6, 2.4, 3.02), Vector3(-4.02, 2.4, 0)]:
		var fen := _deco(maison, "Fenetre_%d" % int(f.x), f, Vector3(1.2, 1.0, 0.06), "fenetre")
		if f.z == 0:
			fen.rotation.y = PI / 2
	var socle := CylinderMesh.new()
	socle.top_radius = 6.5
	socle.bottom_radius = 0.8
	socle.height = 7.0
	var ms := MeshInstance3D.new()
	ms.mesh = socle
	ms.position = Vector3(0, -3.55, 0)
	ms.material_override = _mat("roche")
	_ajouter(maison, ms, "Socle")
	var dessus := CylinderMesh.new()
	dessus.top_radius = 6.6
	dessus.bottom_radius = 6.6
	dessus.height = 0.1
	var md := MeshInstance3D.new()
	md.mesh = dessus
	md.position = Vector3(0, -0.04, 0)
	md.material_override = _mat("herbe")
	_ajouter(maison, md, "Pelouse")
	# Le jardin : un chemin, une barrière, des fleurs, des arbres.
	_deco(g, "Chemin", Vector3(0, 0.01, 9.0), Vector3(1.6, 0.02, 12.0), "chemin")
	for i in 9:
		_deco(g, "Barriere_%d" % i, Vector3(-8.0 + 2.0 * i if i != 4 else 99.0, 0.5, 12.0), Vector3(0.12, 1.0, 0.12), "barriere")
	_deco(g, "Barriere_haut_g", Vector3(-5.0, 0.8, 12.0), Vector3(6.2, 0.1, 0.08), "barriere")
	_deco(g, "Barriere_haut_d", Vector3(5.0, 0.8, 12.0), Vector3(6.2, 0.1, 0.08), "barriere")
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 1987
	for i in 40:
		var x := hasard.randf_range(-9.0, 9.0)
		if absf(x) < 1.2:
			x += 2.0 * signf(x + 0.01)
		_deco(g, "Fleur_%d" % i, Vector3(x, 0.15, hasard.randf_range(4.0, 11.5)), Vector3(0.2, 0.3, 0.2), "fleur_%d" % (i % 3 + 1))
	for i in 14:
		var a := TAU * i / 14.0
		var r := hasard.randf_range(16.0, 40.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r - 6.0)
		var h := hasard.randf_range(3.0, 5.0)
		# Pas d'arbre entre la caméra et la maison.
		if p.z > 0.0 and absf(p.x) < 16.0:
			continue
		_deco(g, "Arbre_%d_tronc" % i, p + Vector3(0, h / 2, 0), Vector3(0.6, h, 0.6), "tronc")
		_deco(g, "Arbre_%d_feuillage" % i, p + Vector3(0, h + 1.2, 0), Vector3(3.4, 2.6, 3.4), "feuillage" if i % 2 else "feuillage_2")
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-30, 40, 0)
	soleil.light_color = Color("ffd6a5")
	soleil.shadow_enabled = true
	_ajouter(g, soleil, "Soleil")
	_marque(g, "Plan_maison", Vector3(9.0, 2.2, 26.0), 0.35)
	_marque(g, "Plan_envol", Vector3(-14.0, 1.6, 30.0), -0.4)


## Le vieux peintre, de dos : blouse, béret rouge, cheveux gris.
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
	_deco(p, "Cheveux", Vector3(0, 1.62, 0.04), Vector3(0.27, 0.2, 0.24), "cheveux_gris")
	_deco(p, "Beret", Vector3(0.03, 1.76, -0.01), Vector3(0.3, 0.06, 0.3), "beret")
	var epaule := Node3D.new()
	epaule.position = Vector3(0.3, 1.35, -0.05)
	_ajouter(p, epaule, "Bras")
	_deco(epaule, "Manche", Vector3(0, 0, -0.25), Vector3(0.1, 0.1, 0.5), "blouse")
	_deco(epaule, "Pinceau", Vector3(0.02, 0.05, -0.6), Vector3(0.02, 0.02, 0.35), "pinceau")
	return p


## L'atelier : une salle sombre ; le peintre, de dos, peint la maison sur sa
## toile. Le ciel de la toile devient la nuit, avec des étoiles (caché au
## début).
func _atelier() -> void:
	var g := _groupe("Atelier", ATELIER)
	var c := ATELIER
	var h := 3.4
	_sol_plafond(g, c.x - 5.3, c.x + 5.3, c.z - 5.3, c.z + 5.3, h, "sol", "plafond")
	_mur(g, "Mur_nord", true, c.z - 5.15, c.x - 5.3, c.x + 5.3, h, "mur")
	_mur(g, "Mur_sud", true, c.z + 5.15, c.x - 5.3, c.x + 5.3, h, "mur")
	_mur(g, "Mur_ouest", false, c.x - 5.15, c.z - 5.0, c.z + 5.0, h, "mur")
	_mur(g, "Mur_est", false, c.x + 5.15, c.z - 5.0, c.z + 5.0, h, "mur")
	_deco(g, "Chevalet_g", Vector3(-0.55, 0.9, -1.5), Vector3(0.06, 1.8, 0.06), "chevalet")
	_deco(g, "Chevalet_d", Vector3(0.55, 0.9, -1.5), Vector3(0.06, 1.8, 0.06), "chevalet")
	var toile := Node3D.new()
	toile.position = Vector3(0, 1.55, -1.45)
	_ajouter(g, toile, "Toile")
	_deco(toile, "Cadre", Vector3(0, 0, -0.02), Vector3(1.5, 1.1, 0.04), "cadre")
	_deco(toile, "Ciel", Vector3(0, 0.15, 0.01), Vector3(1.4, 0.7, 0.01), "ciel_toile")
	_deco(toile, "Herbe", Vector3(0, -0.35, 0.01), Vector3(1.4, 0.3, 0.01), "herbe")
	_deco(toile, "Maison", Vector3(0, -0.12, 0.02), Vector3(0.36, 0.26, 0.01), "facade")
	_deco(toile, "Toit", Vector3(0, 0.06, 0.02), Vector3(0.42, 0.1, 0.01), "toit")
	var nuit := Node3D.new()
	nuit.visible = false
	_ajouter(toile, nuit, "Nuit")
	_deco(nuit, "Ciel_nuit", Vector3(0, 0.0, 0.03), Vector3(1.4, 1.0, 0.01), "nuit_toile")
	_deco(nuit, "Maison", Vector3(0, 0.08, 0.04), Vector3(0.36, 0.26, 0.01), "facade")
	_deco(nuit, "Toit", Vector3(0, 0.26, 0.04), Vector3(0.42, 0.1, 0.01), "toit")
	_deco(nuit, "Socle", Vector3(0, -0.1, 0.04), Vector3(0.3, 0.1, 0.01), "roche")
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 12
	for i in 26:
		_deco(nuit, "Etoile_%d" % i, Vector3(hasard.randf_range(-0.66, 0.66), hasard.randf_range(-0.46, 0.46), 0.045), Vector3(0.025, 0.025, 0.01), "etoile")
	var peintre := _peintre(g, "Peintre")
	peintre.position = Vector3(0.15, 0, -0.4)
	_lampe(g, "Lampe", c + Vector3(0.6, 2.6, -0.6), 7.0, true, 2.4)
	_lampe(g, "Lampe_dos", c + Vector3(-1.2, 2.4, 2.0), 6.0, false, 0.9)
	_marque(g, "Plan_dos", c + Vector3(1.1, 1.75, 2.4), 0.25)


## Le noir des fondus, le texte, le titre, et l'aide pour passer.
func _interface() -> void:
	var ui := CanvasLayer.new()
	_ajouter(_racine, ui, "Interface")
	var noir := ColorRect.new()
	noir.color = Color(0, 0, 0, 1)
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, noir, "Noir")
	for l in [["Texte", Control.PRESET_CENTER_BOTTOM, 28, -110.0], ["Titre", Control.PRESET_CENTER, 60, -230.0], ["Passer", Control.PRESET_BOTTOM_RIGHT, 16, -40.0]]:
		var label := Label.new()
		label.set_anchors_and_offsets_preset(l[1])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH if l[0] != "Passer" else Control.GROW_DIRECTION_BEGIN
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		label.offset_top = l[3]
		label.offset_bottom = l[3]
		if l[0] == "Passer":
			label.offset_left = -24
			label.offset_right = -24
		label.add_theme_font_size_override("font_size", l[2])
		label.add_theme_color_override("font_outline_color", Color("2b1d4e"))
		label.add_theme_constant_override("outline_size", 10)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.modulate.a = 0.0
		_ajouter(ui, label, l[0])
	(ui.get_node("Titre") as Label).text = "Aligner l'espace et le temps"
	(ui.get_node("Passer") as Label).text = "Espace : passer"
