class_name HabillageCartoon
extends Node3D

## À mettre sur le nœud qui porte un modèle importé (glTF) : au lancement, le
## modèle prend le style cartoon du jeu (ombres en aplats), et peut jouer une
## animation en boucle.


## Ravive les couleurs des modèles de Kenney (voir Style.cartoon).
@export var corriger_couleurs := false
## Animation jouée en boucle au lancement (un morceau de son nom, voir Anime).
@export var animation := ""
## Morceaux du modèle à cacher (les armes des soldats…).
@export var caches := PackedStringArray()


func _ready() -> void:
	Style.habiller(self, corriger_couleurs)
	for nom in caches:
		for n in find_children(nom, "Node3D", true, false):
			n.visible = false
	if animation != "":
		Anime.jouer(self, animation, false, true)
