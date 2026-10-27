shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, ambient_light_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

// Contour cartoon dessiné sur tout l'écran : là où la profondeur casse (bord
// d'un objet, arête d'un meuble), on trace un trait sombre. Contrairement à un
// contour par objet, le trait colle toujours aux formes et ne scintille pas.
// Posé sur un quad enfant de la caméra.

uniform sampler2D profondeur : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 couleur : source_color = vec4(0.17, 0.11, 0.31, 1.0);
// Plus le seuil est bas, plus on trace d'arêtes (et de bruit).
uniform float seuil = 0.01;
// Écart entre les échantillons (épaisseur du trait), en pixels d'un écran de
// 720 pixels de haut : le trait garde la même allure en 1080p.
uniform float epaisseur = 1.5;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// 1 / distance à la caméra : elle varie en ligne droite sur une surface plane,
// donc sa courbure n'est forte qu'aux bords et aux arêtes.
float inverse_distance(vec2 uv, mat4 inv_projection) {
	float d = texture(profondeur, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_projection * vec4(ndc, 1.0);
	return max(-v.w / v.z, 1e-6);
}

void fragment() {
	vec2 px = vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0) * epaisseur / 720.0;
	float c = inverse_distance(SCREEN_UV, INV_PROJECTION_MATRIX);
	float autour = inverse_distance(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX)
		+ inverse_distance(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX)
		+ inverse_distance(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX)
		+ inverse_distance(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float courbure = abs(4.0 * c - autour) / c;
	// Au loin, la profondeur est moins précise : on demande une cassure plus
	// nette pour ne pas noircir le fond d'un long couloir.
	float s = seuil * (1.0 + pow(1.0 / (c * 8.0), 2.0));
	ALBEDO = couleur.rgb;
	ALPHA = couleur.a * smoothstep(s, s * 2.0, courbure);
}
