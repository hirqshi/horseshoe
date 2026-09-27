shader_type canvas_item;
render_mode blend_disabled;

// Port of growth automaton / mycelium-like branching pattern
// Buffer pass: reads its own previous frame (via ping-pong, see setup script)
// and grows angle-directed cells outward from a seeded center point.
//
// render_mode blend_disabled is REQUIRED: this shader uses alpha as a plain
// data channel (always writes 0.0), not as transparency. Without this mode,
// Godot's default alpha blending discards every write with alpha=0.0,
// leaving the buffer permanently black regardless of the growth logic.
//
// NOTE: fragment() cannot use early "return" in Godot (undefined behavior) -
// the whole function is restructured as nested if/else instead.

uniform sampler2D previous_frame : repeat_enable, filter_linear;
uniform float density : hint_range(1.0, 20.0) = 6.0;
uniform float search_radius : hint_range(1.0, 6.0) = 3.0;
uniform float angle_speed : hint_range(0.0, 1.0) = 0.3;
uniform float reset_interval : hint_range(1.0, 20.0) = 4.0;
uniform float reset_window : hint_range(0.01, 1.0) = 0.1;
uniform float start_speed : hint_range(0.0, 3.0) = 0.0;
uniform float seed_radius_px : hint_range(0.5, 10.0) = 1.0;

const float M_PI = 3.1415926;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 frag_coord = FRAGCOORD.xy;

	bool is_reset = TIME >= reset_interval && mod(TIME, reset_interval) < reset_window;

	if (is_reset) {
		COLOR = vec4(0.0);
	} else {
		vec2 xy = floor(frag_coord);
		vec2 center = resolution * 0.5;
		bool is_seed = distance(frag_coord, center) < seed_radius_px;

		if (is_seed) {
			COLOR = vec4(sin(TIME * 1.0), 0.0, 0.0, 0.0);
		} else {
			vec4 color = texture(previous_frame, frag_coord / resolution);
			COLOR = color;

			bool done = false;
			float non_empty = 0.0;
			int k_int = int(search_radius);

			for (int dx = -k_int; dx <= k_int; dx++) {
				for (int dy = -k_int; dy <= k_int; dy++) {
					vec2 fc = frag_coord + vec2(float(dx), float(dy));
					vec4 previous = texture(previous_frame, fc / resolution);
					float raw_angle = previous.x;
					float angle = raw_angle * 2.0 * M_PI;

					if (angle > 0.0) {
						non_empty += 1.0;
					}

					if (!done && angle != 0.0) {
						for (float speed = start_speed; speed <= search_radius; speed += 1.0) {
							vec2 xy2 = floor(fc) + speed * vec2(cos(angle), sin(angle));
							if (distance(xy, xy2) < 1.0) {
								float a = raw_angle + angle_speed * (rand(sin(TIME) * fc) - 0.5);
								color += vec4(fract(a), 0.25, 0.0, 0.0);
							}
						}
						done = true;
					}
				}
			}

			if (non_empty <= density) {
				COLOR = color;
			}
		}
	}
}