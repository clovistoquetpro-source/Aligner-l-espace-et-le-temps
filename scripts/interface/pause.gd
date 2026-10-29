extends CanvasLayer

## Autoload « Pause » : Échap met le jeu en pause, partout sauf au menu
## principal. Reprendre, la sensibilité de la souris, le plein écran, les
## touches, retour au menu, quitter. Les réglages sont sauvegardés.

const MENU := "res://scenes/menu.tscn"
## Là, Échap ne met pas en pause (le menu, la cinématique du début).
const HORS_JEU := [MENU, "res://scenes/intro.tscn"]

var sensibilite := 1.0
var plein_ecran := false
var en_pause := false
## Où sont les réglages (les tests en prennent un autre).
var chemin_reglages := "user://reglages.cfg"

var _panneau: Control
var _reprendre: Button
var _touches: Label
var _texte_sensibilite: Label
var _curseur: HSlider
var _case_plein_ecran: CheckBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_lire_reglages()
	_construire()
	_panneau.visible = false
	if plein_ecran and not _headless():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("liberer_souris") and jeu_en_cours():
		basculer()
		get_viewport().set_input_as_handled()


## Un niveau est lancé (pas le menu principal).
func jeu_en_cours() -> bool:
	var s := get_tree().current_scene
	return s != null and not s.scene_file_path in HORS_JEU


func basculer() -> void:
	if en_pause:
		reprendre()
	else:
		mettre_en_pause()


func mettre_en_pause() -> void:
	en_pause = true
	get_tree().paused = true
	var s := get_tree().current_scene
	var en_plus: String = s.get("touches_en_plus") if s != null and s.get("touches_en_plus") != null else ""
	_touches.text = Souvenir.TOUCHES + ("\n" + en_plus if en_plus != "" else "")
	_panneau.visible = true
	if not _headless():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_reprendre.grab_focus()


func reprendre() -> void:
	en_pause = false
	get_tree().paused = false
	_panneau.visible = false
	if not _headless():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Retour au menu principal ; la partie reste sauvegardée au début du niveau.
func retour_au_menu() -> void:
	reprendre()
	if not _headless():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Histoire.vers(MENU)


func changer_sensibilite(v: float) -> void:
	sensibilite = v
	_texte_sensibilite.text = "Sensibilité de la souris : %.2f" % v
	_ecrire_reglages()


func changer_plein_ecran(oui: bool) -> void:
	plein_ecran = oui
	if not _headless():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if oui else DisplayServer.WINDOW_MODE_WINDOWED)
	_ecrire_reglages()


func _lire_reglages() -> void:
	var f := ConfigFile.new()
	if f.load(chemin_reglages) != OK:
		return
	sensibilite = float(f.get_value("souris", "sensibilite", 1.0))
	plein_ecran = bool(f.get_value("ecran", "plein_ecran", false))


func _ecrire_reglages() -> void:
	var f := ConfigFile.new()
	f.set_value("souris", "sensibilite", sensibilite)
	f.set_value("ecran", "plein_ecran", plein_ecran)
	f.save(chemin_reglages)


## Le panneau : un voile sombre, puis, au milieu, les boutons et les réglages,
## et les touches à côté.
func _construire() -> void:
	_panneau = Control.new()
	_panneau.name = "Panneau"
	_panneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panneau)
	var voile := ColorRect.new()
	voile.color = Color(0.03, 0.03, 0.08, 0.82)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panneau.add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panneau.add_child(centre)
	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 80)
	centre.add_child(rangee)
	var colonne := VBoxContainer.new()
	colonne.custom_minimum_size = Vector2(360, 0)
	colonne.add_theme_constant_override("separation", 14)
	rangee.add_child(colonne)
	var titre := Label.new()
	titre.text = "Pause"
	titre.add_theme_font_size_override("font_size", 40)
	colonne.add_child(titre)
	_reprendre = _bouton(colonne, "Reprendre", reprendre)
	_texte_sensibilite = Label.new()
	_texte_sensibilite.add_theme_font_size_override("font_size", 18)
	colonne.add_child(_texte_sensibilite)
	_curseur = HSlider.new()
	_curseur.min_value = 0.25
	_curseur.max_value = 3.0
	_curseur.step = 0.05
	_curseur.value = sensibilite
	_curseur.custom_minimum_size = Vector2(320, 24)
	colonne.add_child(_curseur)
	_texte_sensibilite.text = "Sensibilité de la souris : %.2f" % sensibilite
	_curseur.value_changed.connect(changer_sensibilite)
	_case_plein_ecran = CheckBox.new()
	_case_plein_ecran.text = "Plein écran"
	_case_plein_ecran.button_pressed = plein_ecran
	_case_plein_ecran.add_theme_font_size_override("font_size", 20)
	_case_plein_ecran.toggled.connect(changer_plein_ecran)
	colonne.add_child(_case_plein_ecran)
	_bouton(colonne, "Retour au menu", retour_au_menu)
	_bouton(colonne, "Quitter le jeu", get_tree().quit)
	var note := Label.new()
	note.text = "Au menu, « Continuer » reprend au début du niveau."
	note.add_theme_font_size_override("font_size", 15)
	note.modulate = Color(1, 1, 1, 0.6)
	colonne.add_child(note)
	_touches = Label.new()
	_touches.add_theme_font_size_override("font_size", 18)
	rangee.add_child(_touches)


func _bouton(parent: Control, texte: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(320, 48)
	b.pressed.connect(action)
	parent.add_child(b)
	return b
