extends "res://tools/constructeur_souvenir.gd"

## Construit scenes/ete.tscn, le niveau 3 en formes simples (« L'été au
## lac »), lancé par construire_ete.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Plan, vu de dessus (-Z vers le haut, le nord) :
##
##                      L'île (le grand arbre)
##                         |
##     cabane   ponton     pont (cassé au milieu)
##   ------------------- rive sud -------------------
##   ------------------- la route -------------------
##
## L'eau est à y = 0 ; le fond du lac à -1,3 m ; la rive et l'île à +0,3 m.
## Le soleil se couche au nord-ouest, derrière l'île. Tout est peint, donc en
## couleurs.

const COULEURS := {
	"herbe": "7cb518", "sable": "e9d8a6", "fond": "3d5a80", "route": "6c757d", "ligne": "f8f9fa",
	"bois": "a47148", "bois_sombre": "6f4518", "planche": "c9905a", "tronc": "7f5539", "feuillage": "52b788",
	"rocher": "9c8f80", "colline": "8ab17d", "colline_loin": "6a8d73", "cabane": "bc6c25", "toit": "9c6644",
	"toile": "f5f5f5", "toile_lac": "4ea8de", "toile_ile": "2d6a4f", "ciel_peint": "f4a261",
	"soleil_peint": "e76f51", "chevalet": "6f4518", "mob": "e63946", "mob_selle": "2b2d42",
	"roue": "222222", "robe": "f6bd60", "peau": "f2c6a0", "cheveux": "7f4f24", "fleur_1": "ff006e",
	"fleur_2": "ffbe0b", "fleur_3": "fb5607", "fleur_4": "8338ec", "tige": "386641", "chemise": "457b9d",
	"porte": "7a5c45", "poignee": "d4af37", "cadre": "b8b8c0", "planche_vive": "ffd166",
}

## Les planches du pont : le pont va de la rive (z = 0) à l'île (z = -22),
## à 1 m au-dessus de l'eau ; il manque les planches de z = -14 à -8.
const PONT_X := 4.0
const PONT_Y := 1.0
const TROU := Vector2(-14.0, -8.0)
const ILE := Vector3(0, 0, -26)
const PONTON_X := -8.0


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Ete"
	_racine.set_script(load("res://scripts/niveau/ete.gd"))
	_environnement()
	_rive()
	_lac()
	_ponton()
	_pont()
	_ile()
	_juliette()
	_nuit()
	_joueur_et_interface(Vector3(PONTON_X, 0.5, -3.6), 0.0)
	_racine.get_node("BasculeFx").free()
	var ui := _racine.get_node("Interface")
	var repeint := ColorRect.new()
	repeint.color = Color("f6f1e7", 0.0)
	repeint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	repeint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, repeint, "Repeint")
	_ajouter(ui, Fissures.new(), "Fissures")
	_interface_souvenir()
	return _enregistrer("res://scenes/ete.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["soleil_peint", "planche_vive"]


## Un après-midi d'été ; le niveau fait descendre le soleil et rougir le ciel.
func _environnement() -> void:
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color("4ea8de")
	ciel.sky_horizon_color = Color("ffe8a3")
	ciel.ground_horizon_color = Color("ffe8a3")
	ciel.ground_bottom_color = Color("3d5a80")
	ciel.sun_angle_max = 8.0
	ciel.sun_curve = 0.05
	var sky := Sky.new()
	sky.sky_material = ciel
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffe8c2")
	env.ambient_light_energy = 0.45
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")
	var soleil := DirectionalLight3D.new()
	soleil.shadow_enabled = true
	soleil.light_color = Color("fff1c9")
	_ajouter(_racine, soleil, "Soleil")


func _forme(parent: Node, nom: String, forme: Shape3D, pos := Vector3.ZERO) -> CollisionShape3D:
	var c := CollisionShape3D.new()
	c.shape = forme
	c.position = pos
	return _ajouter(parent, c, nom)


func _boite_forme(taille: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = taille
	return b


func _mesh(parent: Node, nom: String, mesh: Mesh, pos: Vector3, couleur: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(couleur)
	return _ajouter(parent, mi, nom)


## Une pente solide, de `bas` à `haut` (coordonnées du monde), large de
## `largeur`, dessinée en `couleur`.
func _pente(g: Node3D, nom: String, bas: Vector3, haut: Vector3, largeur: float, couleur: String) -> void:
	var dir := haut - bas
	var b := _boite(g, nom, (bas + haut) / 2 - g.position, Vector3(largeur, 0.3, dir.length()), couleur)
	b.basis = Basis.looking_at(dir, Vector3.UP)
	b.position -= b.basis.y * 0.15


# --- La rive, la route, les collines ---------------------------------------


func _rive() -> void:
	var g := _groupe("Rive")
	_boite(g, "Sol_sud", Vector3(0, -0.1, 10), Vector3(64, 0.8, 20), "herbe")
	_boite(g, "Sol_ouest", Vector3(-38, -0.1, -20), Vector3(12, 0.8, 40), "herbe")
	_boite(g, "Sol_est", Vector3(38, -0.1, -20), Vector3(12, 0.8, 40), "herbe")
	_boite(g, "Sol_nord", Vector3(0, -0.1, -44), Vector3(88, 0.8, 8), "herbe")
	# La plage : une pente douce pour entrer dans l'eau et en sortir.
	_pente(g, "Plage", Vector3(16, -1.3, -6), Vector3(16, 0.3, 0), 8.0, "sable")
	_boite(g, "Route", Vector3(0, 0.31, 12), Vector3(64, 0.02, 3.5), "route", false)
	for i in 12:
		_boite(g, "Ligne_%d" % i, Vector3(-27 + 5 * i, 0.325, 12), Vector3(2.0, 0.01, 0.15), "ligne", false)
	# La cabane, à l'ouest du ponton.
	_boite(g, "Cabane", Vector3(-20, 1.55, 4), Vector3(4, 2.5, 3), "cabane")
	_boite(g, "Cabane_toit", Vector3(-20, 3.0, 4), Vector3(4.6, 0.4, 3.6), "toit")
	# Des collines tout autour, pour fermer l'horizon (le nord-ouest reste
	# bas : c'est là que le soleil se couche).
	for c in [["Colline_1", Vector3(-30, 3, 26), Vector3(30, 8, 10), "colline"],
			["Colline_2", Vector3(25, 4, 28), Vector3(36, 10, 10), "colline"],
			["Colline_3", Vector3(52, 5, -10), Vector3(10, 12, 50), "colline_loin"],
			["Colline_4", Vector3(30, 2.5, -56), Vector3(50, 6, 12), "colline_loin"],
			["Colline_5", Vector3(-52, 1.5, 10), Vector3(10, 4, 30), "colline_loin"]]:
		_boite(g, c[0], c[1], c[2], c[3], false)
	for m in [["Bord_sud", Vector3(0, 3, 20.5), Vector3(64, 8, 1)], ["Bord_est", Vector3(32.5, 3, -10), Vector3(1, 8, 62)],
			["Bord_ouest", Vector3(-32.5, 3, -10), Vector3(1, 8, 62)], ["Bord_nord", Vector3(0, 3, -42.5), Vector3(64, 8, 1)]]:
		_mur_invisible(g, m[0], m[1], m[2])
	_marque(g, "Depart", Vector3(PONTON_X, 0.5, -3.6), 0.0)


## Le lac : le fond, l'eau (un grand miroir bleuté, tourné vers le ciel) et la
## zone où l'on nage.
func _lac() -> void:
	var g := _groupe("Lac")
	_boite(g, "Fond", Vector3(0, -1.55, -20), Vector3(64, 0.5, 40), "fond")
	var eau := Miroir.new()
	eau.taille = Vector2(64, 40)
	eau.definition = 16
	eau.teinte = Color("9fc9e8")
	eau.distance_vue = 200.0
	eau.position = Vector3(0, 0.0, -20)
	eau.rotation.x = -PI / 2
	_ajouter(g, eau, "Eau")
	# Sous la surface des rives, de l'île et du ponton : on n'y est que dans l'eau.
	_zone(g, "Nage", Vector3(0, -0.625, -20), Vector3(64, 1.55, 40))
	_marque(g, "Rive_est", Vector3(16, 0.3, 2), PI)


## Le ponton, le chevalet et le tableau (le lac et l'île ; le ciel est blanc).
func _ponton() -> void:
	var g := _groupe("Ponton")
	_boite(g, "Planches", Vector3(PONTON_X, 0.35, -2.5), Vector3(2.0, 0.3, 5.0), "bois")
	for z in [-1.0, -4.0]:
		for x in [-0.9, 0.9]:
			_boite(g, "Pilotis_%d_%d" % [int(x > 0), int(z < -2)], Vector3(PONTON_X + x, -0.6, z), Vector3(0.2, 1.6, 0.2), "bois_sombre", false)
	_boite(g, "Chevalet_g", Vector3(PONTON_X - 0.35, 1.1, -4.6), Vector3(0.06, 1.3, 0.06), "chevalet", false)
	_boite(g, "Chevalet_d", Vector3(PONTON_X + 0.35, 1.1, -4.6), Vector3(0.06, 1.3, 0.06), "chevalet", false)
	_boite(g, "Chevalet_barre", Vector3(PONTON_X, 1.05, -4.58), Vector3(0.8, 0.05, 0.1), "chevalet", false)
	var tableau := RigidBody3D.new()
	tableau.position = Vector3(PONTON_X, 1.42, -4.6)
	tableau.freeze = true
	tableau.continuous_cd = true
	tableau.add_to_group("tableau", true)
	_ajouter(g, tableau, "Tableau")
	_forme(tableau, "CollisionShape3D", _boite_forme(Vector3(0.8, 0.6, 0.06)))
	# Face peinte vers +Z (vers Thomas). Le ciel (en haut) est blanc ; la
	# version finie et les coulures de l'eau sont cachées.
	var f := Node3D.new()
	_ajouter(tableau, f, "Peinture")
	for b in [["Toile", Vector3(0, 0, 0), Vector3(0.8, 0.6, 0.03), "toile"],
			["Lac", Vector3(0, -0.15, 0.017), Vector3(0.78, 0.28, 0.004), "toile_lac"],
			["Ile", Vector3(0.05, -0.04, 0.02), Vector3(0.26, 0.07, 0.004), "toile_ile"],
			["Arbre", Vector3(0.05, 0.03, 0.021), Vector3(0.06, 0.1, 0.004), "feuillage"]]:
		_boite(f, b[0], b[1], b[2], b[3], false)
	var ciel := _boite(f, "Ciel", Vector3(0, 0.15, 0.019), Vector3(0.78, 0.28, 0.004), "ciel_peint", false)
	ciel.visible = false
	var soleil := _boite(f, "Soleil", Vector3(-0.15, 0.06, 0.022), Vector3(0.07, 0.07, 0.004), "soleil_peint", false)
	soleil.visible = false
	var coulures := _boite(f, "Coulures", Vector3(0, -0.02, 0.024), Vector3(0.78, 0.56, 0.004), "fond", false)
	coulures.visible = false
	_zone(g, "Zone", Vector3(PONTON_X, 1.5, -2.5), Vector3(2.0, 2.4, 5.0))
	_pensee(g, "PenseeTableau", Vector3(PONTON_X, 1.42, -4.6), "Le lac, l'île… Il me manque le ciel du soir.", 3.0, 20.0)


## Le pont de bois, de la rive à l'île, cassé au milieu. Les planches du
## milieu existent dans le reflet du lac (à partir de la deuxième journée),
## et ne portent Thomas que s'il regarde leur reflet.
func _pont() -> void:
	var g := _groupe("Pont")
	for m in [["Morceau_sud", 0.0, TROU.y], ["Morceau_nord", TROU.x, -21.5]]:
		var z0: float = m[1]
		var z1: float = m[2]
		_boite(g, m[0], Vector3(PONT_X, PONT_Y - 0.1, (z0 + z1) / 2), Vector3(2.0, 0.2, absf(z1 - z0)), "planche")
		for k in int(absf(z1 - z0) / 3.0) + 1:
			var z: float = z0 + signf(z1 - z0) * (1.0 + 3.0 * k)
			_boite(g, "%s_pilotis_%d" % [m[0], k], Vector3(PONT_X, -0.25, z), Vector3(0.25, 2.3, 0.25), "bois_sombre", false)
	_boite(g, "Rambarde_g", Vector3(PONT_X - 1.0, PONT_Y + 0.45, -4.0), Vector3(0.08, 0.08, 8.0), "bois_sombre", false)
	_boite(g, "Rambarde_d", Vector3(PONT_X + 1.0, PONT_Y + 0.45, -4.0), Vector3(0.08, 0.08, 8.0), "bois_sombre", false)
	# Les bouts cassés.
	var casse_sud := _boite(g, "Casse_sud", Vector3(PONT_X - 0.5, PONT_Y - 0.25, TROU.y - 0.3), Vector3(0.9, 0.12, 0.6), "planche", false)
	casse_sud.rotation.x = 0.4
	var casse_nord := _boite(g, "Casse_nord", Vector3(PONT_X + 0.4, PONT_Y - 0.25, TROU.x + 0.3), Vector3(1.0, 0.12, 0.6), "planche", false)
	casse_nord.rotation.x = -0.4
	# Les planches du reflet.
	var reflet := Node3D.new()
	_ajouter(g, reflet, "Reflet")
	# Elles brillent fort : la teinte bleue de l'eau ne doit pas les éteindre.
	var vive := Style.materiau(Color(COULEURS["planche_vive"]), true)
	vive.emission_energy_multiplier = 3.0
	var n := 10
	for k in n:
		var z := TROU.x + (TROU.y - TROU.x) * (k + 0.5) / n
		# Des couleurs vives : on les remarque dans l'eau, depuis la rive.
		var p := _boite(reflet, "Planche_%d" % k, Vector3(PONT_X, PONT_Y - 0.1, z), Vector3(2.0, 0.2, 0.55), "planche_vive", false)
		p.layers = Miroir.COUCHE_REFLET
		p.material = vive
	var corps := StaticBody3D.new()
	corps.position = Vector3(PONT_X, PONT_Y - 0.1, (TROU.x + TROU.y) / 2)
	_ajouter(g, corps, "Solide")
	var forme := _forme(corps, "CollisionShape3D", _boite_forme(Vector3(2.0, 0.2, TROU.y - TROU.x)))
	forme.disabled = true
	_pensee(g, "PenseeTrou", Vector3(PONT_X, PONT_Y, (TROU.x + TROU.y) / 2), "Le pont est cassé…", 7.0, 25.0)
	var dans_l_eau := Pensee.new()
	dans_l_eau.position = Vector3(PONT_X, -1.0, (TROU.x + TROU.y) / 2)
	dans_l_eau.texte = "Dans l'eau… le pont est entier."
	dans_l_eau.distance = 9.0
	dans_l_eau.angle_max_deg = 20.0
	dans_l_eau.active = false
	_ajouter(g, dans_l_eau, "PenseeReflet")
	# Au bord du trou, quand le pont est repeint dans le reflet.
	var bord := Pensee.new()
	bord.position = Vector3(PONT_X, PONT_Y + 0.5, TROU.y + 0.8)
	bord.texte = "Le pont est entier, dans l'eau. Si je ne regarde que l'eau…"
	bord.regard = false
	bord.distance = 1.8
	bord.active = false
	_ajouter(g, bord, "PenseeBord")


## L'île : une butte, une pente pour sortir de l'eau au sud, le grand arbre,
## et la place de Juliette, face au soleil couchant.
func _ile() -> void:
	var g := _groupe("Ile", ILE)
	_boite(g, "Sol", Vector3(0, 0.05, 0), Vector3(12, 0.5, 9), "herbe")
	_pente(g, "Pente", ILE + Vector3(-3, -1.3, 7.5), ILE + Vector3(-3, 0.3, 4.5), 3.0, "sable")
	_boite(g, "Escalier", Vector3(PONT_X, 0.65, 4.3), Vector3(2.0, 0.7, 0.4), "planche")
	_boite(g, "Tronc", Vector3(-1.0, 2.3, -1.5), Vector3(0.7, 4.0, 0.7), "tronc")
	_boite(g, "Feuillage", Vector3(-1.0, 4.8, -1.5), Vector3(5.0, 2.6, 5.0), "feuillage")
	_boite(g, "Rocher", Vector3(3.5, 0.6, -2.5), Vector3(1.6, 0.8, 1.2), "rocher")
	_marque(g, "Place", ILE + Vector3(-1.0, 0.3, -3.6), PI * 0.15)
	_zone(g, "Rendez_vous", ILE + Vector3(-1.0, 1.5, -2.6), Vector3(5.0, 3.0, 4.0))
	# Les fleurs du moment parfait, cachées.
	var fleurs := Node3D.new()
	fleurs.visible = false
	_ajouter(g, fleurs, "Fleurs")
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 16
	for i in 60:
		var p := Vector3(hasard.randf_range(-5.5, 5.5), 0.3, hasard.randf_range(-4.2, 4.2))
		_boite(fleurs, "Tige_%d" % i, p + Vector3(0, 0.2, 0), Vector3(0.03, 0.4, 0.03), "tige", false)
		_boite(fleurs, "Fleur_%d" % i, p + Vector3(0, 0.42, 0), Vector3(0.14, 0.08, 0.14), "fleur_%d" % (i % 4 + 1), false)


## Juliette, debout (sur l'île) et sur sa mobylette (sur la route). Des
## formes simples : une robe, une tête, de longs cheveux.
func _juliette() -> void:
	var g := _groupe("Juliette")
	var debout := _silhouette(g, "Debout", false)
	debout.position = ILE + Vector3(-1.0, 0.3, -3.6)
	debout.visible = false
	var mob := Node3D.new()
	mob.position = Vector3(36, 0.32, 12.8)
	mob.rotation.y = PI / 2
	_ajouter(g, mob, "Mobylette")
	_boite(mob, "Cadre", Vector3(0, 0.45, 0), Vector3(0.25, 0.3, 1.2), "mob", false)
	_boite(mob, "Selle", Vector3(0, 0.68, 0.15), Vector3(0.28, 0.08, 0.5), "mob_selle", false)
	_boite(mob, "Guidon", Vector3(0, 0.95, -0.55), Vector3(0.6, 0.05, 0.05), "mob_selle", false)
	_boite(mob, "Fourche", Vector3(0, 0.6, -0.5), Vector3(0.05, 0.6, 0.05), "mob_selle", false)
	for r in [["Roue_av", -0.55], ["Roue_ar", 0.5]]:
		var roue := CylinderMesh.new()
		roue.top_radius = 0.28
		roue.bottom_radius = 0.28
		roue.height = 0.08
		var mr := _mesh(mob, r[0], roue, Vector3(0, 0.28, r[1]), "roue")
		mr.rotation.z = PI / 2
	var assise := _silhouette(mob, "Juliette", true)
	assise.position = Vector3(0, 0.35, 0.15)
	# La fleur sauvage qu'elle donne à Thomas, le premier jour.
	var fleur := RigidBody3D.new()
	fleur.position = Vector3(-6.5, 1.0, 2.0)
	fleur.freeze = true
	fleur.continuous_cd = true
	fleur.visible = false
	fleur.collision_layer = 0
	_ajouter(g, fleur, "Fleur")
	_forme(fleur, "CollisionShape3D", _boite_forme(Vector3(0.12, 0.4, 0.12)))
	_boite(fleur, "Tige", Vector3(0, -0.05, 0), Vector3(0.02, 0.3, 0.02), "tige", false)
	_boite(fleur, "Fleur", Vector3(0, 0.13, 0), Vector3(0.12, 0.06, 0.12), "fleur_1", false)


func _silhouette(parent: Node3D, nom: String, assise: bool) -> Node3D:
	var j := Node3D.new()
	_ajouter(parent, j, nom)
	var robe := CylinderMesh.new()
	robe.top_radius = 0.18
	robe.bottom_radius = 0.32 if not assise else 0.22
	robe.height = 0.9 if not assise else 0.6
	_mesh(j, "Robe", robe, Vector3(0, 0.45 if not assise else 0.6, 0), "robe")
	var tete := SphereMesh.new()
	tete.radius = 0.13
	tete.height = 0.26
	var y_tete := 1.5 if not assise else 1.08
	_mesh(j, "Tete", tete, Vector3(0, y_tete, 0), "peau")
	var buste := CapsuleMesh.new()
	buste.radius = 0.16
	buste.height = 0.6
	_mesh(j, "Buste", buste, Vector3(0, y_tete - 0.37, 0), "robe")
	# Les cheveux : une mèche qui flotte au vent (le niveau l'anime).
	var cheveux := Node3D.new()
	cheveux.position = Vector3(0, y_tete + 0.05, 0.08)
	_ajouter(j, cheveux, "Cheveux")
	_boite(cheveux, "Meche", Vector3(0, -0.2, 0.08), Vector3(0.26, 0.45, 0.08), "cheveux", false)
	_boite(cheveux, "Dessus", Vector3(0, 0.07, -0.06), Vector3(0.28, 0.1, 0.26), "cheveux", false)
	return j


## Le vrai soir : la nuit, une lanterne sur la rive de l'île. Caché.
func _nuit() -> void:
	var g := _groupe("Nuit")
	g.visible = false
	var l := OmniLight3D.new()
	l.position = ILE + Vector3(-3, 1.2, 4.0)
	l.omni_range = 9.0
	l.light_energy = 1.5
	l.light_color = Color("ffd6a5")
	_ajouter(g, l, "Lanterne")
	_marque(g, "Dans_l_eau", ILE + Vector3(-3, -1.3, 11.0), 0.0)
	var j := _silhouette(g, "Juliette", false)
	j.position = ILE + Vector3(-3, 0.3, 3.5)
	j.rotation.y = PI
