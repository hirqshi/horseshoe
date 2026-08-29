class_name FallDangerHud
extends HudElement

@export_category("references")
@export var content: Control
@export var height_bar: TextureRect
@export var player_marker: TextureRect

@export_category("placement")
@export var marker_offset_px: Vector2 = Vector2(10.0, 0.0)

@export_category("fade")
@export_range(0.0, 2.0, 0.01, "suffix:s") var fade_in_duration_s: float = 0.12
@export_range(0.0, 2.0, 0.01, "suffix:s") var fade_out_duration_s: float = 0.18

@export_category("danger colors")
@export var danger_color: Color = Color(1.0, 0.08, 0.04, 1.0)
@export_range(0.0, 1.0, 0.01) var danger_color_start_progress: float = 0.65
@export_range(0.0, 1.0, 0.01) var danger_color_strength: float = 1.0

@export_category("critical blink")
@export_range(0.1, 60.0, 0.1, "suffix:hz") var critical_blink_min_hz: float = 5.0
@export_range(0.1, 60.0, 0.1, "suffix:hz") var critical_blink_max_hz: float = 15.0
@export_range(0.0, 1.0, 0.01) var critical_marker_min_alpha: float = 0.15

var _fall_tracker: FallTracker

var _content_base_modulate: Color
var _height_bar_base_modulate: Color
var _marker_base_modulate: Color

var _is_visible_for_fall: bool = false
var _current_progress: float = 0.0
var _is_critical: bool = false
var _blink_time_s: float = 0.0

var _fade_tween: Tween

func _ready() -> void:
	super()

	if content == null:
		push_error("FallDangerHud requires Content.")
		set_process(false)
		return

	if height_bar == null:
		push_error("FallDangerHud requires HeightBar.")
		set_process(false)
		return

	if player_marker == null:
		push_error("FallDangerHud requires PlayerMarker.")
		set_process(false)
		return

	_content_base_modulate = content.modulate
	_height_bar_base_modulate = height_bar.modulate
	_marker_base_modulate = player_marker.modulate

	content.modulate.a = 0.0
	_update_visuals()

func _process(delta: float) -> void:
	super(delta)

	if not _is_visible_for_fall:
		return

	_blink_time_s += delta
	_update_visuals()

func set_fall_tracker(fall_tracker: FallTracker) -> void:
	if _fall_tracker == fall_tracker:
		return

	_disconnect_fall_tracker()
	_fall_tracker = fall_tracker

	if _fall_tracker == null:
		return

	_fall_tracker.fall_updated.connect(
		_on_fall_tracker_fall_updated
	)

	_fall_tracker.fall_ui_hidden.connect(
		_on_fall_tracker_fall_ui_hidden
	)

	_fall_tracker.fall_ended.connect(
		_on_fall_tracker_fall_ended
	)

func _on_fall_tracker_fall_updated(
	_fall_distance_m: float,
	fall_progress: float,
	_downward_speed_mps: float,
	_fall_time_s: float,
	is_critical: bool
) -> void:
	_current_progress = clampf(
		fall_progress,
		0.0,
		1.0
	)

	_is_critical = is_critical

	if not _is_visible_for_fall:
		_is_visible_for_fall = true
		_blink_time_s = 0.0
		_fade_content_to(
			_content_base_modulate.a,
			fade_in_duration_s
		)

	_update_visuals()

func _on_fall_tracker_fall_ui_hidden() -> void:
	_hide()

func _on_fall_tracker_fall_ended(
	_fall_distance_m: float,
	_impact_speed_mps: float
) -> void:
	_hide()

func _update_visuals() -> void:
	_update_marker_position()
	_update_colors()

func _update_marker_position() -> void:
	var bar_rect: Rect2 = height_bar.get_global_rect()
	var marker_size: Vector2 = player_marker.size

	var marker_x: float = (
		bar_rect.position.x
		+ bar_rect.size.x
		+ marker_offset_px.x
	)

	var marker_y: float = (
		bar_rect.position.y
		+ bar_rect.size.y * _current_progress
		- marker_size.y * 0.5
		+ marker_offset_px.y
	)

	player_marker.global_position = Vector2(
		marker_x,
		marker_y
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

func _hide() -> void:
	if not _is_visible_for_fall:
		return

	_is_visible_for_fall = false
	_is_critical = false
	_current_progress = 0.0
	_blink_time_s = 0.0

	_fade_content_to(
		0.0,
		fade_out_duration_s
	)

func _fade_content_to(
	target_alpha: float,
	duration_s: float
) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	var target_modulate: Color = content.modulate
	target_modulate.a = target_alpha

	if is_zero_approx(duration_s):
		content.modulate = target_modulate
		return

	_fade_tween = create_tween()

	_fade_tween.tween_property(
		content,
		"modulate",
		target_modulate,
		duration_s
	).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_OUT
	)

func _disconnect_fall_tracker() -> void:
	if _fall_tracker == null:
		return

	var update_callable: Callable = (
		_on_fall_tracker_fall_updated
	)

	if _fall_tracker.fall_updated.is_connected(
		update_callable
	):
		_fall_tracker.fall_updated.disconnect(
			update_callable
		)

	var hidden_callable: Callable = (
		_on_fall_tracker_fall_ui_hidden
	)

	if _fall_tracker.fall_ui_hidden.is_connected(
		hidden_callable
	):
		_fall_tracker.fall_ui_hidden.disconnect(
			hidden_callable
		)

	var ended_callable: Callable = (
		_on_fall_tracker_fall_ended
	)

	if _fall_tracker.fall_ended.is_connected(
		ended_callable
	):
		_fall_tracker.fall_ended.disconnect(
			ended_callable
		)
