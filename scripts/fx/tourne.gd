extends Node3D

## Fait tourner lentement un décor (objets qui flottent dans le ciel).

@export var vitesse := Vector3(0, 0.2, 0)


func _process(delta: float) -> void:
	rotation += vitesse * delta
