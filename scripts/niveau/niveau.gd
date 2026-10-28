class_name Niveau
extends Node3D

## Base des niveaux : affiche les messages en haut de l'écran.

const DUREE_MESSAGE := 4.0

var _reste_message := 0.0

@onready var _message: Label = $Interface/Message


func afficher(texte: String, duree := DUREE_MESSAGE) -> void:
	_message.text = texte
	_reste_message = duree


func _process(delta: float) -> void:
	if _reste_message > 0.0:
		_reste_message -= delta
		_message.modulate.a = clampf(_reste_message, 0.0, 1.0)
