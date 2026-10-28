extends "res://tools/constructeur.gd"

## Construit scenes/illusions.tscn, le niveau 1 en formes simples (« La
## maison dans les étoiles »), lancé par construire_illusions.gd. Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Plan, vu de dessus (-Z vers le haut) :
##
##            Couloir de l'entrée (sans fin, vers -Z)
##                       |
##   étoiles -- Entrée (hall) -- Salon -- Salle de bain
##                       |
##                    Chambre
##
## À l'écart : la galerie (dans la toile, en z = 80) et la chambre d'enfant
## peinte (x = 40), que la toile tournante filme et qui tourne avec elle.
## Tout est gris, sauf ce qui est peint : les toiles et ce qu'il y a dedans.

const COULEURS := {
	# La maison, en gris.
	"sol": "5d5d66", "mur": "9a9aa3", "plafond": "7d7d86", "meuble": "6e6e78", "drap": "b4b4bd",
	"couloir_sol": "4a4a52", "couloir_mur": "85858e", "pilier": "6e6e77",
	"cadre": "b8b8c0", "toile": "3a3a42", "miroir_cadre": "2e2e36",
	"passage": "55555e", "toile_passage": "e0e0ea", "porte": "7a5c45", "poignee": "d4af37",
	"lumiere_porte": "fff1c9",
	# Ce qui est peint.
	"cadre_toile": "b08d57", "nuit": "1b1f4a", "etoile": "fff3b0", "maison": "e8d7b5",
	"toit": "c0504d", "ciel": "8ecae6", "herbe": "6a994e", "soleil": "ffd166",
	"beige": "e9dcc9", "bois": "8d6346", "blanc": "f5f5f5", "rouge": "d1495b",
	"peau": "f2c6a0", "brun": "5e4b3c", "dos_toile": "3d3029", "blouse": "dcdcdc",
	"maison_toile": "2a2f66",
	# La chambre d'enfant, dans la toile.
	"r_sol": "c9905a", "r_mur": "a8dadc", "r_plafond": "fdf0b2", "r_fond": "f4a6b8",
	"r_lit": "e76f51", "r_drap": "fefae0",
}

## Les toiles : un fond et des formes, en coordonnées de la toile (0 à 1,
## depuis le coin en bas à gauche) : [x, y, largeur, hauteur, couleur].
const MOTIFS := {
	"maison_etoiles": { "fond": "nuit", "formes": [
		[0.1, 0.75, 0.03, 0.04, "etoile"], [0.3, 0.88, 0.02, 0.03, "etoile"], [0.62, 0.8, 0.03, 0.04, "etoile"],
		[0.85, 0.65, 0.02, 0.03, "etoile"], [0.18, 0.3, 0.02, 0.03, "etoile"], [0.8, 0.2, 0.03, 0.04, "etoile"],
		[0.4, 0.3, 0.2, 0.22, "maison"], [0.36, 0.52, 0.28, 0.08, "toit"], [0.47, 0.3, 0.06, 0.1, "brun"],
	]},
	"jardin": { "fond": "ciel", "formes": [
		[0.0, 0.0, 1.0, 0.35, "herbe"], [0.35, 0.3, 0.3, 0.3, "maison"], [0.32, 0.6, 0.36, 0.1, "toit"],
		[0.46, 0.3, 0.08, 0.14, "brun"], [0.75, 0.72, 0.12, 0.15, "soleil"],
	]},
	"enfant": { "fond": "beige", "formes": [
		[0.6, 0.08, 0.04, 0.55, "bois"], [0.5, 0.42, 0.26, 0.3, "blanc"], [0.55, 0.5, 0.1, 0.1, "ciel"],
		[0.22, 0.08, 0.14, 0.32, "rouge"], [0.25, 0.42, 0.08, 0.12, "peau"], [0.36, 0.32, 0.12, 0.03, "bois"],
	]},
	"atelier": { "fond": "brun", "formes": [
		[0.58, 0.45, 0.32, 0.4, "nuit"], [0.65, 0.7, 0.03, 0.04, "etoile"], [0.8, 0.55, 0.02, 0.03, "etoile"],
		[0.15, 0.1, 0.32, 0.5, "dos_toile"], [0.29, 0.0, 0.04, 0.12, "bois"],
		[0.55, 0.08, 0.05, 0.04, "rouge"], [0.65, 0.12, 0.04, 0.03, "ciel"], [0.75, 0.06, 0.05, 0.04, "soleil"],
	]},
	"peintre": { "fond": "nuit", "formes": [
		[0.15, 0.08, 0.2, 0.45, "blouse"], [0.2, 0.55, 0.1, 0.12, "peau"], [0.18, 0.67, 0.15, 0.04, "rouge"],
		[0.35, 0.38, 0.14, 0.03, "bois"], [0.7, 0.05, 0.04, 0.4, "bois"],
		[0.52, 0.35, 0.4, 0.4, "maison_toile"], [0.66, 0.45, 0.12, 0.1, "maison"], [0.64, 0.55, 0.16, 0.04, "toit"],
		[0.58, 0.68, 0.02, 0.03, "etoile"], [0.85, 0.62, 0.02, 0.03, "etoile"], [0.1, 0.85, 0.03, 0.04, "etoile"],
	]},
}

const HAUTEUR := 3.2
const EP := 0.3
## Le couloir : largeur, hauteur, longueur d'un tronçon et nombre de tronçons.
const COULOIR_L := 2.0
const COULOIR_H := 2.6
const TRONCON := 4.0
const TRONCONS := 16
## Le couloir ramène le joueur 3 tronçons en arrière quand il passe le 7e.
const TRONCON_BOUCLE := 7
const RECUL := 3
const COULOIR_Z := -4.3
## Le passage du reflet, dans le mur sud de la salle de bain.
const PASSAGE_X := 16.8
const PASSAGE_L := 1.2
const PASSAGE_H := 2.2
## La galerie et la chambre d'enfant peinte (un cube de 6 m).
const GALERIE := Vector3(0, 0, 80)
const CHAMBRE_PEINTE := Vector3(40, 3, 80)
const COTE_PEINT := 6.0
## Le bord ouest du balcon (dans la galerie) ; le palier s'arrête en x = -6,5.
const BALCON_X := -1.0


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Illusions"
	_racine.set_script(load("res://scripts/niveau/illusions.gd"))
	_environnement()
	_entree()
	_couloir()
	_chambre()
	_salon()
	_salle_de_bain()
	_galerie()
	_chambre_peinte()
	_joueur_et_interface(Vector3(-1.2, 0, 7.6), PI)
	# Pas d'époques dans ce niveau : pas d'effet de bascule.
	_racine.get_node("BasculeFx").free()
	var ui := _racine.get_node("Interface")
	_ajouter(ui, ChuteToiles.new(), "ChuteToiles")
	var noir := ColorRect.new()
	noir.color = Color.BLACK
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, noir, "Noir")
	# Les pensées s'affichent par-dessus le noir.
	ui.move_child(ui.get_node("Message"), -1)
	return _enregistrer("res://scenes/illusions.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["toile_passage", "etoile", "soleil", "lumiere_porte"]


func _environnement() -> void:
	var ciel := ShaderMaterial.new()
	ciel.shader = load("res://shaders/ciel_etoiles.gdshader")
	var sky := Sky.new()
	sky.sky_material = ciel
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8a8a99")
	env.ambient_light_energy = 0.06
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")


# --- Petites briques -------------------------------------------------------


func _lampe(g: Node3D, nom: String, pos: Vector3, portee: float, ombres := true, energie := 1.2) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos - g.position
	l.omni_range = portee
	l.light_energy = energie
	l.shadow_enabled = ombres
	return _ajouter(g, l, nom)


## Une zone (Area3D) en coordonnées du monde.
func _zone(g: Node3D, nom: String, centre: Vector3, taille: Vector3) -> Area3D:
	var a := Area3D.new()
	a.position = centre - g.position
	_ajouter(g, a, nom)
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = taille
	forme.shape = boite
	_ajouter(a, forme, "CollisionShape3D")
	return a


func _marque(g: Node3D, nom: String, pos: Vector3, rot_y := 0.0) -> Marker3D:
	var m := Marker3D.new()
	m.position = pos - g.position
	m.rotation.y = rot_y
	return _ajouter(g, m, nom)


func _pensee(g: Node3D, nom: String, pos: Vector3, texte: String, distance := 6.0, angle := 20.0, regard := true, active := true) -> Pensee:
	var p := Pensee.new()
	p.position = pos - g.position
	p.texte = texte
	p.distance = distance
	p.angle_max_deg = angle
	p.regard = regard
	p.active = active
	return _ajouter(g, p, nom)


## Un mur en coordonnées du monde, de `a0` à `a1` le long de X (`le_long_de_x`)
## ou de Z, centré sur `c` (le z ou le x du mur), avec des ouvertures :
## [centre, largeur, hauteur, hauteur du bas (0 pour une porte)].
func _mur(g: Node3D, nom: String, le_long_de_x: bool, c: float, a0: float, a1: float, h: float, couleur: String, trous := []) -> void:
	var tries := trous.duplicate()
	tries.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var morceaux := []
	var debut := a0
	for t in tries:
		var t0: float = t[0] - t[1] / 2.0
		var t1: float = t[0] + t[1] / 2.0
		var bas: float = t[3] if t.size() > 3 else 0.0
		if t0 > debut:
			morceaux.append([debut, t0, 0.0, h])
		if bas > 0.0:
			morceaux.append([t0, t1, 0.0, bas])
		if bas + t[2] < h:
			morceaux.append([t0, t1, bas + t[2], h])
		debut = t1
	if a1 > debut:
		morceaux.append([debut, a1, 0.0, h])
	for i in morceaux.size():
		var m: Array = morceaux[i]
		var milieu: float = (m[0] + m[1]) / 2.0
		var longueur: float = m[1] - m[0]
		var y: float = (m[2] + m[3]) / 2.0
		var hy: float = m[3] - m[2]
		var pos := Vector3(milieu, y, c) if le_long_de_x else Vector3(c, y, milieu)
		var taille := Vector3(longueur, hy, EP) if le_long_de_x else Vector3(EP, hy, longueur)
		var suffixe := "" if morceaux.size() == 1 else "_%d" % (i + 1)
		_boite(g, nom + suffixe, pos - g.position, taille, couleur)


## Le sol et le plafond d'une pièce : [x0, x1] × [z0, z1] en coordonnées du
## monde, murs compris.
func _sol_plafond(g: Node3D, x0: float, x1: float, z0: float, z1: float, h: float, sol := "sol", plafond := "plafond") -> void:
	var centre := Vector3((x0 + x1) / 2, 0, (z0 + z1) / 2) - g.position
	_boite(g, "Sol", centre + Vector3(0, -0.25, 0), Vector3(x1 - x0, 0.5, z1 - z0), sol)
	if plafond != "":
		_boite(g, "Plafond", centre + Vector3(0, h + EP / 2, 0), Vector3(x1 - x0, EP, z1 - z0), plafond)


## Une toile encadrée (motif de MOTIFS), tournée vers le +Z de `rot_y`.
func _toile(g: Node3D, nom: String, centre: Vector3, rot_y: float, taille: Vector2, motif: String, cadre := "cadre_toile") -> Node3D:
	var t := Node3D.new()
	t.position = centre - g.position
	t.rotation.y = rot_y
	_ajouter(g, t, nom)
	var m: Dictionary = MOTIFS[motif]
	_boite(t, "Fond", Vector3.ZERO, Vector3(taille.x, taille.y, 0.03), m["fond"], false)
	var b := 0.08
	_boite(t, "Cadre_haut", Vector3(0, (taille.y + b) / 2, 0), Vector3(taille.x + 2 * b, b, 0.06), cadre, false)
	_boite(t, "Cadre_bas", Vector3(0, -(taille.y + b) / 2, 0), Vector3(taille.x + 2 * b, b, 0.06), cadre, false)
	_boite(t, "Cadre_g", Vector3(-(taille.x + b) / 2, 0, 0), Vector3(b, taille.y, 0.06), cadre, false)
	_boite(t, "Cadre_d", Vector3((taille.x + b) / 2, 0, 0), Vector3(b, taille.y, 0.06), cadre, false)
	var formes: Array = m["formes"]
	for i in formes.size():
		var f: Array = formes[i]
		var pos := Vector3((f[0] + f[2] / 2.0 - 0.5) * taille.x, (f[1] + f[3] / 2.0 - 0.5) * taille.y, 0.02 + 0.002 * i)
		_boite(t, "Forme_%d" % i, pos, Vector3(f[2] * taille.x, f[3] * taille.y, 0.01), f[4], false)
	return t


## Une porte fermée, dessinée sur un mur (montants, panneau, poignée).
func _porte_dessinee(g: Node3D, nom: String, centre_bas: Vector3, rot_y: float) -> Node3D:
	var p := Node3D.new()
	p.position = centre_bas - g.position
	p.rotation.y = rot_y
	_ajouter(g, p, nom)
	_boite(p, "Panneau", Vector3(0, 1.2, 0), Vector3(1.0, 2.4, 0.06), "porte", false)
	_boite(p, "Montant_g", Vector3(-0.57, 1.25, 0.02), Vector3(0.14, 2.5, 0.1), "cadre", false)
	_boite(p, "Montant_d", Vector3(0.57, 1.25, 0.02), Vector3(0.14, 2.5, 0.1), "cadre", false)
	_boite(p, "Linteau", Vector3(0, 2.57, 0.02), Vector3(1.28, 0.14, 0.1), "cadre", false)
	_boite(p, "Poignee", Vector3(0.38, 1.05, 0.06), Vector3(0.12, 0.05, 0.06), "poignee", false)
	return p


# --- La maison -------------------------------------------------------------


## L'entrée (8 × 8 m) : le couloir de la porte d'entrée au nord, la chambre
## au sud, le salon à l'est, une fenêtre sur les étoiles à l'ouest.
func _entree() -> void:
	var g := _groupe("Hall")
	var h := HAUTEUR
	_sol_plafond(g, -4.3, 4.3, -4.3, 4.3, h)
	_mur(g, "Mur_nord", true, -4.15, -4.0, 4.0, h, "mur", [[0.0, COULOIR_L, COULOIR_H]])
	_mur(g, "Mur_sud", true, 4.15, -4.0, 4.0, h, "mur", [[0.0, 1.4, 2.4]])
	_mur(g, "Mur_ouest", false, -4.15, -4.3, 4.3, h, "mur", [[0.0, 4.0, 1.7, 0.9]])
	_mur_invisible(g, "Fenetre", Vector3(-4.15, 1.75, 0), Vector3(EP, 1.7, 4))
	_mur(g, "Mur_est", false, 4.15, -4.3, 4.3, h, "mur", [[0.0, 1.4, 2.4]])
	# Un porte-manteau et un banc, pour que ce soit une entrée.
	_boite(g, "Banc", Vector3(-3.5, 0.25, -2.6), Vector3(0.6, 0.5, 1.8), "meuble")
	_boite(g, "Portemanteau", Vector3(3.85, 1.7, -2.5), Vector3(0.1, 0.1, 1.2), "meuble", false)
	_lampe(g, "Lampe", Vector3(0, 2.8, 0), 7.0)
	_zone(g, "Zone", Vector3(0, 1.5, 0), Vector3(8, 3, 8))
	_pensee(g, "PenseeFenetre", Vector3(-4.15, 1.75, 0), "La maison flotte… au milieu de rien.", 6.0, 25.0)


## Le couloir de la porte d'entrée : 16 tronçons identiques. Au 7e, une porte
## trompeuse ramène le joueur 3 tronçons en arrière : il court sans jamais
## avancer. Au fond, la porte d'entrée reste toujours à la même distance (le
## niveau la déplace). Seule la lanterne du joueur éclaire le couloir.
func _couloir() -> void:
	var g := _groupe("Couloir")
	var longueur := TRONCON * TRONCONS
	var milieu := COULOIR_Z - longueur / 2
	var x_mur := COULOIR_L / 2 + EP / 2
	_boite(g, "Sol", Vector3(0, -0.25, milieu), Vector3(COULOIR_L + 2 * EP, 0.5, longueur), "couloir_sol")
	_boite(g, "Plafond", Vector3(0, COULOIR_H + EP / 2, milieu), Vector3(COULOIR_L + 2 * EP, EP, longueur), "plafond")
	_boite(g, "Mur_g", Vector3(-x_mur, COULOIR_H / 2, milieu), Vector3(EP, COULOIR_H, longueur), "couloir_mur")
	_boite(g, "Mur_d", Vector3(x_mur, COULOIR_H / 2, milieu), Vector3(EP, COULOIR_H, longueur), "couloir_mur")
	_boite(g, "Mur_fond", Vector3(0, COULOIR_H / 2, COULOIR_Z - longueur - EP / 2), Vector3(COULOIR_L + 2 * EP, COULOIR_H, EP), "couloir_mur")
	var x_face := COULOIR_L / 2
	for i in TRONCONS:
		var z_debut := COULOIR_Z - TRONCON * i
		var z_milieu := z_debut - TRONCON / 2
		# Piliers et poutre au début de chaque tronçon : on les voit défiler.
		_boite(g, "Pilier_g_%d" % i, Vector3(-x_face + 0.075, COULOIR_H / 2, z_debut - 0.15), Vector3(0.15, COULOIR_H, 0.3), "pilier", false)
		_boite(g, "Pilier_d_%d" % i, Vector3(x_face - 0.075, COULOIR_H / 2, z_debut - 0.15), Vector3(0.15, COULOIR_H, 0.3), "pilier", false)
		_boite(g, "Poutre_%d" % i, Vector3(0, COULOIR_H - 0.075, z_debut - 0.15), Vector3(COULOIR_L - 0.3, 0.15, 0.3), "pilier", false)
		# Un cadre vide de chaque côté.
		for cote in [-1, 1]:
			var x: float = cote * (x_face - 0.03)
			var nom := "g" if cote < 0 else "d"
			_boite(g, "Cadre_%s_%d" % [nom, i], Vector3(x, 1.5, z_milieu), Vector3(0.06, 0.9, 1.1), "cadre", false)
			_boite(g, "Toile_%s_%d" % [nom, i], Vector3(cote * (x_face - 0.065), 1.5, z_milieu), Vector3(0.02, 0.7, 0.9), "toile", false)
	var z_boucle := COULOIR_Z - TRONCON * TRONCON_BOUCLE
	var boucle := _porte_trompeuse(g, "Boucle", Vector3(0, 0, z_boucle), Vector3(COULOIR_L, COULOIR_H, 0.4))
	_marque(g, "Retour", Vector3(0, 0, z_boucle + TRONCON * RECUL))
	boucle.destinations = [NodePath("../Retour")]
	_zone(g, "Zone", Vector3(0, COULOIR_H / 2, milieu), Vector3(COULOIR_L, COULOIR_H, longueur))
	# La porte d'entrée, éclairée par en dessous, que l'on n'atteint jamais.
	var porte := _porte_dessinee(g, "PorteEntree", Vector3(0, 0, -22), 0.0)
	_boite(porte, "Rai", Vector3(0, 0.02, 0.06), Vector3(0.9, 0.03, 0.04), "lumiere_porte", false)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 1.2, 0.8)
	l.omni_range = 3.5
	l.light_energy = 0.9
	l.light_color = Color("fff1c9")
	_ajouter(porte, l, "Lumiere")
	var p := Pensee.new()
	p.position = Vector3(0, 1.2, 0)
	p.texte = "La porte d'entrée. Il faut que je sorte d'ici."
	p.distance = 30.0
	p.angle_max_deg = 8.0
	_ajouter(porte, p, "Pensee")


## La chambre, où l'on se réveille. Au-dessus du lit, une toile montre la
## maison dans les étoiles. À l'est, une fenêtre sur le vide.
func _chambre() -> void:
	var g := _groupe("Chambre")
	var h := HAUTEUR
	_sol_plafond(g, -3.3, 3.3, 4.3, 10.6, h)
	_mur(g, "Mur_sud", true, 10.45, -3.0, 3.0, h, "mur")
	_mur(g, "Mur_ouest", false, -3.15, 4.3, 10.6, h, "mur")
	_mur(g, "Mur_est", false, 3.15, 4.3, 10.6, h, "mur", [[7.3, 2.4, 1.5, 1.0]])
	_mur_invisible(g, "Fenetre", Vector3(3.15, 1.75, 7.3), Vector3(EP, 1.5, 2.4))
	_boite(g, "Lit", Vector3(0, 0.225, 9.2), Vector3(1.6, 0.45, 2.1), "meuble")
	_boite(g, "Lit_drap", Vector3(0, 0.52, 9.15), Vector3(1.5, 0.14, 1.9), "drap", false)
	_boite(g, "Lit_oreiller", Vector3(0, 0.65, 9.95), Vector3(1.0, 0.12, 0.35), "drap", false)
	_boite(g, "Lit_tete", Vector3(0, 0.6, 10.25), Vector3(1.7, 1.2, 0.1), "meuble")
	_boite(g, "Table_de_nuit", Vector3(1.25, 0.275, 10.0), Vector3(0.5, 0.55, 0.45), "meuble")
	_boite(g, "Armoire", Vector3(-2.7, 1.0, 6.0), Vector3(0.6, 2.0, 1.6), "meuble")
	var t := _toile(g, "Toile_lit", Vector3(0, 2.05, 10.28), PI, Vector2(1.6, 1.0), "maison_etoiles")
	var fin := _toile(g, "Toile_lit_fin", Vector3(0, 2.05, 10.28), PI, Vector2(1.6, 1.0), "peintre")
	fin.visible = false
	_lampe(g, "Lampe", Vector3(0, 2.8, 7.3), 6.0)
	_zone(g, "Zone", Vector3(0, 1.5, 7.45), Vector3(6, 3, 6))
	_marque(g, "Reveil", Vector3(-1.2, 0, 7.6), PI)
	_pensee(g, "PenseeFenetre", Vector3(3.15, 1.75, 7.3), "Des étoiles… Où est passé le jardin ?", 5.0, 25.0)
	_pensee(g, "PenseeToile", t.position + g.position, "Ce tableau… je ne l'ai jamais accroché ici.", 4.0, 15.0)
	_pensee(g, "PenseeFin", fin.position + g.position, "Sur le tableau, c'est moi, plus vieux.\nJe peins la maison… dans les étoiles.", 4.0, 15.0, true, false)


## Le salon, avec trois toiles qui sont des souvenirs. À l'est, la porte de
## la salle de bain, murée au début : elle n'apparaît que dans le dos du
## joueur, après son passage dans le couloir.
func _salon() -> void:
	var g := _groupe("Salon")
	var h := HAUTEUR
	_sol_plafond(g, 4.3, 12.6, -4.3, 4.3, h)
	_mur(g, "Mur_nord", true, -4.15, 4.3, 12.3, h, "mur")
	_mur(g, "Mur_sud", true, 4.15, 4.3, 12.3, h, "mur")
	_mur(g, "Mur_est", false, 12.45, -4.3, 4.3, h, "mur", [[0.0, 1.4, 2.4]])
	_boite(g, "PorteSdb", Vector3(12.45, 1.2, 0), Vector3(EP, 2.4, 1.4), "mur")
	_boite(g, "Canape", Vector3(8.3, 0.22, 3.0), Vector3(2.4, 0.45, 0.9), "meuble")
	_boite(g, "Canape_dossier", Vector3(8.3, 0.6, 3.5), Vector3(2.4, 0.8, 0.2), "meuble")
	_boite(g, "Table_basse", Vector3(8.3, 0.2, 1.4), Vector3(1.2, 0.4, 0.7), "meuble")
	_boite(g, "Table", Vector3(10.6, 0.38, -1.8), Vector3(1.4, 0.76, 0.9), "meuble")
	_boite(g, "Chaise_1", Vector3(10.0, 0.23, -0.9), Vector3(0.45, 0.46, 0.45), "meuble")
	_boite(g, "Chaise_2", Vector3(11.2, 0.23, -0.9), Vector3(0.45, 0.46, 0.45), "meuble")
	var jardin := _toile(g, "Toile_jardin", Vector3(6.5, 1.7, -3.98), 0.0, Vector2(1.4, 1.0), "jardin")
	var enfant := _toile(g, "Toile_enfant", Vector3(10.4, 1.8, -3.98), 0.0, Vector2(0.9, 1.1), "enfant")
	var atelier := _toile(g, "Toile_atelier", Vector3(8.3, 2.0, 3.98), PI, Vector2(1.6, 0.9), "atelier")
	_lampe(g, "Lampe", Vector3(8.3, 2.8, 0), 8.0)
	_zone(g, "Zone", Vector3(8.3, 1.5, 0), Vector3(8, 3, 8))
	_pensee(g, "PenseeJardin", jardin.position + g.position, "Notre jardin. Avant, la maison était sur Terre.", 4.5, 15.0)
	_pensee(g, "PenseeEnfant", enfant.position + g.position, "C'est moi, petit. Je peignais déjà.", 4.5, 15.0)
	_pensee(g, "PenseeAtelier", atelier.position + g.position, "Un atelier… Je ne m'en souviens pas.", 4.5, 15.0)
	_pensee(g, "PenseePorte", Vector3(12.45, 1.2, 0), "Cette porte… elle n'était pas là.", 8.0, 25.0, true, false)


## La salle de bain. Le miroir est au nord. Au sud, le vrai mur est plein ;
## dans le reflet, il a un passage.
func _salle_de_bain() -> void:
	var g := _groupe("SalleDeBain")
	var h := HAUTEUR
	_sol_plafond(g, 12.6, 18.9, -3.3, 3.3, h)
	_mur(g, "Mur_nord", true, -3.15, 12.6, 18.6, h, "mur")
	_mur(g, "Mur_est", false, 18.75, -3.3, 3.3, h, "mur")
	var reel := _boite(g, "MurReel", Vector3(15.6, h / 2, 3.15), Vector3(6.0, h, EP), "mur")
	reel.layers = Miroir.COUCHE_REEL
	var reflet := _boite(g, "MurReflet", Vector3(15.6, h / 2, 3.15), Vector3(6.0, h, EP), "mur", false)
	reflet.layers = Miroir.COUCHE_REFLET
	var trou := CSGBox3D.new()
	trou.operation = CSGShape3D.OPERATION_SUBTRACTION
	trou.position = Vector3(PASSAGE_X - 15.6, PASSAGE_H / 2 - h / 2, 0)
	trou.size = Vector3(PASSAGE_L, PASSAGE_H, EP + 0.2)
	_ajouter(reflet, trou, "Trou")
	# Derrière : le passage, qu'on ne voit que par le trou du reflet. Au fond,
	# la toile dans laquelle on tombe.
	var z0 := 3.3
	var lp := 3.0
	_boite(g, "Passage_sol", Vector3(PASSAGE_X, -0.25, z0 + lp / 2), Vector3(PASSAGE_L + 2 * EP, 0.5, lp), "passage")
	_boite(g, "Passage_plafond", Vector3(PASSAGE_X, PASSAGE_H + EP / 2, z0 + lp / 2), Vector3(PASSAGE_L + 2 * EP, EP, lp), "passage")
	_boite(g, "Passage_g", Vector3(PASSAGE_X - PASSAGE_L / 2 - EP / 2, PASSAGE_H / 2, z0 + lp / 2), Vector3(EP, PASSAGE_H, lp), "passage")
	_boite(g, "Passage_d", Vector3(PASSAGE_X + PASSAGE_L / 2 + EP / 2, PASSAGE_H / 2, z0 + lp / 2), Vector3(EP, PASSAGE_H, lp), "passage")
	_boite(g, "Passage_fond", Vector3(PASSAGE_X, PASSAGE_H / 2, z0 + lp + EP / 2), Vector3(PASSAGE_L + 2 * EP, PASSAGE_H, EP), "passage")
	_boite(g, "Passage_cadre", Vector3(PASSAGE_X, 1.15, z0 + lp - 0.03), Vector3(0.9, 1.2, 0.06), "cadre", false)
	_boite(g, "Passage_toile", Vector3(PASSAGE_X, 1.15, z0 + lp - 0.065), Vector3(0.7, 1.0, 0.02), "toile_passage", false)
	# Le lavabo, le miroir au-dessus, la baignoire et les toilettes.
	_boite(g, "Lavabo", Vector3(15.6, 0.425, -2.75), Vector3(1.0, 0.85, 0.5), "drap")
	_boite(g, "Miroir_cadre", Vector3(15.6, 1.85, -2.98), Vector3(2.6, 2.0, 0.04), "miroir_cadre", false)
	var miroir := Miroir.new()
	miroir.taille = Vector2(2.4, 1.8)
	miroir.position = Vector3(15.6, 1.85, -2.955) - g.position
	_ajouter(g, miroir, "Miroir")
	_boite(g, "Baignoire", Vector3(18.15, 0.3, 0.6), Vector3(0.8, 0.6, 1.9), "drap")
	_boite(g, "Toilettes", Vector3(13.1, 0.225, -2.6), Vector3(0.4, 0.45, 0.6), "drap")
	var passage := PassageReflet.new()
	passage.position = Vector3(PASSAGE_X, 0, 2.7) - g.position
	passage.rotation.y = PI
	_ajouter(g, passage, "Passage")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(PASSAGE_L, PASSAGE_H, 0.6)
	forme.shape = boite
	forme.position = Vector3(0, PASSAGE_H / 2, 0)
	_ajouter(passage, forme, "CollisionShape3D")
	passage.miroir = NodePath("../Miroir")
	_lampe(g, "Lampe", Vector3(15.6, 2.8, 0.3), 7.0)
	_pensee(g, "PenseeMiroir", Vector3(15.6, 1.85, -2.955), "Ce n'est pas moi… Si. C'est moi, plus vieux.", 4.0, 15.0)


# --- Dans la toile -----------------------------------------------------------


## La galerie, où l'on atterrit après la chute : à ciel ouvert, au milieu des
## étoiles. La porte d'entrée de la maison est sur un balcon, à 4 m. Une
## rampe monte à un palier à la même hauteur, mais le vide entre les deux
## (5,5 m) est trop large pour un saut : il faut y poser un grand cube. À
## l'est, la toile tournante : la chambre d'enfant, où est le cube.
func _galerie() -> void:
	var g := _groupe("Galerie", GALERIE)
	var h := 9.0
	var c := GALERIE
	_sol_plafond(g, c.x - 8.3, c.x + 8.3, c.z - 8.3, c.z + 8.3, h, "sol", "")
	_mur(g, "Mur_nord", true, c.z - 8.15, c.x - 8.0, c.x + 8.0, h, "mur")
	_mur(g, "Mur_sud", true, c.z + 8.15, c.x - 8.0, c.x + 8.0, h, "mur")
	_mur(g, "Mur_ouest", false, c.x - 8.15, c.z - 8.3, c.z + 8.3, h, "mur")
	_mur(g, "Mur_est", false, c.x + 8.15, c.z - 8.3, c.z + 8.3, h, "mur")
	_boite(g, "Balcon", Vector3(BALCON_X + 2.0, 3.85, -7.0), Vector3(4.0, 0.3, 2.0), "meuble")
	_boite(g, "Palier", Vector3(-7.25, 3.85, -6.0), Vector3(1.5, 0.3, 4.0), "meuble")
	# La rampe passe par (z = 84, y = 0) et (z = 76, y = 4), le long du mur ouest.
	var pente := atan2(4.0, 8.0)
	var rampe := _boite(g, "Rampe", Vector3(-7.25, 2.0, 0) - Vector3(0, cos(pente), sin(pente)) * 0.15, Vector3(1.5, 0.3, sqrt(80.0)), "meuble")
	rampe.rotation.x = pente
	_porte_dessinee(g, "PorteEntree", c + Vector3(BALCON_X + 2.0, 4.0, -7.97), 0.0)
	var fin := _porte_trompeuse(g, "PorteFin", c + Vector3(BALCON_X + 2.0, 4.0, -7.6), Vector3(1.0, 2.4, 0.5))
	fin.destinations = [NodePath("../../Chambre/Reveil")]
	# La toile tournante, sur le mur est, posée au sol : on peut y entrer.
	var toile := ToileTournante.new()
	toile.position = Vector3(7.97, 1.5, 0)
	toile.rotation.y = -PI / 2
	_ajouter(g, toile, "ToileTournante")
	var b := 0.2
	var cote := toile.taille
	for bord in [["Cadre_haut", Vector3(0, cote / 2 + b / 2, 0), Vector3(cote + 2 * b, b, 0.12)],
			["Cadre_g", Vector3(-cote / 2 - b / 2, -0.1, 0), Vector3(b, cote + 0.2, 0.12)],
			["Cadre_d", Vector3(cote / 2 + b / 2, -0.1, 0), Vector3(b, cote + 0.2, 0.12)],
			["Manivelle", Vector3(cote / 2 + b + 0.12, 0, 0.12), Vector3(0.12, 0.5, 0.12)],
			["Manivelle_bras", Vector3(cote / 2 + b + 0.12, 0.25, 0.25), Vector3(0.08, 0.08, 0.3)]]:
		_boite(toile, bord[0], bord[1], bord[2], "cadre_toile", false)
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = bord[2]
		forme.shape = boite
		forme.position = bord[1]
		_ajouter(toile, forme, "Forme_" + bord[0])
	toile.piece = NodePath("../../ToilePeinte/Chambre")
	toile.vue = NodePath("../../ToilePeinte/Vue")
	var entree := _porte_trompeuse(g, "EntreeToile", c + Vector3(7.75, 0, 0), Vector3(cote, cote + 0.2, 0.4), -PI / 2)
	entree.destinations = [NodePath("../../ToilePeinte/Arrivee")]
	_marque(g, "RetourGalerie", c + Vector3(6.3, 0, 0), PI / 2)
	_toile(g, "Toile_maison", c + Vector3(-7.98, 2.6, -3.0), PI / 2, Vector2(2.4, 1.7), "jardin")
	_toile(g, "Toile_atelier", c + Vector3(-7.98, 2.6, 3.0), PI / 2, Vector2(2.4, 1.4), "atelier")
	_lampe(g, "Lampe_nord", c + Vector3(0, 7.0, -4.0), 14.0, true, 2.0)
	_lampe(g, "Lampe_sud", c + Vector3(0, 7.0, 4.0), 14.0, true, 2.0)
	_marque(g, "Arrivee", c + Vector3(0, 1.0, 6.0))
	_pensee(g, "PenseeArrivee", c + Vector3(0, 1.0, 6.0), "Je suis… dans le tableau ?", 2.0, 0.0, false)
	_pensee(g, "PenseePorte", c + Vector3(BALCON_X + 2.0, 5.2, -7.97), "La porte d'entrée. Là-haut.", 18.0, 12.0)
	_pensee(g, "PenseeToile", c + Vector3(7.97, 1.5, 0), "Ma chambre d'enfant… Tout y est en couleurs.", 6.0, 15.0)


## La chambre d'enfant peinte : un cube de 6 m, ouvert vers +Z, que la toile
## tournante filme. « Chambre » tourne autour de Z avec la toile ; l'arrivée,
## la sortie, la lumière et le point de vue ne tournent pas. Le cube est en
## haut d'une étagère, hors de portée tant que la pièce est droite.
func _chambre_peinte() -> void:
	var g := _groupe("ToilePeinte", CHAMBRE_PEINTE)
	var d := COTE_PEINT / 2
	var piece := Node3D.new()
	_ajouter(g, piece, "Chambre")
	_boite(piece, "Sol", Vector3(0, -d - EP / 2, 0), Vector3(COTE_PEINT + 2 * EP, EP, COTE_PEINT), "r_sol")
	_boite(piece, "Plafond", Vector3(0, d + EP / 2, 0), Vector3(COTE_PEINT + 2 * EP, EP, COTE_PEINT), "r_plafond")
	_boite(piece, "Mur_g", Vector3(-d - EP / 2, 0, 0), Vector3(EP, COTE_PEINT, COTE_PEINT), "r_mur")
	_boite(piece, "Mur_d", Vector3(d + EP / 2, 0, 0), Vector3(EP, COTE_PEINT, COTE_PEINT), "r_mur")
	_boite(piece, "Mur_fond", Vector3(0, 0, -d - EP / 2), Vector3(COTE_PEINT + 2 * EP, COTE_PEINT + 2 * EP, EP), "r_fond")
	_boite(piece, "Lit", Vector3(-1.6, -d + 0.2, -1.6), Vector3(1.0, 0.4, 1.8), "r_lit")
	_boite(piece, "Lit_drap", Vector3(-1.6, -d + 0.45, -1.7), Vector3(0.9, 0.1, 1.5), "r_drap", false)
	_boite(piece, "Fenetre", Vector3(-d + 0.03, 0.5, 0), Vector3(0.05, 1.2, 1.4), "ciel", false)
	_boite(piece, "Fenetre_soleil", Vector3(-d + 0.06, 0.8, 0.3), Vector3(0.02, 0.3, 0.3), "soleil", false)
	_boite(piece, "Etagere", Vector3(d - 0.3, 2.2, 0), Vector3(0.6, 0.1, 1.4), "bois")
	var cube: ObjetPerspectif = load("res://scenes/cube.tscn").instantiate()
	cube.position = Vector3(d - 0.3, 2.5, 0)
	cube.freeze = true
	_ajouter(piece, cube, "Cube")
	var bas := CHAMBRE_PEINTE.y - d
	_lampe(g, "Lampe", CHAMBRE_PEINTE + Vector3(0, 0, 1.0), 9.0, false)
	_marque(g, "Arrivee", Vector3(CHAMBRE_PEINTE.x, bas, CHAMBRE_PEINTE.z + 1.2))
	var sortie := _porte_trompeuse(g, "Sortie", Vector3(CHAMBRE_PEINTE.x, bas, CHAMBRE_PEINTE.z + d - 0.4), Vector3(COTE_PEINT, COTE_PEINT, 0.4), PI)
	sortie.destinations = [NodePath("../../Galerie/RetourGalerie")]
	# Le point de vue de la toile : face à l'ouverture, à la distance où le
	# cube remplit l'image (champ de 70°).
	var vue := Marker3D.new()
	vue.position = Vector3(0, 0, d + d / tan(deg_to_rad(35.0)))
	_ajouter(g, vue, "Vue")
	_pensee(g, "PenseeArrivee", Vector3(CHAMBRE_PEINTE.x, bas + 1.0, CHAMBRE_PEINTE.z + 1.2), "C'est peint… Tout est peint.", 2.0, 0.0, false)
