class_name Support
extends StaticBody3D

## Un objet sur lequel on se sert de ce qu'on tient : le chevalet, avec le
## pinceau. E en le visant, l'objet en main.

signal utilise(objet: Node3D)

## Ce que fait E (affiché sous le viseur).
var action_avec := "peindre"
var actif := true


func utiliser_avec(_joueur: Node3D, objet: Node3D) -> bool:
	if not actif:
		return false
	utilise.emit(objet)
	return true
