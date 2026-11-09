shader_type spatial;
render_mode diffuse_burley;

#include "res://world/grass_common.gdshaderinc"

varying vec3 field_position;

void vertex() {
	field_position = VERTEX;
}

void fragment() {
	vec2 p = field_position.xz;
	float far = smoothstep(8.0, 30.0, length(CAMERA_POSITION_WORLD - field_position));
	ALBEDO = pitch_albedo(p, far) * mow_sheen(p, CAMERA_POSITION_WORLD - field_position);
	NORMAL_MAP = turf_normal_map(p);
	// Turf is matte: a strong normal map plus specular turns grazing-sun stripes pale beige.
	NORMAL_MAP_DEPTH = 0.55;
	ROUGHNESS = 0.97;
	SPECULAR = 0.12;
}
