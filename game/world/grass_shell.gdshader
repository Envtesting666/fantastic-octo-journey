shader_type spatial;
render_mode diffuse_burley, cull_back;

#include "res://world/grass_common.gdshaderinc"

// Shell-textured turf: each MultiMesh instance is one height slice of the same plane.
uniform int shell_count = 16;
uniform float blade_height = 0.035;
uniform float blades_per_metre = 90.0;
uniform vec2 fade_distance = vec2(4.0, 9.0);
uniform vec2 wind_direction = vec2(0.8, 0.6);
// Tip offset (in blade cells) of a mown blade; alternating per stripe it creates the stripe sheen.
uniform float mow_lean = 1.6;
uniform float clumps_per_metre = 18.0;

varying vec3 world_position;
varying float layer;

void vertex() {
	layer = float(INSTANCE_ID + 1) / float(shell_count);
	VERTEX.y += layer * blade_height;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Tips sway more than roots; gusts are scrolling noise at two scales, not one sine.
	vec2 drift = wind_direction * TIME;
	float gust = value_noise(world_position.xz * 0.25 - drift * 0.5) * 0.7 + value_noise(world_position.xz * 1.3 - drift * 1.7) * 0.3;
	world_position.xz += wind_direction * gust * layer * layer * 0.005;
}

void fragment() {
	// Far turf is resolved by the ground shader; thin out shells with distance.
	float keep = 1.0 - smoothstep(fade_distance.x, fade_distance.y, length(world_position - CAMERA_POSITION_WORLD));
	// Once blades shrink below a pixel they only alias (moiré); drop slices by screen footprint too.
	vec2 footprint = fwidth(world_position.xz) * blades_per_metre;
	keep = min(keep, 1.0 - smoothstep(0.6, 1.6, max(footprint.x, footprint.y)));
	float mow = mow_direction(world_position.xz);
	// Blades bend: higher slices are sampled further along the lean, so each blade reads as a slanted streak.
	// Blades grow in clumps (Voronoi cells ~5 cm): a clump shares height and a lean wobble.
	vec2 clump_cell = world_position.xz * clumps_per_metre;
	vec2 clump_base = floor(clump_cell);
	float nearest = 9.0;
	vec2 clump_id = clump_base;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 candidate = clump_base + vec2(float(x), float(y));
			vec2 seed = candidate + vec2(hash(candidate + 3.7), hash(candidate + 9.2));
			float distance_to_seed = length(clump_cell - seed);
			if (distance_to_seed < nearest) {
				nearest = distance_to_seed;
				clump_id = candidate;
			}
		}
	}
	float clump_height = mix(0.75, 1.1, hash(clump_id + 1.9));
	vec2 clump_lean = (vec2(hash(clump_id + 4.4), hash(clump_id + 8.8)) - 0.5) * 0.8;
	vec2 bend = (vec2(0.0, -mow * mow_lean) + clump_lean) * layer * layer; // same lean as the baked tile
	vec2 cell = world_position.xz * blades_per_metre - bend;
	vec2 id = floor(cell);
	float rnd = hash(id);
	// Blades shorten with distance instead of thinning out: sparse leftovers read as dark dots.
	float blade_length = mix(0.45, 1.0, rnd) * clump_height * keep;
	if (layer > blade_length) {
		discard;
	}
	vec2 offset = fract(cell) - 0.5 - (vec2(hash(id + 13.1), hash(id + 71.7)) - 0.5) * 0.5;
	if (length(offset * vec2(1.0, 0.6)) > 0.42 * (1.0 - layer / blade_length)) {
		discard;
	}
	// Lean tilts the normal (stripe sheen); the offset from the blade axis rounds it.
	vec3 blade_normal = normalize(vec3(offset.x * 1.4, 1.0, -mow * 0.55 + offset.y * 1.4));
	NORMAL = normalize((VIEW_MATRIX * vec4(blade_normal, 0.0)).xyz);
	vec3 albedo = pitch_albedo(world_position.xz, 0.0);
		// Root shading fades as slices thin out, so near and far turf keep the same mean brightness.
	albedo *= mow_sheen(world_position.xz, CAMERA_POSITION_WORLD - world_position);
	// Root shading fades out with the blades, so the shell edge blends into the ground.
	ALBEDO = albedo * mix(1.0, mix(0.7, 0.95, layer) * (0.9 + rnd * 0.2), keep);
	// Thin blades let low sun through when seen against the light.
	BACKLIGHT = ALBEDO * 0.3 * layer;
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
