shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, diffuse_burley;

// Rope net drawn on a coarse panel grid. Mesh is in world space; COLOR.r = how free a vertex is
// (0 on the frame and ground pegs, 1 mid-panel). goal_net.gd feeds the ball each frame.
uniform vec3 rope_color : source_color = vec3(0.88, 0.88, 0.84);
uniform float mesh_size = 0.11;
uniform float rope_width = 0.005;
// Nets hang loose: free vertices sag under gravity and belly outward.
uniform float slack = 0.2;
// Breeze: slow travelling billows across the free part of each panel.
uniform float wind_strength = 0.035;
uniform float pocket_spread = 0.45;
instance uniform vec3 ball_position = vec3(0.0, -10.0, 0.0);
instance uniform float impact_energy = 0.0;

const float BALL_RADIUS = 0.11;

void vertex() {
	vec3 to_ball = ball_position - VERTEX;
	float along = dot(to_ball, NORMAL);
	float lateral = length(to_ball - NORMAL * along);
	float reach = exp(-pow(lateral / pocket_spread, 2.0)) * COLOR.r;
	// The ball stretches a pocket to its surface; a fresh hit leaves the panel shivering.
	float pocket = max(along + BALL_RADIUS, 0.0) * reach;
	float wobble = impact_energy * sin(TIME * 16.0) * reach * 0.04;
	float breeze = sin(TIME * 1.7 + VERTEX.x * 0.9 + VERTEX.y * 1.3) * 0.6 + sin(TIME * 2.9 - VERTEX.x * 2.1 + VERTEX.z * 1.7) * 0.4;
	// Gravity drapes the free middle down (catenary-like via the sin·sin freedom) and bellies it out.
	VERTEX += NORMAL * (pocket + wobble + (slack * 0.4 + breeze * wind_strength) * COLOR.r) + vec3(0.0, -slack, 0.0) * COLOR.r;
}

void fragment() {
	// Hexagonal mesh as in match nets; distance to the nearest cord in metres.
	const vec2 HEX = vec2(1.0, 1.7320508);
	vec2 cell = UV / mesh_size;
	vec4 centres = floor(vec4(cell, cell - vec2(0.5, 1.0)) / HEX.xyxy) + 0.5;
	vec4 offsets = vec4(cell - centres.xy * HEX, cell - (centres.zw + 0.5) * HEX);
	vec2 local = abs(dot(offsets.xy, offsets.xy) < dot(offsets.zw, offsets.zw) ? offsets.xy : offsets.zw);
	float to_cord = (0.5 - max(dot(local, HEX * 0.5), local.x)) * mesh_size;
	float pixel = max(fwidth(to_cord), 1e-5);
	float half_width = max(rope_width * 0.5, pixel * 0.75);
	// Cords thinner than a pixel fade instead of shimmering; the cord is round, so its rim darkens.
	ALPHA = (1.0 - smoothstep(half_width - pixel * 0.5, half_width + pixel * 0.5, to_cord)) * (rope_width * 0.5 / half_width) * 0.9;
	if (ALPHA < 0.02) {
		discard;
	}
	ALBEDO = rope_color * mix(1.0, 0.7, clamp(to_cord / half_width, 0.0, 1.0));
	ROUGHNESS = 0.9;
	BACKLIGHT = rope_color * 0.3;
}
