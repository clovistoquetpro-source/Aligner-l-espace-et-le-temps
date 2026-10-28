class_name Pensee
extends Node3D

## Une pensée du joueur, affichée une seule fois quand il regarde ce point
## (ou, sans `regard`, quand il s'en approche). Elle raconte, elle ne donne
## jamais la solution.

const GROUPE := "pensees"

@export_multiline var texte := ""
@export var regard := true
@export var distance := 6.0
@export var angle_max_deg := 20.0
## Une pensée inactive attend que le niveau l'active.
@export var active := true

var dite := false


static func vue(oeil: Vector3, dir_regard: Vector3, point: Vector3, dist_max: float, angle_max: float, par_le_regard: bool) -> bool:
	var vers := point - oeil
	if vers.length() > dist_max:
		return false
	return not par_le_regard or rad_to_deg(dir_regard.angle_to(vers)) <= angle_max


func _ready() -> void:
	add_to_group(GROUPE)
