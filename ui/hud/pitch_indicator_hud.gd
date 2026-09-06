class_name PitchIndicatorHud
extends HudElement

@export_category("references")
@export var pointer: TextureRect
@export var angle_label: Label

@export_category("scale")
@export_range(
	1.0,
	100.0,
	0.1,
	"suffix:px/deg"
) var pixels_per_degree: float = 2.0

@export var scale_center_px: Vector2 = Vector2(
	20.0,
	110.0
)

@export_range(
	5.0,
	360.0,
	1.0,
	"suffix:deg"
) var visible_range_degrees: float = 100.0

@export_category("ticks")
@export_range(
	1.0,
	90.0,
	1.0,
	"suffix:deg"
) var minor_tick_step_degrees: float = 5.0

@export_range(
	1.0,
	90.0,
	1.0,
	"suffix:deg"
) var medium_tick_step_degrees: float = 15.0

@export_range(
	1.0,
	90.0,
	1.0,
	"suffix:deg"
) var major_tick_step_degrees: float = 30.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:px"
) var minor_tick_length_px: float = 5.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:px"
) var medium_tick_length_px: float = 9.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:px"
) var major_tick_length_px: float = 14.0

@export_range(
	0.1,
	10.0,
	0.1,
	"suffix:px"
) var minor_tick_width_px: float = 1.0

@export_range(
	0.1,
	10.0,
	0.1,
	"suffix:px"
) var medium_tick_width_px: float = 1.0

@export_range(
	0.1,
	10.0,
	0.1,
	"suffix:px"
) var major_tick_width_px: float = 2.0

@export var tick_color: Color = Color.WHITE

@export_range(
	0.0,
	1.0,
	0.01
) var tick_alpha: float = 1.0

@export_category("angle label")
@export var angle_label_prefix: String = ""
@export var angle_label_suffix: String = "°"

@export_category("smoothing")
@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var pitch_follow_speed: float = 18.0

var _target_pitch_degrees: float = 0.0
var _displayed_pitch_degrees: float = 0.0


func _ready() -> void:
	super._ready()

	if pointer == null:
		push_error(
			"%s requires Pointer."
			% name
		)
		set_process(false)
		return

	if angle_label == null:
		push_error(
			"%s requires AngleLabel."
			% name
		)
		set_process(false)
		return

	_update_angle_label()

	queue_redraw()


func _process(
	delta: float
) -> void:
	super._process(delta)

	var follow_weight: float = (
		1.0
		- exp(
			-pitch_follow_speed
			* delta
		)
	)

	_displayed_pitch_degrees = lerpf(
		_displayed_pitch_degrees,
		_target_pitch_degrees,
		follow_weight
	)

	_update_angle_label()

	queue_redraw()


func set_pitch_degrees(
	pitch_degrees: float
) -> void:
	_target_pitch_degrees = clampf(
		pitch_degrees,
		-90.0,
		90.0
	)


func _draw() -> void:
	var half_visible_range_degrees: float = (
		visible_range_degrees
		* 0.5
	)

	var first_tick_degree: int = floori(
		(
			_displayed_pitch_degrees
			- half_visible_range_degrees
		)
		/ minor_tick_step_degrees
	) * roundi(
		minor_tick_step_degrees
	)

	var last_tick_degree: int = ceili(
		(
			_displayed_pitch_degrees
			+ half_visible_range_degrees
		)
		/ minor_tick_step_degrees
	) * roundi(
		minor_tick_step_degrees
	)

	var draw_tick_color: Color = Color(
		tick_color.r,
		tick_color.g,
		tick_color.b,
		tick_color.a
		* tick_alpha
	)

	var minor_step: int = roundi(
		minor_tick_step_degrees
	)

	var medium_step: int = roundi(
		medium_tick_step_degrees
	)

	var major_step: int = roundi(
		major_tick_step_degrees
	)

	for degree: int in range(
		first_tick_degree,
		last_tick_degree
		+ 1,
		minor_step
	):
		var degree_delta: float = (
			_displayed_pitch_degrees
			- float(degree)
		)

		var tick_y: float = (
			scale_center_px.y
			+ degree_delta
			* pixels_per_degree
		)

		if tick_y < 0.0:
			continue

		if tick_y > size.y:
			continue

		var is_major_tick: bool = (
			degree
			% major_step
			== 0
		)

		var is_medium_tick: bool = (
			not is_major_tick
			and degree
			% medium_step
			== 0
		)

		var tick_length_px: float = minor_tick_length_px
		var tick_width_px: float = minor_tick_width_px

		if is_major_tick:
			tick_length_px = major_tick_length_px
			tick_width_px = major_tick_width_px
		elif is_medium_tick:
			tick_length_px = medium_tick_length_px
			tick_width_px = medium_tick_width_px

		var tick_start: Vector2 = Vector2(
			scale_center_px.x
			- tick_length_px
			* 0.5,
			tick_y
		)

		var tick_end: Vector2 = Vector2(
			scale_center_px.x
			+ tick_length_px
			* 0.5,
			tick_y
		)

		draw_line(
			tick_start,
			tick_end,
			draw_tick_color,
			tick_width_px,
			true
		)


func _update_angle_label() -> void:
	if angle_label == null:
		return

	angle_label.text = (
		angle_label_prefix
		+ "%d" % roundi(
			_displayed_pitch_degrees
		)
		+ angle_label_suffix
	)
