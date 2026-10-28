shader_type sky;

// Un ciel noir semé d'étoiles : la maison flotte dans l'espace.

uniform float densite = 260.0;
uniform float proportion = 0.004;

float hasard(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 cellule = floor(EYEDIR * densite);
	float h = hasard(cellule);
	vec3 couleur = vec3(0.004, 0.004, 0.012);
	if (h < proportion) {
		float d = length(EYEDIR * densite - (cellule + 0.5));
		float eclat = h / proportion;
		couleur += vec3(0.8 + 0.2 * eclat, 0.85, 1.0) * (0.5 + 1.5 * eclat) * smoothstep(0.5, 0.0, d);
	}
	COLOR = couleur;
}
