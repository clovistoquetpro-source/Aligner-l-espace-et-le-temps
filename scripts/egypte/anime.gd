class_name Anime
extends RefCounted

## Joue les animations des modèles importés (soldats, dinosaures) d'après un
## morceau de leur nom : « Walk » trouve « Armature|TRex_Walk ».


## Joue la première animation dont le nom contient `motif`. Avec `a_la_fin`,
## saute directement à sa dernière image (une pose figée). Faux si le modèle
## n'a pas d'animation de ce nom.
static func jouer(racine: Node, motif: String, a_la_fin := false) -> bool:
	var lecteurs := racine.find_children("*", "AnimationPlayer", true, false)
	if lecteurs.is_empty():
		return false
	var lecteur := lecteurs[0] as AnimationPlayer
	for nom in lecteur.get_animation_list():
		if motif in nom:
			lecteur.play(nom)
			if a_la_fin:
				lecteur.seek(lecteur.get_animation(nom).length, true)
				lecteur.pause()
			return true
	return false
