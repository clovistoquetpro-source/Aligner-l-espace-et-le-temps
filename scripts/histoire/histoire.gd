extends Node

## Autoload « Histoire » : où en est Thomas dans ses souvenirs, d'un niveau à
## l'autre (pas encore sauvegardé sur le disque).

## Le niveau à jouer : 1 la maison dans les étoiles, 2 l'enfance…
var chapitre := 1
## Les souvenirs repeints : la maison du présent s'abîme d'autant.
var corrections := 0
## Pour les tests : on note la scène demandée sans la charger.
var simuler := false
var scene_demandee := ""


func vers(chemin: String) -> void:
	scene_demandee = chemin
	if not simuler:
		get_tree().change_scene_to_file.call_deferred(chemin)


func reinitialiser() -> void:
	chapitre = 1
	corrections = 0
	scene_demandee = ""
