class_name Style
extends RefCounted

## Le style « cartoon coloré » du jeu : ombres en aplats, reflet sur les bords
## et contour sombre.

const CONTOUR := preload("res://shaders/contour.gdshader")

static var _contour: ShaderMaterial


static func materiau(couleur: Color, lumineux := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = couleur
	m.roughness = 0.8
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	if lumineux:
		m.emission_enabled = true
		m.emission = couleur
		m.emission_energy_multiplier = 0.8
	m.next_pass = contour()
	return m


static func contour() -> ShaderMaterial:
	if _contour == null:
		_contour = ShaderMaterial.new()
		_contour.shader = CONTOUR
	return _contour
