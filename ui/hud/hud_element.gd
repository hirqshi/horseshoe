class_name HudElement
extends Control

@export_category("visibility")
@export var is_element_enabled: bool = true
@export var element_color: Color = Color.WHITE
@export_range(0.0, 1.0, 0.01) var element_alpha: float = 1.0

@export_category("camera lag")
@export var is_lag_enabled: bool = true
@export_range(0.0, 20.0, 0.001) var lag_sensitivity: float = 0.06
@export_range(0.0, 500.0, 0.1, "suffix:px") var lag_max_distance_px: float = 18.0
@export_range(0.1, 100.0, 0.1, "suffix:1/s") var lag_follow_speed: float = 24.0
@export_range(0.1, 100.0, 0.1, "suffix:1/s") var lag_return_speed: float = 12.0

var _base_position: Vector2 = Vector2.ZERO
var _lag_offset: Vector2 = Vector2.ZERO
var _lag_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_position = position
	_apply_visual_settings()

func _process(delta: float) -> void:
	_update_lag(delta)

func register_look_delta(mouse_delta: Vector2) -> void:
	if not is_element_enabled:
		return

	if not is_lag_enabled:
		return

	_lag_target = (
		_lag_target
		- mouse_delta * lag_sensitivity
	).limit_length(lag_max_distance_px)

func set_element_enabled(value: bool) -> void:
	is_element_enabled = value
	_apply_visual_settings()

func set_element_color(value: Color) -> void:
	element_color = value
	_apply_visual_settings()

func set_element_alpha(value: float) -> void:
	element_alpha = clampf(value, 0.0, 1.0)
	_apply_visual_settings()

func set_lag_enabled(value: bool) -> void:
	is_lag_enabled = value

	if not is_lag_enabled:
		_lag_target = Vector2.ZERO

func _update_lag(delta: float) -> void:
	if not is_element_enabled:
		return

	var is_returning: bool = _lag_target.is_zero_approx()

	var response_speed: float = (
		lag_return_speed
		if is_returning
		else lag_follow_speed
	)

	var response_weight: float = (
		1.0 - exp(-response_speed * delta)
	)

	_lag_offset = _lag_offset.lerp(
		_lag_target,
		response_weight
	)

	_lag_target = _lag_target.lerp(
		Vector2.ZERO,
		1.0 - exp(-lag_return_speed * delta)
	)

	position = _base_position + _lag_offset

func _apply_visual_settings() -> void:
	visible = is_element_enabled

	modulate = Color(
		element_color.r,
		element_color.g,
		element_color.b,
		element_color.a * element_alpha
	)
