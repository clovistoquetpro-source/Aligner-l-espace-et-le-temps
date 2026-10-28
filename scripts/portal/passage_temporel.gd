class_name PassageTemporel
extends Area3D

## Un passage vers une autre époque : si le joueur le traverse en regardant
## la cible (ou s'il n'y a pas de cible), il émet `franchi` et charge `scene`.

@export var cible_regard: NodePath
@export var angle_max_deg := 20.0
@export_file("*.tscn") var scene := ""

signal franchi


static func regarde(dir: Vector3, vers_cible: Vector3, angle_max: float) -> bool:
	return PorteTrompeuse.choisir(dir, vers_cible, angle_max, 1, 0) == 1


func _ready() -> void:
	body_entered.connect(_corps_entre)


func _corps_entre(corps: Node3D) -> void:
	if not corps is Player:
		return
	var cible := get_node_or_null(cible_regard) as Node3D
	if cible != null:
		var cam := (corps as Player).camera
		if not regarde(-cam.global_basis.z, cible.global_position - cam.global_position, angle_max_deg):
			return
	franchi.emit()
	if scene != "":
		get_tree().change_scene_to_file.call_deferred(scene)
