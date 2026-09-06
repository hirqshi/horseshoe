class_name CompassHud
extends HudElement

@export_category("references")
@export var pointer: TextureRect
@export var heading_label: Label

@export_category("scale")
@export_range(
	1.0,
	100.0,
	0.1,
	"suffix:px/deg"
) var pixels_per_degree: float = 2.0

@export var scale_center_px: Vector2 = Vector2(
	160.0,
	20.0
)

@export_range(
	5.0,
	360.0,
	1.0,
	"suffix:deg"
) var visible_range_degrees: float = 130.0

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
	180.0,
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

@export_category("labels")
@export var is_cardinal_labels_enabled: bool = true
@export var is_degree_labels_enabled: bool = true

@export var label_font: Font

@export_range(
	1,
	128,
	1,
	"suffix:px"
) var label_font_size: int = 12

@export_range(
	-100.0,
	100.0,
	0.1,
	"suffix:px"
) var label_offset_px: float = 12.0

@export var label_color: Color = Color.WHITE

@export_range(
	0.0,
	1.0,
	0.01
) var label_alpha: float = 1.0

@export_category("heading label")
@export var heading_label_prefix: String = ""
@export var heading_label_suffix: String = "°"

@export_category("smoothing")
@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var heading_follow_speed: float = 18.0

var _target_heading_radians: float = 0.0
var _displayed_heading_radians: float = 0.0


func _ready() -> void:
	super._ready()

	if pointer == null:
		push_error(
			"%s requires Pointer."
			% name
		)
		set_process(false)
		return

	if heading_label == null:
		push_error(
			"%s requires HeadingLabel."
			% name
		)
		set_process(false)
		return

	if (
		is_cardinal_labels_enabled
		or is_degree_labels_enabled
	) and label_font == null:
		push_error(
			"%s requires LabelFont "
			+ "when labels are enabled."
			% name
		)
		set_process(false)
		return

	_update_heading_label()

	queue_redraw()


func _process(
	delta: float
) -> void:
	super._process(delta)

	var follow_weight: float = (
		1.0
		- exp(
			-heading_follow_speed
			* delta
		)
	)

	_displayed_heading_radians = lerp_angle(
		_displayed_heading_radians,
		_target_heading_radians,
		follow_weight
	)

	_update_heading_label()

	queue_redraw()


func set_heading_degrees(
	heading_degrees: float
) -> void:
	_target_heading_radians = deg_to_rad(
		fposmod(
			heading_degrees,
			360.0
		)
	)


func _draw() -> void:
	var current_heading_degrees: float = fposmod(
		rad_to_deg(
			_displayed_heading_radians
		),
		360.0
	)

	var half_visible_range_degrees: float = (
		visible_range_degrees
		* 0.5
	)

	var first_tick_degree: int = (
		floori(
			(
				current_heading_degrees
				- half_visible_range_degrees
			)
			/ minor_tick_step_degrees
		)
		* roundi(
			minor_tick_step_degrees
		)
	)

	var last_tick_degree: int = (
		ceili(
			(
				current_heading_degrees
				+ half_visible_range_degrees
			)
			/ minor_tick_step_degrees
		)
		* roundi(
			minor_tick_step_degrees
		)
	)

	var draw_tick_color: Color = Color(
		tick_color.r,
		tick_color.g,
		tick_color.b,
		tick_color.a
		* tick_alpha
	)

	var draw_label_color: Color = Color(
		label_color.r,
		label_color.g,
		label_color.b,
		label_color.a
		* label_alpha
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
		var normalized_degree: float = fposmod(
			float(degree),
			360.0
		)

		var degree_delta: float = wrapf(
			normalized_degree
			- current_heading_degrees,
			-180.0,
			180.0
		)

		var tick_x: float = (
			scale_center_px.x
			+ degree_delta
			* pixels_per_degree
		)

		if tick_x < 0.0:
			continue

		if tick_x > size.x:
			continue

		var normalized_int_degree: int = roundi(
			normalized_degree
		)

		var is_major_tick: bool = (
			normalized_int_degree
			% major_step
			== 0
		)

		var is_medium_tick: bool = (
			not is_major_tick
			and normalized_int_degree
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
			tick_x,
			scale_center_px.y
		)

		var tick_end: Vector2 = Vector2(
			tick_x,
			scale_center_px.y
			+ tick_length_px
		)

		draw_line(
			tick_start,
			tick_end,
			draw_tick_color,
			tick_width_px,
			true
		)

		if not is_major_tick:
			continue

		if label_font == null:
			continue

		var cardinal_label: String = _get_cardinal_label(
			normalized_int_degree
		)

		var has_cardinal_label: bool = (
			not cardinal_label.is_empty()
		)

		var should_draw_cardinal: bool = (
			is_cardinal_labels_enabled
			and has_cardinal_label
		)

		var should_draw_degree: bool = (
			is_degree_labels_enabled
			and not has_cardinal_label
		)

		if not should_draw_cardinal \
		and not should_draw_degree:
			continue

		var label_text: String = cardinal_label

		if should_draw_degree:
			label_text = str(
				normalized_int_degree
			)

		var label_width_px: float = 44.0

		var label_position: Vector2 = Vector2(
			tick_x
			- label_width_px
			* 0.5,

			scale_center_px.y
			+ tick_length_px
			+ label_offset_px
		)

		draw_string(
			label_font,
			label_position,
			label_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			label_width_px,
			label_font_size,
			draw_label_color
		)


func _get_cardinal_label(
	heading_degrees: int
) -> String:
	match heading_degrees:
		0:
			return "N"

		90:
			return "E"

		180:
			return "S"

		270:
			return "W"

	return ""


func _update_heading_label() -> void:
	if heading_label == null:
		return

	var heading_degrees: float = fposmod(
		rad_to_deg(
			_displayed_heading_radians
		),
		360.0
	)

	heading_label.text = (
		heading_label_prefix
		+ "%03d" % roundi(
			heading_degrees
		)
		+ heading_label_suffix
	)
