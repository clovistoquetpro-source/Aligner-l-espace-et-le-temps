extends RefCounted

## Le contour façon BD est dessiné sur tout l'écran, à partir de la
## profondeur. (Un contour par objet se décollait des objets et scintillait.)


func test_la_camera_dessine_le_contour() -> void:
	var j: Player = load("res://scenes/player.tscn").instantiate()
	var c := j.get_node_or_null("Head/Camera3D/ContourEcran") as MeshInstance3D
	T.ok(c != null, "un contour plein écran sur la caméra")
	if c != null:
		var m := c.material_override as ShaderMaterial
		T.ok(m != null and m.shader.resource_path == "res://shaders/contour_ecran.gdshader", "shader de contour à l'écran")
		T.eq(c.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "ne fait pas d'ombre")
		T.ok(c.extra_cull_margin > 1000.0, "jamais caché par la caméra")
	j.free()
