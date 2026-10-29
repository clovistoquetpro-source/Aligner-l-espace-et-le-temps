extends "res://tools/constructeur_souvenir.gd"

## Construit scenes/dispute.tscn, le niveau 4 en formes simples (« La
## pluie »), lancé par construire_dispute.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Trois lieux, loin l'un de l'autre :
## - l'atelier, autour de l'origine : le rez-de-chaussée, la mezzanine au
##   nord (on y arrive), l'escalier le long du mur est, la porte au sud et la
##   rue, sous la pluie ;
## - la route de la course-poursuite, en x = 500, de z = 10 jusqu'au vide en
##   z = -330 ;
## - le vide où l'on tombe, en x = 1000.
## Tout est peint, donc en couleurs (des couleurs de pluie).

const COULEURS := {
	"parquet": "8d6346", "mur": "c9b8a6", "plafond": "a89a8c", "mezzanine": "7f5539", "rambarde": "5e4b3c",
	"marche": "a47148", "etagere": "6f4518", "livre_1": "e63946", "livre_2": "457b9d", "livre_3": "f4a261",
	"porte": "7a5c45", "poignee": "d4af37", "cadre": "b8b8c0", "portemanteau": "3d3029", "casque": "e63946",
	"visiere": "1d3557", "grille": "2b2d42", "table": "8d6346", "tasse": "f1faee", "lit": "577590", "drap": "f1faee",
	"chevalet": "6f4518", "toile": "f5f5f5", "toile_peinte": "4ea8de", "fenetre": "1d3557", "rue": "4a4e69",
	"trottoir": "6c757d", "facade": "9a8c98", "facade_1": "b5838d", "facade_2": "c9ada7", "facade_3": "4a4e69", "mob": "e63946",
	"mob_selle": "2b2d42", "roue": "222222", "robe": "f6bd60", "peau": "f2c6a0", "cheveux": "7f4f24",
	"chemise": "457b9d", "pantalon": "2b2d42", "barriere": "ffb703", "mur_course": "e76f51", "telephone": "222222",
	"tronc": "7f5539", "feuillage": "52b788",
	"ecran": "caf0f8", "soleil_mur": "ffe8c2", "parquet_clair": "c9905a", "fleurs": "ff8fab", "vase": "457b9d",
	"cle": "d4af37", "mer": "3a86ff", "falaise": "bc8a5f", "champ": "a7c957", "route_claire": "8d99ae",
	"toile_juliette": "f6bd60", "photo": "f1faee", "veste": "e63946", "disque": "2b2d42",
	"cadre_toile": "c08552", "joint": "9d4edd", "vrai": "f1faee", "ligne": "caf0f8",
}

const H := 6.0
const MEZZ_Y := 2.8
## L'escalier, de la mezzanine (en haut, z = -1,5) au rez-de-chaussée
## (z = 3,5), le long du mur est.
const ESC_X := 5.2
const ESC_HAUT := Vector3(5.2, 2.8, -1.5)
const ESC_BAS := Vector3(5.2, 0.0, 3.5)
const PORTE_X := -3.0
## La route de la course : le niveau en donne le tracé et les obstacles.
const Niveau4 := preload("res://scripts/niveau/dispute.gd")
const COURSE := Vector3(500, 0, 0)
const FIN_COURSE := Niveau4.FIN_COURSE
const VOIES := Niveau4.VOIES
const OBSTACLES := Niveau4.OBSTACLES
const INONDEE := Niveau4.INONDEE
const DEBUT_TOILES := Niveau4.DEBUT_TOILES
const COUCHE_VRAI := Niveau4.COUCHE_VRAI
## Le rez-de-chaussée des immeubles, solide, au bord de la route ; au-dessus,
## les étages penchent au-dessus d'elle.
const BORD := 4.9
const REZ := 4.0
const VIDE := Vector3(1000, 0, 0)
## Le prologue heureux : l'atelier, au soleil, et la balade à moto, au bord
## de la mer.
const BONHEUR := Vector3(-500, 0, 0)
const BALADE := Vector3(-1000, 0, 0)
const LONGUEUR_BALADE := 620.0
## Les reflets sont un peu sous la surface de l'eau (sinon, elle scintille).
const SOUS_L_EAU := Niveau4.SOUS_L_EAU


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Dispute"
	_racine.set_script(load("res://scripts/niveau/dispute.gd"))
	_environnement()
	_bonheur()
	_balade()
	_atelier()
	_mezzanine()
	_escalier()
	_dispute()
	_rue()
	_course()
	_vide()
	_joueur_et_interface(BONHEUR + Vector3(1.5, 0, 2.0), PI)
	_racine.get_node("BasculeFx").free()
	var ui := _racine.get_node("Interface")
	for r in [["Rebours", Color(0.55, 0.75, 1.0, 0.0)], ["Blanc", Color(1, 1, 1, 0.0)]]:
		var c := ColorRect.new()
		c.color = r[1]
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ajouter(ui, c, r[0])
	_interface_souvenir()
	return _enregistrer("res://scenes/dispute.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["ecran", "barriere", "vrai", "ligne"]


## Un soir de pluie : un ciel bas, gris bleu.
func _environnement() -> void:
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color("2b2d42")
	ciel.sky_horizon_color = Color("6c757d")
	ciel.ground_horizon_color = Color("6c757d")
	ciel.ground_bottom_color = Color("1b1b2f")
	ciel.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = ciel
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a3b1c6")
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("6c757d")
	env.fog_density = 0.012
	env.fog_sky_affect = 0.3
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")


# --- Petites briques ---------------------------------------------------------


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


## Une rampe solide et invisible, de `bas` à `haut` (coordonnées du monde).
func _rampe(g: Node3D, nom: String, bas: Vector3, haut: Vector3, largeur: float) -> StaticBody3D:
	var corps := StaticBody3D.new()
	corps.position = (bas + haut) / 2 - g.position
	var dir := haut - bas
	corps.basis = Basis.looking_at(dir, Vector3.UP)
	_ajouter(g, corps, nom)
	_forme(corps, "CollisionShape3D", _boite_forme(Vector3(largeur, 0.2, dir.length())), Vector3(0, -0.1, 0))
	return corps


## Un objet qui suit la ligne du temps du souvenir.
func _temporel(n: Node3D, cles: Array) -> ObjetTemporel:
	var o := ObjetTemporel.new()
	o.cles = cles
	return _ajouter(n, o, "Temps")


## Juliette ou Thomas, debout (formes simples). `nom_couleur` : la robe de
## Juliette, la chemise de Thomas.
func _silhouette(parent: Node3D, nom: String, robe: bool, assise := false) -> Node3D:
	var j := Node3D.new()
	_ajouter(parent, j, nom)
	var bas := CylinderMesh.new()
	bas.top_radius = 0.18
	bas.bottom_radius = (0.32 if robe else 0.2) if not assise else 0.22
	bas.height = 0.9 if not assise else 0.6
	_mesh(j, "Bas", bas, Vector3(0, 0.45 if not assise else 0.6, 0), "robe" if robe else "pantalon")
	var y_tete := 1.6 if not assise else 1.08
	var buste := CapsuleMesh.new()
	buste.radius = 0.17
	buste.height = 0.62
	_mesh(j, "Buste", buste, Vector3(0, y_tete - 0.38, 0), "robe" if robe else "chemise")
	var tete := SphereMesh.new()
	tete.radius = 0.13
	tete.height = 0.26
	_mesh(j, "Tete", tete, Vector3(0, y_tete, 0), "peau")
	var cheveux := Node3D.new()
	cheveux.position = Vector3(0, y_tete + 0.05, 0.08)
	_ajouter(j, cheveux, "Cheveux")
	_boite(cheveux, "Meche", Vector3(0, -0.2 if robe else 0.0, 0.08 if robe else -0.02), Vector3(0.26, 0.45 if robe else 0.12, 0.08 if robe else 0.24), "cheveux", false)
	_boite(cheveux, "Dessus", Vector3(0, 0.07, -0.06), Vector3(0.28, 0.1, 0.26), "cheveux", false)
	return j


## La mobylette de Juliette, avec Juliette dessus (vers son -Z).
func _mobylette(parent: Node3D, nom: String) -> Node3D:
	var mob := Node3D.new()
	_ajouter(parent, mob, nom)
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
	var j := _silhouette(mob, "Juliette", true, true)
	j.position = Vector3(0, 0.35, 0.15)
	return mob


# --- Le bonheur : l'atelier au soleil, puis la balade ------------------------


## Le même atelier, des années plus tôt, un jour de soleil : la vie à deux.
## Les clés de la moto, que Juliette cache, ne se voient que dans le miroir.
func _bonheur() -> void:
	var g := _groupe("Bonheur", BONHEUR)
	var c := BONHEUR
	var h := 4.0
	_sol_plafond(g, c.x - 5.3, c.x + 5.3, c.z - 4.3, c.z + 4.3, h, "parquet_clair", "plafond")
	_mur(g, "Mur_nord", true, c.z - 4.15, c.x - 5.3, c.x + 5.3, h, "soleil_mur")
	_mur(g, "Mur_sud", true, c.z + 4.15, c.x - 5.3, c.x + 5.3, h, "soleil_mur", [[c.x - 3.0, 1.2, 2.3]])
	_mur(g, "Mur_ouest", false, c.x - 5.15, c.z - 4.0, c.z + 4.0, h, "soleil_mur", [[c.z, 3.0, 2.0, 0.9]])
	_mur_invisible(g, "Fenetre", c + Vector3(-5.15, 1.9, 0), Vector3(EP, 2.0, 3.0))
	_mur(g, "Mur_est", false, c.x + 5.15, c.z - 4.0, c.z + 4.0, h, "soleil_mur")
	# La vie à deux : deux chevalets, ses toiles à elle et à lui, des fleurs,
	# des photos, sa veste rouge, un tourne-disque.
	_boite(g, "Chevalet_thomas", Vector3(1.5, 0.8, 0.5), Vector3(0.08, 1.6, 0.08), "chevalet", false)
	_boite(g, "Toile_thomas", Vector3(1.5, 1.3, 0.55), Vector3(1.0, 0.75, 0.04), "toile", false)
	_boite(g, "Toile_thomas_portrait", Vector3(1.5, 1.3, 0.58), Vector3(0.3, 0.45, 0.01), "toile_juliette", false)
	_boite(g, "Chevalet_juliette", Vector3(-1.5, 0.8, -0.5), Vector3(0.08, 1.6, 0.08), "chevalet", false)
	_boite(g, "Toile_juliette", Vector3(-1.5, 1.3, -0.45), Vector3(1.0, 0.75, 0.04), "toile", false)
	_boite(g, "Toile_juliette_mer", Vector3(-1.5, 1.2, -0.42), Vector3(0.9, 0.3, 0.01), "mer", false)
	_boite(g, "Table", Vector3(3.5, 0.38, -2.8), Vector3(1.4, 0.76, 0.8), "table")
	_boite(g, "Vase", Vector3(3.2, 0.9, -2.8), Vector3(0.15, 0.28, 0.15), "vase", false)
	_boite(g, "Fleurs", Vector3(3.2, 1.12, -2.8), Vector3(0.3, 0.16, 0.3), "fleurs", false)
	_boite(g, "Tasse_1", Vector3(3.7, 0.82, -2.6), Vector3(0.1, 0.12, 0.1), "tasse", false)
	_boite(g, "Tasse_2", Vector3(3.9, 0.82, -2.9), Vector3(0.1, 0.12, 0.1), "tasse", false)
	_boite(g, "Tourne_disque", Vector3(4.6, 0.85, -1.2), Vector3(0.5, 0.15, 0.4), "disque", false)
	for i in 4:
		_boite(g, "Photo_%d" % i, Vector3(-3.0 + 1.1 * i, 2.4, -3.98), Vector3(0.6, 0.45, 0.03), "photo", false)
	_boite(g, "Veste", Vector3(-4.95, 1.6, 3.4), Vector3(0.06, 0.7, 0.45), "veste", false)
	# Le miroir, et l'étagère derrière Thomas où Juliette cache les clés.
	_boite(g, "Miroir_cadre", Vector3(4.98, 1.6, 1.5), Vector3(0.04, 1.5, 1.1), "rambarde", false)
	var miroir := Miroir.new()
	miroir.taille = Vector2(1.0, 1.4)
	miroir.position = Vector3(4.955, 1.6, 1.5)
	miroir.rotation.y = -PI / 2
	_ajouter(g, miroir, "Miroir")
	_boite(g, "Etagere", Vector3(-4.8, 1.4, 1.6), Vector3(0.5, 0.06, 1.2), "etagere")
	var cles := RigidBody3D.new()
	cles.position = Vector3(-4.75, 1.47, 1.7)
	cles.freeze = true
	cles.add_to_group("cles", true)
	_ajouter(g, cles, "Cles")
	_forme(cles, "CollisionShape3D", _boite_forme(Vector3(0.2, 0.1, 0.2)))
	var anneau := TorusMesh.new()
	anneau.inner_radius = 0.03
	anneau.outer_radius = 0.05
	var ma := _mesh(cles, "Anneau", anneau, Vector3.ZERO, "cle")
	ma.layers = Miroir.COUCHE_REFLET
	var tige := BoxMesh.new()
	tige.size = Vector3(0.12, 0.02, 0.03)
	var mt := _mesh(cles, "Cle", tige, Vector3(0.09, 0, 0), "cle")
	mt.layers = Miroir.COUCHE_REFLET
	var j := _silhouette(g, "Juliette", true)
	j.position = Vector3(-1.0, 0, 0.6)
	j.rotation.y = -PI * 0.7
	_lampe(g, "Lumiere", c + Vector3(-3.0, 3.2, 0), 12.0, true, 1.6)
	var soleil := SpotLight3D.new()
	soleil.position = Vector3(-8, 4.5, 0)
	soleil.rotation_degrees = Vector3(-25, -90, 0)
	soleil.spot_range = 16.0
	soleil.spot_angle = 35.0
	soleil.light_energy = 3.0
	soleil.light_color = Color("ffe8a3")
	soleil.shadow_enabled = true
	_ajouter(g, soleil, "Soleil_fenetre")
	# Dehors, devant la porte : la moto.
	_boite(g, "Trottoir", Vector3(0, -0.25, 6.3), Vector3(12, 0.5, 4.0), "trottoir")
	# Autour : de l'herbe, des arbres, la mer au loin.
	_boite(g, "Herbe", Vector3(0, -0.3, 0), Vector3(80, 0.4, 80), "champ", false)
	for i in 8:
		var a := TAU * i / 8.0 + 0.3
		var p := Vector3(cos(a) * 16.0, 0, sin(a) * 16.0 + 2.0)
		_boite(g, "Arbre_%d_tronc" % i, p + Vector3(0, 1.5, 0), Vector3(0.5, 3.0, 0.5), "tronc", false)
		_boite(g, "Arbre_%d_feuillage" % i, p + Vector3(0, 3.8, 0), Vector3(3.0, 2.2, 3.0), "feuillage", false)
	_mur_invisible(g, "Bord_dehors", c + Vector3(0, 2, 8.4), Vector3(12, 4, 0.4))
	_mur_invisible(g, "Bord_dehors_g", c + Vector3(-6, 2, 6.3), Vector3(0.4, 4, 4))
	_mur_invisible(g, "Bord_dehors_d", c + Vector3(6, 2, 6.3), Vector3(0.4, 4, 4))
	var mob := _mobylette(g, "Mobylette")
	mob.position = Vector3(-1.0, 0, 6.5)
	mob.rotation.y = -PI / 2
	mob.get_node("Juliette").visible = false
	_zone(g, "Depart_moto", c + Vector3(-1.0, 1.0, 6.5), Vector3(3.0, 2.0, 2.5))
	_marque(g, "Depart", c + Vector3(1.5, 0, 2.0), PI)
	_pensee(g, "PenseeAtelier", c + Vector3(-1.5, 1.3, -0.45), "Notre atelier. Elle peignait la mer, moi je la peignais, elle.", 6.0, 25.0)
	_pensee(g, "PenseePhotos", c + Vector3(-1.4, 2.4, -3.98), "Nos photos… On était heureux.", 5.0, 20.0)


## La balade : une route au bord de la mer, au coucher du soleil, avec des
## champs de l'autre côté. Le niveau y fait avancer la moto.
func _balade() -> void:
	var g := _groupe("Balade", BALADE)
	var pas := 15.0
	var n := int(LONGUEUR_BALADE / pas)
	for i in n:
		var z0 := -pas * i
		var z1 := z0 - pas
		var a := Vector3(Niveau4.virage(z0), 0, z0)
		var b := Vector3(Niveau4.virage(z1), 0, z1)
		var morceau := _boite(g, "Route_%d" % i, (a + b) / 2 + Vector3(0, -0.1, 0), Vector3(6.0, 0.2, a.distance_to(b) + 0.4), "route_claire", false)
		morceau.rotation.y = atan2(-(b.x - a.x), -(b.z - a.z))
		_boite(g, "Falaise_%d" % i, (a + b) / 2 + Vector3(-7.0, -1.5, 0), Vector3(8.0, 3.0, pas + 0.4), "falaise", false)
		_boite(g, "Champ_%d" % i, (a + b) / 2 + Vector3(13.0, -0.3, 0), Vector3(20.0, 0.4, pas + 0.4), "champ", false)
		if i % 3 == 0:
			_boite(g, "Arbre_%d_tronc" % i, (a + b) / 2 + Vector3(9.0 + 4.0 * (i % 2), 1.5, 0), Vector3(0.5, 3.0, 0.5), "tronc", false)
			_boite(g, "Arbre_%d_feuillage" % i, (a + b) / 2 + Vector3(9.0 + 4.0 * (i % 2), 3.8, 0), Vector3(3.0, 2.0, 3.0), "feuillage", false)
	_boite(g, "Mer", Vector3(-160, -3.0, -LONGUEUR_BALADE / 2), Vector3(300, 0.2, LONGUEUR_BALADE + 200), "mer", false)
	var mob := _mobylette(g, "Mobylette")
	mob.position = Vector3(0, 0, 0)


# --- L'atelier ---------------------------------------------------------------


func _atelier() -> void:
	var g := _groupe("Atelier")
	_sol_plafond(g, -6.3, 6.3, -5.3, 5.3, H, "parquet", "plafond")
	_mur(g, "Mur_nord", true, -5.15, -6.3, 6.3, H, "mur")
	_mur(g, "Mur_sud", true, 5.15, -6.3, 6.3, H, "mur", [[PORTE_X, 1.2, 2.3]])
	_mur(g, "Mur_ouest", false, -6.15, -5.0, 5.0, H, "mur", [[0.5, 4.0, 3.0, 1.0]])
	_mur_invisible(g, "Fenetre", Vector3(-6.15, 2.5, 0.5), Vector3(EP, 3.0, 4.0))
	_mur(g, "Mur_est", false, 6.15, -5.0, 5.0, H, "mur")
	# La porte de la rue : elle tourne autour de son gond (à l'ouest).
	var gond := Node3D.new()
	gond.position = Vector3(PORTE_X - 0.6, 0, 5.15)
	_ajouter(g, gond, "Porte")
	_boite(gond, "Panneau", Vector3(0.6, 1.15, 0), Vector3(1.2, 2.3, 0.08), "porte")
	_boite(gond, "Poignee", Vector3(1.05, 1.05, -0.06), Vector3(0.1, 0.05, 0.05), "poignee", false)
	_temporel(gond, [[0.0, gond.position, Vector3.ZERO, true], [30.0, gond.position, Vector3.ZERO, true],
		[30.6, gond.position, Vector3(0, -1.6, 0), true], [33.0, gond.position, Vector3(0, -1.6, 0), true],
		[33.6, gond.position, Vector3.ZERO, true]])
	_zone(g, "Sortie", Vector3(PORTE_X, 1.0, 6.2), Vector3(1.6, 2.0, 1.0))
	# Le portemanteau, le casque de Juliette et la grille du plancher.
	_boite(g, "Portemanteau", Vector3(-4.8, 0.9, 4.5), Vector3(0.08, 1.8, 0.08), "portemanteau", false)
	_boite(g, "Portemanteau_pied", Vector3(-4.8, 0.03, 4.5), Vector3(0.5, 0.06, 0.5), "portemanteau", false)
	_boite(g, "Crochet", Vector3(-4.8, 1.62, 4.35), Vector3(0.05, 0.05, 0.25), "portemanteau", false)
	_boite(g, "Grille", Vector3(-4.3, 0.005, 3.8), Vector3(0.8, 0.012, 0.6), "grille", false)
	for i in 5:
		_boite(g, "Grille_barreau_%d" % i, Vector3(-4.62 + 0.16 * i, 0.012, 3.8), Vector3(0.04, 0.01, 0.6), "parquet", false)
	var casque := RigidBody3D.new()
	casque.position = Vector3(-4.8, 1.5, 4.25)
	casque.freeze = true
	casque.add_to_group("casque", true)
	_ajouter(g, casque, "Casque")
	_forme(casque, "CollisionShape3D", _boite_forme(Vector3(0.32, 0.3, 0.34)))
	var coque := SphereMesh.new()
	coque.radius = 0.16
	coque.height = 0.3
	_mesh(casque, "Coque", coque, Vector3.ZERO, "casque")
	_boite(casque, "Visiere", Vector3(0, 0.0, -0.13), Vector3(0.22, 0.1, 0.06), "visiere", false)
	var sol := Vector3(-4.3, 0.15, 3.8)
	_temporel(casque, [[0.0, casque.position, Vector3.ZERO, true], [19.8, casque.position, Vector3.ZERO, true],
		[20.4, sol, Vector3(0.4, 0, 0.8), true], [21.0, sol, Vector3(0.4, 0, 0.8), true],
		[21.4, sol + Vector3(0, -0.6, 0), Vector3(0.4, 0, 0.8), true], [21.5, sol + Vector3(0, -0.6, 0), Vector3.ZERO, false]])
	_pensee(g, "PenseeGrille", Vector3(-4.3, 0.1, 3.8), "Son casque est tombé là-dessous…", 4.0, 20.0, true, false)
	# Le chevalet, la table et la tasse (sous la mezzanine), le téléphone.
	_boite(g, "Chevalet", Vector3(0.5, 0.8, 1.0), Vector3(0.08, 1.6, 0.08), "chevalet", false)
	_boite(g, "Chevalet_toile", Vector3(0.5, 1.3, 1.05), Vector3(1.0, 0.75, 0.04), "toile", false)
	_boite(g, "Chevalet_peinture", Vector3(0.5, 1.3, 1.08), Vector3(0.9, 0.3, 0.01), "toile_peinte", false)
	_boite(g, "Table", Vector3(-1.5, 0.38, -3.2), Vector3(1.6, 0.76, 0.9), "table")
	var tasse := _boite(g, "Tasse", Vector3(-1.1, 0.83, -3.0), Vector3(0.1, 0.12, 0.1), "tasse", false)
	_temporel(tasse, [[0.0, tasse.position, Vector3.ZERO, true], [24.0, tasse.position, Vector3.ZERO, true],
		[24.4, Vector3(-0.5, 0.06, -2.3), Vector3(1.2, 0, 0.6), true], [24.45, Vector3(-0.5, 0.06, -2.3), Vector3.ZERO, false]])
	var morceaux := Node3D.new()
	_ajouter(g, morceaux, "Morceaux")
	for i in 4:
		_boite(morceaux, "Morceau_%d" % i, Vector3(-0.5 + 0.12 * cos(i * 1.7), 0.02, -2.3 + 0.12 * sin(i * 1.7)), Vector3(0.05, 0.02, 0.04), "tasse", false)
	_temporel(morceaux, [[0.0, Vector3.ZERO, Vector3.ZERO, false], [24.44, Vector3.ZERO, Vector3.ZERO, false], [24.45, Vector3.ZERO, Vector3.ZERO, true]])
	var telephone := Node3D.new()
	telephone.position = Vector3(-1.9, 0.77, -3.3)
	telephone.visible = false
	_ajouter(g, telephone, "Telephone")
	_boite(telephone, "Boitier", Vector3.ZERO, Vector3(0.08, 0.015, 0.15), "telephone", false)
	_boite(telephone, "Ecran", Vector3(0, 0.01, 0), Vector3(0.065, 0.005, 0.12), "ecran", false)
	for l in [["Lampe_haut", Vector3(0, 5.5, -1), 12.0], ["Lampe_bas", Vector3(-1.5, 2.4, -3.0), 5.0]]:
		_lampe(g, l[0], l[1], l[2], true, 1.0)
	_marque(g, "Verite", Vector3(-1.0, 0, 2.2), PI * 0.8)
	_pensee(g, "PenseePluie", Vector3(-6.15, 2.5, 0.5), "La pluie… elle ne tombe plus.", 9.0, 25.0)


func _mezzanine() -> void:
	var g := _groupe("Mezzanine")
	_boite(g, "Plancher", Vector3(0, MEZZ_Y - 0.15, -3.25), Vector3(12.0, 0.3, 3.5), "mezzanine")
	# La rambarde, trop haute pour sauter, s'arrête à l'escalier.
	_boite(g, "Rambarde", Vector3(-0.85, MEZZ_Y + 0.6, -1.55), Vector3(10.3, 1.2, 0.1), "rambarde")
	_mur_invisible(g, "Haut_rambarde", Vector3(-0.85, MEZZ_Y + 2.0, -1.55), Vector3(10.3, 1.6, 0.1))
	_boite(g, "Lit", Vector3(-4.5, MEZZ_Y + 0.25, -4.0), Vector3(1.4, 0.5, 2.0), "lit")
	_boite(g, "Lit_drap", Vector3(-4.5, MEZZ_Y + 0.52, -4.1), Vector3(1.3, 0.06, 1.6), "drap", false)
	_marque(g, "Depart", Vector3(-3.0, MEZZ_Y, -3.6), PI)


## L'escalier de la mezzanine, et l'étagère qui tombe dessus pendant la
## dispute.
func _escalier() -> void:
	var g := _groupe("Escalier")
	for i in 12:
		var k := (i + 0.5) / 12.0
		var p := ESC_HAUT.lerp(ESC_BAS, k)
		_boite(g, "Marche_%d" % i, Vector3(p.x, p.y - 0.12, p.z), Vector3(1.4, 0.24, 0.42), "marche", false)
	_rampe(g, "Pente", ESC_BAS, ESC_HAUT, 1.4)
	# Le côté de l'escalier : on ne saute pas dans la pièce.
	var cote := StaticBody3D.new()
	_ajouter(g, cote, "Cote")
	_forme(cote, "CollisionShape3D", _boite_forme(Vector3(0.1, 5.0, 5.0)), Vector3(ESC_X - 0.75, 2.5, 1.0))
	var rampe := _boite(g, "Rampe_escalier", (ESC_HAUT + ESC_BAS) / 2 + Vector3(-0.72, 0.9, 0), Vector3(0.06, 0.06, 5.7), "rambarde", false)
	rampe.rotation.x = atan2(2.8, 5.0)
	# L'étagère, contre le mur sud, au pied de l'escalier. Elle tombe (en
	# pivotant sur son pied) en travers du bas de l'escalier.
	var pied := Node3D.new()
	pied.position = Vector3(ESC_X, 0, 4.8)
	_ajouter(g, pied, "Etagere")
	_boite(pied, "Meuble", Vector3(0, 1.6, -0.2), Vector3(1.5, 3.2, 0.4), "etagere")
	for i in 6:
		_boite(pied, "Livre_%d" % i, Vector3(-0.5 + 0.2 * i, 1.0 + 0.8 * (i % 3), -0.42), Vector3(0.12, 0.35, 0.05), "livre_%d" % (i % 3 + 1), false)
	_temporel(pied, [[0.0, pied.position, Vector3.ZERO, true], [28.0, pied.position, Vector3.ZERO, true],
		[28.6, pied.position, Vector3(-1.1, 0, 0), true]])
	_pensee(g, "PenseeEtagere", Vector3(ESC_X, 0.8, 3.4), "L'étagère est tombée sur l'escalier.", 6.0, 25.0)


## Juliette et Thomas, le soir de la dispute (des silhouettes qui suivent la
## ligne du temps).
func _dispute() -> void:
	var g := _groupe("Souvenir")
	var j := _silhouette(g, "Juliette", true)
	var jp := [Vector3(1.2, 0, 2.2), Vector3(4.2, 0, 3.8), Vector3(PORTE_X, 0, 4.4), Vector3(PORTE_X, 0, 6.8)]
	_temporel(j, [[0.0, jp[0], Vector3(0, -PI * 0.75, 0), true], [22.0, jp[0], Vector3(0, -PI * 0.75, 0), true],
		[26.0, jp[1], Vector3(0, -PI * 0.5, 0), true], [28.5, jp[1], Vector3(0, PI * 0.5, 0), true],
		[30.0, jp[2], Vector3(0, PI, 0), true], [31.4, jp[3], Vector3(0, PI, 0), true], [31.5, jp[3], Vector3(0, PI, 0), false]])
	var t := _silhouette(g, "Thomas", false)
	var tp := [Vector3(0.3, 0, 0.3), Vector3(-4.3, 0, 3.6), Vector3(-2.2, 0, 3.2), Vector3(PORTE_X + 0.5, 0, 4.5)]
	_temporel(t, [[0.0, tp[0], Vector3(0, PI * 0.25, 0), true], [19.0, tp[0], Vector3(0, PI * 0.25, 0), true],
		[20.0, tp[1], Vector3(0, PI * 0.8, 0), true], [22.0, tp[0], Vector3(0, PI * 0.25, 0), true],
		[29.5, tp[0], Vector3(0, PI * 0.25, 0), true], [31.0, tp[2], Vector3(0, PI, 0), true],
		[33.0, tp[3], Vector3(0, PI, 0), true], [36.0, tp[0], Vector3(0, PI * 0.25, 0), true]])


## La rue, sous la pluie, et la mobylette de Juliette.
func _rue() -> void:
	var g := _groupe("Rue")
	_boite(g, "Sol", Vector3(0, -0.25, 10.15), Vector3(30, 0.5, 9.7), "rue")
	_boite(g, "Trottoir", Vector3(0, 0.05, 6.1), Vector3(30, 0.1, 1.4), "trottoir", false)
	_boite(g, "Facade_face", Vector3(0, 4, 15.0), Vector3(30, 8, 0.5), "facade")
	_mur_invisible(g, "Bord_ouest", Vector3(-15, 3, 10), Vector3(0.5, 6, 10))
	_mur_invisible(g, "Bord_est", Vector3(15, 3, 10), Vector3(0.5, 6, 10))
	for i in 4:
		_boite(g, "Facade_%d" % i, Vector3(-11 + 7.3 * i, 3.5, -6.5), Vector3(6.5, 7.0 + 2.0 * (i % 2), 2.0), "facade_%d" % (i % 3 + 1) if i % 3 > 0 else "facade", false)
	var mob := _mobylette(g, "Mobylette")
	mob.rotation.y = -PI / 2
	var garee := Vector3(PORTE_X, 0.0, 8.4)
	var partie := Vector3(20, 0.0, 8.4)
	_temporel(mob, [[0.0, garee, Vector3(0, -PI / 2, 0), true], [31.5, garee, Vector3(0, -PI / 2, 0), true],
		[33.5, partie, Vector3(0, -PI / 2, 0), true], [33.6, partie, Vector3(0, -PI / 2, 0), false]])
	var rider := mob.get_node("Juliette") as Node3D
	_temporel(rider, [[0.0, rider.position, Vector3.ZERO, false], [31.5, rider.position, Vector3.ZERO, true]])
	var pluie := Pluie.new()
	pluie.position = Vector3(0, 4.5, 10)
	pluie.taille = Vector3(30, 9, 9)
	pluie.nombre = 700
	_ajouter(g, pluie, "Pluie")
	var pluie_ouest := Pluie.new()
	pluie_ouest.position = Vector3(-10, 4.5, 0)
	pluie_ouest.taille = Vector3(7, 9, 10)
	pluie_ouest.nombre = 300
	_ajouter(g, pluie_ouest, "Pluie_ouest")
	_lampe(g, "Reverbere", Vector3(3, 4.5, 9), 12.0, true, 1.2)


# --- La course-poursuite -----------------------------------------------------


## La route sous la pluie, qui se déforme comme dans un rêve : les immeubles
## se penchent de plus en plus au-dessus d'elle. Des barrières, des murs et
## des trous ; puis la rue inondée, toute noire, où l'on ne voit la rue que
## dans l'eau ; puis les toiles du peintre, et derrière, les vrais murs.
## Jusqu'au vide.
func _course() -> void:
	var g := _groupe("Course", COURSE)
	var reflets := Node3D.new()
	_ajouter(g, reflets, "Reflets")
	var trous := []
	for o in OBSTACLES:
		if o[1] == "trou":
			trous.append([o[0], o[0] - o[2]])
	# La route, coupée aux trous, et l'eau de la rue inondée.
	var debut := 12.0
	var morceaux := []
	for t in trous:
		morceaux.append([debut, t[0]])
		debut = t[1]
	morceaux.append([debut, FIN_COURSE])
	var k := 0
	for m in morceaux:
		var coupes := [m[0]]
		for c in INONDEE:
			if c < m[0] and c > m[1]:
				coupes.append(c)
		coupes.append(m[1])
		for i in coupes.size() - 1:
			var z0: float = coupes[i]
			var z1: float = coupes[i + 1]
			var r := _boite(g, "Route_%d" % k, Vector3(0, -0.25, (z0 + z1) / 2), Vector3(9.0, 0.5, z0 - z1), "rue")
			if _dans_l_eau((z0 + z1) / 2):
				r.name = "Eau_%d" % k
				r.material = _eau()
				r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			k += 1
	_mur_invisible(g, "Bord_g", COURSE + Vector3(-4.7, 3, (12 + FIN_COURSE) / 2), Vector3(0.4, 6, 12 - FIN_COURSE))
	_mur_invisible(g, "Bord_d", COURSE + Vector3(4.7, 3, (12 + FIN_COURSE) / 2), Vector3(0.4, 6, 12 - FIN_COURSE))
	_mur_invisible(g, "Bord_debut", COURSE + Vector3(0, 3, 12.2), Vector3(9.4, 6, 0.4))
	for o in OBSTACLES:
		var z: float = o[0]
		match o[1]:
			"barriere":
				_obstacle(g, "Barriere_%d" % int(-z), Vector3(0, 0.3, z), Vector3(9.0, 0.6, 0.3), "barriere")
			"mur":
				for v in o[2]:
					_obstacle(g, "Mur_%d_%d" % [int(-z), v], Vector3(VOIES[v], 1.5, z), Vector3(3.0, 3.0, 0.6), "mur_course")
			"toiles":
				_toiles(g, z, o[2])
	# Parmi les toiles, les lignes de la route brillent : on les voit aussi
	# les yeux fermés.
	for x in [-4.4, -1.5, 1.5, 4.4]:
		var l := _boite(g, "Ligne_%d" % int(x * 10), Vector3(x, 0.01, (DEBUT_TOILES + FIN_COURSE) / 2), Vector3(0.12, 0.02, DEBUT_TOILES - FIN_COURSE), "ligne", false)
		l.layers = 1 | COUCHE_VRAI
	# Les immeubles : un rez-de-chaussée solide au bord de la route, puis des
	# étages qui penchent de plus en plus au-dessus d'elle, en tournant autour
	# de leur bord intérieur, à 4 m de haut : ils ne descendent jamais jusqu'à
	# Thomas. Au bout, ils se rejoignent au-dessus de la route.
	k = 0
	for z in range(0, int(FIN_COURSE), -12):
		var penche := clampf(-float(z) / -FIN_COURSE, 0.0, 1.0)
		for cote in [-1, 1]:
			var nom := "Immeuble_%d_%s" % [k, "g" if cote < 0 else "d"]
			var couleur := "facade_%d" % ((k + (1 if cote > 0 else 0)) % 3 + 1) if (k + 1) % 3 > 0 else "facade"
			var haut := 10.0 + 6.0 * ((k * 7 + (3 if cote > 0 else 0)) % 4)
			var rez := _boite(g, nom + "_rez", Vector3(cote * (BORD + 2.5), REZ / 2, z), Vector3(5.0, REZ, 10.0), couleur)
			var pivot := Node3D.new()
			pivot.position = Vector3(cote * BORD, REZ, z)
			pivot.rotation.z = cote * penche * 1.0
			_ajouter(g, pivot, nom)
			var etages := _boite(pivot, "Etages", Vector3(cote * 2.5, (haut - REZ) / 2, 0), Vector3(5.0, haut - REZ, 10.0), couleur, false)
			if _dans_l_eau(z):
				# Dans la nuit, on ne voit plus que leur reflet.
				rez.layers = Miroir.COUCHE_REFLET
				etages.layers = Miroir.COUCHE_REFLET
				_boite(reflets, "Reflet_" + nom + "_rez", Vector3(cote * (BORD + 2.5), -REZ / 2 - SOUS_L_EAU, z), Vector3(5.0, REZ, 10.0), couleur, false).material = _mat_reflet(couleur)
				var p := Node3D.new()
				p.position = Vector3(cote * BORD, -REZ - SOUS_L_EAU, z)
				p.rotation.z = -cote * penche * 1.0
				_ajouter(reflets, p, "Reflet_" + nom)
				_boite(p, "Reflet_etages", Vector3(cote * 2.5, -(haut - REZ) / 2, 0), Vector3(5.0, haut - REZ, 10.0), couleur, false).material = _mat_reflet(couleur)
		k += 1
	# Des toiles qui flottent au-dessus de la route.
	for i in 8:
		var z := -40.0 - 36.0 * i
		var c := _boite(g, "Toile_ciel_%d" % i, Vector3(-3.0 + 2.0 * (i % 4), 8.0 + (i % 3), z), Vector3(2.4, 1.6, 0.08), "toile_peinte" if i % 2 == 0 else "robe", false)
		c.rotation = Vector3(0.3 * (i % 3), 0.5 * i, 0.2 * (i % 2))
		if _dans_l_eau(z):
			c.layers = Miroir.COUCHE_REFLET
	_marque(g, "Depart", COURSE + Vector3(0, 0, 8.0), 0.0)
	_zone(g, "Vide", COURSE + Vector3(0, -8.0, (12 + FIN_COURSE) / 2), Vector3(40, 4, 12 - FIN_COURSE + 40))
	_zone(g, "Bord", COURSE + Vector3(0, 1.0, FIN_COURSE - 0.5), Vector3(9.0, 4.0, 1.0))
	var mob := _mobylette(g, "Mobylette")
	mob.position = Vector3(0, 0, -4.0)
	for n in mob.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).layers = 1 | COUCHE_VRAI
	var reflet := _mobylette(reflets, "Mobylette")
	reflet.scale = Vector3(1, -1, 1)
	reflet.visible = false
	var pluie := Pluie.new()
	pluie.taille = Vector3(18, 10, 24)
	pluie.nombre = 700
	pluie.vitesse = 12.0
	_ajouter(g, pluie, "Pluie")
	for i in 14:
		_lampe(g, "Reverbere_%d" % i, COURSE + Vector3(-4.0 if i % 2 == 0 else 4.0, 5.0, -10.0 - 33.0 * i), 16.0, false, 1.4)


## Dans la rue inondée (z, en coordonnées de la route).
func _dans_l_eau(z: float) -> bool:
	return z < INONDEE[0] and z > INONDEE[1]


## L'eau de la rue inondée : sombre, et on voit au travers le reflet de la
## rue.
func _eau() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.05, 0.12, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## Les couleurs du reflet, dans l'eau : plus bleues, et qui brillent un peu
## dans le noir.
func _mat_reflet(cle: String) -> StandardMaterial3D:
	var nom := "reflet_" + cle
	if not _materiaux.has(nom):
		var c := Color(_couleurs()[cle]).lerp(Color("4ea8de"), 0.35)
		var m := Style.materiau(c, true)
		m.emission_energy_multiplier = 0.6
		_materiaux[nom] = m
	return _materiaux[nom]


## Un obstacle de la course (Thomas s'y cogne). Dans la rue inondée, on ne
## voit que son reflet, dans l'eau.
func _obstacle(g: Node3D, nom: String, pos: Vector3, taille: Vector3, couleur: String) -> CSGBox3D:
	var b := _boite(g, nom, pos, taille, couleur)
	b.add_to_group("obstacle_course", true)
	if _dans_l_eau(pos.z):
		b.layers = Miroir.COUCHE_REFLET
		var r := _boite(g.get_node("Reflets"), "Reflet_" + nom, Vector3(pos.x, -pos.y - SOUS_L_EAU, pos.z), taille, couleur, false)
		r.material = _mat_reflet(couleur)
	return b


## Trois toiles peintes en travers de la route, en l'air au-dessus d'elle (le
## niveau les fait tomber quand Thomas arrive) ; derrière, les vrais murs,
## qu'on ne voit que les yeux fermés.
func _toiles(g: Node3D, z: float, bloquees: Array) -> void:
	for v in VOIES.size():
		var t := Node3D.new()
		t.position = Vector3(VOIES[v], Niveau4.HAUT_TOILES, z + 0.5)
		t.add_to_group("toiles_course", true)
		_ajouter(g, t, "Toile_%d_%d" % [int(-z), v])
		_boite(t, "Cadre", Vector3(0, 1.5, 0), Vector3(3.0, 3.0, 0.1), "cadre_toile", false)
		_boite(t, "Peinture", Vector3(0, 1.5, 0.06), Vector3(2.7, 2.7, 0.04), "mur_course", false)
		for j in 3:
			_boite(t, "Joint_%d" % j, Vector3(0, 0.75 + 0.75 * j, 0.085), Vector3(2.7, 0.06, 0.01), "joint", false)
		if v in bloquees:
			var b := _boite(g, "Vrai_mur_%d_%d" % [int(-z), v], Vector3(VOIES[v], 1.5, z), Vector3(3.0, 3.0, 0.6), "vrai")
			b.layers = COUCHE_VRAI
			b.add_to_group("obstacle_course", true)
			var m := _mat("vrai")
			m.emission_energy_multiplier = 2.0


## Le vide : on y tombe, Juliette sous Thomas.
func _vide() -> void:
	var g := _groupe("Vide", VIDE)
	var j := _silhouette(g, "Juliette", true)
	j.position = Vector3(0, -6, 0)
	var pluie := Pluie.new()
	pluie.taille = Vector3(12, 30, 12)
	pluie.nombre = 500
	pluie.vitesse = -30.0
	_ajouter(g, pluie, "Pluie")
	_marque(g, "Chute", VIDE + Vector3(0, 0, 0.6), 0.0)
