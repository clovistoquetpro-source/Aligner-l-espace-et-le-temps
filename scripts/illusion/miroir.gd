class_name Miroir
extends Node3D

## Un miroir accroché au mur. Une seconde caméra, placée au reflet de l'œil du
## joueur derrière le mur, filme la pièce à travers le cadre du miroir ; son
## image est affichée retournée sur la vitre.
## Le miroir est dans le plan XY du nœud, tourné vers son +Z.

## Couche visible du joueur mais pas dans le reflet (le vrai mur, la vitre).
const COUCHE_REEL := 2
## Couche visible seulement dans le reflet (le passage, le corps du joueur).
const COUCHE_REFLET := 4
const NEAR_MIN := 0.05
## Au-delà de cette distance, on ne met plus le reflet à jour.
const DISTANCE_VUE := 15.0

@export var taille := Vector2(3.0, 2.4)
## Pixels par mètre de l'image du reflet.
@export var definition := 300

var camera: Camera3D
var _vue: SubViewport
var _vitre: MeshInstance3D


## Où placer la caméra du reflet pour un œil en `oeil` (coordonnées du monde),
## et le cadrage qui fait passer son image juste par le cadre du miroir.
## Renvoie {} si l'œil est derrière le miroir.
static func camera_reflet(miroir: Transform3D, oeil: Vector3, taille_miroir: Vector2) -> Dictionary:
	var p := miroir.affine_inverse() * oeil
	if p.z < NEAR_MIN:
		return {}
	var reflet := Vector3(p.x, p.y, -p.z)
	return {
		"transform": Transform3D(miroir.basis * Basis(Vector3.UP, PI), miroir * reflet),
		"near": p.z,
		"decalage": Vector2(p.x, -p.y),
		"hauteur": taille_miroir.y,
	}


func _ready() -> void:
	_vue = SubViewport.new()
	_vue.size = Vector2i(taille * definition)
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vue)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_FRUSTUM
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.far = 200.0
	camera.cull_mask = 0xFFFFF & ~COUCHE_REEL
	_vue.add_child(camera)
	var quad := QuadMesh.new()
	quad.size = taille
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/miroir.gdshader")
	mat.set_shader_parameter("reflet", _vue.get_texture())
	_vitre = MeshInstance3D.new()
	_vitre.name = "Vitre"
	_vitre.mesh = quad
	_vitre.material_override = mat
	_vitre.layers = COUCHE_REEL
	_vitre.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_vitre)


func _process(_delta: float) -> void:
	var oeil := get_viewport().get_camera_3d()
	if oeil == null:
		return
	var c := camera_reflet(global_transform, oeil.global_position, taille)
	var utile := not c.is_empty() and oeil.global_position.distance_to(global_position) < DISTANCE_VUE
	_vitre.visible = not c.is_empty()
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS if utile else SubViewport.UPDATE_DISABLED
	if not utile:
		return
	camera.global_transform = c["transform"]
	camera.near = c["near"]
	camera.size = c["hauteur"]
	camera.frustum_offset = c["decalage"]
