class_name Constructeur
extends RefCounted

## Base des constructeurs de niveaux (maison, Égypte…) : chaque niveau est
## généré par le code, puis enregistré en .tscn.
## Attention : reconstruire écrase les retouches faites dans l'éditeur.

const TempsScript := preload("res://scripts/time/temps.gd")
const PRESENT := TempsScript.Epoque.PRESENT
const PASSE := TempsScript.Epoque.PASSE

var _racine: Node3D
var _materiaux := {}
var _m  # meubles (tools/meubles.gd)


## Couleurs du niveau : { clé: "rrggbb" }.
func _couleurs() -> Dictionary:
	return {}


## Clés de couleur qui brillent un peu (repères, objets importants).
func _lumineux() -> Array:
	return []


## Enregistre la scène construite, puis libère les nœuds.
func _enregistrer(chemin: String) -> int:
	var scene := PackedScene.new()
	var err := scene.pack(_racine)
	if err == OK:
		err = ResourceSaver.save(scene, chemin)
	print(chemin.get_file(), " : ", error_string(err))
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
		_materiaux[cle] = Style.materiau(Color(_couleurs()[cle]), cle in _lumineux())
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


## Point de réapparition : `point` en coordonnées du monde, avec la zone qui
## l'active.
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


## Un morceau d'une image à aligner : posé sur le rayon qui va de `vue` à
## `point_image`, à la fraction `k` de la distance, et agrandi d'autant. Vu
## depuis `vue`, il a donc toujours la même taille apparente.
func _morceau(parent: Node3D, nom: String, vue: Vector3, point_image: Vector3, taille: Vector3, rot_z: float, k: float, couleur: String) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.position = vue + (point_image - vue) * k - parent.position
	b.size = taille
	b.scale = Vector3.ONE * k
	b.rotation.z = rot_z
	b.material = _mat(couleur)
	b.use_collision = false
	return _ajouter(parent, b, nom)


## Le joueur, l'effet de bascule, le viseur et la zone des messages.
func _joueur_et_interface(depart: Vector3, rot_y := 0.0) -> void:
	var joueur: Player = load("res://scenes/player.tscn").instantiate()
	joueur.position = depart
	joueur.rotation.y = rot_y
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
