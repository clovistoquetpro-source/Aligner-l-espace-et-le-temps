class_name Fissures
extends Control

## L'image qui se fissure : des fêlures partent du milieu de l'écran et
## s'étendent avec `progres` (0 : rien, 1 : tout l'écran).

const NOMBRE := 14
const SEGMENTS := 9

var progres := 0.0:
	set(p):
		progres = clampf(p, 0.0, 1.0)
		queue_redraw()

## Chaque fêlure : une suite de points, de 0 (le milieu) à 1 (le bord).
var _felures: Array[PackedVector2Array] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 1987
	for i in NOMBRE:
		var a := TAU * i / NOMBRE + hasard.randf_range(-0.2, 0.2)
		var points := PackedVector2Array([Vector2.ZERO])
		for k in range(1, SEGMENTS + 1):
			var r := float(k) / SEGMENTS
			var b := a + hasard.randf_range(-0.35, 0.35)
			points.append(Vector2(cos(b), sin(b)) * r)
		_felures.append(points)


func _draw() -> void:
	if progres <= 0.0:
		return
	var centre := size / 2
	var rayon := size.length() / 2
	for f in _felures:
		var n := int(ceil(progres * (f.size() - 1)))
		for k in n:
			var a := centre + f[k] * rayon
			var b := centre + f[k + 1] * rayon
			draw_line(a, b, Color(0.05, 0.04, 0.08, 0.9), 3.0 * (1.0 - float(k) / SEGMENTS) + 1.0, true)
