extends RefCounted

## Meubles et décors low-poly, faits de formes simples (boîtes, cylindres à
## peu de côtés, sphères anguleuses). Chaque meuble est un CSGCombiner3D :
## ses morceaux gardent leur couleur, et un EpochMember peut le rattacher à
## une époque.

const TempsScript := preload("res://scripts/time/temps.gd")
const PRESENT := TempsScript.Epoque.PRESENT
const PASSE := TempsScript.Epoque.PASSE

const COULEURS := {
	"bois": "c97b4a", "bois_fonce": "7a4a2e", "tissu": "ffd93d", "coussin": "fff3b0",
	"metal": "5c5f7a", "abat_jour": "ffe066", "terre_cuite": "e07a5f", "feuille": "52b788",
	"feuille_claire": "95d5b2", "ecran": "4cc9f0", "livre_1": "ef476f", "livre_2": "06d6a0",
	"livre_3": "118ab2", "livre_4": "ffd166", "tapis": "b388eb", "tapis_2": "7b2cbf",
	"pierre_claire": "e9c46a", "flamme": "ff9f1c", "dalle": "d4a373", "engrenage": "f72585",
	"cadran": "fffcf2", "tronc": "8d5524", "fleur_1": "ff006e", "fleur_2": "ffbe0b",
	"fleur_3": "3a86ff", "applique": "fff3b0", "nuage": "ffffff", "flottant_1": "f15bb5",
	"flottant_2": "00bbf9", "flottant_3": "fee440", "flottant_4": "9b5de5",
	"cadre_fenetre": "ffffff", "ampoule": "fff8e1", "fer": "3d3551", "bougie": "fffcf2",
}
const LUMINEUX := ["abat_jour", "ecran", "flamme", "applique", "cadran", "ampoule"]
const LUMIERE_CHAUDE := Color("ffd6a5")

var _b
var _materiaux := {}


func _init(constructeur) -> void:
	_b = constructeur


func mat(cle: String) -> StandardMaterial3D:
	if not _materiaux.has(cle):
		_materiaux[cle] = Style.materiau(Color(COULEURS[cle]), cle in LUMINEUX)
	return _materiaux[cle]


# --- Briques ---------------------------------------------------------------

func prop(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, solide := true, epoque := -1) -> CSGCombiner3D:
	var p := CSGCombiner3D.new()
	p.position = pos
	p.rotation.y = rot_y
	p.use_collision = solide
	_b._ajouter(parent, p, nom)
	if epoque >= 0:
		var m := EpochMember.new()
		m.epoque = epoque
		_b._ajouter(p, m, "EpochMember")
	return p


func cube(p: Node, pos: Vector3, taille: Vector3, couleur: String, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.position = pos
	b.size = taille
	b.rotation = rot
	b.material = mat(couleur)
	return _b._ajouter(p, b, "Boite%d" % p.get_child_count())


func cyl(p: Node, pos: Vector3, rayon: float, hauteur: float, couleur: String, cotes := 8, cone := false, rot := Vector3.ZERO) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.position = pos
	c.radius = rayon
	c.height = hauteur
	c.sides = cotes
	c.cone = cone
	c.rotation = rot
	c.smooth_faces = false
	c.material = mat(couleur)
	return _b._ajouter(p, c, "Cylindre%d" % p.get_child_count())


func boule(p: Node, pos: Vector3, rayon: float, couleur: String, segments := 6) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.position = pos
	s.radius = rayon
	s.radial_segments = segments
	s.rings = maxi(3, segments / 2)
	s.smooth_faces = false
	s.material = mat(couleur)
	return _b._ajouter(p, s, "Boule%d" % p.get_child_count())


# --- Maison d'aujourd'hui ------------------------------------------------------

func canape(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true, epoque)
	cube(p, Vector3(0, 0.225, 0), Vector3(2.2, 0.45, 0.9), "tissu")
	cube(p, Vector3(0, 0.6, -0.33), Vector3(2.2, 0.6, 0.25), "tissu")
	cube(p, Vector3(-0.98, 0.33, 0), Vector3(0.25, 0.66, 0.9), "tissu")
	cube(p, Vector3(0.98, 0.33, 0), Vector3(0.25, 0.66, 0.9), "tissu")
	cube(p, Vector3(-0.43, 0.52, 0.03), Vector3(0.82, 0.14, 0.6), "coussin")
	cube(p, Vector3(0.43, 0.52, 0.03), Vector3(0.82, 0.14, 0.6), "coussin")
	return p


func table_basse(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true, epoque)
	cube(p, Vector3(0, 0.42, 0), Vector3(1.2, 0.08, 0.7), "bois")
	for x in [-0.5, 0.5]:
		for z in [-0.27, 0.27]:
			cyl(p, Vector3(x, 0.19, z), 0.04, 0.38, "bois_fonce", 6)
	boule(p, Vector3(0.25, 0.53, 0), 0.08, "fleur_1", 5)
	return p


func lampe(parent: Node, nom: String, pos: Vector3, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, 0.03, 0), 0.2, 0.06, "metal", 8)
	cyl(p, Vector3(0, 0.75, 0), 0.03, 1.4, "metal", 6)
	cyl(p, Vector3(0, 1.55, 0), 0.32, 0.4, "abat_jour", 8, true)
	return p


func plante(parent: Node, nom: String, pos: Vector3, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, 0.2, 0), 0.22, 0.4, "terre_cuite", 6)
	boule(p, Vector3(0, 0.62, 0), 0.32, "feuille", 6)
	boule(p, Vector3(0.15, 0.85, 0.05), 0.22, "feuille_claire", 5)
	boule(p, Vector3(-0.12, 0.9, -0.08), 0.2, "feuille", 5)
	return p


func etagere(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true, epoque)
	cube(p, Vector3(-0.6, 0.9, 0), Vector3(0.06, 1.8, 0.35), "bois")
	cube(p, Vector3(0.6, 0.9, 0), Vector3(0.06, 1.8, 0.35), "bois")
	var livres := ["livre_1", "livre_2", "livre_3", "livre_4"]
	for i in 4:
		var y := 0.05 + i * 0.55
		cube(p, Vector3(0, y, 0), Vector3(1.26, 0.05, 0.35), "bois")
		if i == 3:
			continue
		var x := -0.5
		var k := i
		while x < 0.45:
			var largeur := 0.08 + (k % 3) * 0.03
			var hauteur := 0.3 + (k % 2) * 0.1
			cube(p, Vector3(x + largeur / 2, y + 0.025 + hauteur / 2, 0), Vector3(largeur, hauteur, 0.25), livres[k % 4])
			x += largeur + 0.02
			k += 1
	return p


func tele(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true, epoque)
	cube(p, Vector3(0, 0.25, 0), Vector3(1.4, 0.5, 0.45), "bois_fonce")
	cube(p, Vector3(0, 0.95, 0), Vector3(1.2, 0.7, 0.08), "metal")
	cube(p, Vector3(0, 0.95, 0.045), Vector3(1.08, 0.58, 0.02), "ecran")
	return p


func tapis(parent: Node, nom: String, pos: Vector3, rayon := 1.4, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, 0.01, 0), rayon, 0.02, "tapis", 12)
	cyl(p, Vector3(0, 0.02, 0), rayon * 0.6, 0.02, "tapis_2", 12)
	return p


func applique(parent: Node, nom: String, pos: Vector3, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	boule(p, Vector3.ZERO, 0.14, "applique", 6)
	return p


func horloge_murale(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, rayon := 0.4) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, false)
	cyl(p, Vector3.ZERO, rayon, 0.06, "bois_fonce", 12, false, Vector3(PI / 2, 0, 0))
	cyl(p, Vector3(0, 0, 0.03), rayon * 0.85, 0.02, "cadran", 12, false, Vector3(PI / 2, 0, 0))
	cube(p, Vector3(0, rayon * 0.25, 0.05), Vector3(0.04, rayon * 0.5, 0.02), "metal")
	cube(p, Vector3(rayon * 0.3, 0, 0.05), Vector3(rayon * 0.6, 0.03, 0.02), "metal", Vector3(0, 0, 0.5))
	return p


## Une lumière ponctuelle qui éclaire autour d'une lampe (sans ombre).
func lumiere(p: Node, pos: Vector3, portee: float, energie: float, couleur := LUMIERE_CHAUDE) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.omni_range = portee
	l.light_energy = energie
	l.light_color = couleur
	return _b._ajouter(p, l, "Lumiere")


## Une lampe suspendue : `pos` est le point d'accroche au plafond.
func suspension(parent: Node, nom: String, pos: Vector3, longueur := 1.0, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, -longueur / 2, 0), 0.015, longueur, "fer", 4)
	cyl(p, Vector3(0, -longueur - 0.12, 0), 0.3, 0.3, "abat_jour", 8, true)
	boule(p, Vector3(0, -longueur - 0.3, 0), 0.08, "ampoule", 5)
	lumiere(p, Vector3(0, -longueur - 0.4, 0), 6.0, 0.8)
	return p


## Un plafonnier plat, collé au plafond (`pos`).
func plafonnier(parent: Node, nom: String, pos: Vector3, epoque := -1) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, -0.04, 0), 0.28, 0.08, "ampoule", 8)
	cyl(p, Vector3(0, -0.01, 0), 0.32, 0.03, "metal", 8)
	lumiere(p, Vector3(0, -0.4, 0), 3.5, 0.5)
	return p


## Le cadre blanc d'une fenêtre (avec sa croix), centré sur `pos`, dans le
## plan local XY.
func cadre_fenetre(parent: Node, nom: String, pos: Vector3, largeur: float, hauteur: float, rot_y := 0.0) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, false)
	var e := 0.1
	for y in [-1, 1]:
		cube(p, Vector3(0, y * (hauteur + e) / 2, 0), Vector3(largeur + 2 * e, e, 0.3), "cadre_fenetre")
	for x in [-1, 1]:
		cube(p, Vector3(x * (largeur + e) / 2, 0, 0), Vector3(e, hauteur, 0.3), "cadre_fenetre")
	cube(p, Vector3.ZERO, Vector3(0.05, hauteur, 0.06), "cadre_fenetre")
	cube(p, Vector3.ZERO, Vector3(largeur, 0.05, 0.06), "cadre_fenetre")
	# Rebord sous la fenêtre.
	cube(p, Vector3(0, -(hauteur / 2 + e), 0), Vector3(largeur + 0.4, 0.06, 0.45), "cadre_fenetre")
	return p


# --- Le passé ------------------------------------------------------------------

## Un lustre en fer avec des bougies, accroché au plafond (`pos`).
func lustre(parent: Node, nom: String, pos: Vector3, longueur := 1.2, epoque := PASSE) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, -longueur / 2, 0), 0.02, longueur, "fer", 4)
	var anneau := CSGTorus3D.new()
	anneau.position = Vector3(0, -longueur, 0)
	anneau.inner_radius = 0.55
	anneau.outer_radius = 0.65
	anneau.sides = 12
	anneau.ring_sides = 4
	anneau.smooth_faces = false
	anneau.material = mat("fer")
	_b._ajouter(p, anneau, "Anneau")
	for i in 6:
		var a := TAU * i / 6.0
		var c := Vector3(cos(a) * 0.6, -longueur + 0.12, sin(a) * 0.6)
		cyl(p, c, 0.04, 0.2, "bougie", 6)
		cyl(p, c + Vector3(0, 0.16, 0), 0.04, 0.1, "flamme", 5, true)
	lumiere(p, Vector3(0, -longueur, 0), 7.0, 1.0, Color("ffb35c"))
	return p

func torche(parent: Node, nom: String, pos: Vector3, epoque := PASSE) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false, epoque)
	cyl(p, Vector3(0, 0, 0), 0.05, 0.5, "bois_fonce", 6)
	cyl(p, Vector3(0, 0.35, 0), 0.12, 0.25, "flamme", 6, true)
	return p


func tonneau(parent: Node, nom: String, pos: Vector3, epoque := PASSE) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, true, epoque)
	cyl(p, Vector3(0, 0.45, 0), 0.35, 0.9, "bois", 10)
	cyl(p, Vector3(0, 0.2, 0), 0.36, 0.06, "metal", 10)
	cyl(p, Vector3(0, 0.7, 0), 0.36, 0.06, "metal", 10)
	return p


func banc(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, epoque := PASSE) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true, epoque)
	cube(p, Vector3(0, 0.45, 0), Vector3(1.8, 0.15, 0.5), "pierre_claire")
	cube(p, Vector3(-0.7, 0.2, 0), Vector3(0.25, 0.4, 0.45), "pierre_claire")
	cube(p, Vector3(0.7, 0.2, 0), Vector3(0.25, 0.4, 0.45), "pierre_claire")
	return p


# --- Atelier et jardin -----------------------------------------------------------

func etabli(parent: Node, nom: String, pos: Vector3, rot_y := 0.0) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, rot_y, true)
	cube(p, Vector3(0, 0.85, 0), Vector3(2.0, 0.1, 0.8), "bois")
	for x in [-0.9, 0.9]:
		for z in [-0.32, 0.32]:
			cube(p, Vector3(x, 0.4, z), Vector3(0.08, 0.8, 0.08), "bois_fonce")
	cube(p, Vector3(0, 0.3, 0), Vector3(1.8, 0.05, 0.7), "bois_fonce")
	cyl(p, Vector3(-0.5, 0.95, 0.1), 0.12, 0.1, "engrenage", 10)
	cyl(p, Vector3(-0.25, 0.93, -0.15), 0.08, 0.06, "metal", 8)
	cube(p, Vector3(0.5, 0.93, 0), Vector3(0.5, 0.06, 0.12), "metal")
	return p


func engrenage(parent: Node, nom: String, pos: Vector3, rayon: float, couleur := "engrenage", rot_y := 0.0) -> Node3D:
	var p := prop(parent, nom, pos, rot_y, false)
	cyl(p, Vector3.ZERO, rayon, 0.08, couleur, 10, false, Vector3(PI / 2, 0, 0))
	for i in 10:
		var a := TAU * i / 10.0
		cube(p, Vector3(cos(a), sin(a), 0) * rayon, Vector3(rayon * 0.25, rayon * 0.25, 0.08), couleur, Vector3(0, 0, a))
	return p


func arbre(parent: Node, nom: String, pos: Vector3, hauteur := 1.0) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, true)
	cyl(p, Vector3(0, 0.7 * hauteur, 0), 0.15 * hauteur, 1.4 * hauteur, "tronc", 6)
	boule(p, Vector3(0, 1.8 * hauteur, 0), 0.9 * hauteur, "feuille", 6)
	boule(p, Vector3(0.4, 2.3, 0.2) * hauteur, 0.55 * hauteur, "feuille_claire", 5)
	return p


func fleur(parent: Node, nom: String, pos: Vector3, couleur: String) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false)
	cyl(p, Vector3(0, 0.15, 0), 0.015, 0.3, "feuille", 4)
	boule(p, Vector3(0, 0.33, 0), 0.07, couleur, 5)
	return p


## Un objet géant qui flotte et tourne dans le ciel, pour l'ambiance.
func flottant(parent: Node, nom: String, pos: Vector3, forme: String, couleur: String, taille: float, vitesse: Vector3) -> CSGCombiner3D:
	var p := prop(parent, nom, pos, 0.0, false)
	p.set_script(load("res://scripts/fx/tourne.gd"))
	p.set("vitesse", vitesse)
	match forme:
		"cube":
			cube(p, Vector3.ZERO, Vector3.ONE * taille, couleur)
		"anneau":
			var t := CSGTorus3D.new()
			t.inner_radius = taille * 0.8
			t.outer_radius = taille
			t.sides = 12
			t.ring_sides = 6
			t.smooth_faces = false
			t.material = mat(couleur)
			_b._ajouter(p, t, "Anneau")
		"pyramide":
			cyl(p, Vector3.ZERO, taille, taille * 1.2, couleur, 4, true)
		_:
			boule(p, Vector3.ZERO, taille, couleur, 6)
	return p
