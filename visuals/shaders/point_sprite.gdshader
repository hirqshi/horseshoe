shader_type canvas_item;
render_mode blend_add;

// Soft circle point sprite for GPU-instanced splatting via MultiMesh.
// Replaces the brute-force per-pixel smoothstep(0.03, 0.005, dist) check
// from the original shader with a real rasterized quad per point, additively
// blended so overlapping points accumulate brightness exactly like the
// original colAccumulator.

uniform float falloff_edge : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float d = length(centered);
	float alpha = smoothstep(1.0, falloff_edge, d);
	COLOR.a *= alpha;
}
