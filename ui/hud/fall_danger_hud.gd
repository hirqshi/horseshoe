class_name FallDangerHud
extends HudElement

@export_category("references")
@export var content: Control
@export var height_bar: TextureRect
@export var player_marker: TextureRect
@export var height_label: Label

@export_category("placement")
@export var marker_offset_px: Vector2 = Vector2(
	10.0,
	0.0
)

@export_category("height label")
@export var height_label_prefix: String = ""
@export var height_label_suffix: String = ""

@export_category("danger colors")
@export var danger_color: Color = Color(
	1.0,
	0.08,
	0.04,
	1.0
)

@export_range(
	0.0,
	1.0,
	0.01
) var danger_color_start_progress: float = 0.65

@export_range(
	0.0,
	1.0,
	0.01
) var danger_color_strength: float = 1.0

@export_category("critical blink")
@export_range(
	0.1,
	60.0,
	0.1,
	"suffix:hz"
) var critical_blink_min_hz: float = 5.0

@export_range(
	0.1,
	60.0,
	0.1,
	"suffix:hz"
) var critical_blink_max_hz: float = 15.0

@export_range(
	0.0,
	1.0,
	0.01
) var critical_marker_min_alpha: float = 0.15

var _fall_tracker: FallTracker

var _height_bar_base_modulate: Color = Color.WHITE
var _marker_base_modulate: Color = Color.WHITE

var _current_fall_distance_m: float = 0.0
var _current_progress: float = 0.0
var _is_critical: bool = false
var _blink_time_s: float = 0.0


func _ready() -> void:
	super._ready()

	if content == null:
		push_error(
			"FallDangerHud requires Content."
		)
		set_process(false)
		return

	if height_bar == null:
		push_error(
			"FallDangerHud requires HeightBar."
		)
		set_process(false)
		return

	if player_marker == null:
		push_error(
			"FallDangerHud requires PlayerMarker."
		)
		set_process(false)
		return

	if height_label == null:
		push_error(
			"FallDangerHud requires HeightLabel."
		)
		set_process(false)
		return

	_height_bar_base_modulate = height_bar.modulate
	_marker_base_modulate = player_marker.modulate

	content.visible = true

	_update_visuals()


func _process(
	delta: float
) -> void:
	super._process(delta)

	if _fall_tracker == null:
		return

	_update_fall_state()

	_blink_time_s += delta

	_update_visuals()


func set_fall_tracker(
	fall_tracker: FallTracker
) -> void:
	_fall_tracker = fall_tracker

	if _fall_tracker == null:
		_current_fall_distance_m = 0.0
		_current_progress = 0.0
		_is_critical = false

		_update_visuals()
		return

	_update_fall_state()

	_update_visuals()


func _update_fall_state() -> void:
	if _fall_tracker == null:
		return

	_current_fall_distance_m = maxf(
		_fall_tracker.get_current_fall_distance_m(),
		0.0
	)

	_current_progress = clampf(
		_fall_tracker.get_current_fall_progress(),
		0.0,
		1.0
	)

	_is_critical = _fall_tracker.is_fall_critical()


func _update_visuals() -> void:
	_update_marker_position()
	_update_height_label()
	_update_colors()


func _update_marker_position() -> void:
	if height_bar == null:
		return

	if player_marker == null:
		return

	var bar_rect: Rect2 = height_bar.get_global_rect()

	var marker_size: Vector2 = player_marker.size

	var marker_x: float = (
		bar_rect.position.x
		+ bar_rect.size.x
		+ marker_offset_px.x
	)

	var marker_y: float = (
		bar_rect.position.y
		+ bar_rect.size.y
		* _current_progress
		- marker_size.y
		* 0.5
		+ marker_offset_px.y
	)

	player_marker.global_position = Vector2(
		marker_x,
		marker_y
	)


func _update_height_label() -> void:
	if height_label == null:
		return

	var formatted_distance: String = "%.2f" % (
		_current_fall_distance_m
	)

	height_label.text = (
		height_label_prefix
		+ formatted_distance
		+ height_label_suffix
	)


func _update_colors() -> void:
	var danger_progress: float = clampf(
		inverse_lerp(
			danger_color_start_progress,
			1.0,
			_current_progress
		),
		0.0,
		1.0
	)

	var danger_weight: float = (
		danger_progress
		* danger_color_strength
	)

	var bar_color: Color = (
		_height_bar_base_modulate.lerp(
			danger_color,
			danger_weight
		)
	)

	height_bar.modulate = bar_color

	var marker_color: Color = (
		_marker_base_modulate.lerp(
			danger_color,
			danger_weight
		)
	)

	marker_color.a *= _get_marker_blink_multiplier()

	player_marker.modulate = marker_color


func _get_marker_blink_multiplier() -> float:
	if not _is_critical:
		return 1.0

	var blink_speed_hz: float = lerpf(
		critical_blink_min_hz,
		critical_blink_max_hz,
		_current_progress
	)

	var blink_wave: float = (
		sin(
			_blink_time_s
			* TAU
			* blink_speed_hz
		)
		* 0.5
		+ 0.5
	)

	return lerpf(
		critical_marker_min_alpha,
		1.0,
		blink_wave
	)
