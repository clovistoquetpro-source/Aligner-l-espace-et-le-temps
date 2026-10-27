class_name EpochMember
extends Node

## À placer sous un CSGShape3D ou un CollisionObject3D : son parent n'existe
## (visible et solide) que dans son époque.

const GROUPE := "membre_epoque"

@export var epoque: int = 0


func _ready() -> void:
	add_to_group(GROUPE)
	Temps.epoque_changee.connect(_appliquer)
	_appliquer(Temps.courante)


func _appliquer(courante: int) -> void:
	var parent := get_parent()
	var actif := courante == epoque
	if parent is Node3D:
		parent.visible = actif
	if parent is CSGShape3D:
		parent.use_collision = actif
	elif parent is CollisionObject3D:
		for c in parent.get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", not actif)


## Boîtes englobantes du parent, dans le monde.
func aabbs_solides() -> Array[AABB]:
	var res: Array[AABB] = []
	var parent := get_parent()
	if parent is VisualInstance3D:
		res.append(parent.global_transform * parent.get_aabb())
	elif parent is CollisionObject3D:
		for c in parent.get_children():
			if c is CollisionShape3D and c.shape != null:
				res.append(c.global_transform * c.shape.get_debug_mesh().get_aabb())
	return res
