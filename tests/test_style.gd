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


func test_cartoon_garde_couleur_et_texture() -> void:
	var original := StandardMaterial3D.new()
	original.albedo_color = Color.ORANGE
	original.albedo_texture = PlaceholderTexture2D.new()
	var m := Style.cartoon(original)
	T.eq(m.albedo_color, Color.ORANGE, "même couleur")
	T.eq(m.albedo_texture, original.albedo_texture, "même texture")
	T.eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, "ombres en aplats")
	T.eq(m.next_pass, Style.contour(), "contour")
	T.eq(original.diffuse_mode, BaseMaterial3D.DIFFUSE_BURLEY, "l'original n'est pas modifié")
	T.ok(Style.cartoon(original) == m, "un seul matériau cartoon par original")


func test_habiller_un_modele() -> void:
	var racine := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var original := StandardMaterial3D.new()
	mi.mesh.surface_set_material(0, original)
	racine.add_child(mi)
	Style.habiller(racine)
	var m := mi.get_surface_override_material(0) as BaseMaterial3D
	T.ok(m != null and m.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "surface habillée en cartoon")
	racine.free()


func test_cartoon_corrige_les_couleurs_delavees() -> void:
	var original := StandardMaterial3D.new()
	original.albedo_color = Color("f9a39e")
	original.emission_enabled = true
	var m := Style.cartoon(original, true)
	T.ok(m.albedo_color.is_equal_approx(Color("f9a39e").srgb_to_linear()), "couleur ravivée")
	T.ok(not m.emission_enabled, "un meuble ne brille pas")
