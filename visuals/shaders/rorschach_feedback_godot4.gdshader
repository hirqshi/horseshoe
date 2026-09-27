shader_type canvas_item;

// Port of Rorschach inkblot raymarch + feedback trail effect
// Leon Denise, 06/12/2025 - improvised during inertia shader royal 2025
//
// previous_frame must be bound in GDScript to this same SubViewport's own
// ViewportTexture (see setup script) - creates the self-feedback trail effect.

uniform sampler2D previous_frame : repeat_enable, filter_linear;

// -- shape animation --
uniform float time_speed : hint_range(0.0, 20.0) = 8.0;
uniform float stagger_power : hint_range(1.0, 10.0) = 4.5;
uniform float fold_freq : hint_range(0.0, 10.0) = 3.0;
uniform float offset_scale : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_freq : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_amp : hint_range(0.0, 2.0) = 0.5;
uniform float rot_speed : hint_range(0.0, 10.0) = 2.0;

// -- shape radius --
uniform float base_radius : hint_range(0.0, 2.0) = 0.2;
uniform float radius_wobble : hint_range(0.0, 1.0) = 0.1;
uniform float wobble_freq : hint_range(0.0, 10.0) = 4.0;
uniform float small_radius : hint_range(0.0, 1.0) = 0.05;
uniform float spike_amount : hint_range(0.0, 1.0) = 0.2;
uniform float spike_threshold : hint_range(0.0, 1.0) = 0.99;

// -- camera --
uniform float camera_dist : hint_range(1.0, 20.0) = 4.0;
uniform float camera_bob_amp : hint_range(0.0, 5.0) = 1.0;
uniform float camera_bob_freq : hint_range(0.0, 5.0) = 0.5;

// -- raymarch quality --
uniform int raymarch_steps : hint_range(10, 200) = 100;
uniform float far_distance : hint_range(1.0, 100.0) = 20.0;
uniform float rng_dither : hint_range(0.0, 1.0) = 0.1;

// -- coloring --
uniform float color_freq : hint_range(0.0, 10.0) = 4.5;
uniform float rim_power : hint_range(0.1, 30.0) = 10.0;
uniform float rim_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float vignette_range : hint_range(0.1, 5.0) = 2.0;

// -- feedback trail --
uniform float feedback_decay : hint_range(0.0, 0.2) = 0.01;
uniform float glitch_amount : hint_range(0.0, 10.0) = 4.0;
uniform float glitch_freq : hint_range(0.0, 30.0) = 10.0;
uniform float glitch_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float warp_amount : hint_range(0.0, 10.0) = 4.0;
uniform float feedback_cell_min : hint_range(1.0, 20.0) = 4.0;
uniform float feedback_cell_max : hint_range(1.0, 20.0) = 8.0;
uniform float feedback_cell_time_freq : hint_range(0.0, 100.0) = 40.0;
uniform float feedback_time_freq : hint_range(0.0, 20.0) = 4.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(123.321, 321.123))) * 321.654); }
vec3 hash31(float i) { return vec3(hash(vec2(i, 17.0)), hash(vec2(i, 357.0)), hash(vec2(i, -95.0))); }
vec3 hash32(vec2 p) { return vec3(hash(p + 17.0), hash(p + 657.0), hash(p + 95.0)); }

mat2 rot(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, -s), vec2(s, c));
}

float map(vec3 p, float time_now, float rng) {
	float t = time_now * time_speed + p.z * 0.5 + rng * 0.25;
	t = pow(fract(t), stagger_power) + floor(t);
	vec2 anim = vec2(fract(t), floor(t));
	vec3 offset = mix(hash31(anim.y), hash31(anim.y + 1.0), anim.x);

	p.x = abs(p.x) - 0.5 * abs(sin(t * fold_freq)) - 0.5;
	p.xz *= rot(t);
	p.xy *= rot(t);
	p += (offset - 0.5) * offset_scale;
	p = abs(p) - abs(sin(time_now * pulse_freq)) * pulse_amp;
	p.xz *= rot(t * rot_speed);

	float d = length(p) - (base_radius - radius_wobble * sin(t * wobble_freq)) * 0.5;
	p = abs(p) - 0.5 * sin(t * wobble_freq);
	d = min(d, length(p) - small_radius + spike_amount * step(spike_threshold, fract(t * rot_speed)));
	return d;
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	float rng = hash(FRAGCOORD.xy);

	vec2 uv = FRAGCOORD.xy / resolution;
	vec2 p = (2.0 * FRAGCOORD.xy - resolution) / resolution.y;

	float time_now = TIME;

	vec3 pos = vec3(0.0, 0.0, -camera_dist + camera_bob_amp * sin(time_now * camera_bob_freq));
	vec3 z_axis = normalize(pos);
	vec3 x_axis = normalize(cross(z_axis, vec3(0.0, 1.0, 0.0)));
	vec3 y_axis = normalize(cross(x_axis, z_axis));
	vec3 ray = mat3(x_axis, y_axis, z_axis) * normalize(vec3(p, -1.0));

	float total = 0.0;
	float shade = 0.0;
	float dist = 100.0;
	float steps_f = float(raymarch_steps);

	for (float i = 1.0; i > 0.0; i -= 1.0 / steps_f) {
		dist = map(pos, time_now, rng);
		if (dist < 0.001 || total > far_distance) {
			break;
		}
		dist *= 0.5 + rng_dither * rng;
		pos += ray * dist;
		total += dist;
		shade = i;
	}

	vec3 color = vec3(shade);
	vec2 e = vec2(0.001, 0.0);
	vec3 normal = normalize(vec3(dist) - vec3(
		map(pos - e.xyy, time_now, rng),
		map(pos - e.yxy, time_now, rng),
		map(pos - e.yyx, time_now, rng)
	));
	color = 0.5 + 0.5 * cos(vec3(1.0, 2.0, 3.0) * color_freq + pos.z + time_now + normal * 1.0);
	color += rim_intensity * pow(0.5 + 0.5 * dot(normal, -ray), rim_power);
	color *= shade;

	vec3 back = vec3(smoothstep(0.0, vignette_range, length(p)));
	if (total > far_distance) {
		color = back;
	}
	color = 1.0 - color;

	vec3 offset = hash32(floor(p * mix(feedback_cell_min, feedback_cell_max, hash31(floor(time_now * feedback_cell_time_freq)).x)) + floor(time_now * feedback_time_freq));
	uv -= step(glitch_threshold, offset.z) * glitch_amount * normalize(offset.xy - 0.5) * abs(sin(time_now * glitch_freq)) / resolution;
	vec3 frame = texture(previous_frame, uv).rgb;
	uv += warp_amount * (frame.xy - 0.5) / resolution;
	frame = texture(previous_frame, uv).rgb;

	COLOR = vec4(min(color, frame + feedback_decay), 1.0);
}