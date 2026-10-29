class_name ObjetTemporel
extends Node

## Un objet d'un souvenir qu'on peut remonter dans le temps : sa place suit
## une ligne du temps. Enfant de l'objet qu'il déplace.
## Un objet que Thomas a pris dans ses mains sort du temps : il ne suit plus
## la ligne, même une fois posé.

## Les moments clés, dans l'ordre : [t, position locale, rotation, visible].
## Entre deux moments, la place est interpolée ; « visible » change d'un coup.
@export var cles: Array = []

var hors_du_temps := false


## La place à l'instant `t` : [position, rotation, visible].
static func etat(moments: Array, t: float) -> Array:
	if moments.is_empty():
		return [Vector3.ZERO, Vector3.ZERO, true]
	if t <= moments[0][0]:
		return [moments[0][1], moments[0][2], moments[0][3]]
	for i in range(1, moments.size()):
		var b: Array = moments[i]
		if t < b[0]:
			var a: Array = moments[i - 1]
			var k: float = (t - a[0]) / maxf(b[0] - a[0], 0.0001)
			return [(a[1] as Vector3).lerp(b[1], k), (a[2] as Vector3).lerp(b[2], k), a[3]]
	var z: Array = moments[moments.size() - 1]
	return [z[1], z[2], z[3]]


func appliquer(t: float) -> void:
	var p := get_parent() as Node3D
	if hors_du_temps or p == null:
		return
	var e := etat(cles, t)
	p.position = e[0]
	p.rotation = e[1]
	p.visible = e[2]
