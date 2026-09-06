class_name RollIndicatorHud
extends HudElement

@export_category("references")
@export var pointer: TextureRect
@export var angle_label: Label

@export_category("pointer alignment")
@export var is_pointer_auto_centered: bool = true

@export_range(
	-200.0,
	200.0,
	0.1,
	"suffix:px"
) var pointer_horizontal_offset_px: float = 0.0

@export_category("arc")
@export var arc_center_px: Vector2 = Vector2(
	100.0,
	100.0
)

@export_range(
	8.0,
	1000.0,
	0.1,
	"suffix:px"
) var arc_radius_px: float = 78.0

@export_range(
	10.0,
	180.0,
	1.0,
	"suffix:deg"
) var visible_arc_degrees: float = 120.0

@export_range(
	5.0,
	180.0,
	1.0,
	"suffix:deg"
) var displayed_roll_range_degrees: float = 60.0

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
	20.0,
	0.1,
	"suffix:px"
) var minor_tick_length_px: float = 5.0

@export_range(
	0.1,
	20.0,
	0.1,
	"suffix:px"
) var medium_tick_length_px: float = 9.0

@export_range(
	0.1,
	30.0,
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

@export_category("degree labels")
@export var is_degree_labels_enabled: bool = true
@export var degree_label_font: Font

@export_range(
	1,
	128,
	1,
	"suffix:px"
) var degree_label_font_size: int = 12

@export_range(
	0.0,
	100.0,
	0.1,
	"suffix:px"
) var degree_label_offset_px: float = 14.0

@export var degree_label_color: Color = Color.WHITE

@export_range(
	0.0,
	1.0,
	0.01
) var degree_label_alpha: float = 1.0

@export_category("angle label")
@export var angle_label_prefix: String = ""
@export var angle_label_suffix: String = "°"

@export_category("smoothing")
@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var roll_follow_speed: float = 18.0

var _target_roll_radians: float = 0.0
var _displayed_roll_radians: float = 0.0


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

	if is_degree_labels_enabled \
	and degree_label_font == null:
		push_error(
			"%s requires DegreeLabelFont "
			+ "when degree labels are enabled."
			% name
		)
		set_process(false)
		return

	_update_angle_label()

	call_deferred(
		"_align_pointer_horizontally"
	)

	queue_redraw()


func _process(
	delta: float
) -> void:
	super._process(delta)

	var follow_weight: float = (
		1.0
		- exp(
			-roll_follow_speed
			* delta
		)
	)

	_displayed_roll_radians = lerp_angle(
		_displayed_roll_radians,
		_target_roll_radians,
		follow_weight
	)

	_update_angle_label()

	queue_redraw()


func set_roll_degrees(
	roll_degrees: float
) -> void:
	_target_roll_radians = deg_to_rad(
		wrapf(
			roll_degrees,
			-180.0,
			180.0
		)
	)


func _draw() -> void:
	var pointer_angle_radians: float = (
		-PI
		* 0.5
	)

	var half_visible_arc_radians: float = deg_to_rad(
		visible_arc_degrees
		* 0.5
	)

	var arc_start_radians: float = (
		pointer_angle_radians
		- half_visible_arc_radians
	)

	var arc_end_radians: float = (
		pointer_angle_radians
		+ half_visible_arc_radians
	)

	var min_display_degree: int = -roundi(
		displayed_roll_range_degrees
	)

	var max_display_degree: int = roundi(
		displayed_roll_range_degrees
	)

	var tick_draw_color: Color = Color(
		tick_color.r,
		tick_color.g,
		tick_color.b,
		tick_color.a
		* tick_alpha
	)

	var label_draw_color: Color = Color(
		degree_label_color.r,
		degree_label_color.g,
		degree_label_color.b,
		degree_label_color.a
		* degree_label_alpha
	)

	for degree: int in range(
		min_display_degree,
		max_display_degree
		+ 1,
		roundi(
			minor_tick_step_degrees
		)
	):
		var is_major_tick: bool = (
			degree
			% roundi(
				major_tick_step_degrees
			)
			== 0
		)

		var is_medium_tick: bool = (
			not is_major_tick
			and degree
			% roundi(
				medium_tick_step_degrees
			)
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

		var tick_angle_radians: float = (
			pointer_angle_radians
			+ deg_to_rad(
				float(degree)
			)
			- _displayed_roll_radians
		)

		if tick_angle_radians < arc_start_radians \
		or tick_angle_radians > arc_end_radians:
			continue

		var radial_direction: Vector2 = Vector2(
			cos(
				tick_angle_radians
			),
			sin(
				tick_angle_radians
			)
		)

		var outer_point: Vector2 = (
			arc_center_px
			+ radial_direction
			* arc_radius_px
		)

		var inner_point: Vector2 = (
			outer_point
			- radial_direction
			* tick_length_px
		)

		draw_line(
			inner_point,
			outer_point,
			tick_draw_color,
			tick_width_px,
			true
		)

		if not is_major_tick:
			continue

		if not is_degree_labels_enabled:
			continue

		if degree_label_font == null:
			continue

		var label_position: Vector2 = (
			outer_point
			+ radial_direction
			* degree_label_offset_px
		)

		var label_text: String = str(
			abs(
				degree
			)
		)

		var label_width_px: float = 42.0

		draw_string(
			degree_label_font,
			label_position
			- Vector2(
				label_width_px
				* 0.5,
				-degree_label_font_size
				* 0.35
			),
			label_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			label_width_px,
			degree_label_font_size,
			label_draw_color
		)


func _update_angle_label() -> void:
	if angle_label == null:
		return

	var roll_degrees: float = wrapf(
		rad_to_deg(
			_displayed_roll_radians
		),
		-180.0,
		180.0
	)

	angle_label.text = (
		angle_label_prefix
		+ "%d" % roundi(
			roll_degrees
		)
		+ angle_label_suffix
	)


func _align_pointer_horizontally() -> void:
	if not is_pointer_auto_centered:
		return

	if pointer == null:
		return

	var pointer_width_px: float = pointer.size.x

	if pointer_width_px <= 0.0 \
	and pointer.texture != null:
		pointer_width_px = pointer.texture.get_size().x

	if pointer_width_px <= 0.0:
		return

	pointer.position.x = (
		arc_center_px.x
		- pointer_width_px
		* 0.5
		+ pointer_horizontal_offset_px
	)
