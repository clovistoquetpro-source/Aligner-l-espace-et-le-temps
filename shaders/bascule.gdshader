shader_type canvas_item;

// Effet de bascule : l'écran ondule et les couleurs se décalent.

uniform sampler2D ecran : hint_screen_texture, filter_linear_mipmap;
uniform float intensite : hint_range(0.0, 1.0) = 0.0;
uniform float secousse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 28.0 + TIME * 12.0) * 0.025 * intensite;
	uv.x += sin(TIME * 90.0) * 0.012 * secousse;
	float dec = 0.015 * intensite + 0.006 * secousse;
	float r = texture(ecran, uv + vec2(dec, 0.0)).r;
	float g = texture(ecran, uv).g;
	float b = texture(ecran, uv - vec2(dec, 0.0)).b;
	COLOR = vec4(r, g, b, 1.0);
}
