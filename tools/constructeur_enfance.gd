extends "res://tools/constructeur_souvenir.gd"

## Construit scenes/enfance.tscn, le niveau 2 en formes simples (« L'enfance »),
## lancé par construire_enfance.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Trois lieux, loin l'un de l'autre :
## - la cour de récré, autour de l'origine ;
## - la maison d'enfance, en x = 500 : le jardin au sud, l'entrée, la chambre
##   de Thomas à l'ouest, la salle de bain à l'est, et au nord la salle à
##   manger, très longue, pour la table sans fin ;
## - le grenier, en x = 1000, qui grandit et rétrécit.
## Tout est peint, donc en couleurs.

const COULEURS := {
	# La cour.
	"cour_sol": "8d99ae", "marelle": "f1faee", "banc": "6d4c3d", "ecole": "e8a87c", "ecole_fenetre": "5c7aa8", "porte_ecole": "8d5a3b",
	"muret": "d9c5a0", "tour": "4ea8de", "tour_bois": "c9905a", "toboggan": "e76f51",
	"lampe": "3d3d3d", "lampe_verre": "ffe8a3",
	"enfant_1": "f4a261", "enfant_2": "2a9d8f", "enfant_3": "e9c46a", "enfant_4": "e76f51",
	"enfant_5": "8ab17d", "enfant_6": "9c89b8", "enfant_7": "f28482", "enfant_8": "84a59d",
	# La maison.
	"parquet": "b5835a", "mur_maison": "f1e3c8", "plafond_maison": "fff8e7", "herbe": "6a994e",
	"cloture": "f5f5f5", "boite": "c0392b", "table": "8d6346", "nappe": "fefae0", "chaise": "a47148",
	"fenetre_nuit": "1d3557", "gateau": "f7cad0", "bougie": "ffffff", "flamme": "ffb703",
	"enveloppe": "fdfcf8", "lit": "577590", "drap": "f1faee", "bureau": "a47148", "armoire": "8d6346",
	"coffre": "e63946", "lavabo": "ffffff", "miroir_cadre": "6d597a", "carton": "d4a373",
	"peau": "f2c6a0", "cheveux": "5e4b3c", "tronc": "7f5539", "feuillage": "52b788", "carte": "ffd6e0",
	# Le grenier.
	"grenier_sol": "8d6346", "grenier_mur": "c9a27e", "grenier_plafond": "a47148", "chevalet": "6f4518",
	"toile_blanche": "fdfcf8", "cerf_1": "e63946", "cerf_2": "ffb703", "cerf_3": "4ea8de",
	"dessin_1": "ffd6a5", "dessin_2": "caffbf", "dessin_3": "a0c4ff", "dessin_4": "ffc6ff", "dessin_5": "fdffb6",
	"cadre": "b8b8c0", "porte": "7a5c45", "poignee": "d4af37",
}

const HAUTEUR_MAISON := 2.8
## La cour : la lampe au milieu des enfants, la tour de jeux à l'est.
const LAMPE_COUR := Vector3(0, 0, 1.0)
const DEPART_COUR := Vector3(-4, 0, -7.3)
const TOUR := Vector3(7.5, 0, -3.0)
const TOUR_H := 4.0
## Les enfants autour de la lampe : [angle (0 = vers le mur de l'école, en
## degrés), distance à la lampe].
const ENFANTS := [[-25, 1.0], [30, 1.25], [75, 0.95], [125, 1.15], [165, 1.05], [210, 1.3], [255, 0.9], [300, 1.1]]
## Couche de collision des enfants : seule la peur la regarde.
const COUCHE_ENFANTS := 128
## La maison d'enfance et le grenier.
const MAISON := Vector3(500, 0, 0)
const GRENIER := Vector3(1000, 0, 0)
const GRENIER_H := 4.0
## La salle à manger : le bout de la table au départ, la boucle et sa période.
const FIN_TABLE := -12.0
const BOUCLE_Z := -28.0
const PERIODE := 8.0


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Enfance"
	_racine.set_script(load("res://scripts/niveau/enfance.gd"))
	_environnement()
	_cour()
	_maison()
	_salle_a_manger()
	_grenier()
	_joueur_et_interface(DEPART_COUR, PI)
	_racine.get_node("BasculeFx").free()
	var ui := _racine.get_node("Interface")
	var flou := ColorRect.new()
	flou.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flou.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/flou_peur.gdshader")
	flou.material = mat
	flou.visible = false
	_ajouter(ui, flou, "Flou")
	_interface_souvenir()
	return _enregistrer("res://scenes/enfance.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["lampe_verre", "flamme", "fenetre_nuit"]


## Un soir d'été : le ciel passe du bleu nuit à l'orange.
func _environnement() -> void:
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color("2b2d6e")
	ciel.sky_horizon_color = Color("f4a261")
	ciel.ground_horizon_color = Color("e9c46a")
	ciel.ground_bottom_color = Color("3d405b")
	ciel.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = ciel
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9b8e8")
	env.ambient_light_energy = 0.25
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")


func _mesh(parent: Node, nom: String, mesh: Mesh, pos: Vector3, couleur: String, ombre := GeometryInstance3D.SHADOW_CASTING_SETTING_ON) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(couleur)
	mi.cast_shadow = ombre
	return _ajouter(parent, mi, nom)


func _forme(parent: Node, nom: String, forme: Shape3D, pos := Vector3.ZERO) -> CollisionShape3D:
	var c := CollisionShape3D.new()
	c.shape = forme
	c.position = pos
	return _ajouter(parent, c, nom)


func _boite_forme(taille: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = taille
	return b


## Une rampe solide et invisible, de `bas` à `haut` (coordonnées du monde),
## large de `largeur`.
func _rampe(g: Node3D, nom: String, bas: Vector3, haut: Vector3, largeur: float) -> StaticBody3D:
	var corps := StaticBody3D.new()
	var milieu := (bas + haut) / 2
	corps.position = milieu - g.position
	var dir := haut - bas
	corps.basis = Basis.looking_at(dir, Vector3.UP)
	_ajouter(g, corps, nom)
	# Le dessus de la boîte passe par la ligne bas-haut.
	_forme(corps, "CollisionShape3D", _boite_forme(Vector3(largeur, 0.2, dir.length())), Vector3(0, -0.1, 0))
	return corps


# --- La cour de récré --------------------------------------------------------


func _cour() -> void:
	var g := _groupe("Cour")
	_boite(g, "Sol", Vector3(0, -0.25, 0), Vector3(24.6, 0.5, 16.6), "cour_sol")
	# L'école au nord, haute ; des murets ailleurs, avec des murs invisibles
	# au-dessus pour qu'on ne saute pas dehors depuis la tour.
	_mur(g, "Mur_ecole", true, -8.15, -12.3, 12.3, 7.0, "ecole")
	for i in 6:
		_boite(g, "Fenetre_%d" % i, Vector3(-10 + 4 * i, 4.2, -7.98), Vector3(1.6, 1.4, 0.04), "ecole_fenetre", false)
	var porte := _porte_dessinee(g, "PorteEcole", Vector3(4, 0, -7.97), 0.0)
	porte.scale = Vector3(1.3, 1.1, 1.0)
	_marque(g, "Rentree", Vector3(4, 0, -7.2))
	_mur(g, "Mur_sud", true, 8.15, -12.3, 12.3, 2.5, "muret")
	_mur(g, "Mur_ouest", false, -12.15, -8.0, 8.0, 2.5, "muret")
	_mur(g, "Mur_est", false, 12.15, -8.0, 8.0, 2.5, "muret")
	for m in [["Haut_sud", Vector3(0, 6.25, 8.15), Vector3(24.6, 7.5, EP)],
			["Haut_ouest", Vector3(-12.15, 6.25, 0), Vector3(EP, 7.5, 16)],
			["Haut_est", Vector3(12.15, 6.25, 0), Vector3(EP, 7.5, 16)]]:
		_mur_invisible(g, m[0], m[1], m[2])
	# La lampe, posée par terre au milieu des enfants.
	var lampe := RigidBody3D.new()
	lampe.position = LAMPE_COUR + Vector3(0, 0.25, 0)
	lampe.add_to_group("lampe", true)
	_ajouter(g, lampe, "Lampe")
	_forme(lampe, "CollisionShape3D", _boite_forme(Vector3(0.3, 0.5, 0.3)))
	var socle := BoxMesh.new()
	socle.size = Vector3(0.3, 0.2, 0.3)
	_mesh(lampe, "Socle", socle, Vector3(0, -0.15, 0), "lampe", GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var verre := BoxMesh.new()
	verre.size = Vector3(0.22, 0.28, 0.22)
	_mesh(lampe, "Verre", verre, Vector3(0, 0.09, 0), "lampe_verre", GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.1, 0)
	l.omni_range = 45.0
	l.omni_attenuation = 0.6
	l.light_energy = 3.0
	l.light_color = Color("ffe8a3")
	l.shadow_enabled = true
	_ajouter(lampe, l, "Lumiere")
	# Les enfants : invisibles, seule leur ombre se voit. Leur corps, caché,
	# n'apparaît que quand la peur est vaincue.
	for i in ENFANTS.size():
		var a := deg_to_rad(float(ENFANTS[i][0]))
		var pos := LAMPE_COUR + Vector3(sin(a), 0, -cos(a)) * float(ENFANTS[i][1])
		var e := Node3D.new()
		e.position = pos
		e.add_to_group("enfants", true)
		_ajouter(g, e, "Enfant_%d" % (i + 1))
		# Un corps et une tête : leur ombre a une silhouette d'enfant.
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.22
		capsule.height = 1.0
		var tete := SphereMesh.new()
		tete.radius = 0.17
		tete.height = 0.34
		var ombre := Node3D.new()
		_ajouter(e, ombre, "Ombre")
		_mesh(ombre, "Corps", capsule, Vector3(0, 0.5, 0), "cour_sol", GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
		_mesh(ombre, "Tete", tete, Vector3(0, 1.15, 0), "cour_sol", GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
		var corps := Node3D.new()
		corps.visible = false
		_ajouter(e, corps, "Corps")
		_mesh(corps, "Corps", capsule, Vector3(0, 0.5, 0), "enfant_%d" % (i + 1))
		_mesh(corps, "Tete", tete, Vector3(0, 1.15, 0), "peau")
		var peur := StaticBody3D.new()
		peur.collision_layer = COUCHE_ENFANTS
		peur.collision_mask = 0
		_ajouter(e, peur, "Peur")
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.25
		cyl.height = 1.3
		_forme(peur, "CollisionShape3D", cyl, Vector3(0, 0.65, 0))
	_tour(g)
	# Une marelle peinte au sol et deux bancs.
	for k in 8:
		var cases := [Vector3(-7, 0, 3.5), Vector3(-7, 0, 4.2), Vector3(-7.35, 0, 4.9), Vector3(-6.65, 0, 4.9),
				Vector3(-7, 0, 5.6), Vector3(-7.35, 0, 6.3), Vector3(-6.65, 0, 6.3), Vector3(-7, 0, 7.0)]
		_boite(g, "Marelle_%d" % k, cases[k] + Vector3(0, 0.005, 0), Vector3(0.6, 0.01, 0.6), "marelle", false)
	_boite(g, "Banc_1", Vector3(-11.6, 0.22, -3.0), Vector3(0.5, 0.45, 2.2), "banc")
	_boite(g, "Banc_2", Vector3(0.0, 0.22, 7.6), Vector3(2.2, 0.45, 0.5), "banc")
	_pensee(g, "PenseeDepart", DEPART_COUR + Vector3(0, 1.0, 0), "Ils sont si grands…", 2.0, 0.0, false)
	_pensee(g, "PenseeLampe", LAMPE_COUR + Vector3(0, 0.4, 0), "C'est la lampe qui les rend si grands.", 5.0, 12.0)
	_pensee(g, "PenseeTour", TOUR + Vector3(0, TOUR_H + 0.5, 0), "Tout là-haut, la lumière tomberait d'en haut…", 9.0, 10.0, true, false)


## La tour de jeux : un escalier à l'ouest, une plateforme à 4 m (avec une
## rambarde au nord et à l'est), et un toboggan vers le sud.
func _tour(g: Node3D) -> void:
	var t := TOUR
	var h := TOUR_H
	_boite(g, "Tour_plateforme", t + Vector3(0, h - 0.1, 0), Vector3(1.8, 0.2, 1.8), "tour_bois")
	for c in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
		_boite(g, "Tour_pilier_%d_%d" % [int(c.x > 0), int(c.z > 0)], t + c + Vector3(0, (h - 0.2) / 2, 0), Vector3(0.15, h - 0.2, 0.15), "tour")
	_boite(g, "Tour_rambarde_nord", t + Vector3(0, h + 0.2, -0.85), Vector3(1.8, 0.4, 0.1), "tour")
	_boite(g, "Tour_rambarde_est", t + Vector3(0.85, h + 0.2, 0.05), Vector3(0.1, 0.4, 1.7), "tour")
	# L'escalier : des marches pour l'œil, une rampe invisible pour les pieds.
	var bas := t + Vector3(-5.5, 0, 0)
	var haut := t + Vector3(-0.9, h, 0)
	for i in 10:
		var k := (i + 0.5) / 10.0
		var p := bas.lerp(haut, k)
		_boite(g, "Tour_marche_%d" % i, Vector3(p.x, p.y - 0.2, p.z), Vector3(0.46, 0.4, 1.0), "tour_bois", false)
	_rampe(g, "Tour_escalier", bas, haut, 1.0)
	# Le toboggan, solide : on peut le descendre.
	var tb := t + Vector3(0, h, 0.9)
	var tbas := t + Vector3(0, 0, 6.0)
	_rampe(g, "Toboggan", tb, tbas, 0.9)
	var milieu := (tb + tbas) / 2
	var planche := _boite(g, "Toboggan_planche", milieu, Vector3(0.9, 0.08, tb.distance_to(tbas)), "toboggan", false)
	planche.rotation.x = atan2(h, 5.1)


# --- La maison d'enfance -----------------------------------------------------


func _maison() -> void:
	var g := _groupe("Maison", MAISON)
	var x0 := MAISON.x
	var h := HAUTEUR_MAISON
	# Le jardin, la clôture, la boîte aux lettres, un arbre.
	_boite(g, "Jardin", Vector3(0, -0.25, 13.3), Vector3(21.2, 0.5, 14.0), "herbe")
	_mur(g, "Cloture_sud", true, 20.15, x0 - 10.6, x0 + 10.6, 1.0, "cloture")
	_mur(g, "Cloture_ouest", false, x0 - 10.45, 6.3, 20.0, 1.0, "cloture")
	_mur(g, "Cloture_est", false, x0 + 10.45, 6.3, 20.0, 1.0, "cloture")
	_mur_invisible(g, "Haut_sud", MAISON + Vector3(0, 3.0, 20.15), Vector3(21.2, 4.0, EP))
	_mur_invisible(g, "Haut_ouest", MAISON + Vector3(-10.45, 3.0, 13.15), Vector3(EP, 4.0, 13.7))
	_mur_invisible(g, "Haut_est", MAISON + Vector3(10.45, 3.0, 13.15), Vector3(EP, 4.0, 13.7))
	_boite(g, "Boite_pied", Vector3(2.5, 0.45, 18.5), Vector3(0.08, 0.9, 0.08), "cloture")
	_boite(g, "Boite", Vector3(2.5, 1.05, 18.5), Vector3(0.45, 0.35, 0.3), "boite")
	_zone(g, "Fente", MAISON + Vector3(2.5, 1.45, 18.5), Vector3(0.7, 0.6, 0.55))
	_boite(g, "Arbre_tronc", Vector3(-6, 1.2, 14), Vector3(0.5, 2.4, 0.5), "tronc")
	_boite(g, "Arbre_feuillage", Vector3(-6, 3.0, 14), Vector3(2.6, 1.8, 2.6), "feuillage")
	_lampe(g, "Lampe_jardin", MAISON + Vector3(0, 3.5, 12), 14.0, true, 0.8)
	_marque(g, "Depart", MAISON + Vector3(0, 0, 17.5))
	# L'entrée.
	_sol_plafond(g, x0 - 4.3, x0 + 4.3, -2.3, 6.3, h, "parquet", "plafond_maison")
	_mur(g, "Mur_entree_sud", true, 6.15, x0 - 4.3, x0 + 4.3, h, "mur_maison", [[x0, 1.4, 2.3]])
	_mur(g, "Mur_entree_nord", true, -2.15, x0 - 4.3, x0 + 4.3, h, "mur_maison", [[x0, 2.0, 2.4]])
	_mur(g, "Mur_entree_ouest", false, x0 - 4.15, -2.0, 6.0, h, "mur_maison", [[2.0, 1.2, 2.3]])
	_mur(g, "Mur_entree_est", false, x0 + 4.15, -2.0, 6.0, h, "mur_maison", [[2.0, 1.2, 2.3]])
	_lampe(g, "Lampe_entree", MAISON + Vector3(0, 2.5, 2), 7.0)
	_chambre(g)
	_salle_de_bain(g)
	_pensee(g, "PenseeDepart", MAISON + Vector3(0, 1.0, 17.5), "Le soir de mon anniversaire. Personne n'est encore là.", 2.0, 0.0, false)


## La chambre de Thomas : l'invitation du bureau, celle du haut de l'armoire,
## et deux cubes de bois pour y monter.
func _chambre(g: Node3D) -> void:
	var x0 := MAISON.x
	var h := HAUTEUR_MAISON
	_sol_plafond(g, x0 - 11.3, x0 - 4.3, -2.3, 6.3, h, "parquet", "plafond_maison")
	_mur(g, "Mur_chambre_nord", true, -2.15, x0 - 11.3, x0 - 4.3, h, "mur_maison")
	_mur(g, "Mur_chambre_sud", true, 6.15, x0 - 11.3, x0 - 4.3, h, "mur_maison")
	_mur(g, "Mur_chambre_ouest", false, x0 - 11.15, -2.0, 6.0, h, "mur_maison")
	_boite(g, "Lit", Vector3(-7.5, 0.25, 4.8), Vector3(1.0, 0.5, 2.0), "lit")
	_boite(g, "Lit_drap", Vector3(-7.5, 0.52, 4.7), Vector3(0.95, 0.06, 1.6), "drap", false)
	_boite(g, "Bureau", Vector3(-5.2, 0.38, -1.4), Vector3(1.2, 0.76, 0.6), "bureau")
	_boite(g, "Chaise", Vector3(-5.2, 0.23, -0.8), Vector3(0.4, 0.46, 0.4), "chaise")
	_boite(g, "Armoire", Vector3(-10.6, 1.0, 1.0), Vector3(0.8, 2.0, 1.6), "armoire")
	_boite(g, "Coffre", Vector3(-6.0, 0.25, 5.5), Vector3(0.8, 0.5, 0.6), "coffre")
	_enveloppe(g, "Invitation_bureau", MAISON + Vector3(-5.3, 0.79, -1.45), Vector3(0.26, 0.02, 0.18))
	_enveloppe(g, "Invitation_armoire", MAISON + Vector3(-10.9, 2.1, 1.0), Vector3(0.02, 0.18, 0.26))
	for c in [["Cube_1", Vector3(-6.4, 0.2, 2.4)], ["Cube_2", Vector3(-6.0, 0.2, 3.4)]]:
		var cube: ObjetPerspectif = load("res://scenes/cube.tscn").instantiate()
		cube.position = c[1]
		cube.taille_depart = 0.35
		cube.zone = AABB(MAISON + Vector3(-11.3, -1, -2.3), Vector3(7.0, 5, 8.6))
		_ajouter(g, cube, c[0])
	_lampe(g, "Lampe_chambre", MAISON + Vector3(-7.7, 2.5, 2), 7.0)
	_pensee(g, "PenseeBureau", MAISON + Vector3(-5.3, 0.8, -1.45), "Mes invitations… Je ne les ai jamais données.", 3.0, 20.0)
	_pensee(g, "PenseeArmoire", MAISON + Vector3(-10.25, 1.95, 1.0), "J'en avais caché là-haut, pour ne plus les voir.", 4.0, 15.0)


## La salle de bain : le miroir au-dessus du lavabo, et une invitation qu'on
## ne voit que dans le reflet, sur l'étagère au-dessus de la baignoire.
func _salle_de_bain(g: Node3D) -> void:
	var x0 := MAISON.x
	var h := HAUTEUR_MAISON
	_sol_plafond(g, x0 + 4.3, x0 + 10.3, -2.3, 6.3, h, "parquet", "plafond_maison")
	_mur(g, "Mur_sdb_nord", true, -2.15, x0 + 4.3, x0 + 10.3, h, "mur_maison")
	_mur(g, "Mur_sdb_sud", true, 6.15, x0 + 4.3, x0 + 10.3, h, "mur_maison")
	_mur(g, "Mur_sdb_est", false, x0 + 10.15, -2.0, 6.0, h, "mur_maison")
	_boite(g, "Lavabo", Vector3(7.3, 0.42, -1.75), Vector3(0.8, 0.84, 0.5), "lavabo")
	_boite(g, "Miroir_cadre", Vector3(7.3, 1.45, -1.98), Vector3(1.55, 1.15, 0.04), "miroir_cadre", false)
	var miroir := Miroir.new()
	miroir.taille = Vector2(1.4, 1.0)
	miroir.position = Vector3(7.3, 1.45, -1.955)
	_ajouter(g, miroir, "Miroir")
	_boite(g, "Baignoire", Vector3(7.3, 0.3, 5.55), Vector3(1.9, 0.6, 0.8), "lavabo")
	_boite(g, "Etagere", Vector3(7.8, 1.0, 5.9), Vector3(0.6, 0.04, 0.2), "armoire")
	_enveloppe(g, "Invitation_reflet", MAISON + Vector3(7.8, 1.11, 5.9), Vector3(0.26, 0.18, 0.02), true)
	_lampe(g, "Lampe_sdb", MAISON + Vector3(7.3, 2.5, 2), 7.0)
	_pensee(g, "PenseeMiroir", MAISON + Vector3(7.3, 1.45, -1.955), "Dans le miroir, je suis si petit.", 3.5, 15.0)


## Une invitation : une petite enveloppe (de la taille donnée, posée à plat ou
## debout) avec un cachet rouge, qu'on peut prendre. Celle du reflet n'est
## visible que dans les miroirs (jusqu'à ce qu'on la prenne).
func _enveloppe(g: Node3D, nom: String, pos: Vector3, taille: Vector3, reflet := false) -> RigidBody3D:
	var e := RigidBody3D.new()
	e.position = pos - g.position
	e.freeze = true
	e.continuous_cd = true
	e.add_to_group("invitations", true)
	_ajouter(g, e, nom)
	_forme(e, "CollisionShape3D", _boite_forme(taille + Vector3(0.04, 0.04, 0.04)))
	var m := BoxMesh.new()
	m.size = taille
	var mi := _mesh(e, "Mesh", m, Vector3.ZERO, "enveloppe")
	# Le cachet, au milieu de la face la plus large, un peu en relief.
	var mince := 0 if taille.x < 0.05 else (1 if taille.y < 0.05 else 2)
	var relief := Vector3.ZERO
	relief[mince] = taille[mince] / 2 + 0.004
	var cachet := BoxMesh.new()
	cachet.size = Vector3(0.05, 0.05, 0.05)
	cachet.size[mince] = 0.008
	var mc := _mesh(e, "Cachet", cachet, relief, "boite")
	if reflet:
		mi.layers = Miroir.COUCHE_REFLET
		mc.layers = Miroir.COUCHE_REFLET
	return e


## La salle à manger : une table très longue, une chaise par mètre de chaque
## côté, une fenêtre tous les 4 m, une lampe tous les 8 m. Le bout de la salle
## (le mur et le gâteau) se déplace : au début, la table fait 9 m. Après la
## correction du peintre, il reste toujours à 5 m devant Thomas, et la boucle
## le ramène 8 m en arrière.
func _salle_a_manger() -> void:
	var g := _groupe("SalleAManger", MAISON)
	var x0 := MAISON.x
	var h := HAUTEUR_MAISON
	var z_loin := -44.3
	_sol_plafond(g, x0 - 3.3, x0 + 3.3, z_loin, -2.3, h, "parquet", "plafond_maison")
	_mur(g, "Mur_ouest", false, x0 - 3.15, z_loin, -2.3, h, "mur_maison")
	_mur(g, "Mur_est", false, x0 + 3.15, z_loin, -2.3, h, "mur_maison")
	_mur(g, "Mur_fond", true, z_loin - 0.15, x0 - 3.3, x0 + 3.3, h, "mur_maison")
	_boite(g, "Table", Vector3(0, 0.375, -23.3), Vector3(1.2, 0.75, 41.0), "table")
	_boite(g, "Nappe", Vector3(0, 0.76, -23.3), Vector3(1.3, 0.02, 41.0), "nappe", false)
	for k in 40:
		var z := -3.5 - k
		for cote in [-1, 1]:
			var nom := "%s_%d" % ["g" if cote < 0 else "d", k]
			_boite(g, "Chaise_" + nom, Vector3(cote * 1.0, 0.23, z), Vector3(0.45, 0.46, 0.45), "chaise")
			_boite(g, "Dossier_" + nom, Vector3(cote * 1.2, 0.72, z), Vector3(0.06, 0.52, 0.45), "chaise", false)
	for k in 10:
		for cote in [-1, 1]:
			_boite(g, "Fenetre_%s_%d" % ["g" if cote < 0 else "d", k], Vector3(cote * 2.98, 1.5, -4.0 - 4.0 * k), Vector3(0.04, 1.0, 1.2), "fenetre_nuit", false)
	for k in 5:
		_lampe(g, "Lampe_%d" % k, MAISON + Vector3(0, 2.5, -6.0 - PERIODE * k), 7.0, false, 1.0)
	# La carte d'anniversaire de maman, posée au début de la table.
	_boite(g, "Carte", Vector3(0.2, 0.78, -3.2), Vector3(0.3, 0.02, 0.2), "carte", false)
	var texte := _texte(g, "Carte_texte", Vector3(0.2, 0.795, -3.2), "Mon Thomas,\nferme les yeux\net fais un vœu.\nMaman", 0.0, 0.0012)
	texte.rotation.x = -PI / 2
	texte.modulate = Color("6d2e46")
	texte.outline_size = 0
	_pensee(g, "PenseeCarte", MAISON + Vector3(0.2, 0.8, -3.2), "La carte de maman.", 3.0, 15.0)
	# Les invités peints, cachés jusqu'à la correction.
	for i in 6:
		var cote := -1 if i % 2 == 0 else 1
		var z := -3.5 - (i / 2)
		var inv := Node3D.new()
		inv.position = Vector3(cote * 1.0, 0.46, z)
		inv.rotation.y = PI / 2 * cote
		inv.visible = false
		inv.add_to_group("invites", true)
		_ajouter(g, inv, "Invite_%d" % (i + 1))
		_boite(inv, "Corps", Vector3(0, 0.38, 0), Vector3(0.5, 0.75, 0.03), "carton", false)
		_boite(inv, "Habit", Vector3(0, 0.38, -0.02), Vector3(0.42, 0.6, 0.01), "enfant_%d" % (i + 1), false)
		_boite(inv, "Tete", Vector3(0, 0.92, 0), Vector3(0.32, 0.32, 0.03), "carton", false)
		_boite(inv, "Visage", Vector3(0, 0.9, -0.02), Vector3(0.26, 0.26, 0.01), "peau", false)
		_boite(inv, "Cheveux", Vector3(0, 1.04, -0.022), Vector3(0.28, 0.08, 0.01), "cheveux", false)
	_pensee(g, "PenseeInvites", MAISON + Vector3(-1.0, 1.2, -4.5), "Ils me regardent… sans bouger.", 5.0, 20.0, true, false)
	# Le bout de la salle, qui se déplace : le mur, le gâteau et ses bougies.
	var fin := Node3D.new()
	fin.position = Vector3(0, 0, FIN_TABLE)
	_ajouter(g, fin, "Fin")
	_boite(fin, "Mur", Vector3(0, h / 2, -0.15), Vector3(6.0, h, EP), "mur_maison")
	var gateau := CSGCylinder3D.new()
	gateau.radius = 0.3
	gateau.height = 0.25
	gateau.sides = 16
	gateau.position = Vector3(0, 0.89, 0.6)
	gateau.material = _mat("gateau")
	_ajouter(fin, gateau, "Gateau")
	for i in 6:
		var a := TAU * i / 6.0
		var p := Vector3(cos(a) * 0.18, 1.08, 0.6 + sin(a) * 0.18)
		_boite(fin, "Bougie_%d" % i, p, Vector3(0.03, 0.14, 0.03), "bougie", false)
		_boite(fin, "Flamme_%d" % i, p + Vector3(0, 0.1, 0), Vector3(0.03, 0.05, 0.03), "flamme", false)
	var lueur := OmniLight3D.new()
	lueur.position = Vector3(0, 1.3, 0.6)
	lueur.omni_range = 2.5
	lueur.light_energy = 0.8
	lueur.light_color = Color("ffb703")
	_ajouter(fin, lueur, "Lueur")
	var voeu := Area3D.new()
	voeu.position = Vector3(0, h / 2, 1.4)
	_ajouter(fin, voeu, "Voeu")
	_forme(voeu, "CollisionShape3D", _boite_forme(Vector3(6.0, h, 1.8)))
	var boucle := _porte_trompeuse(g, "Boucle", MAISON + Vector3(0, 0, BOUCLE_Z), Vector3(6.0, h, 0.4))
	_marque(g, "Retour", MAISON + Vector3(0, 0, BOUCLE_Z + PERIODE))
	boucle.destinations = [NodePath("../Retour")]
	boucle.monitoring = false
	_zone(g, "Zone", MAISON + Vector3(0, h / 2, -23.3), Vector3(6.0, h, 42.0))


# --- Le grenier --------------------------------------------------------------


## Le grenier (6 × 6 m, 4 m de haut), dont la taille change. La lucarne est en
## haut du mur nord, couverte de dessins. Dehors, des cerfs-volants.
func _grenier() -> void:
	var g := _groupe("Grenier", GRENIER)
	var x0 := GRENIER.x
	var h := GRENIER_H
	_sol_plafond(g, x0 - 3.3, x0 + 3.3, -3.3, 3.3, h, "grenier_sol", "grenier_plafond")
	_mur(g, "Mur_nord", true, -3.15, x0 - 3.3, x0 + 3.3, h, "grenier_mur", [[x0, 1.0, 0.6, 3.0]])
	_mur(g, "Mur_sud", true, 3.15, x0 - 3.3, x0 + 3.3, h, "grenier_mur")
	_mur(g, "Mur_ouest", false, x0 - 3.15, -3.0, 3.0, h, "grenier_mur")
	_mur(g, "Mur_est", false, x0 + 3.15, -3.0, 3.0, h, "grenier_mur")
	_boite(g, "Chevalet", Vector3(0.8, 0.8, 0.2), Vector3(0.08, 1.6, 0.08), "chevalet")
	_boite(g, "Chevalet_toile", Vector3(0.8, 1.15, 0.25), Vector3(0.7, 0.55, 0.03), "toile_blanche", false)
	_boite(g, "Caisse", Vector3(-2.2, 0.35, 2.2), Vector3(0.9, 0.7, 0.9), "chevalet")
	# Les dessins de la lucarne, puis ceux des murs.
	var n := 0
	for p in [Vector2(-0.25, 3.15), Vector2(0.25, 3.15), Vector2(-0.25, 3.45), Vector2(0.25, 3.45)]:
		n += 1
		_dessin(g, "Dessin_lucarne_%d" % n, Vector3(p.x, p.y, -2.97), Vector3(0.52, 0.32, 0.02), "dessin_%d" % n, true)
	var murs := [[Vector3(-2.97, 1.4, -1.0), true], [Vector3(-2.97, 1.5, 1.2), true], [Vector3(2.97, 1.3, 0.0), true],
			[Vector3(-1.2, 1.5, 2.97), false], [Vector3(1.4, 1.35, 2.97), false]]
	for i in murs.size():
		var pos: Vector3 = murs[i][0]
		var taille := Vector3(0.02, 0.45, 0.6) if murs[i][1] else Vector3(0.6, 0.45, 0.02)
		_dessin(g, "Dessin_mur_%d" % (i + 1), pos, taille, "dessin_%d" % (i % 5 + 1), false)
	var lucarne := _zone(g, "Lucarne", GRENIER + Vector3(0, 3.3, -3.15), Vector3(1.0, 0.6, 0.5))
	lucarne.monitoring = true
	_lampe(g, "Lampe", GRENIER + Vector3(0, 3.0, 1.0), 9.0, false, 1.2)
	_marque(g, "Arrivee", GRENIER + Vector3(0, 0, 1.8), 0.0)
	_pensee(g, "PenseeDessins", GRENIER + Vector3(-2.97, 1.45, 0.1), "Je dessinais tout le temps. Tout seul.", 4.0, 25.0)
	_pensee(g, "PenseeLucarne", GRENIER + Vector3(0, 3.3, -3.0), "Des cerfs-volants… Les autres jouent dehors.", 12.0, 15.0, true, false)
	# Dehors, fixes : les cerfs-volants des autres enfants.
	var dehors := _groupe("Dehors", GRENIER)
	for i in 3:
		var c := _boite(dehors, "Cerf_volant_%d" % (i + 1), Vector3(-4.0 + 4.0 * i, 9.0 + 2.0 * (i % 2), -22.0), Vector3(1.2, 1.2, 0.05), "cerf_%d" % (i + 1), false)
		c.rotation.z = PI / 4
		_boite(dehors, "Ficelle_%d" % (i + 1), Vector3(-4.0 + 4.0 * i, 4.0 + (i % 2), -22.0), Vector3(0.02, 8.0, 0.02), "cloture", false)


## Un dessin punaisé : on le décroche avec E.
func _dessin(g: Node3D, nom: String, pos_locale: Vector3, taille: Vector3, couleur: String, lucarne: bool) -> Decrochable:
	var d := Decrochable.new()
	d.position = pos_locale
	d.add_to_group("dessins_lucarne" if lucarne else "dessins", true)
	_ajouter(g, d, nom)
	_forme(d, "CollisionShape3D", _boite_forme(taille))
	var m := BoxMesh.new()
	m.size = taille
	_mesh(d, "Mesh", m, Vector3.ZERO, couleur, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	return d
