class_name ToileTournante
extends StaticBody3D

## Une toile qu'on tourne d'un quart de tour (E en visant son cadre). Elle
## montre une pièce peinte, construite ailleurs dans le monde, filmée par une
## caméra fixe : quand on tourne la toile, la pièce tourne avec elle, et ses
## murs deviennent son sol. On y entre en marchant dans la toile.
## La toile est dans le plan XY du nœud, tournée vers son +Z.

signal tournee(quarts: int)

const DUREE := 0.8
## Au-delà de cette distance, on ne met plus l'image à jour.
const DISTANCE_VUE := 25.0

## La pièce peinte, qui tourne autour de son axe Z.
@export var piece: NodePath
## Le point de vue (Marker3D) qui filme la pièce.
@export var vue: NodePath
@export var taille := 2.6
@export var pixels := 512

## Quarts de tour (dans le sens des aiguilles d'une montre) depuis le début.
var quarts := 0

var _tween: Tween
var _vue: SubViewport
var _camera: Camera3D


## L'angle de la pièce après `n` quarts de tour.
static func angle(n: int) -> float:
	return -n * PI / 2.0


func _ready() -> void:
	_vue = SubViewport.new()
	_vue.size = Vector2i(pixels, pixels)
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vue)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.cull_mask = 0xFFFFF & ~Miroir.COUCHE_REFLET
	_vue.add_child(_camera)
	var marque := get_node_or_null(vue) as Node3D
	if marque != null:
		_camera.global_transform = marque.global_transform
	var quad := QuadMesh.new()
	quad.size = Vector2(taille, taille)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vue.get_texture()
	var toile := MeshInstance3D.new()
	toile.name = "Image"
	toile.mesh = quad
	toile.material_override = mat
	toile.position = Vector3(0, 0, 0.02)
	toile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(toile)


func en_rotation() -> bool:
	return _tween != null and _tween.is_running()


func activer(_joueur: Node3D = null) -> void:
	var p := get_node_or_null(piece) as Node3D
	if p == null or en_rotation():
		return
	quarts += 1
	_tween = create_tween()
	_tween.tween_property(p, "rotation:z", angle(quarts), DUREE).set_trans(Tween.TRANS_SINE)
	tournee.emit(quarts)


func _process(_delta: float) -> void:
	var oeil := get_viewport().get_camera_3d()
	var proche := oeil != null and oeil.global_position.distance_to(global_position) < DISTANCE_VUE
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS if proche else SubViewport.UPDATE_DISABLED
