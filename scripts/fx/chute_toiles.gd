class_name ChuteToiles
extends Control

## La chute dans les toiles : on tombe à travers une suite de tableaux
## encadrés, chacun plus petit que le précédent, qui tournent sur eux-mêmes.
## Plein écran ; `finie` est émis à la fin, sur un écran noir.

signal finie

const DUREE := 4.0
## Chaque toile fait cette fraction de la précédente.
const RAPPORT := 0.6
## Toiles traversées par seconde.
const VITESSE := 1.8
const NOMBRE := 10
const FONDU := 0.6

var _t := -1.0


## Taille d'affichage de la toile `k` au temps `t`, par rapport à l'écran.
## La toile qu'on traverse dépasse l'écran (taille > 1).
static func echelle(k: int, t: float) -> float:
	return pow(RAPPORT, k - t * VITESSE)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func lancer() -> void:
	_t = 0.0
	visible = true
	queue_redraw()


func en_cours() -> bool:
	return _t >= 0.0


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	queue_redraw()
	if _t >= DUREE:
		_t = -1.0
		visible = false
		finie.emit()


func _draw() -> void:
	if _t < 0.0:
		return
	var ecran := Rect2(Vector2.ZERO, size)
	draw_rect(ecran, Color.BLACK)
	var premier := floori(_t * VITESSE)
	for k in range(premier, premier + NOMBRE):
		var cote := size.length() * echelle(k, _t)
		var cadre := Rect2(-Vector2(cote, cote * 0.75) / 2, Vector2(cote, cote * 0.75))
		draw_set_transform(size / 2, k * 0.35 + _t * 0.5)
		var teinte := fposmod(k * 0.13, 1.0)
		draw_rect(cadre, Color.from_hsv(0.1, 0.35, 0.55 + 0.1 * (k % 2)))
		var toile := cadre.grow(-cote * 0.06)
		draw_rect(toile, Color.from_hsv(teinte, 0.45, 0.75))
		var sol := Rect2(toile.position + Vector2(0, toile.size.y * 0.62), Vector2(toile.size.x, toile.size.y * 0.38))
		draw_rect(sol, Color.from_hsv(fposmod(teinte + 0.5, 1.0), 0.5, 0.45))
	draw_set_transform(Vector2.ZERO)
	var debut := clampf(1.0 - _t / 0.3, 0.0, 1.0)
	var fin := clampf((_t - (DUREE - FONDU)) / FONDU, 0.0, 1.0)
	draw_rect(ecran, Color(0, 0, 0, maxf(debut, fin)))
