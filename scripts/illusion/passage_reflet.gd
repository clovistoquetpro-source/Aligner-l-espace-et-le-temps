class_name PassageReflet
extends Area3D

## Le passage qui n'existe que dans le reflet : on le franchit en reculant
## vers le mur, les yeux sur le miroir. Le mur est en -Z de cette zone.
## Sinon, le mur reste un mur.

signal franchi(joueur: Player)

@export var miroir: NodePath
@export var angle_max_deg := 35.0
## Vitesse minimale vers le mur (m/s) : on fonce, on ne se colle pas au mur.
@export var vitesse_min := 1.5

var actif := true


static func franchit(regard: Vector3, vers_miroir: Vector3, vitesse: Vector3, vers_le_mur: Vector3, angle_max: float, v_min: float) -> bool:
	return rad_to_deg(regard.angle_to(vers_miroir)) <= angle_max and vitesse.dot(vers_le_mur) >= v_min


func _physics_process(_delta: float) -> void:
	var m := get_node_or_null(miroir) as Node3D
	if not actif or m == null:
		return
	for corps in get_overlapping_bodies():
		if not corps is Player:
			continue
		var cam: Camera3D = corps.camera
		if franchit(-cam.global_basis.z, m.global_position - cam.global_position, corps.velocity, -global_basis.z, angle_max_deg, vitesse_min):
			actif = false
			franchi.emit(corps)
			return
