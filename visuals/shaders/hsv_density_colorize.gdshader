shader_type canvas_item;

// Image pass: colorizes the accumulated point-density buffer using the
// same HSV mapping as the original shader. Requires the buffer SubViewport
// to have use_hdr_2d = true, otherwise dense overlaps clip at 1.0 and the
// hue mapping will look different from the original (which allowed
// colAccumulator to exceed 1.0 freely).

uniform sampler2D buffer_texture;
uniform float hue_density_scale : hint_range(0.0, 2.0) = 0.55;
uniform float hue_time_speed : hint_range(0.0, 1.0) = 0.125;
uniform float saturation : hint_range(0.0, 1.0) = 0.9;
uniform float value_scale : hint_range(0.0, 2.0) = 0.6;

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	float accum = texture(buffer_texture, UV).r;
	float hue = mod(accum * hue_density_scale + TIME * hue_time_speed, 1.0);
	float val = clamp(accum * value_scale, 0.0, 1.0);
	vec3 color = hsv2rgb(vec3(hue, saturation, val));
	COLOR = vec4(color, 1.0);
}
