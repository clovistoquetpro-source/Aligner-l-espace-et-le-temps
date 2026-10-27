class_name Style
extends RefCounted

## Le style « cartoon coloré » du jeu : ombres en aplats, reflet sur les bords
## et contour sombre.

const CONTOUR := preload("res://shaders/contour.gdshader")

static var _contour: ShaderMaterial


## Matériaux cartoon déjà faits à partir des matériaux des modèles importés.
static var _cartoons := {}


static func materiau(couleur: Color, lumineux := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = couleur
	m.roughness = 0.8
	_styliser(m)
	if lumineux:
		m.emission_enabled = true
		m.emission = couleur
		m.emission_energy_multiplier = 0.8
	return m


## La version cartoon du matériau d'un modèle importé : mêmes couleur et
## texture, ombres en aplats et contour. Une seule copie par original.
## `corriger_couleurs` : Kenney enregistre ses couleurs telles qu'on les voit
## (sRGB) là où glTF attend des valeurs linéaires ; sans correction, elles
## sortent délavées.
static func cartoon(original: BaseMaterial3D, corriger_couleurs := false) -> BaseMaterial3D:
	if not _cartoons.has(original):
		var m: BaseMaterial3D = original.duplicate()
		if corriger_couleurs:
			m.albedo_color = original.albedo_color.srgb_to_linear()
		m.metallic = 0.0
		m.roughness = 0.8
		m.emission_enabled = false
		_styliser(m)
		_cartoons[original] = m
	return _cartoons[original]


## Habille au style cartoon tous les maillages sous `racine`.
static func habiller(racine: Node, corriger_couleurs := false) -> void:
	for n in racine.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is BaseMaterial3D:
				mi.set_surface_override_material(i, cartoon(m, corriger_couleurs))


static func _styliser(m: BaseMaterial3D) -> void:
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.rim_enabled = true
	m.rim = 0.15
	m.rim_tint = 0.8
	m.next_pass = contour()


static func contour() -> ShaderMaterial:
	if _contour == null:
		_contour = ShaderMaterial.new()
		_contour.shader = CONTOUR
	return _contour


## Une vitre à peine teintée, sans contour : on voit le ciel à travers.
static func vitre() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.97, 1.0, 0.15)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
