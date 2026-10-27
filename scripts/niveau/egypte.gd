extends Niveau

## Niveau « L'Égypte » : relie les énigmes, le chantier, les messages et la fin.

const TempsScript := preload("res://scripts/time/temps.gd")

## Couleurs du ciel et de l'ambiance : l'Antiquité, saturée ; 1942, plus terne.
const PALETTES := {
	TempsScript.Epoque.PASSE: { "ciel": Color("3ee6d0"), "ambiance": Color("ffb347") },
	TempsScript.Epoque.PRESENT: { "ciel": Color("9fd8cf"), "ambiance": Color("c9a66b") },
}


func _ready() -> void:
	$BasculeFx.palettes = PALETTES
	Temps.reinitialiser(Temps.Epoque.PASSE)
	$BasculeFx.environnement = $WorldEnvironment.environment
	afficher("L'Égypte… mais quelque chose cloche.")
