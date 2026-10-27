class_name Alignement
extends Node3D

## Des morceaux éparpillés (les enfants de ce nœud) forment une seule image
## quand on les regarde depuis le point de vue. Ce nœud est placé au centre
## des morceaux.

signal resolu

@export var point_de_vue: NodePath
@export var distance_max := 0.6
@export var angle_max_deg := 6.0
## Inactif, l'énigme ne se résout pas, même vue du bon endroit.
@export var actif := true

var est_resolu := false


static func aligne(cam_pos: Vector3, cam_dir: Vector3, vue_pos: Vector3, vue_dir: Vector3, dist_max: float, angle_max: float) -> bool:
	return cam_pos.distance_to(vue_pos) <= dist_max and rad_to_deg(cam_dir.angle_to(vue_dir)) <= angle_max


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		verifier(cam)


func verifier(cam: Camera3D) -> void:
	if est_resolu or not actif:
		return
	var vue := get_node_or_null(point_de_vue) as Node3D
	if vue == null:
		return
	if not aligne(cam.global_position, -cam.global_basis.z, vue.global_position, -vue.global_basis.z, distance_max, angle_max_deg):
		return
	if _cache(cam):
		return
	est_resolu = true
	resolu.emit()


## Vrai si un objet solide se trouve entre la caméra et les morceaux.
func _cache(cam: Camera3D) -> bool:
	var requete := PhysicsRayQueryParameters3D.create(cam.global_position, global_position)
	var joueur := get_tree().get_first_node_in_group("joueur") as CollisionObject3D
	if joueur != null:
		requete.exclude = [joueur.get_rid()]
	var touche := get_world_3d().direct_space_state.intersect_ray(requete)
	return not touche.is_empty() and not is_ancestor_of(touche["collider"])
