// Shared pitch colouring: the ground and every grass shell sample the same field.
// Turf tile baked from modelled blades (tools/bake_turf.py); blades lean toward image-up.
uniform sampler2D turf_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D turf_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float turf_tile = 0.5;
uniform float turf_brightness = 1.25;
uniform vec3 line_color : source_color = vec3(0.78, 0.80, 0.70);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// +1 / -1: mowing direction of the 5 m stripe (blades laid toward or away from the goal).
float mow_direction(vec2 p) {
	return smoothstep(0.47, 0.53, fract((p.y + 28.0) / 10.0)) * 2.0 - 1.0;
}

// Mown stripes are a viewing effect: blades laid away from the viewer show their lit length.
uniform float stripe_sheen = 0.08;

// Alternate stripes use the tile turned 180°, so their blades really lie the other way (-Z / +Z).
vec2 turf_uv(vec2 p) {
	vec2 uv = p / turf_tile;
	return mow_direction(p) > 0.0 ? uv : -uv;
}

float mow_sheen(vec2 p, vec3 to_camera) {
	return 1.0 + mow_direction(p) * normalize(to_camera.xz + vec2(1e-4)).y * stripe_sheen;
}

float paint(float distance_to_line) {
	return 1.0 - smoothstep(0.035, 0.065, distance_to_line);
}

// Training-half markings in metres (pitch centre at origin, goal line at z = -25).
float pitch_lines(vec2 p) {
	float inside = step(abs(p.x), 17.56) * step(abs(p.y), 25.06);
	float line = paint(min(abs(abs(p.x) - 17.5), abs(abs(p.y) - 25.0))) * inside;
	float penalty = max(paint(abs(abs(p.x) - 10.0)) * step(p.y, -8.5), paint(abs(p.y + 8.5)) * step(abs(p.x), 10.0));
	float small_box = max(paint(abs(abs(p.x) - 5.5)) * step(p.y, -19.5), paint(abs(p.y + 19.5)) * step(abs(p.x), 5.5));
	float spot = 1.0 - smoothstep(0.09, 0.13, length(p - vec2(0.0, -14.0)));
	float arc = paint(abs(length(p - vec2(0.0, -14.0)) - 9.15)) * step(-8.45, p.y);
	return max(line, max(max(penalty, small_box) * step(-25.04, p.y), max(spot, arc)));
}

// far: 0 near .. 1 distant. Far turf also reads the tile at 5x scale, so distance keeps
// visible grain instead of mip-averaging to flat green (distance tiling).
vec3 pitch_albedo(vec2 p, float far) {
	// Rotated domain hides the value-noise grid; macro variation stays subtle, busy turf reads messy.
	vec2 q = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p;
	float patches = value_noise(q * 0.35) * 0.6 + value_noise(q * 1.7) * 0.4;
	vec3 turf = texture(turf_albedo, turf_uv(p)).rgb;
	turf = mix(turf, texture(turf_albedo, turf_uv(p) * 0.2).rgb, far * 0.6);
	vec3 grass = turf * turf_brightness * mix(0.88, 1.12, patches);
	return mix(grass, line_color, pitch_lines(p) * 0.9);
}

// Tangent-space turf normal, turned with its stripe.
vec3 turf_normal_map(vec2 p) {
	vec3 n = texture(turf_normal, turf_uv(p)).rgb * 2.0 - 1.0;
	n.xy *= mow_direction(p) > 0.0 ? 1.0 : -1.0;
	return n * 0.5 + 0.5;
}
