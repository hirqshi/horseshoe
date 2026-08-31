class_name ChargeIcon
extends TextureRect

@export_category("alpha")
@export_range(0.0, 1.0, 0.01) var default_alpha: float = 0.75
@export_range(0.0, 1.0, 0.01) var unavailable_alpha: float = 0.22
@export_range(0.0, 1.0, 0.01) var empty_alpha: float = 0.0
@export_range(0.0, 1.0, 0.01) var pulse_alpha: float = 1.0

@export_category("pulse")
@export_range(1.0, 3.0, 0.01) var pulse_scale: float = 1.2
@export_range(0.01, 1.0, 0.01, "suffix:s") var pulse_in_duration: float = 0.06
@export_range(0.01, 1.0, 0.01, "suffix:s") var pulse_out_duration: float = 0.13

@export_category("transition")
@export_range(0.01, 1.0, 0.01, "suffix:s") var alpha_transition_duration: float = 0.12

var _base_self_modulate: Color = Color.WHITE
var _base_scale: Vector2 = Vector2.ONE

var _current_alpha: float = 1.0
var _state_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_base_self_modulate = self_modulate
	_base_scale = scale

	_set_alpha(default_alpha)


func set_charge_state(
	has_charge: bool,
	is_move_available: bool,
	should_pulse: bool
) -> void:
	var target_alpha: float = _get_target_alpha(
		has_charge,
		is_move_available
	)

	if should_pulse:
		_play_pulse_to(target_alpha)
		return

	_tween_to(
		target_alpha,
		alpha_transition_duration
	)


func _get_target_alpha(
	has_charge: bool,
	is_move_available: bool
) -> float:
	if not has_charge:
		return empty_alpha

	if not is_move_available:
		return unavailable_alpha

	return default_alpha


func _play_pulse_to(
	target_alpha: float
) -> void:
	_kill_state_tween()

	_state_tween = create_tween()

	var grow_tween: Tween = _state_tween.set_parallel(
		true
	)

	grow_tween.tween_method(
		_set_alpha,
		_current_alpha,
		pulse_alpha,
		pulse_in_duration
	)

	grow_tween.tween_property(
		self,
		"scale",
		_base_scale * pulse_scale,
		pulse_in_duration
	)

	var settle_tween: Tween = _state_tween.chain().set_parallel(
		true
	)

	settle_tween.tween_method(
		_set_alpha,
		pulse_alpha,
		target_alpha,
		pulse_out_duration
	)

	settle_tween.tween_property(
		self,
		"scale",
		_base_scale,
		pulse_out_duration
	)


func _tween_to(
	target_alpha: float,
	duration: float
) -> void:
	_kill_state_tween()

	if is_equal_approx(
		_current_alpha,
		target_alpha
	):
		return

	_state_tween = create_tween()

	_state_tween.tween_method(
		_set_alpha,
		_current_alpha,
		target_alpha,
		duration
	)


func _set_alpha(
	alpha: float
) -> void:
	_current_alpha = clampf(
		alpha,
		0.0,
		1.0
	)

	self_modulate = Color(
		_base_self_modulate.r,
		_base_self_modulate.g,
		_base_self_modulate.b,
		_base_self_modulate.a * _current_alpha
	)


func _kill_state_tween() -> void:
	if _state_tween != null:
		_state_tween.kill()
		_state_tween = null
