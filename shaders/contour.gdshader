shader_type spatial;
render_mode unshaded, cull_front;

// Contour cartoon : la forme est regonflée le long des normales et seules ses
// faces arrière sont dessinées, d'un trait sombre.

uniform vec4 couleur : source_color = vec4(0.17, 0.11, 0.31, 1.0);
uniform float epaisseur = 0.018;

void vertex() {
	VERTEX += NORMAL * epaisseur;
}

void fragment() {
	ALBEDO = couleur.rgb;
}
