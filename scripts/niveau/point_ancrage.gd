class_name PointAncrage
extends Area3D

## Quand le joueur entre ici, ce point devient l'endroit où il réapparaît.


func _ready() -> void:
	body_entered.connect(_corps_entre)


func _corps_entre(corps: Node3D) -> void:
	if corps is Player:
		corps.set_anchor(global_transform)
