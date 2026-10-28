class_name Decrochable
extends StaticBody3D

## Un dessin punaisé au mur : E le décroche, il tombe et disparaît.

signal decroche

const DUREE := 0.5

var accroche := true
## Ce que fait E (affiché sous le viseur).
var action := "décrocher"


func activer(_joueur: Node3D = null) -> void:
	if not accroche:
		return
	accroche = false
	collision_layer = 0
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 0.8, DUREE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "rotation:z", 0.9, DUREE)
	t.tween_callback(hide)
	decroche.emit()
