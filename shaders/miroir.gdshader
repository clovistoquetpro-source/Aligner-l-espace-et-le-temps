shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled;

// La vitre d'un miroir : l'image de la caméra du reflet, retournée de gauche à
// droite (scripts/illusion/miroir.gd).

uniform sampler2D reflet : source_color, filter_linear, repeat_disable;
// La couleur de la vitre (blanc : un miroir ; bleu : l'eau d'un lac).
uniform vec3 teinte : source_color = vec3(1.0);

void fragment() {
	ALBEDO = texture(reflet, vec2(1.0 - UV.x, UV.y)).rgb * teinte;
}
