extends Node

## Autoload « Histoire » : où en est Thomas dans ses souvenirs, d'un niveau à
## l'autre. Sauvegardé sur le disque à chaque changement de niveau.

## Le dernier chapitre : le jeu est fini.
const FIN := 6

## Le niveau à jouer : 1 la maison dans les étoiles, 2 l'enfance…
var chapitre := 1
## Les souvenirs repeints : la maison du présent s'abîme d'autant.
var corrections := 0
## Pour les tests : on note la scène demandée sans la charger, et on ne
## sauvegarde rien.
var simuler := false
var scene_demandee := ""
## Où est la sauvegarde (les tests en prennent une autre).
var chemin_sauvegarde := "user://sauvegarde.cfg"


## Change de niveau, et sauvegarde : « Continuer » y ramènera.
func vers(chemin: String) -> void:
	scene_demandee = chemin
	if chemin != "res://scenes/menu.tscn" or chapitre >= FIN:
		sauver(chemin)
	if not simuler:
		get_tree().change_scene_to_file.call_deferred(chemin)


func reinitialiser() -> void:
	chapitre = 1
	corrections = 0
	scene_demandee = ""


func sauver(scene: String) -> void:
	if simuler and chemin_sauvegarde == "user://sauvegarde.cfg":
		return
	var f := ConfigFile.new()
	f.set_value("histoire", "chapitre", chapitre)
	f.set_value("histoire", "corrections", corrections)
	f.set_value("histoire", "scene", scene)
	f.save(chemin_sauvegarde)


## Ce qu'il y a dans la sauvegarde : {chapitre, corrections, scene}, ou {} si
## rien.
func lire() -> Dictionary:
	var f := ConfigFile.new()
	if f.load(chemin_sauvegarde) != OK:
		return {}
	return {
		"chapitre": int(f.get_value("histoire", "chapitre", 1)),
		"corrections": int(f.get_value("histoire", "corrections", 0)),
		"scene": String(f.get_value("histoire", "scene", "res://scenes/illusions.tscn")),
	}


## Une partie à continuer (pas finie).
func peut_continuer() -> bool:
	var s := lire()
	return not s.is_empty() and s["chapitre"] < FIN and ResourceLoader.exists(s["scene"])


## Reprend la partie sauvegardée, là où on l'a laissée (au début du niveau).
func continuer() -> void:
	var s := lire()
	if s.is_empty():
		return
	chapitre = s["chapitre"]
	corrections = s["corrections"]
	vers(s["scene"])


## Une nouvelle partie : on oublie la sauvegarde.
func nouvelle_partie(premiere_scene: String) -> void:
	reinitialiser()
	vers(premiere_scene)


func effacer() -> void:
	if FileAccess.file_exists(chemin_sauvegarde):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(chemin_sauvegarde))
