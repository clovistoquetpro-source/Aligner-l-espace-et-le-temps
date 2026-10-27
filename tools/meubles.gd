extends RefCounted

## Meubles et décors de la maison. La plupart viennent des packs importés
## (assets/modeles : Kenney pour la maison et le jardin, Quaternius pour le
## château du passé). Ce qu'aucun pack ne fournit (horloges, engrenages,
## lampes, objets du ciel…) est fait de formes simples : chaque décor est
## alors un CSGCombiner3D dont les morceaux gardent leur couleur. Un
## EpochMember peut rattacher un décor à une époque.

const TempsScript := preload("res://scripts/time/temps.gd")
const PRESENT := TempsScript.Epoque.PRESENT
const PASSE := TempsScript.Epoque.PASSE

const COULEURS := {
	"bois": "c97b4a", "bois_fonce": "7a4a2e", "metal": "5c5f7a", "abat_jour": "ffe066",
	"livre_1": "ef476f", "livre_2": "06d6a0", "livre_3": "118ab2",
	"livre_4": "ffd166", "flamme": "ff9f1c", "engrenage": "f72585", "cadran": "fffcf2",
	"applique": "fff3b0", "flottant_1": "f15bb5", "flottant_2": "00bbf9", "flottant_3": "fee440",
	"flottant_4": "9b5de5", "cadre_fenetre": "ffffff", "ampoule": "fff8e1", "fer": "3d3551",
	# Égypte (mêmes teintes que le Low Poly Egypt Pack)
	"ocre": "d2af73", "ocre_fonce": "b99561", "or": "f3c330", "lapis": "183da0",
	"turquoise": "1fb5a8", "palme": "5aa83c", "tronc": "8a5a3c", "papyrus": "7cb342",
	"dune": "e08a4c", "rocher": "c9874f", "peau": "c68a4a",
}
const LUMINEUX := ["abat_jour", "flamme", "applique", "cadran", "ampoule"]
const LUMIERE_CHAUDE := Color("ffd6a5")
## Les armes que le modèle du soldat porte toutes à la fois.
const ARMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]

var _b
var _materiaux := {}
var _decor_egypte


func _init(constructeur) -> void:
	_b = constructeur


func mat(cle: String) -> StandardMaterial3D:
	if not _materiaux.has(cle):
		_materiaux[cle] = Style.materiau(Color(COULEURS[cle]), cle in LUMINEUX)
	return _materiaux[cle]


# --- Modèles importés (assets/modeles) ------------------------------------------

const MODELES := "res://assets/modeles/"
const HABILLAGE := preload("res://scripts/fx/habillage_cartoon.gd")
## Les meubles de Kenney sont à la moitié de la taille réelle.
const ECHELLE_KENNEY := 2.0


## Un modèle importé (glTF), habillé en cartoon au lancement. `ancrage` dit
## quel point du modèle est posé sur `pos` : "sol" (milieu de la base),
## "plafond" (milieu du haut), "mur" (base, contre le dos) ou "mur_haut"
## (haut, contre le dos). Les modèles regardent vers +Z. `solide` ajoute une
## boîte de collision à la taille du modèle.
## Avec `hauteur` > 0, l'échelle est calculée pour que le modèle mesure
## cette hauteur.
func modele(parent: Node, nom: String, chemin: String, pos: Vector3, rot_y := 0.0, echelle := 1.0, solide := true, epoque := -1, ancrage := "sol", hauteur := 0.0) -> Node3D:
	var corps: Node3D = StaticBody3D.new() if solide else Node3D.new()
	corps.set_script(HABILLAGE)
	corps.position = pos
	corps.rotation.y = rot_y
	_b._ajouter(parent, corps, nom)
	var m: Node3D = load(MODELES + chemin).instantiate()
	var boite := _boite_englobante(m, Transform3D.IDENTITY)
	if hauteur > 0.0:
		echelle = hauteur / boite.size.y
	var c := boite.get_center()
	var ancre := c
	ancre.y = boite.end.y if ancrage in ["plafond", "mur_haut"] else boite.position.y
	if ancrage.begins_with("mur"):
		ancre.z = boite.position.z
	m.scale = Vector3.ONE * echelle
	m.position = -ancre * echelle
	_b._ajouter(corps, m, "Modele")
	# Les packs de Kenney (maison, jardin) ont des couleurs à raviver.
	corps.set("corriger_couleurs", chemin.get_slice("/", 0) in ["maison", "jardin"])
	if solide:
		var forme := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = boite.size * echelle
		forme.shape = b
		forme.position = (c - ancre) * echelle
		_b._ajouter(corps, forme, "Collision")
	if epoque >= 0:
		var e := EpochMember.new()
		e.epoque = epoque
		_b._ajouter(corps, e, "EpochMember")
	return corps


## Un meuble de la maison du présent (Kenney Furniture Kit, couleurs unies).
func kenney(parent: Node, nom: String, modele_nom: String, pos: Vector3, rot_y := 0.0, solide := true, epoque := -1, echelle := ECHELLE_KENNEY, ancrage := "sol") -> Node3D:
	return modele(parent, nom, "maison/%s.glb" % modele_nom, pos, rot_y, echelle, solide, epoque, ancrage)


## Un objet de la salle de château du passé (Quaternius Fantasy Props,
## textures peintes).
func chateau(parent: Node, nom: String, modele_nom: String, pos: Vector3, rot_y := 0.0, solide := true, ancrage := "sol", epoque := PASSE) -> Node3D:
	return modele(parent, nom, "chateau/%s.gltf" % modele_nom, pos, rot_y, 1.0, solide, epoque, ancrage)


## Un élément du jardin (Kenney Nature Kit), sans collision.
func nature(parent: Node, nom: String, modele_nom: String, pos: Vector3, echelle: float, rot_y := 0.0) -> Node3D:
	return modele(parent, nom, "jardin/%s.glb" % modele_nom, pos, rot_y, echelle, false)


## Un monument de l'Égypte ancienne (Low Poly Egypt Pack, à l'échelle réelle).
## La licence du pack interdit d'en redistribuer les fichiers : tant que le
## dépôt est public, il n'est pas dans assets/modeles/egypte, et on construit
## à la place une forme simple de même taille (tools/decor_egypte.gd).
func egypte(parent: Node, nom: String, modele_nom: String, pos: Vector3, rot_y := 0.0, echelle := 1.0, solide := true, epoque := -1) -> Node3D:
	var chemin := "egypte/%s.glb" % modele_nom
	if ResourceLoader.exists(MODELES + chemin):
		return modele(parent, nom, chemin, pos, rot_y, echelle, solide, epoque)
	if _decor_egypte == null:
		_decor_egypte = load("res://tools/decor_egypte.gd").new(self)
	return _decor_egypte.construire(parent, nom, modele_nom, pos, rot_y, echelle, solide, epoque)


## Un objet du camp de 1942 (Toon Shooter Game Kit de Quaternius).
func militaire(parent: Node, nom: String, modele_nom: String, pos: Vector3, rot_y := 0.0, echelle := 1.0, solide := true, epoque := PRESENT) -> Node3D:
	return modele(parent, nom, "militaire/%s.gltf" % modele_nom, pos, rot_y, echelle, solide, epoque)


## Un soldat de 1942 de 1,8 m, sans collision et sans armes, qui joue une
## animation en boucle (« Idle », « Wave »…).
func soldat(parent: Node, nom: String, pos: Vector3, rot_y := 0.0, animation := "Idle", epoque := PRESENT) -> Node3D:
	var s := modele(parent, nom, "militaire/Character_Soldier.gltf", pos, rot_y, 1.0, false, epoque, "sol", 1.8)
	s.set("animation", animation)
	s.set("caches", ARMES)
	return s


## Boîte englobante des maillages sous `n`, dans le repère de `n`.
func _boite_englobante(n: Node, t: Transform3D) -> AABB:
	var res := AABB()
	var vide := true
	var tn := t * (n as Node3D).transform if n is Node3D else t
	if n is MeshInstance3D:
		res = tn * (n as MeshInstance3D).mesh.get_aabb()
		vide = false
	for enfant in n.get_children():
		var b := _boite_englobante(enfant, tn)
		if b.size == Vector3.ZERO:
			continue
		res = b if vide else res.merge(b)
		vide = false
	return res


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
	# Le cadre mord de 2 cm dans l'ouverture : ses faces ne tombent pas pile
	# sur celles du trou (elles scintilleraient).
	var r := 0.02
	for y in [-1, 1]:
		cube(p, Vector3(0, y * (hauteur / 2 + e / 2 - r), 0), Vector3(largeur + 2 * (e - r), e, 0.3), "cadre_fenetre")
	for x in [-1, 1]:
		cube(p, Vector3(x * (largeur / 2 + e / 2 - r), 0, 0), Vector3(e, hauteur, 0.3), "cadre_fenetre")
	cube(p, Vector3.ZERO, Vector3(0.05, hauteur, 0.06), "cadre_fenetre")
	cube(p, Vector3.ZERO, Vector3(largeur, 0.05, 0.06), "cadre_fenetre")
	# Rebord sous la fenêtre.
	cube(p, Vector3(0, -(hauteur / 2 + e), 0), Vector3(largeur + 0.4, 0.06, 0.45), "cadre_fenetre")
	return p


# --- Atelier et ciel -----------------------------------------------------------

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
