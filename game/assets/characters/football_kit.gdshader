shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec3 jersey_color : source_color = vec3(0.035, 0.19, 0.225);
uniform vec3 shorts_color : source_color = vec3(0.03, 0.07, 0.085);
uniform vec3 sock_color : source_color = vec3(0.78, 0.8, 0.72);
// Kit panel cuts in rest-pose metres (UV2 = rest X/Y), so they follow the skinned body.
uniform vec2 shirt_height = vec2(0.925, 1.47);
uniform float back_collar_height = 1.505;
uniform float neck_half_width = 0.075;
uniform float shoulder_top_height = 1.56;
uniform float shirt_half_width = 0.236;
uniform float sleeve_start_height = 1.22;
uniform float sleeve_half_width = 0.335;
uniform vec2 shorts_height = vec2(0.58, 0.99);
uniform float shorts_half_width = 0.255;
uniform vec2 sock_height = vec2(0.105, 0.435);
// Fabric motion: the shirt is part of the body mesh, so it ripples instead of simulating cloth.
instance uniform float cloth_motion = 0.0; // 0 standing .. 1 running, set by locomotion
uniform float cloth_amplitude = 0.006;
uniform float cloth_slack = 0.003;

varying float cloth_slope;

// One-pixel antialiased step: edges stay clean at any vertex density or distance.
float above(float value, float edge) {
	return clamp((value - edge) / max(fwidth(value), 1e-5) + 0.5, 0.0, 1.0);
}

float band(float value, vec2 range) {
	return above(value, range.x) * (1.0 - above(value, range.y));
}

float soft_band(float value, vec2 range) {
	return smoothstep(range.x - 0.01, range.x + 0.01, value) * (1.0 - smoothstep(range.y - 0.01, range.y + 0.01, value));
}

void vertex() {
	float x = abs(UV2.x);
	float y = UV2.y;
	float shirt = soft_band(y, shirt_height) * max(1.0 - smoothstep(shirt_half_width - 0.01, shirt_half_width + 0.01, x),
		smoothstep(sleeve_start_height - 0.01, sleeve_start_height + 0.01, y) * (1.0 - smoothstep(sleeve_half_width - 0.01, sleeve_half_width + 0.01, x)));
	// Hem and sleeve ends hang loose; shoulders and collar sit on the body.
	float loose = shirt * max(1.0 - smoothstep(shirt_height.x + 0.02, 1.3, y), smoothstep(0.26, sleeve_half_width, x));
	float phase = TIME * (3.0 + 7.0 * cloth_motion) - y * 38.0 + UV2.x * 12.0;
	float wave = 0.5 + 0.35 * sin(phase) + 0.15 * sin(phase * 1.7 + x * 20.0);
	float strength = cloth_amplitude * loose * (0.25 + cloth_motion);
	float model_scale = length(MODEL_MATRIX[0].xyz);
	VERTEX += normalize(NORMAL) * (strength * wave + cloth_slack * loose) / model_scale;
	cloth_slope = -strength * 38.0 * (0.35 * cos(phase) + 0.255 * cos(phase * 1.7 + x * 20.0));
}

void fragment() {
	// Light the ripples: tilt the normal by the wave's vertical slope.
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz * cloth_slope);
	float x = abs(UV2.x);
	float y = UV2.y;
	// Bare feet are covered by the attached boots.
	if (y < sock_height.x) { discard; }
	// Round collar: higher at the nape (COLOR.r = rest depth), rising over the shoulders.
	float rest_z = COLOR.r * 0.5 - 0.25;
	float neck_line = mix(shirt_height.y, back_collar_height, smoothstep(0.0, -0.1, rest_z));
	float collar_top = mix(neck_line, shoulder_top_height, smoothstep(neck_half_width - 0.015, neck_half_width + 0.025, x));
	float shirt = band(y, vec2(shirt_height.x, collar_top)) * max(1.0 - above(x, shirt_half_width),
		above(y, sleeve_start_height) * (1.0 - above(x, sleeve_half_width)));
	float shorts = (1.0 - shirt) * band(y, shorts_height) * (1.0 - above(x, shorts_half_width));
	float sock = band(y, sock_height);
	vec3 base = texture(albedo_map, UV).rgb;
	float shade = clamp(dot(base, vec3(0.2126, 0.7152, 0.0722)) * 1.3 + 0.7, 0.65, 1.25);
	vec3 kit = mix(base, jersey_color * shade, shirt);
	kit = mix(kit, shorts_color * shade, shorts);
	ALBEDO = mix(kit, sock_color * (0.92 + shade * 0.08), sock);
	ROUGHNESS = mix(0.67, 0.88, max(max(shirt, shorts), sock));
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = mix(0.7, 0.28, sock);
}
