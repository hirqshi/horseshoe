class_name HudElement
extends Control

@export_category("settings")
@export var settings_id: StringName = &"":
	set(value):
		settings_id = value

		if is_inside_tree():
			_connect_settings()
			_apply_settings_visibility()

@export_category("visibility")
@export var is_element_enabled: bool = true
@export var element_color: Color = Color.WHITE

@export_range(
	0.0,
	1.0,
	0.01
) var element_alpha: float = 1.0

@export_category("camera motion")
@export var is_lag_enabled: bool = true

# -1.0 = trails camera
# 0.0 = static
# 1.0 = leads camera
@export_range(
	-1.0,
	1.0,
	0.01
) var look_offset_multiplier: float = -1.0

@export_range(
	0.0,
	20.0,
	0.001
) var lag_sensitivity: float = 0.06

@export_range(
	0.0,
	500.0,
	0.1,
	"suffix:px"
) var lag_max_distance_px: float = 18.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var lag_follow_speed: float = 24.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var lag_return_speed: float = 12.0

var _base_position: Vector2 = Vector2.ZERO
var _lag_offset: Vector2 = Vector2.ZERO
var _lag_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_base_position = position

	_connect_settings()
	_apply_settings_visibility()
	_apply_visual_settings()


func _process(delta: float) -> void:
	_update_lag(delta)


func register_look_delta(
	mouse_delta: Vector2
) -> void:
	if not is_element_enabled:
		return

	if not is_lag_enabled:
		return

	if is_zero_approx(
		look_offset_multiplier
	):
		return

	_lag_target = (
		_lag_target
		+ mouse_delta
		* lag_sensitivity
		* look_offset_multiplier
	).limit_length(
		lag_max_distance_px
	)


func set_element_enabled(
	value: bool
) -> void:
	is_element_enabled = value

	_apply_visual_settings()


func set_element_color(
	value: Color
) -> void:
	element_color = value

	_apply_visual_settings()


func set_element_alpha(
	value: float
) -> void:
	element_alpha = clampf(
		value,
		0.0,
		1.0
	)

	_apply_visual_settings()


func set_lag_enabled(
	value: bool
) -> void:
	is_lag_enabled = value

	if not is_lag_enabled:
		_lag_target = Vector2.ZERO
		_lag_offset = Vector2.ZERO
		position = _base_position


func reset_camera_motion() -> void:
	_lag_target = Vector2.ZERO
	_lag_offset = Vector2.ZERO

	position = _base_position


func _update_lag(
	delta: float
) -> void:
	if not is_element_enabled:
		return

	if not is_lag_enabled:
		return

	if is_zero_approx(
		look_offset_multiplier
	):
		_lag_target = Vector2.ZERO
		_lag_offset = Vector2.ZERO
		position = _base_position
		return

	var is_returning: bool = _lag_target.is_zero_approx()

	var response_speed: float = (
		lag_return_speed
		if is_returning
		else lag_follow_speed
	)

	var response_weight: float = (
		1.0
		- exp(
			-response_speed
			* delta
		)
	)

	_lag_offset = _lag_offset.lerp(
		_lag_target,
		response_weight
	)

	var return_weight: float = (
		1.0
		- exp(
			-lag_return_speed
			* delta
		)
	)

	_lag_target = _lag_target.lerp(
		Vector2.ZERO,
		return_weight
	)

	position = _base_position + _lag_offset


func _apply_visual_settings() -> void:
	visible = is_element_enabled

	modulate = Color(
		element_color.r,
		element_color.g,
		element_color.b,
		element_color.a
		* element_alpha
	)


func _connect_settings() -> void:
	if settings_id == &"":
		return

	if GameSettings == null:
		return

	if not GameSettings.hud_element_visibility_changed.is_connected(
		_on_hud_element_visibility_changed
	):
		GameSettings.hud_element_visibility_changed.connect(
			_on_hud_element_visibility_changed
		)


func _apply_settings_visibility() -> void:
	if settings_id == &"":
		return

	if GameSettings == null:
		return

	set_element_enabled(
		GameSettings.is_hud_element_enabled(
			settings_id
		)
	)


func _on_hud_element_visibility_changed(
	element_id: StringName,
	is_enabled: bool
) -> void:
	if element_id != settings_id:
		return

	set_element_enabled(
		is_enabled
	)
