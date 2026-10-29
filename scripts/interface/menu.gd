extends Control

## Le menu principal : le titre, des étoiles, et Continuer (s'il y a une
## partie en cours), Nouvelle partie, Quitter.

## Où commence une nouvelle partie.
const PREMIERE_SCENE := "res://scenes/intro.tscn"
const NOMBRE_ETOILES := 220

var _continuer: Button
var _nouvelle: Button
## Une partie est en cours : « Nouvelle partie » demande d'abord de confirmer.
var _confirmer := false
var _etoiles: Array[Vector3] = []
var _temps := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 42
	for i in NOMBRE_ETOILES:
		_etoiles.append(Vector3(hasard.randf(), hasard.randf(), hasard.randf()))
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 16)
	centre.add_child(colonne)
	var titre := Label.new()
	titre.text = "Aligner l'espace et le temps"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 52)
	titre.add_theme_color_override("font_outline_color", Color("2b1d4e"))
	titre.add_theme_constant_override("outline_size", 12)
	colonne.add_child(titre)
	var espace := Control.new()
	espace.custom_minimum_size = Vector2(0, 40)
	colonne.add_child(espace)
	_continuer = _bouton(colonne, "Continuer", Histoire.continuer)
	_continuer.visible = Histoire.peut_continuer()
	_nouvelle = _bouton(colonne, "Nouvelle partie", nouvelle_partie)
	_bouton(colonne, "Quitter", get_tree().quit)
	(_continuer if _continuer.visible else _nouvelle).grab_focus.call_deferred()


func _bouton(parent: Control, texte: String, action: Callable) -> Button:
	var b := Button.new()
	b.name = texte.replace(" ", "_")
	b.text = texte
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(420, 56)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## Avec une partie en cours, il faut appuyer deux fois : elle sera effacée.
func nouvelle_partie() -> void:
	if Histoire.peut_continuer() and not _confirmer:
		_confirmer = true
		_nouvelle.text = "Effacer la partie et recommencer ?"
		return
	Histoire.nouvelle_partie(PREMIERE_SCENE)


func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()


## Le fond : la nuit, et des étoiles qui scintillent et dérivent lentement.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b0b1a"))
	for e in _etoiles:
		var p := Vector2(fposmod(e.x + _temps * 0.004 * (0.3 + e.z), 1.0) * size.x, e.y * size.y)
		var eclat := 0.45 + 0.55 * absf(sin(_temps * (0.6 + e.z) + e.x * 40.0))
		draw_circle(p, 0.8 + 1.6 * e.z, Color(1.0, 0.95, 0.8, eclat))
