class_name CrosshairHudElement
extends Control

@export_category("references")
@export var center_dot_group: HudElement
@export var primary_crosshair_group: HudElement
@export var upper_segment: TextureRect
@export var right_segment: TextureRect
@export var left_segment: TextureRect

@export_category("spread directions")
@export var upper_spread_direction: Vector2 = Vector2(0.0, -1.0)
@export var right_spread_direction: Vector2 = Vector2(0.866, 0.5)
@export var left_spread_direction: Vector2 = Vector2(-0.866, 0.5)

@export_category("speed spread")
@export_range(0.0, 500.0, 0.1, "suffix:px") var max_speed_spread_px: float = 30.0
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var speed_spread_cap_mps: float = 12.0
@export_range(0.0, 5.0, 0.01, "suffix:m/s") var speed_spread_deadzone_mps: float = 0.1
@export_range(0.1, 1000.0, 0.1, "suffix:px/s") var spread_expand_speed_px_s: float = 180.0
@export_range(0.1, 1000.0, 0.1, "suffix:px/s") var spread_return_speed_px_s: float = 240.0

@export_category("adaptive spread")
@export_range(0.0, 1.0, 0.01) var stable_speed_spread_multiplier: float = 0.72
@export_range(0.0, 1.0, 0.01) var speed_change_threshold: float = 0.025
@export_range(0.1, 100.0, 0.1, "suffix:1/s") var speed_change_decay_speed: float = 2.5

@export_category("action spread impulses")
@export_range(0.0, 500.0, 0.1, "suffix:px") var dash_impulse_spread_px: float = 17.0
@export_range(0.1, 1000.0, 0.1, "suffix:px/s") var dash_impulse_return_speed_px_s: float = 85.0
@export_range(0.0, 500.0, 0.1, "suffix:px") var slide_impulse_spread_px: float = 8.0
@export_range(0.1, 1000.0, 0.1, "suffix:px/s") var slide_impulse_return_speed_px_s: float = 55.0
@export_range(0.0, 1000.0, 0.1, "suffix:px") var max_total_spread_px: float = 65.0

var _body: Player

var _upper_base_position: Vector2 = Vector2.ZERO
var _right_base_position: Vector2 = Vector2.ZERO
var _left_base_position: Vector2 = Vector2.ZERO

var _current_speed_spread_px: float = 0.0
var _previous_speed_ratio: float = 0.0
var _speed_change_impulse: float = 0.0

var _action_impulse_spread_px: float = 0.0
var _action_impulse_return_speed_px_s: float = 0.0

@export var is_debug_enabled: bool = false

var _next_debug_time_s: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if center_dot_group == null:
		push_error("CrosshairHudElement requires CenterDotGroup.")
		set_process(false)
		return

	if primary_crosshair_group == null:
		push_error(
			"CrosshairHudElement requires PrimaryCrosshairGroup."
		)
		set_process(false)
		return

	if upper_segment == null:
		push_error("CrosshairHudElement requires UpperSegment.")
		set_process(false)
		return

	if right_segment == null:
		push_error("CrosshairHudElement requires RightSegment.")
		set_process(false)
		return

	if left_segment == null:
		push_error("CrosshairHudElement requires LeftSegment.")
		set_process(false)
		return

	_upper_base_position = upper_segment.position
	_right_base_position = right_segment.position
	_left_base_position = left_segment.position

func _process(delta: float) -> void:
	if _body == null:
		return
	_update_speed_spread(delta)
	_update_action_impulse(delta)
	_apply_speed_spread()

func set_player(player: Player) -> void:
	_body = player

func register_look_delta(mouse_delta: Vector2) -> void:
	center_dot_group.register_look_delta(mouse_delta)
	primary_crosshair_group.register_look_delta(mouse_delta)

func _update_speed_spread(delta: float) -> void:
	var horizontal_speed_mps: float = Vector2(
		_body.velocity.x,
		_body.velocity.z
	).length()

	var spread_speed_mps: float = horizontal_speed_mps

	if not _body.is_on_floor():
		spread_speed_mps = _body.velocity.length()

	var speed_ratio: float = 0.0

	if spread_speed_mps > speed_spread_deadzone_mps:
		var usable_speed_range_mps: float = maxf(
			speed_spread_cap_mps
			- speed_spread_deadzone_mps,
			0.001
		)

		speed_ratio = clampf(
			(
				spread_speed_mps
				- speed_spread_deadzone_mps
			)
			/ usable_speed_range_mps,
			0.0,
			1.0
		)

	var target_speed_spread_px: float = (
		max_speed_spread_px * speed_ratio
	)

	var transition_speed_px_s: float = (
		spread_return_speed_px_s
	)

	if target_speed_spread_px > _current_speed_spread_px:
		transition_speed_px_s = spread_expand_speed_px_s

	_current_speed_spread_px = move_toward(
		_current_speed_spread_px,
		target_speed_spread_px,
		transition_speed_px_s * delta
	)

	var speed_ratio_delta: float = absf(
		speed_ratio - _previous_speed_ratio
	)

	if speed_ratio_delta >= speed_change_threshold:
		_speed_change_impulse = 1.0

	_speed_change_impulse = move_toward(
		_speed_change_impulse,
		0.0,
		speed_change_decay_speed * delta
	)

	_previous_speed_ratio = speed_ratio
	_debug_spread(
		spread_speed_mps,
		speed_ratio,
		target_speed_spread_px
	)

func _apply_speed_spread() -> void:
	var stable_spread_px: float = (
		_current_speed_spread_px
		* stable_speed_spread_multiplier
	)

	var adaptive_spread_px: float = (
		_current_speed_spread_px
		* (1.0 - stable_speed_spread_multiplier)
		* _speed_change_impulse
	)

	var total_dynamic_spread_px: float = minf(
		stable_spread_px
		+ adaptive_spread_px
		+ _action_impulse_spread_px,
		max_total_spread_px
	)

	upper_segment.position = (
		_upper_base_position
		+ upper_spread_direction.normalized()
		* total_dynamic_spread_px
	)

	right_segment.position = (
		_right_base_position
		+ right_spread_direction.normalized()
		* total_dynamic_spread_px
	)

	left_segment.position = (
		_left_base_position
		+ left_spread_direction.normalized()
		* total_dynamic_spread_px
	)

func play_dash_impulse() -> void:
	_play_action_impulse(
		dash_impulse_spread_px,
		dash_impulse_return_speed_px_s
	)

func play_slide_impulse() -> void:
	_play_action_impulse(
		slide_impulse_spread_px,
		slide_impulse_return_speed_px_s
	)

func _play_action_impulse(
	spread_px: float,
	return_speed_px_s: float
) -> void:
	_action_impulse_spread_px = maxf(
		_action_impulse_spread_px,
		spread_px
	)

	_action_impulse_return_speed_px_s = maxf(
		_action_impulse_return_speed_px_s,
		return_speed_px_s
	)

func _update_action_impulse(delta: float) -> void:
	if _action_impulse_spread_px <= 0.0:
		return

	_action_impulse_spread_px = move_toward(
		_action_impulse_spread_px,
		0.0,
		_action_impulse_return_speed_px_s * delta
	)

	if _action_impulse_spread_px <= 0.0:
		_action_impulse_return_speed_px_s = 0.0

func _debug_spread(
	spread_speed_mps: float,
	speed_ratio: float,
	target_spread_px: float
) -> void:
	if not is_debug_enabled:
		return

	var current_time_s: float = (
		Time.get_ticks_msec() * 0.001
	)

	if current_time_s < _next_debug_time_s:
		return

	_next_debug_time_s = current_time_s + 0.25

	print(
		"CROSSHAIR"
		+ " | player_path: %s"
		% [_body.get_path()]
		+ " | floor: %s"
		% [_body.is_on_floor()]
		+ " | velocity: %s"
		% [_body.velocity]
		+ " | spread_speed: %.3f"
		% [spread_speed_mps]
		+ " | ratio: %.3f"
		% [speed_ratio]
		+ " | target_px: %.3f"
		% [target_spread_px]
		+ " | current_px: %.3f"
		% [_current_speed_spread_px]
	)
