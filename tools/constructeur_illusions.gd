extends "res://tools/constructeur.gd"

## Construit scenes/illusions.tscn, le prototype gris du musée des illusions
## (lancé par construire_illusions.gd). Voir
## docs/superpowers/specs/2026-10-28-direction-illusions-design.md.
##
## Plan, vu de dessus (-Z vers le haut) :
##
##        Couloir sans fin (64 m, vers -Z)
##               |
##   étoiles -- Hall -- Salle du miroir
##                         (le passage du reflet au sud)
##
## La « suite », où l'on atterrit après la chute, est à l'écart, en z = 60.

const COULEURS := {
	"sol": "5d5d66", "mur": "9a9aa3", "plafond": "7d7d86",
	"couloir_sol": "4a4a52", "couloir_mur": "85858e", "pilier": "6e6e77",
	"cadre": "b8b8c0", "toile": "3a3a42", "miroir_cadre": "2e2e36",
	"passage": "55555e", "toile_passage": "e0e0ea",
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
## Le passage du reflet, dans le mur sud de la salle du miroir.
const PASSAGE_X := 11.3
const PASSAGE_L := 1.4
const PASSAGE_H := 2.3


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Illusions"
	_racine.set_script(load("res://scripts/niveau/illusions.gd"))
	_environnement()
	_hall()
	_couloir()
	_salle_miroir()
	_suite()
	_joueur_et_interface(Vector3(0, 0, 2.5))
	# Pas d'époques dans ce prototype : pas d'effet de bascule.
	_racine.get_node("BasculeFx").free()
	var chute := ChuteToiles.new()
	_ajouter(_racine.get_node("Interface"), chute, "ChuteToiles")
	return _enregistrer("res://scenes/illusions.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["toile_passage"]


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


func _lampe(g: Node3D, nom: String, pos: Vector3, portee: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos - g.position
	l.omni_range = portee
	l.light_energy = 1.2
	l.shadow_enabled = true
	_ajouter(g, l, nom)


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


## Le hall (8 × 8 m) : une fenêtre sur les étoiles à l'ouest, le couloir au
## nord, et à l'est un mur qui deviendra la porte de la salle du miroir.
func _hall() -> void:
	var g := _groupe("Hall")
	var h := HAUTEUR
	_boite(g, "Sol", Vector3(0, -0.25, 0), Vector3(8.6, 0.5, 8.6), "sol")
	_boite(g, "Plafond", Vector3(0, h + 0.15, 0), Vector3(8.6, EP, 8.6), "plafond")
	# Nord : l'entrée du couloir.
	_boite(g, "Mur_nord_a", Vector3(-2.65, h / 2, -4.15), Vector3(3.3, h, EP), "mur")
	_boite(g, "Mur_nord_b", Vector3(2.65, h / 2, -4.15), Vector3(3.3, h, EP), "mur")
	_boite(g, "Mur_nord_linteau", Vector3(0, (h + COULOIR_H) / 2, -4.15), Vector3(COULOIR_L, h - COULOIR_H, EP), "mur")
	_boite(g, "Mur_sud", Vector3(0, h / 2, 4.15), Vector3(8.6, h, EP), "mur")
	# Ouest : une grande fenêtre sur le vide et les étoiles.
	_boite(g, "Mur_ouest_a", Vector3(-4.15, h / 2, -3), Vector3(EP, h, 2), "mur")
	_boite(g, "Mur_ouest_b", Vector3(-4.15, h / 2, 3), Vector3(EP, h, 2), "mur")
	_boite(g, "Mur_ouest_bas", Vector3(-4.15, 0.45, 0), Vector3(EP, 0.9, 4), "mur")
	_boite(g, "Mur_ouest_haut", Vector3(-4.15, (h + 2.6) / 2, 0), Vector3(EP, h - 2.6, 4), "mur")
	_mur_invisible(g, "Fenetre", Vector3(-4.15, 1.75, 0), Vector3(EP, 1.7, 4))
	# Est : la porte de la salle du miroir, murée au début.
	_boite(g, "Mur_est_a", Vector3(4.15, h / 2, -2.5), Vector3(EP, h, 3), "mur")
	_boite(g, "Mur_est_b", Vector3(4.15, h / 2, 2.5), Vector3(EP, h, 3), "mur")
	_boite(g, "Mur_est_linteau", Vector3(4.15, (h + 2.6) / 2, 0), Vector3(EP, h - 2.6, 2), "mur")
	_boite(g, "PorteMiroir", Vector3(4.15, 1.3, 0), Vector3(EP, 2.6, 2), "mur")
	_lampe(g, "Lampe", Vector3(0, 2.8, 0), 7.0)
	_zone(g, "Zone", Vector3(0, 1.5, 0), Vector3(8, 3, 8))


## Le couloir sans fin : 16 tronçons identiques. Au 7e, une porte trompeuse
## ramène le joueur 3 tronçons en arrière : il court sans jamais avancer. Il
## n'a d'autre lumière que sa lanterne, le fond reste noir.
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
	var retour := Marker3D.new()
	retour.position = Vector3(0, 0, z_boucle + TRONCON * RECUL) - g.position
	_ajouter(g, retour, "Retour")
	boucle.destinations = [NodePath("../Retour")]
	_zone(g, "Zone", Vector3(0, COULOIR_H / 2, milieu), Vector3(COULOIR_L, COULOIR_H, longueur))


## La salle du miroir (10 × 8 m), à l'est du hall. Le miroir est au nord. Au
## sud, le vrai mur est plein ; dans le reflet, il a un passage.
func _salle_miroir() -> void:
	var g := _groupe("SalleMiroir")
	var h := HAUTEUR
	_boite(g, "Sol", Vector3(9.45, -0.25, 0), Vector3(10.3, 0.5, 8.6), "sol")
	_boite(g, "Plafond", Vector3(9.45, h + 0.15, 0), Vector3(10.3, EP, 8.6), "plafond")
	_boite(g, "Mur_nord", Vector3(9.45, h / 2, -4.15), Vector3(10.3, h, EP), "mur")
	_boite(g, "Mur_est", Vector3(14.45, h / 2, 0), Vector3(EP, h, 8), "mur")
	var reel := _boite(g, "MurReel", Vector3(9.45, h / 2, 4.15), Vector3(10.3, h, EP), "mur")
	reel.layers = Miroir.COUCHE_REEL
	var reflet := _boite(g, "MurReflet", Vector3(9.45, h / 2, 4.15), Vector3(10.3, h, EP), "mur", false)
	reflet.layers = Miroir.COUCHE_REFLET
	var trou := CSGBox3D.new()
	trou.operation = CSGShape3D.OPERATION_SUBTRACTION
	trou.position = Vector3(PASSAGE_X - 9.45, PASSAGE_H / 2 - h / 2, 0)
	trou.size = Vector3(PASSAGE_L, PASSAGE_H, EP + 0.2)
	_ajouter(reflet, trou, "Trou")
	# Derrière : le passage, qu'on ne voit que par le trou du reflet. Au fond,
	# la toile dans laquelle on tombe.
	var z0 := 4.3
	var lp := 4.0
	_boite(g, "Passage_sol", Vector3(PASSAGE_X, -0.25, z0 + lp / 2), Vector3(PASSAGE_L + 2 * EP, 0.5, lp), "passage")
	_boite(g, "Passage_plafond", Vector3(PASSAGE_X, PASSAGE_H + EP / 2, z0 + lp / 2), Vector3(PASSAGE_L + 2 * EP, EP, lp), "passage")
	_boite(g, "Passage_g", Vector3(PASSAGE_X - PASSAGE_L / 2 - EP / 2, PASSAGE_H / 2, z0 + lp / 2), Vector3(EP, PASSAGE_H, lp), "passage")
	_boite(g, "Passage_d", Vector3(PASSAGE_X + PASSAGE_L / 2 + EP / 2, PASSAGE_H / 2, z0 + lp / 2), Vector3(EP, PASSAGE_H, lp), "passage")
	_boite(g, "Passage_fond", Vector3(PASSAGE_X, PASSAGE_H / 2, z0 + lp + EP / 2), Vector3(PASSAGE_L + 2 * EP, PASSAGE_H, EP), "passage")
	_boite(g, "Passage_cadre", Vector3(PASSAGE_X, 1.2, z0 + lp - 0.03), Vector3(1.0, 1.3, 0.06), "cadre", false)
	_boite(g, "Passage_toile", Vector3(PASSAGE_X, 1.2, z0 + lp - 0.065), Vector3(0.8, 1.1, 0.02), "toile_passage", false)
	# Le miroir et son cadre.
	_boite(g, "Miroir_cadre", Vector3(9.3, 1.5, -3.98), Vector3(3.3, 2.7, 0.04), "miroir_cadre", false)
	var miroir := Miroir.new()
	miroir.position = Vector3(9.3, 1.5, -3.955) - g.position
	_ajouter(g, miroir, "Miroir")
	var passage := PassageReflet.new()
	passage.position = Vector3(PASSAGE_X, 0, 3.7) - g.position
	passage.rotation.y = PI
	_ajouter(g, passage, "Passage")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(PASSAGE_L, PASSAGE_H, 0.6)
	forme.shape = boite
	forme.position = Vector3(0, PASSAGE_H / 2, 0)
	_ajouter(passage, forme, "CollisionShape3D")
	passage.miroir = NodePath("../Miroir")
	_lampe(g, "Lampe", Vector3(9.3, 2.8, 0.5), 9.0)


## La suite : une petite salle fermée où l'on atterrit après la chute.
func _suite() -> void:
	var c := Vector3(0, 0, 60)
	var g := _groupe("Suite", c)
	var h := HAUTEUR
	_boite(g, "Sol", Vector3(0, -0.25, 0), Vector3(6.6, 0.5, 6.6), "sol")
	_boite(g, "Plafond", Vector3(0, h + 0.15, 0), Vector3(6.6, EP, 6.6), "plafond")
	_boite(g, "Mur_nord", Vector3(0, h / 2, -3.15), Vector3(6.6, h, EP), "mur")
	_boite(g, "Mur_sud", Vector3(0, h / 2, 3.15), Vector3(6.6, h, EP), "mur")
	_boite(g, "Mur_ouest", Vector3(-3.15, h / 2, 0), Vector3(EP, h, 6), "mur")
	_boite(g, "Mur_est", Vector3(3.15, h / 2, 0), Vector3(EP, h, 6), "mur")
	_lampe(g, "Lampe", c + Vector3(0, 2.8, 0), 6.0)
	var arrivee := Marker3D.new()
	arrivee.position = Vector3(0, 1.0, 1.5)
	_ajouter(g, arrivee, "Arrivee")
