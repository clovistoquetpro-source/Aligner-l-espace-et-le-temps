class_name Player
extends CharacterBody3D

## Joueur à la première personne : marcher, regarder, sauter, prendre un objet.

const SPEED := 5.0
const JUMP := 4.5
const MOUSE_SENS := 0.0025
const KILL_Y := -20.0
const HOLD_DIST := 1.5
const PICK_DIST := 4.0

var anchor: Transform3D
## Multiplie la vitesse de marche (la peur ralentit Thomas).
var facteur_vitesse := 1.0
var held: RigidBody3D = null
## Taille à l'écran de l'objet perspectif porté (taille / distance).
var _ratio := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D


## Direction de marche dans le monde, à partir des touches et de l'orientation.
static func wish_direction(input: Vector2, yaw: float) -> Vector3:
	var dir := Basis(Vector3.UP, yaw) * Vector3(input.x, 0.0, input.y)
	return dir.normalized() if dir.length() > 1.0 else dir


func _ready() -> void:
	add_to_group("joueur")
	anchor = global_transform
	ray.target_position = Vector3(0, 0, -PICK_DIST)
	ray.add_exception(self)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_anchor(t: Transform3D) -> void:
	anchor = t


func respawn() -> void:
	velocity = Vector3.ZERO
	teleport(anchor)


func teleport(t: Transform3D) -> void:
	global_transform = t
	_suivre_objet()


func prendre(objet: RigidBody3D) -> void:
	held = objet
	objet.freeze = true
	add_collision_exception_with(objet)
	if objet is ObjetPerspectif:
		objet.porte = true
		_ratio = objet.taille / camera.global_position.distance_to(objet.global_position)
	_suivre_objet()


func poser() -> void:
	if held == null:
		return
	held.freeze = false
	remove_collision_exception_with(held)
	if held is ObjetPerspectif:
		held.porte = false
	held = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * MOUSE_SENS, deg_to_rad(-89), deg_to_rad(89))
	elif event.is_action_pressed("liberer_souris"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interagir"):
		_interagir()
	elif event.is_action_pressed("basculer"):
		Temps.basculer(self)


func _interagir() -> void:
	if held != null:
		poser()
		return
	ray.force_raycast_update()
	var cible := ray.get_collider()
	if cible is RigidBody3D:
		prendre(cible)
	elif cible != null and cible.has_method("activer"):
		cible.activer(self)


func _physics_process(delta: float) -> void:
	if global_position.y < KILL_Y:
		respawn()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("sauter"):
		velocity.y = JUMP
	var input := Input.get_vector("gauche", "droite", "avancer", "reculer")
	var dir := wish_direction(input, rotation.y)
	velocity.x = dir.x * SPEED * facteur_vitesse
	velocity.z = dir.z * SPEED * facteur_vitesse
	move_and_slide()
	_suivre_objet()


func _suivre_objet() -> void:
	if held == null or not is_instance_valid(held):
		held = null
		return
	if held is ObjetPerspectif:
		var exclure: Array[RID] = [get_rid()]
		held.placer(camera, _ratio, exclure)
		return
	held.global_position = camera.global_position - camera.global_basis.z * HOLD_DIST
	held.global_rotation = Vector3(0, global_rotation.y, 0)
