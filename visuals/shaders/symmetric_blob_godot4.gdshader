shader_type canvas_item;

// Port of symmetric radial blob-noise pattern
// Multi-layer angular/radial noise blend creating organic blob shapes

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform float speed : hint_range(0.0, 2.0) = 0.5;
uniform float time_step : hint_range(0.0, 1.0) = 0.2;
uniform float center1 : hint_range(0.0, 1.0) = 0.05;
uniform float noise_influence1 : hint_range(0.0, 1.0) = 0.5;
uniform float smooth1 : hint_range(0.0, 1.0) = 0.02;
uniform float center2 : hint_range(0.0, 1.0) = 0.25;
uniform float noise_influence2 : hint_range(0.0, 1.0) = 0.05;
uniform float smooth2 : hint_range(0.0, 1.0) = 0.25;
uniform vec4 noise_tiles = vec4(0.2, 0.4, 0.5, 0.75);
uniform vec4 noise_evolution = vec4(0.25, -0.25, 0.1, -0.1);
uniform vec4 noise_weights = vec4(1.0, 0.5, 0.25, 0.1);
uniform vec4 noise_radius_tiles = vec4(0.1, 0.2, 0.5, 0.1);
uniform vec4 noise_radius_evolution = vec4(0.25, -0.25, 0.1, -0.1);
uniform float noise_radius_weight : hint_range(0.0, 1.0) = 0.5;
uniform float final_mix : hint_range(0.0, 1.0) = 0.25;
uniform float texture_tile : hint_range(0.1, 10.0) = 3.0;
uniform float texture_influence : hint_range(0.0, 0.1) = 0.0025;
uniform float texture_add : hint_range(0.0, 1.0) = 0.2;

float noise_lookup(float x) {
	return texture(noise_texture, vec2(x, x)).x;
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	float t = speed * TIME;
	float step_time = mix(floor(t), floor(t + 1.0), smoothstep(0.0, 0.5, fract(t))) * time_step;

	vec2 uv = FRAGCOORD.xy / resolution;
	vec4 tex = texture(noise_texture, uv * texture_tile);

	vec2 x = vec2(abs(uv.x - 0.5) * 1.5, uv.y - 0.5);
	float radius = length(x);
	float angle = atan(x.y, x.x);

	vec4 speed_radius = noise_radius_evolution * step_time;
	vec4 noise_radius = vec4(noise_radius_weight);
	tex.w = tex.x;
	vec4 a = radius * noise_radius_tiles + speed_radius + tex * texture_influence;
	noise_radius *= vec4(noise_lookup(a.x), noise_lookup(a.y), noise_lookup(a.z), noise_lookup(a.w));

	vec4 speed2 = noise_evolution * step_time;
	a = angle * noise_tiles + speed2 + noise_radius * 2.0 - 1.0 + tex * texture_influence;
	vec4 n_vec = vec4(noise_lookup(a.x), noise_lookup(a.y), noise_lookup(a.z), noise_lookup(a.w));

	// NOTE: original shadertoy code divides n_vec by itself (n_vec/n_vec) to
	// sum noiseWeights via dot product. If any component of n_vec is exactly
	// 0.0 (a black texel), this produces 0/0 = NaN and can corrupt the whole
	// pixel. Kept for fidelity to source, but if you see black/glitch pixels,
	// replace the denominator with dot(vec4(1.0), noise_weights) instead.
	float n = dot(n_vec, noise_weights) / dot(n_vec / n_vec, noise_weights);

	float c1 = smoothstep(0.0, smooth1, radius - center1 - n * noise_influence1);
	float c2 = smoothstep(0.0, smooth2, radius - center2 - n * noise_influence2);

	COLOR = vec4(vec3(mix(c1, c2, final_mix) * smoothstep(0.0, 0.75, 1.0 - radius) + tex.x * texture_add), 1.0);
}
