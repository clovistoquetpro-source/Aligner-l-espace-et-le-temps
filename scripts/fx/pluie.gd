class_name Pluie
extends MultiMeshInstance3D

## De la pluie, dessinée gouttes par gouttes. La hauteur de chaque goutte ne
## dépend que de `temps` : si le temps s'arrête, la pluie reste suspendue ;
## s'il recule, elle remonte vers le ciel.

@export var taille := Vector3(20, 10, 20)
@export var nombre := 500
@export var vitesse := 9.0

var temps := 0.0:
	set(t):
		temps = t
		_placer()

var _graines: PackedVector3Array = []


func _ready() -> void:
	var goutte := BoxMesh.new()
	goutte.size = Vector3(0.015, 0.35, 0.015)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.85, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	goutte.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = goutte
	mm.instance_count = nombre
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 7
	for i in nombre:
		_graines.append(Vector3(hasard.randf_range(-0.5, 0.5), hasard.randf(), hasard.randf_range(-0.5, 0.5)))
	_placer()


## La hauteur d'une goutte (0 en bas, 1 en haut) au temps `t`.
static func hauteur(graine: float, t: float, v: float, h: float) -> float:
	return 1.0 - fposmod(graine + t * v / h, 1.0)


func _placer() -> void:
	if multimesh == null:
		return
	for i in _graines.size():
		var g := _graines[i]
		var y := (hauteur(g.y, temps, vitesse, taille.y) - 0.5) * taille.y
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(g.x * taille.x, y, g.z * taille.z)))
