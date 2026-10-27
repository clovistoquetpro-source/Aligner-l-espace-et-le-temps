class_name HabillageCartoon
extends Node3D

## À mettre sur le nœud qui porte un modèle importé (glTF) : au lancement, le
## modèle prend le style cartoon du jeu (ombres en aplats et contour).


## Ravive les couleurs des modèles de Kenney (voir Style.cartoon).
@export var corriger_couleurs := false


func _ready() -> void:
	Style.habiller(self, corriger_couleurs)
