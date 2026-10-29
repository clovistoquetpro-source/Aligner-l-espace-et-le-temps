class_name Passant
extends StaticBody3D

## Quelqu'un qu'on croise : E pour lui dire bonjour. Il répond, et fait signe
## de la main.

signal salue(passant: Passant)

@export var nom := ""
@export var repliques: Array[String] = []

## Ce que fait E (affiché sous le viseur) ; rien une fois qu'on s'est salués.
var action := "dire bonjour"
var deja_salue := false


func activer(_joueur: Node3D = null) -> void:
	if deja_salue:
		return
	deja_salue = true
	action = ""
	salue.emit(self)
	var bras := get_node_or_null("Bras") as Node3D
	if bras != null:
		var t := create_tween().set_loops(3)
		t.tween_property(bras, "rotation:z", 2.4, 0.25)
		t.tween_property(bras, "rotation:z", 1.8, 0.25)
