extends RefCounted


func test_materiau_cartoon() -> void:
	var m := Style.materiau(Color.RED)
	T.eq(m.albedo_color, Color.RED, "couleur")
	T.eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, "ombres en aplats")
	T.eq(m.specular_mode, BaseMaterial3D.SPECULAR_DISABLED, "pas de reflet blanc sur les grands murs")
	T.ok(m.next_pass is ShaderMaterial, "contour en seconde passe")
	T.eq((m.next_pass as ShaderMaterial).shader.resource_path, "res://shaders/contour.gdshader", "shader de contour")


func test_materiau_lumineux() -> void:
	var m := Style.materiau(Color.CYAN, true)
	T.ok(m.emission_enabled, "lumineux")


func test_contour_partage() -> void:
	T.eq(Style.materiau(Color.RED).next_pass, Style.materiau(Color.BLUE).next_pass, "un seul matériau de contour")


func test_vitre_transparente_sans_contour() -> void:
	var m := Style.vitre()
	T.eq(m.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "transparente")
	T.ok(m.albedo_color.a < 0.5, "on voit à travers")
	T.ok(m.next_pass == null, "pas de contour autour du verre")
