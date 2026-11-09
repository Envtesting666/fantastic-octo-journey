shader_type spatial;
render_mode diffuse_burley;

// Original 12-panel ball: panels are the Voronoi cells of icosahedron vertex directions.
uniform vec3 panel_color : source_color = vec3(0.86, 0.86, 0.82);
uniform vec3 accent_color : source_color = vec3(0.78, 0.55, 0.2);
uniform vec3 seam_color : source_color = vec3(0.12, 0.13, 0.13);

varying vec3 local_normal;

void vertex() {
	local_normal = NORMAL;
}

void fragment() {
	const float PHI = 1.618034;
	vec3 directions[12] = vec3[](
		vec3(0.0, 1.0, PHI), vec3(0.0, -1.0, PHI), vec3(0.0, 1.0, -PHI), vec3(0.0, -1.0, -PHI),
		vec3(1.0, PHI, 0.0), vec3(-1.0, PHI, 0.0), vec3(1.0, -PHI, 0.0), vec3(-1.0, -PHI, 0.0),
		vec3(PHI, 0.0, 1.0), vec3(-PHI, 0.0, 1.0), vec3(PHI, 0.0, -1.0), vec3(-PHI, 0.0, -1.0));
	vec3 n = normalize(local_normal);
	float best = -2.0;
	float second = -2.0;
	int panel = 0;
	for (int i = 0; i < 12; i++) {
		float d = dot(n, normalize(directions[i]));
		if (d > best) {
			second = best;
			best = d;
			panel = i;
		} else if (d > second) {
			second = d;
		}
	}
	float gap = best - second;
	float seam = 1.0 - clamp(gap / max(fwidth(gap) * 1.5, 1e-4), 0.0, 1.0);
	// Accent panels sit on opposite poles so the spin reads in flight.
	vec3 albedo = (panel == 0 || panel == 3 || panel == 8 || panel == 11) ? accent_color : panel_color;
	ALBEDO = mix(albedo, seam_color, seam * 0.8);
	ROUGHNESS = mix(0.42, 0.75, seam);
}
