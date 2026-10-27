extends RefCounted

## Construit scenes/maison.tscn à partir du code (lancé par construire_maison.gd).
## Attention : reconstruire écrase les retouches faites dans l'éditeur.

const TempsScript := preload("res://scripts/time/temps.gd")
const PRESENT := TempsScript.Epoque.PRESENT
const PASSE := TempsScript.Epoque.PASSE

const COULEURS := {
	"hall_sol": "ffd6e8", "hall_mur": "8be9fd",
	"couloir_sol": "ffe66d", "couloir_mur": "c3a6ff",
	"salon_sol": "4d96ff", "salon_mur": "ff7eb6", "canape": "ffd93d",
	"pierre": "c08552", "colonne": "e0c097",
	"atelier_sol": "3a3360", "atelier_mur": "6bcb77",
	"horloge": "ff3d7f", "aiguille": "00f5d4",
	"photo_cadre": "ffffff", "photo_rouge": "ff595e", "photo_bonne": "00d1b2",
	"photo_jaune": "ffca3a", "photo_violette": "9b5de5", "soleil": "fff3b0", "repere": "00f5d4",
	"porte": "f15bb5", "jardin": "9ef01a",
	"plafond": "fff4fb", "plafond_couloir": "efe6ff", "plafond_salon": "fff0f6",
	"plinthe": "fffcf2", "toit": "ff5d5d", "faitage": "c1121f", "poutre": "7a4a2e",
}

const HAUTEUR_HALL := 4.0
const HAUTEUR_SALON := 5.0

var _racine: Node3D
var _materiaux := {}
var _m  # meubles (tools/meubles.gd)


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Maison"
	_racine.set_script(load("res://scripts/niveau/maison.gd"))
	_m = load("res://tools/meubles.gd").new(self)
	_environnement()
	_hall()
	_couloir()
	_salon()
	_atelier()
	_jardin()
	_ciel()
	_joueur_et_interface()
	var scene := PackedScene.new()
	var err := scene.pack(_racine)
	if err == OK:
		err = ResourceSaver.save(scene, "res://scenes/maison.tscn")
	print("maison.tscn : ", error_string(err))
	_racine.free()
	return err


func _ajouter(parent: Node, enfant: Node, nom: String) -> Node:
	enfant.name = nom
	parent.add_child(enfant)
	enfant.owner = _racine
	return enfant


func _groupe(nom: String, pos := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	return _ajouter(_racine, g, nom)


func _mat(cle: String) -> StandardMaterial3D:
	if not _materiaux.has(cle):
		var lumineux: bool = cle in ["repere", "photo_bonne", "soleil", "aiguille", "horloge"]
		_materiaux[cle] = Style.materiau(Color(COULEURS[cle]), lumineux)
	return _materiaux[cle]


func _boite(parent: Node, nom: String, pos: Vector3, taille: Vector3, couleur: String, solide := true, epoque := -1) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.position = pos
	b.size = taille
	b.material = _mat(couleur)
	b.use_collision = solide
	_ajouter(parent, b, nom)
	if epoque >= 0:
		var m := EpochMember.new()
		m.epoque = epoque
		_ajouter(b, m, "EpochMember")
	return b


func _texte(parent: Node, nom: String, pos: Vector3, texte: String, rot_y := 0.0, taille := 0.006) -> Label3D:
	var l := Label3D.new()
	l.position = pos
	l.rotation.y = rot_y
	l.text = texte
	l.font_size = 64
	l.pixel_size = taille
	l.outline_size = 16
	l.modulate = Color.WHITE
	l.outline_modulate = Color("2b1d4e")
	return _ajouter(parent, l, nom)


## Une pièce rectangulaire : sol, 4 murs et plinthes. `ouvertures` donne,
## pour chaque mur ("avant" vers -Z, "arriere", "gauche", "droite"), la
## largeur d'une ouverture centrée (0 = mur plein).
func _piece(g: Node3D, centre: Vector3, taille: Vector2, sol: String, mur: String, ouvertures := {}, hauteur := 3.0) -> void:
	var lx := taille.x
	var lz := taille.y
	var h := hauteur
	_boite(g, "Sol", centre + Vector3(0, -0.25, 0), Vector3(lx, 0.5, lz), sol)
	# [centre du mur, longueur, le long de X ?, vers l'intérieur, longueur intérieure]
	var murs := {
		"avant": [Vector3(0, h / 2, -lz / 2 - 0.1), lx + 0.4, true, Vector3(0, 0, 1), lx],
		"arriere": [Vector3(0, h / 2, lz / 2 + 0.1), lx + 0.4, true, Vector3(0, 0, -1), lx],
		"gauche": [Vector3(-lx / 2 - 0.1, h / 2, 0), lz, false, Vector3(1, 0, 0), lz],
		"droite": [Vector3(lx / 2 + 0.1, h / 2, 0), lz, false, Vector3(-1, 0, 0), lz],
	}
	for cote in murs:
		var pos: Vector3 = centre + murs[cote][0]
		var longueur: float = murs[cote][1]
		var sur_x: bool = murs[cote][2]
		var dedans: Vector3 = murs[cote][3]
		var interieur: float = murs[cote][4]
		var trou: float = ouvertures.get(cote, 0.0)
		var axe := Vector3(1, 0, 0) if sur_x else Vector3(0, 0, 1)
		var pied := Vector3(pos.x, 0.06, pos.z) + dedans * 0.12
		if trou <= 0.0:
			var t := Vector3(longueur, h, 0.2) if sur_x else Vector3(0.2, h, longueur)
			_boite(g, "Mur_" + cote, pos, t, mur)
			_plinthe(g, "Plinthe_" + cote, pied, interieur, sur_x)
			continue
		var bout := (longueur - trou) / 2
		var decalage := (trou + bout) / 2
		var t2 := Vector3(bout, h, 0.2) if sur_x else Vector3(0.2, h, bout)
		_boite(g, "Mur_%s_a" % cote, pos - axe * decalage, t2, mur)
		_boite(g, "Mur_%s_b" % cote, pos + axe * decalage, t2, mur)
		var bout_i := (interieur - trou) / 2
		var decalage_i := (trou + bout_i) / 2
		_plinthe(g, "Plinthe_%s_a" % cote, pied - axe * decalage_i, bout_i, sur_x)
		_plinthe(g, "Plinthe_%s_b" % cote, pied + axe * decalage_i, bout_i, sur_x)


## Une plinthe le long d'un mur, posée au sol (décor sans collision).
func _plinthe(g: Node3D, nom: String, pos: Vector3, longueur: float, sur_x: bool) -> void:
	var t := Vector3(longueur, 0.12, 0.04) if sur_x else Vector3(0.04, 0.12, longueur)
	_boite(g, nom, pos, t, "plinthe", false)


## Un plafond solide posé à `hauteur`. Il ne fait pas d'ombre : le soleil
## continue d'éclairer la pièce (rendu cartoon lumineux).
func _plafond(g: Node3D, centre: Vector3, taille: Vector2, hauteur: float, couleur: String) -> CSGBox3D:
	var p := _boite(g, "Plafond", Vector3(centre.x, hauteur + 0.15, centre.z), Vector3(taille.x, 0.3, taille.y), couleur)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## Perce une fenêtre dans un mur (boîte CSG droite) : trou, cadre, rebord
## et vitre solide (on ne sort pas de la maison).
func _fenetre(g: Node3D, mur: CSGBox3D, nom: String, centre: Vector3, largeur: float, hauteur: float) -> void:
	var sur_x := mur.size.x > mur.size.z
	var trou := CSGBox3D.new()
	trou.operation = CSGShape3D.OPERATION_SUBTRACTION
	trou.position = centre - mur.position
	trou.size = Vector3(largeur, hauteur, 1.0) if sur_x else Vector3(1.0, hauteur, largeur)
	_ajouter(mur, trou, "Trou" + nom)
	var rot_y := 0.0 if sur_x else PI / 2
	_m.cadre_fenetre(g, "Fenetre" + nom, centre, largeur, hauteur, rot_y)
	var vitre := CSGBox3D.new()
	vitre.position = centre
	vitre.rotation.y = rot_y
	vitre.size = Vector3(largeur, hauteur, 0.02)
	vitre.material = Style.vitre()
	vitre.use_collision = true
	vitre.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ajouter(g, vitre, "Vitre" + nom)


## Un toit à deux pentes au-dessus d'un bloc (faîte le long de Z), vu depuis
## le jardin. Décor sans ombre, comme les plafonds.
func _toit(g: Node3D, centre: Vector3, largeur: float, longueur: float, mur: String, cheminee := true, pente := deg_to_rad(30.0)) -> void:
	var t := Node3D.new()
	t.position = centre
	_ajouter(g, t, "Toit")
	var debord := 0.4
	var demi := largeur / 2 + debord
	var montee := largeur / 2 * tan(pente)
	var y_bas := -debord * tan(pente)
	for cote in [-1, 1]:
		var pan := _boite(t, "Pan%s" % ("G" if cote < 0 else "D"),
			Vector3(cote * demi / 2, (y_bas + montee) / 2, 0),
			Vector3(demi / cos(pente) + 0.1, 0.2, longueur + 2 * debord), "toit", false)
		pan.rotation.z = -cote * pente
	var faitage := CSGCylinder3D.new()
	faitage.position = Vector3(0, montee + 0.08, 0)
	faitage.rotation.x = PI / 2
	faitage.radius = 0.14
	faitage.height = longueur + 2 * debord
	faitage.sides = 6
	faitage.material = _mat("faitage")
	_ajouter(t, faitage, "Faitage")
	for z in [longueur / 2 - 0.1, -longueur / 2 + 0.1]:
		var pignon := CSGPolygon3D.new()
		pignon.polygon = PackedVector2Array([Vector2(-largeur / 2, 0), Vector2(largeur / 2, 0), Vector2(0, montee)])
		pignon.depth = 0.2
		pignon.position = Vector3(0, 0, z + 0.1)
		pignon.material = _mat(mur)
		_ajouter(t, pignon, "Pignon%d" % t.get_child_count())
	if cheminee:
		_boite(t, "Cheminee", Vector3(largeur / 4, montee / 2 + 0.6, -longueur / 4), Vector3(0.7, 1.6, 0.7), "pierre", false)
	for n in t.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ancrage(g: Node3D, nom: String, point: Vector3, centre_zone: Vector3, taille_zone: Vector3) -> void:
	var a := PointAncrage.new()
	a.position = point - g.position
	_ajouter(g, a, nom)
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = taille_zone
	forme.shape = boite
	forme.position = centre_zone - point
	_ajouter(a, forme, "CollisionShape3D")


func _photo(g: Node3D, nom: String, pos: Vector3, couleur: String, avec_soleil := false, rot_y := 0.0) -> Node3D:
	var p := Node3D.new()
	p.position = pos - g.position
	p.rotation.y = rot_y
	_ajouter(g, p, nom)
	_boite(p, "Cadre", Vector3.ZERO, Vector3(0.7, 0.7, 0.04), "photo_cadre", false)
	_boite(p, "Image", Vector3(0, 0, 0.025), Vector3(0.56, 0.56, 0.02), couleur, false)
	if avec_soleil:
		var s := CSGSphere3D.new()
		s.radius = 0.12
		s.position = Vector3(0.1, 0.1, 0.04)
		s.material = _mat("soleil")
		_ajouter(p, s, "Soleil")
	return p


func _environnement() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(COULEURS["hall_sol"])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("3ee6d0")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.005
	env.fog_sky_affect = 0.0
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-55, 35, 0)
	soleil.light_energy = 0.8
	soleil.shadow_enabled = true
	soleil.shadow_blur = 1.5
	_ajouter(_racine, soleil, "Soleil")


func _hall() -> void:
	var g := _groupe("Hall")
	# 4 m sous plafond : debout sur l'estrade (1,6 m), on passe encore.
	_piece(g, Vector3(0, 0, 3), Vector2(6, 6), "hall_sol", "hall_mur", {"avant": 2.5}, HAUTEUR_HALL)
	_plafond(g, Vector3(0, 0, 3), Vector2(6.4, 6.4), HAUTEUR_HALL, "plafond")
	# Vue de loin depuis le jardin, l'entrée est une autre petite maison.
	_toit(g, Vector3(0, HAUTEUR_HALL + 0.3, 3), 6.4, 6.4, "hall_mur")
	_fenetre(g, g.get_node("Mur_arriere"), "Arriere", Vector3(1.1, 1.75, 6.1), 1.2, 1.4)
	_fenetre(g, g.get_node("Mur_gauche"), "Gauche", Vector3(-3.1, 1.8, 4.5), 1.0, 1.4)
	_m.suspension(g, "Suspension", Vector3(0, HAUTEUR_HALL, 3.5), 0.9)
	_photo(g, "PhotoSouvenir", Vector3(-2.98, 1.7, 3), "photo_bonne", true, PI / 2)
	_texte(g, "Souvenir", Vector3(-2.95, 2.3, 3), "Mon souvenir préféré", PI / 2, 0.004)
	_texte(g, "Indice", Vector3(0, 2.75, 0.05), "Le couloir ne mène nulle part…\nsauf si tu regardes le bon souvenir.", 0.0, 0.004)
	_ancrage(g, "Ancrage", Vector3(0, 0, 4.5), Vector3(0, 1.5, 3), Vector3(6, 3, 6))
	# L'entrée du couloir est sur une estrade trop haute pour un saut : il faut
	# agrandir le cube (perspective forcée) et s'en servir comme marche.
	_boite(g, "Estrade", Vector3(0, 0.8, 0.75), Vector3(6, 1.6, 1.5), "hall_mur")
	_texte(g, "IndiceEstrade", Vector3(0, 1.0, 1.52), "Trop haut ?\nPrends le cube (E), vise loin pour l'agrandir,\npose-le (E) et grimpe dessus.", 0.0, 0.0035)
	var cube: ObjetPerspectif = load("res://scenes/cube.tscn").instantiate()
	cube.position = Vector3(1.8, 0.15, 3.5)
	cube.taille_depart = 0.3
	cube.zone = AABB(Vector3(-3, -1, 0), Vector3(6, 6, 6))
	_ajouter(g, cube, "Cube")
	_m.etagere(g, "Etagere", Vector3(-0.9, 0, 5.75), PI)
	_m.kenney(g, "Tapis", "rugRound", Vector3(0, 0, 4.1), 0.0, false, -1, 2.8)
	var lampe: Node3D = _m.kenney(g, "Lampe", "lampRoundFloor", Vector3(-2.55, 0, 5.55), 0.0, false)
	_m.lumiere(lampe, Vector3(0, 1.5, 0), 3.0, 0.5)
	_m.kenney(g, "Plante", "pottedPlant", Vector3(2.55, 0, 5.55))
	_m.kenney(g, "PorteManteau", "coatRackStanding", Vector3(-2.6, 0, 2.1))
	_m.kenney(g, "Commode", "sideTableDrawers", Vector3(2.78, 0, 4.5), -PI / 2)
	var lampe_table: Node3D = _m.kenney(g, "LampeTable", "lampRoundTable", Vector3(2.8, 0.76, 4.85), -PI / 2, false)
	_m.lumiere(lampe_table, Vector3(0, 0.5, 0), 2.5, 0.4)
	_m.kenney(g, "PetitePlante", "plantSmall2", Vector3(2.8, 0.76, 4.2), 0.0, false)
	_m.kenney(g, "Ours", "bear", Vector3(-1.3, 1.62, 5.8), PI, false, -1, 1.1)
	_m.applique(g, "AppliqueGauche", Vector3(-2.88, 2.3, 1.9))
	_m.applique(g, "AppliqueDroite", Vector3(2.88, 2.3, 1.9))
	_m.horloge_murale(g, "Horloge", Vector3(2.92, 1.8, 3.6), -PI / 2, 0.35)


func _couloir() -> void:
	var g := _groupe("Couloir")
	_boite(g, "Sol", Vector3(0, -0.25, -7), Vector3(2.5, 0.5, 14), "couloir_sol")
	var h := HAUTEUR_HALL
	_boite(g, "MurGauche", Vector3(-1.35, h / 2, -7), Vector3(0.2, h, 14), "couloir_mur")
	_boite(g, "MurDroit", Vector3(1.35, h / 2, -7), Vector3(0.2, h, 14), "couloir_mur")
	_boite(g, "MurFond", Vector3(0, h / 2, -14.1), Vector3(2.9, h, 0.2), "couloir_mur")
	_plafond(g, Vector3(0, 0, -7), Vector2(2.9, 14), h, "plafond_couloir")
	# Le débord du toit ne doit pas dépasser dans le hall.
	_toit(g, Vector3(0, h + 0.3, -7.25), 2.9, 13.5, "couloir_mur", false)
	_plinthe(g, "PlintheGauche", Vector3(-1.23, 0.06, -7), 14, false)
	_plinthe(g, "PlintheDroite", Vector3(1.23, 0.06, -7), 14, false)
	_plinthe(g, "PlintheFond", Vector3(0, 0.06, -13.98), 2.5, true)
	# Les mauvaises photos sont dans l'axe ; la bonne est sur le côté, il faut
	# tourner la tête vers elle en traversant.
	_photo(g, "PhotoRouge", Vector3(-0.8, 1.8, -13.97), "photo_rouge")
	_photo(g, "PhotoViolette", Vector3(0, 1.8, -13.97), "photo_violette")
	_photo(g, "PhotoJaune", Vector3(0.8, 1.8, -13.97), "photo_jaune")
	_photo(g, "PhotoBonne", Vector3(-1.23, 1.7, -13.2), "photo_bonne", true, PI / 2)
	# Décor répété tous les 2,5 m : la boucle (10 m) ne se voit pas.
	_boite(g, "Tapis", Vector3(0, 0.011, -7), Vector3(0.9, 0.02, 13.6), "photo_violette", false)
	var couleurs_cadres := ["photo_rouge", "photo_jaune", "photo_violette"]
	for k in 6:
		_m.plafonnier(g, "Plafonnier%d" % k, Vector3(0, h, -1.25 - 2.5 * k))
	for k in 5:
		var z := -1.0 - 2.5 * k
		_m.applique(g, "Applique%dG" % k, Vector3(-1.18, 2.3, z))
		_m.applique(g, "Applique%dD" % k, Vector3(1.18, 2.3, z))
		if k < 4:
			_photo(g, "Cadre%dG" % k, Vector3(-1.23, 1.6, z - 1.25), couleurs_cadres[k % 3], false, PI / 2)
			_photo(g, "Cadre%dD" % k, Vector3(1.23, 1.6, z - 1.25), couleurs_cadres[(k + 1) % 3], false, -PI / 2)
	# Une console avec des plantes tous les 5 m (la boucle fait 10 m).
	for k in 2:
		var z := -3.75 - 5.0 * k
		_m.kenney(g, "Console%d" % k, "sideTable", Vector3(1.03, 0, z), -PI / 2)
		for i in 3:
			_m.kenney(g, "Plante%d_%d" % [k, i], "plantSmall%d" % (i + 1), Vector3(1.03, 0.76, z - 0.35 + 0.35 * i), 0.0, false)
	var boucle := Marker3D.new()
	boucle.position = Vector3(0, 0, -2.5)
	_ajouter(g, boucle, "Boucle")
	var porte: PorteTrompeuse = load("res://scenes/porte_trompeuse.tscn").instantiate()
	porte.position = Vector3(0, 0, -12.5)
	_ajouter(g, porte, "PorteTrompeuse")
	porte.cible_regard = NodePath("../PhotoBonne")
	porte.destinations = [NodePath("../Boucle"), NodePath("../../Salon/Arrivee")]
	porte.index_sinon = 0
	porte.index_si_regard = 1


func _salon() -> void:
	var g := _groupe("Salon")
	var c := Vector3(30, 0, -11)
	_boite(g, "Sol", c + Vector3(0, -0.25, 0), Vector3(10, 0.5, 22), "salon_sol")
	# Le salon et l'atelier forment un grand volume de 5 m sous plafond (l'horloge
	# éparpillée monte haut).
	var h := HAUTEUR_SALON
	_boite(g, "MurGauche", Vector3(24.9, h / 2, -11), Vector3(0.2, h, 22), "salon_mur")
	var droit := _boite(g, "MurDroit", Vector3(35.1, h / 2, -11), Vector3(0.2, h, 22), "salon_mur")
	var arriere := _boite(g, "MurArriere", Vector3(30, h / 2, 0.1), Vector3(10.4, h, 0.2), "salon_mur")
	_boite(g, "MurHaut", Vector3(30, 4, -10), Vector3(10, 2, 0.3), "salon_mur")
	_plafond(g, Vector3(30, 0, -11), Vector2(10.4, 22.4), h, "plafond_salon")
	_toit(g, Vector3(30, h + 0.3, -11), 10.4, 22.4, "salon_mur")
	_plinthe(g, "PlintheGauche", Vector3(25.12, 0.06, -11), 22, false)
	_plinthe(g, "PlintheDroite", Vector3(34.88, 0.06, -11), 22, false)
	_plinthe(g, "PlintheArriere", Vector3(30, 0.06, -0.12), 10, true)
	# Une grande fenêtre basse et des fenêtres hautes côté jardin.
	_fenetre(g, arriere, "Arriere", Vector3(32.0, 1.8, 0.1), 1.4, 1.4)
	_fenetre(g, droit, "Droite", Vector3(35.1, 1.8, -4.5), 1.2, 1.4)
	for z in [-1.5, -7.5, -13.5, -18.0]:
		_fenetre(g, droit, "Haute%d" % absi(int(z)), Vector3(35.1, 3.9, z), 1.2, 1.0)
	# Au présent, un mur plein ; dans le passé, une arche en pierre.
	_boite(g, "MurPresent", Vector3(30, 1.5, -10), Vector3(10, 3, 0.3), "salon_mur", true, PRESENT)
	_boite(g, "ArcheGauche", Vector3(27, 1.5, -10), Vector3(4, 3, 0.3), "pierre", true, PASSE)
	_boite(g, "ArcheDroite", Vector3(33, 1.5, -10), Vector3(4, 3, 0.3), "pierre", true, PASSE)
	_boite(g, "ArcheHaut", Vector3(30, 2.75, -10), Vector3(2, 0.5, 0.3), "pierre", true, PASSE)
	# Le présent : un salon moderne (Kenney), avec des cartons pas encore
	# déballés.
	var ke: Callable = _m.kenney
	ke.call(g, "Tapis", "rugRectangle", Vector3(27, 0, -3.6), 0.0, false, PRESENT, 2.5)
	ke.call(g, "MeubleTele", "cabinetTelevision", Vector3(27, 0, -0.27), PI, true, PRESENT)
	ke.call(g, "Tele", "televisionModern", Vector3(27, 0.62, -0.3), PI, false, PRESENT)
	ke.call(g, "Radio", "radio", Vector3(26.4, 0.62, -0.25), PI, false, PRESENT)
	ke.call(g, "EnceinteG", "speaker", Vector3(25.5, 0, -0.3), PI, true, PRESENT)
	ke.call(g, "EnceinteD", "speaker", Vector3(28.5, 0, -0.3), PI, true, PRESENT)
	ke.call(g, "TableBasse", "tableCoffee", Vector3(27, 0, -3.2), 0.0, true, PRESENT)
	ke.call(g, "Canape", "loungeSofa", Vector3(27, 0, -5.0), 0.0, true, PRESENT)
	ke.call(g, "Coussin", "pillowBlue", Vector3(26.4, 0.5, -5.0), 0.3, false, PRESENT)
	ke.call(g, "Fauteuil", "loungeChair", Vector3(28.85, 0, -3.2), -PI / 2, true, PRESENT)
	var lampe := ke.call(g, "Lampe", "lampSquareFloor", Vector3(25.45, 0, -5.4), 0.0, false, PRESENT) as Node3D
	_m.lumiere(lampe, Vector3(0, 1.5, 0), 3.5, 0.5)
	ke.call(g, "Plante", "pottedPlant", Vector3(34.4, 0, -0.6), 0.0, true, PRESENT)
	ke.call(g, "PlanteTele", "plantSmall1", Vector3(27.6, 0.62, -0.25), 0.0, false, PRESENT)
	ke.call(g, "FauteuilLecture", "loungeDesignChair", Vector3(25.6, 0, -7.3), PI / 2, true, PRESENT)
	ke.call(g, "TableLecture", "sideTable", Vector3(25.3, 0, -8.3), PI / 2, true, PRESENT)
	ke.call(g, "LivresLecture", "books", Vector3(25.3, 0.76, -8.3), 0.4, false, PRESENT)
	ke.call(g, "Bibliotheque", "bookcaseClosedWide", Vector3(34.75, 0, -7.2), -PI / 2, true, PRESENT)
	ke.call(g, "Livres", "books", Vector3(34.75, 1.58, -7.6), -PI / 2, false, PRESENT)
	ke.call(g, "Table", "tableCross", Vector3(32.5, 0, -2.6), 0.0, true, PRESENT)
	for i in 4:
		var x := 32.0 + (i % 2)
		var z := -1.85 if i < 2 else -3.35
		ke.call(g, "Chaise%d" % i, "chairCushion", Vector3(x, 0, z), PI if i < 2 else 0.0, true, PRESENT)
	ke.call(g, "Carton1", "cardboardBoxClosed", Vector3(25.5, 0, -9.3), 0.2, true, PRESENT, 2.5)
	ke.call(g, "Carton2", "cardboardBoxClosed", Vector3(25.5, 0.7, -9.3), -0.3, false, PRESENT, 2.5)
	ke.call(g, "Carton3", "cardboardBoxOpen", Vector3(26.4, 0, -9.3), 0.1, true, PRESENT, 2.5)
	var ventilo := Node3D.new()
	ventilo.position = Vector3(30, h, -5)
	ventilo.set_script(load("res://scripts/fx/tourne.gd"))
	ventilo.set("vitesse", Vector3(0, 2.5, 0))
	_ajouter(g, ventilo, "Ventilateur")
	ke.call(ventilo, "Helices", "ceilingFan", Vector3.ZERO, 0.0, false, PRESENT, 3.0, "plafond")
	_m.suspension(g, "Suspension1", Vector3(27, h, -4.2), 1.6, PRESENT)
	_m.suspension(g, "Suspension2", Vector3(32.5, h, -2.6), 1.8, PRESENT)
	# Le passé : une salle de château.
	_boite(g, "Dalles", Vector3(30, 0.011, -5), Vector3(10, 0.02, 9.9), "pierre", false, PASSE)
	# Le passé : une salle de château (Quaternius), aux mêmes places que les
	# meubles du présent.
	var ch: Callable = _m.chateau
	ch.call(g, "GrandeTable", "Table_Large", Vector3(27, 0, -4.5))
	ch.call(g, "BancNord", "Bench", Vector3(27, 0, -3.55))
	ch.call(g, "BancSud", "Bench", Vector3(27, 0, -5.45))
	ch.call(g, "Fauteuil", "Chair_1", Vector3(28.95, 0, -4.5), -PI / 2)
	for i in 3:
		ch.call(g, "Assiette%d" % i, "Table_Plate", Vector3(26.0 + i, 0.81, -4.2), 0.0, false)
	ch.call(g, "Chope1", "Mug", Vector3(26.3, 0.81, -4.75), 0.4, false)
	ch.call(g, "Chope2", "Mug", Vector3(27.6, 0.81, -4.8), -0.8, false)
	ch.call(g, "Calice", "Chalice", Vector3(28.1, 0.81, -4.3), 0.0, false)
	ch.call(g, "Marmite", "Pot_1", Vector3(27.0, 0.81, -4.7), 0.0, false)
	var chandelier := ch.call(g, "Chandelier3", "CandleStick_Triple", Vector3(25.9, 0.81, -4.75), 0.0, false) as Node3D
	_m.lumiere(chandelier, Vector3(0, 0.6, 0), 2.5, 0.5, Color("ffb35c"))
	var lustre := ch.call(g, "Lustre", "Chandelier", Vector3(27, h, -4.5), 0.0, false, "plafond") as Node3D
	_m.lumiere(lustre, Vector3(0, -1.2, 0), 7.0, 1.0, Color("ffb35c"))
	for z in [-2.5, -7.5]:
		for cote in [-1, 1]:
			var nom := "Torche%s%d" % ["G" if cote < 0 else "D", absi(int(z * 10))]
			var torche := ch.call(g, nom, "Torch_Metal", Vector3(30 + cote * 5.0, 1.7, z), -cote * PI / 2, false, "mur") as Node3D
			_m.cyl(torche, Vector3(0, 0.72, 0.3), 0.08, 0.2, "flamme", 5, true)
			_m.lumiere(torche, Vector3(0, 0.9, 0.4), 4.0, 0.6, Color("ff9f1c"))
	ch.call(g, "BanniereG", "Banner_1_Cloth", Vector3(25.0, 4.2, -5.0), PI / 2, false, "mur_haut")
	ch.call(g, "BanniereD", "Banner_1_Cloth", Vector3(35.0, 4.2, -9.0), -PI / 2, false, "mur_haut")
	ch.call(g, "BanniereFondG", "Banner_1_Cloth", Vector3(26.5, 4.2, 0.0), PI, false, "mur_haut")
	ch.call(g, "BanniereFondD", "Banner_1_Cloth", Vector3(34.0, 4.2, 0.0), PI, false, "mur_haut")
	ch.call(g, "BanniereArcheG", "Banner_1_Cloth", Vector3(27.0, 2.9, -9.85), 0.0, false, "mur_haut")
	ch.call(g, "BanniereArcheD", "Banner_1_Cloth", Vector3(33.0, 2.9, -9.85), 0.0, false, "mur_haut")
	ch.call(g, "Tonneau1", "Barrel", Vector3(34.4, 0, -0.55))
	ch.call(g, "Tonneau2", "Barrel_Apples", Vector3(33.6, 0, -0.5))
	ch.call(g, "Caisse", "Crate_Wooden", Vector3(34.5, 0, -1.6), 0.3)
	ch.call(g, "Bibliotheque", "Bookcase_2", Vector3(34.78, 0, -7.2), -PI / 2)
	ch.call(g, "Coffre", "Chest_Wood", Vector3(25.45, 0, -9.0), PI / 2)
	ch.call(g, "Armes", "WeaponStand", Vector3(25.5, 0, -1.0), PI / 2)
	ch.call(g, "Chaudron", "Cauldron", Vector3(33.4, 0, -8.6))
	var chandelier_pied := ch.call(g, "ChandelierPied", "CandleStick_Stand", Vector3(28.3, 0, -8.8)) as Node3D
	_m.lumiere(chandelier_pied, Vector3(0, 1.4, 0), 3.0, 0.5, Color("ffb35c"))
	_boite(g, "Colonne", Vector3(32.5, h / 2, -5), Vector3(0.8, h, 0.8), "colonne", true, PASSE)
	for k in 11:
		_boite(g, "Poutre%d" % k, Vector3(30, h - 0.15, -1 - 2 * k), Vector3(10, 0.3, 0.3), "poutre", false, PASSE)
	_texte(g, "Indice", Vector3(30, 2.5, -9.8), "Appuie sur Tab (ou clic droit)\npour voir cette pièce à une autre époque.")
	var arrivee := Marker3D.new()
	arrivee.position = Vector3(30, 0, -1.5)
	_ajouter(g, arrivee, "Arrivee")
	_ancrage(g, "Ancrage", Vector3(30, 0, -2), Vector3(30, 1.5, -5), Vector3(10, 3, 10))


func _atelier() -> void:
	var g := _groupe("Atelier")
	# Le sol et les murs de côté sont ceux du salon (même grand volume).
	var h := HAUTEUR_SALON
	_boite(g, "MurFond_a", Vector3(27, h / 2, -22.1), Vector3(4, h, 0.2), "atelier_mur")
	_boite(g, "MurFond_b", Vector3(33, h / 2, -22.1), Vector3(4, h, 0.2), "atelier_mur")
	_boite(g, "MurFond_haut", Vector3(30, (2.5 + h) / 2, -22.1), Vector3(2, h - 2.5, 0.2), "atelier_mur")
	_plinthe(g, "PlintheFond_a", Vector3(27, 0.06, -21.98), 4, true)
	_plinthe(g, "PlintheFond_b", Vector3(33, 0.06, -21.98), 4, true)
	_m.suspension(g, "Suspension1", Vector3(27, h, -17), 1.4)
	_m.suspension(g, "Suspension2", Vector3(33, h, -17), 1.4)
	_boite(g, "PorteSortie", Vector3(30, 1.25, -22.1), Vector3(2, 2.5, 0.2), "porte")
	_boite(g, "Repere", Vector3(30, 0.01, -12), Vector3(0.6, 0.02, 0.6), "repere", false)
	_texte(g, "Indice", Vector3(34.9, 1.8, -14), "Place-toi sur la marque\net regarde au loin.", -PI / 2)
	_ancrage(g, "Ancrage", Vector3(30, 0, -11), Vector3(30, 1.5, -16), Vector3(10, 3, 12))
	_m.etabli(g, "Etabli", Vector3(34.2, 0, -16.5), -PI / 2)
	_m.engrenage(g, "Engrenage1", Vector3(34.93, 2.1, -18.4), 0.5, "engrenage", PI / 2)
	_m.engrenage(g, "Engrenage2", Vector3(34.93, 1.55, -19.3), 0.3, "flottant_2", PI / 2)
	for k in 3:
		_m.horloge_murale(g, "HorlogeMurale%d" % k, Vector3(25.07, 1.7 + 0.3 * (k % 2), -13.5 - 2.8 * k), PI / 2, 0.3 + 0.1 * k)
	_m.kenney(g, "Plante", "pottedPlant", Vector3(25.6, 0, -21.4))
	var lampe: Node3D = _m.kenney(g, "Lampe", "lampSquareFloor", Vector3(34.5, 0, -21.5), 0.0, false)
	_m.lumiere(lampe, Vector3(0, 1.5, 0), 3.5, 0.5)
	for i in 2:
		_m.kenney(g, "EtagereBasse%d" % i, "bookcaseOpenLow", Vector3(25.25, 0, -14.9 - 2.8 * i), PI / 2)
		_m.kenney(g, "Livres%d" % i, "books", Vector3(25.25, 0.8, -14.9 - 2.8 * i), PI / 2, false)
	_m.kenney(g, "Bureau", "desk", Vector3(34.6, 0, -12.3), -PI / 2)
	_m.kenney(g, "Ecran", "computerScreen", Vector3(34.75, 0.76, -12.3), -PI / 2, false)
	_m.kenney(g, "ChaiseBureau", "chairDesk", Vector3(33.6, 0, -12.3), PI / 2)
	_m.kenney(g, "Poubelle", "trashcan", Vector3(34.6, 0, -13.5))
	_m.kenney(g, "Carton", "cardboardBoxOpen", Vector3(25.6, 0, -11.0), 0.4, true, -1, 2.5)
	# L'horloge : vue depuis la marque, ses morceaux éparpillés forment un cadran.
	var centre_image := Vector3(30, 2.2, -20)
	var vue := Marker3D.new()
	var oeil := Vector3(30, 1.6, -12)
	vue.transform = Transform3D(Basis.looking_at(centre_image - oeil), oeil)
	_ajouter(g, vue, "PointDeVue")
	var centre := vue.position + (centre_image - vue.position) * 0.9
	var horloge := Alignement.new()
	horloge.position = centre
	_ajouter(g, horloge, "Horloge")
	horloge.point_de_vue = NodePath("../PointDeVue")
	var profondeurs := [0.6, 1.15, 0.75, 1.05, 0.65, 0.9, 1.2, 0.8, 0.7, 1.1]
	var i := 0
	for k in 8:
		var a := TAU * k / 8.0
		var p := centre_image + Vector3(cos(a), sin(a), 0) * 1.4
		_morceau(horloge, "Graduation%d" % k, vue.position, p, Vector3(0.22, 0.5, 0.1), a - PI / 2, profondeurs[i], "horloge")
		i += 1
	_morceau(horloge, "PetiteAiguille", vue.position, centre_image + Vector3(0, 0.4, 0), Vector3(0.14, 0.8, 0.1), 0.0, profondeurs[i], "aiguille")
	_morceau(horloge, "GrandeAiguille", vue.position, centre_image + Vector3(0.55, 0, 0), Vector3(1.1, 0.12, 0.1), 0.0, profondeurs[i + 1], "aiguille")


## Place un morceau sur le rayon qui part du point de vue vers son point
## d'image, à la profondeur k, et l'agrandit d'autant : vu du point de vue, il
## a exactement la même taille que s'il était dans le plan de l'image.
func _morceau(horloge: Node3D, nom: String, vue: Vector3, point_image: Vector3, taille: Vector3, rot_z: float, k: float, couleur: String) -> void:
	var b := CSGBox3D.new()
	b.position = vue + (point_image - vue) * k - horloge.position
	b.size = taille
	b.scale = Vector3.ONE * k
	b.rotation.z = rot_z
	b.material = _mat(couleur)
	b.use_collision = false
	_ajouter(horloge, b, nom)


func _jardin() -> void:
	var g := _groupe("Jardin")
	_boite(g, "Sol", Vector3(30, -0.25, -26.2), Vector3(6, 0.5, 8), "jardin")
	_texte(g, "Panneau", Vector3(30, 1.9, -29.4), "Bientôt : l'Égypte ancienne…")
	var n: Callable = _m.nature
	n.call(g, "Arbre1", "tree_default", Vector3(27.9, 0, -28.9), 3.0, 0.4)
	n.call(g, "Arbre2", "tree_oak", Vector3(32.2, 0, -27.8), 3.2, 1.2)
	n.call(g, "Arbre3", "tree_small", Vector3(27.8, 0, -25.6), 3.0, 2.0)
	for i in 4:
		n.call(g, "Dalle%d" % i, "path_stone", Vector3(30, 0, -22.75 - 0.95 * i), 1.5, 0.15 * (i % 2))
	n.call(g, "Panneau3D", "sign", Vector3(30, 0, -29.5), 3.0)
	# Un avant-goût de la suite : un obélisque égyptien au fond du jardin.
	n.call(g, "Obelisque", "statue_obelisk", Vector3(32.0, 0, -29.4), 3.0, 0.3)
	n.call(g, "BuissonG", "plant_bushDetailed", Vector3(27.6, 0, -22.9), 2.5)
	n.call(g, "BuissonD", "plant_bushDetailed", Vector3(32.4, 0, -22.9), 2.5, 1.0)
	var fleurs := [
		["flower_redA", 28.6, -24.2], ["flower_yellowA", 31.5, -24.0], ["flower_purpleA", 29.0, -26.6],
		["flower_redB", 31.3, -29.4], ["flower_yellowB", 28.3, -26.9], ["flower_purpleB", 32.5, -25.4],
		["flower_redA", 31.9, -26.3], ["flower_yellowA", 28.9, -29.6], ["flower_purpleA", 30.9, -27.4],
		["flower_redB", 27.6, -27.6], ["flower_yellowB", 32.6, -29.6], ["flower_purpleB", 29.6, -28.2],
	]
	for i in fleurs.size():
		n.call(g, "Fleur%d" % i, fleurs[i][0], Vector3(fleurs[i][1], 0, fleurs[i][2]), 2.2, i * 0.7)
	var herbes := [[28.2, -23.6], [31.8, -23.4], [29.4, -25.3], [32.7, -26.6], [27.5, -26.4], [30.6, -28.6], [28.6, -28.0], [32.0, -28.9], [30.3, -25.9], [27.6, -29.8]]
	for i in herbes.size():
		n.call(g, "Herbe%d" % i, "grass_large" if i % 2 else "grass", Vector3(herbes[i][0], 0, herbes[i][1]), 2.5, i * 1.3)
	n.call(g, "Champignons", "mushroom_redGroup", Vector3(28.4, 0, -29.5), 2.5)
	n.call(g, "Souche", "stump_round", Vector3(32.6, 0, -24.3), 2.5)
	n.call(g, "Rocher1", "rock_smallA", Vector3(29.3, 0, -29.8), 2.5)
	n.call(g, "Rocher2", "rock_smallB", Vector3(32.8, 0, -27.0), 2.0, 1.0)
	for i in 3:
		n.call(g, "ClotureG%d" % i, "fence_simple", Vector3(27.1, 0, -23.6 - 2.5 * i), 2.5, PI / 2)
		n.call(g, "ClotureD%d" % i, "fence_simple", Vector3(32.9, 0, -23.6 - 2.5 * i), 2.5, PI / 2)
	for i in 3:
		n.call(g, "ClotureFond%d" % i, "fence_gate" if i == 1 else "fence_simple", Vector3(28.0 + 2.0 * i, 0, -30.1), 2.0)
	var fin := Area3D.new()
	fin.position = Vector3(30, 1, -25)
	_ajouter(g, fin, "Fin")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(6, 2, 2)
	forme.shape = boite
	_ajouter(fin, forme, "CollisionShape3D")


## Des objets géants qui flottent autour de la maison : le temps se dérègle.
func _ciel() -> void:
	var g := _groupe("Ciel")
	var objets := [
		["anneau", "flottant_1", Vector3(14, 10, -12), 4.0, Vector3(0.2, 0.3, 0)],
		["cube", "flottant_2", Vector3(-12, 8, -18), 3.0, Vector3(0.1, 0.25, 0.15)],
		["pyramide", "flottant_3", Vector3(46, 11, -14), 3.0, Vector3(0, 0.2, 0.1)],
		["boule", "flottant_4", Vector3(12, 15, -38), 2.5, Vector3(0, 0.15, 0)],
		["anneau", "flottant_3", Vector3(-9, 12, 9), 3.0, Vector3(0.25, 0, 0.2)],
		["cube", "flottant_1", Vector3(42, 9, 6), 2.0, Vector3(0.3, 0.1, 0)],
		["anneau", "flottant_2", Vector3(30, 14, -40), 5.0, Vector3(0, 0, 0.15)],
	]
	for k in objets.size():
		var o: Array = objets[k]
		_m.flottant(g, "Flottant%d" % k, o[2], o[0], o[1], o[3], o[4])


func _joueur_et_interface() -> void:
	var joueur: Player = load("res://scenes/player.tscn").instantiate()
	joueur.position = Vector3(0, 0, 4.5)
	_ajouter(_racine, joueur, "Player")
	var fx: Node = load("res://scenes/bascule_fx.tscn").instantiate()
	_ajouter(_racine, fx, "BasculeFx")
	var ui := CanvasLayer.new()
	_ajouter(_racine, ui, "Interface")
	var viseur := Label.new()
	viseur.text = "·"
	viseur.add_theme_font_size_override("font_size", 40)
	viseur.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	viseur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viseur.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	viseur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, viseur, "Viseur")
	var msg := Label.new()
	msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	msg.offset_top = 40
	msg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 30)
	msg.add_theme_color_override("font_outline_color", Color("2b1d4e"))
	msg.add_theme_constant_override("outline_size", 10)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, msg, "Message")
