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
	"photo_jaune": "ffca3a", "soleil": "fff3b0", "repere": "00f5d4",
	"porte": "f15bb5", "jardin": "9ef01a",
}

var _racine: Node3D
var _materiaux := {}


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Maison"
	_racine.set_script(load("res://scripts/niveau/maison.gd"))
	_environnement()
	_hall()
	_couloir()
	_salon()
	_atelier()
	_jardin()
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
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(COULEURS[cle])
		m.roughness = 0.6
		if cle in ["repere", "photo_bonne", "soleil", "aiguille", "horloge"]:
			m.emission_enabled = true
			m.emission = Color(COULEURS[cle])
			m.emission_energy_multiplier = 0.6
		_materiaux[cle] = m
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


func _texte(parent: Node, nom: String, pos: Vector3, texte: String, rot_y := 0.0) -> Label3D:
	var l := Label3D.new()
	l.position = pos
	l.rotation.y = rot_y
	l.text = texte
	l.font_size = 64
	l.pixel_size = 0.006
	l.outline_size = 16
	l.modulate = Color.WHITE
	l.outline_modulate = Color("2b1d4e")
	return _ajouter(parent, l, nom)


## Une pièce rectangulaire : sol et 4 murs. `ouvertures` donne, pour chaque
## mur ("avant" vers -Z, "arriere", "gauche", "droite"), la largeur d'une
## ouverture centrée (0 = mur plein).
func _piece(g: Node3D, centre: Vector3, taille: Vector2, sol: String, mur: String, ouvertures := {}) -> void:
	var lx := taille.x
	var lz := taille.y
	_boite(g, "Sol", centre + Vector3(0, -0.25, 0), Vector3(lx, 0.5, lz), sol)
	var murs := {
		"avant": [Vector3(0, 1.5, -lz / 2 - 0.1), lx + 0.4, true],
		"arriere": [Vector3(0, 1.5, lz / 2 + 0.1), lx + 0.4, true],
		"gauche": [Vector3(-lx / 2 - 0.1, 1.5, 0), lz, false],
		"droite": [Vector3(lx / 2 + 0.1, 1.5, 0), lz, false],
	}
	for cote in murs:
		var pos: Vector3 = centre + murs[cote][0]
		var longueur: float = murs[cote][1]
		var sur_x: bool = murs[cote][2]
		var trou: float = ouvertures.get(cote, 0.0)
		if trou <= 0.0:
			var t := Vector3(longueur, 3, 0.2) if sur_x else Vector3(0.2, 3, longueur)
			_boite(g, "Mur_" + cote, pos, t, mur)
			continue
		var bout := (longueur - trou) / 2
		var decalage := (trou + bout) / 2
		var axe := Vector3(1, 0, 0) if sur_x else Vector3(0, 0, 1)
		var t2 := Vector3(bout, 3, 0.2) if sur_x else Vector3(0.2, 3, bout)
		_boite(g, "Mur_%s_a" % cote, pos - axe * decalage, t2, mur)
		_boite(g, "Mur_%s_b" % cote, pos + axe * decalage, t2, mur)


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
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-55, 35, 0)
	soleil.light_energy = 1.1
	soleil.shadow_enabled = true
	_ajouter(_racine, soleil, "Soleil")


func _hall() -> void:
	var g := _groupe("Hall")
	_piece(g, Vector3(0, 0, 3), Vector2(6, 6), "hall_sol", "hall_mur", {"avant": 2.5})
	_photo(g, "PhotoSouvenir", Vector3(-2.98, 1.7, 3), "photo_bonne", true, PI / 2)
	_texte(g, "Souvenir", Vector3(-2.95, 2.3, 3), "Mon souvenir préféré", PI / 2)
	_texte(g, "Indice", Vector3(0, 2.6, 0.05), "Le couloir ne mène nulle part…\nsauf si tu regardes\nle bon souvenir.")
	_ancrage(g, "Ancrage", Vector3(0, 0, 4.5), Vector3(0, 1.5, 3), Vector3(6, 3, 6))


func _couloir() -> void:
	var g := _groupe("Couloir")
	_boite(g, "Sol", Vector3(0, -0.25, -7), Vector3(2.5, 0.5, 14), "couloir_sol")
	_boite(g, "MurGauche", Vector3(-1.35, 1.5, -7), Vector3(0.2, 3, 14), "couloir_mur")
	_boite(g, "MurDroit", Vector3(1.35, 1.5, -7), Vector3(0.2, 3, 14), "couloir_mur")
	_boite(g, "MurFond", Vector3(0, 1.5, -14.1), Vector3(2.9, 3, 0.2), "couloir_mur")
	_photo(g, "PhotoRouge", Vector3(-0.8, 1.8, -13.97), "photo_rouge")
	_photo(g, "PhotoBonne", Vector3(0, 1.8, -13.97), "photo_bonne", true)
	_photo(g, "PhotoJaune", Vector3(0.8, 1.8, -13.97), "photo_jaune")
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
	_boite(g, "MurGauche", Vector3(24.9, 1.5, -11), Vector3(0.2, 3, 22), "salon_mur")
	_boite(g, "MurDroit", Vector3(35.1, 1.5, -11), Vector3(0.2, 3, 22), "salon_mur")
	_boite(g, "MurArriere", Vector3(30, 1.5, 0.1), Vector3(10.4, 3, 0.2), "salon_mur")
	# Au présent, un mur plein ; dans le passé, une arche en pierre.
	_boite(g, "MurPresent", Vector3(30, 1.5, -10), Vector3(10, 3, 0.3), "salon_mur", true, PRESENT)
	_boite(g, "ArcheGauche", Vector3(27, 1.5, -10), Vector3(4, 3, 0.3), "pierre", true, PASSE)
	_boite(g, "ArcheDroite", Vector3(33, 1.5, -10), Vector3(4, 3, 0.3), "pierre", true, PASSE)
	_boite(g, "ArcheHaut", Vector3(30, 2.75, -10), Vector3(2, 0.5, 0.3), "pierre", true, PASSE)
	_boite(g, "Canape", Vector3(27, 0.4, -6), Vector3(3, 0.8, 1), "canape", true, PRESENT)
	_boite(g, "Colonne", Vector3(32.5, 1.5, -5), Vector3(0.8, 3, 0.8), "colonne", true, PASSE)
	_texte(g, "Indice", Vector3(30, 2.5, -9.8), "Appuie sur Tab (ou clic droit)\npour voir cette pièce à une autre époque.")
	var arrivee := Marker3D.new()
	arrivee.position = Vector3(30, 0, -1.5)
	_ajouter(g, arrivee, "Arrivee")
	_ancrage(g, "Ancrage", Vector3(30, 0, -2), Vector3(30, 1.5, -5), Vector3(10, 3, 10))


func _atelier() -> void:
	var g := _groupe("Atelier")
	# Le sol et les murs de côté sont ceux du salon (même grand volume).
	_boite(g, "MurFond_a", Vector3(27, 1.5, -22.1), Vector3(4, 3, 0.2), "atelier_mur")
	_boite(g, "MurFond_b", Vector3(33, 1.5, -22.1), Vector3(4, 3, 0.2), "atelier_mur")
	_boite(g, "MurFond_haut", Vector3(30, 2.75, -22.1), Vector3(2, 0.5, 0.2), "atelier_mur")
	_boite(g, "PorteSortie", Vector3(30, 1.25, -22.1), Vector3(2, 2.5, 0.2), "porte")
	_boite(g, "Repere", Vector3(30, 0.01, -12), Vector3(0.6, 0.02, 0.6), "repere", false)
	_texte(g, "Indice", Vector3(34.9, 1.8, -14), "Place-toi sur la marque\net regarde au loin.", -PI / 2)
	_ancrage(g, "Ancrage", Vector3(30, 0, -11), Vector3(30, 1.5, -16), Vector3(10, 3, 12))
	var vue := Marker3D.new()
	vue.position = Vector3(30, 1.6, -12)
	_ajouter(g, vue, "PointDeVue")
	# L'horloge : vue depuis la marque, ses morceaux éparpillés forment un cadran.
	var centre_image := Vector3(30, 2.2, -20)
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
	_texte(g, "Panneau", Vector3(30, 1.8, -29), "Bientôt : l'Égypte ancienne…")
	var fin := Area3D.new()
	fin.position = Vector3(30, 1, -25)
	_ajouter(g, fin, "Fin")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(6, 2, 2)
	forme.shape = boite
	_ajouter(fin, forme, "CollisionShape3D")


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
