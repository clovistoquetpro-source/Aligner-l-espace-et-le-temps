shader_type canvas_item;

// La peur : la vue se brouille et s'assombrit sur les bords.

uniform sampler2D ecran : hint_screen_texture, filter_linear_mipmap;
uniform float flou : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	// La vue tremble un peu.
	uv += flou * 0.004 * vec2(sin(TIME * 7.0 + uv.y * 20.0), cos(TIME * 6.0 + uv.x * 20.0));
	vec3 c = textureLod(ecran, uv, flou * 4.5).rgb;
	float bord = smoothstep(0.25, 0.8, length(SCREEN_UV - 0.5));
	c *= 1.0 - flou * bord * 0.85;
	COLOR = vec4(c, 1.0);
}
