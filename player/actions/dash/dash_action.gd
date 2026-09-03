class_name DashAction
extends MovementAction

signal charges_changed(
	current_charges: int,
	max_charges: int
)
signal dash_landed(
	dash_velocity: Vector3
)
signal dash_failed()

@export var config: DashConfig

var _motor: MovementMotor

var _charges: int = 0
var _remaining_time_s: float = 0.0
var _cooldown_until_s: float = -INF

var _dash_velocity: Vector3 = Vector3.ZERO
var _is_dashing: bool = false


func setup(motor: MovementMotor) -> void:
	_motor = motor

	if config == null:
		push_error(
			"DashAction requires DashConfig."
		)
		set_process(false)
		return

	_set_charges(
		config.max_charges,
		false
	)

	_motor.landed.connect(
		_on_motor_landed
	)

	_motor.wall_touched.connect(
		_on_motor_wall_touched
	)

	_motor.wall_jumped.connect(
		_on_motor_wall_jumped
	)


func can_start(
	context: MovementContext
) -> bool:
	if context.is_grounded:
		return false

	if not context.player_input.is_walk_just_pressed:
		return false

	var has_charges: bool = _charges > 0

	var is_on_cooldown: bool = (
		context.time_s
		< _cooldown_until_s
	)

	if not has_charges or is_on_cooldown:
		dash_failed.emit()
		return false

	return true


func start(
	context: MovementContext
) -> void:
	_set_charges(
		_charges - 1,
		false
	)

	_remaining_time_s = config.duration_s
	_is_dashing = true
	
	_cooldown_until_s = (
		context.time_s
		+ config.cooldown_s
	)

	var dash_direction: Vector3 = (
		-context.view_pivot.global_basis.z
	)

	dash_direction = dash_direction.normalized()

	var current_speed_mps: float = (
		context.velocity.length()
	)

	var dash_speed_mps: float = (
		maxf(
			current_speed_mps,
			config.minimum_speed_mps
		)
		+ config.speed_bonus_mps
	)

	_dash_velocity = dash_direction * dash_speed_mps

	context.velocity = _dash_velocity

	_motor.dash_started.emit()


func physics_tick(
	context: MovementContext
) -> bool:
	_remaining_time_s -= context.delta

	context.velocity = _dash_velocity

	return _remaining_time_s > 0.0


func finish(
	_context: MovementContext
) -> void:
	_remaining_time_s = 0.0
	_is_dashing = false


func get_charges() -> int:
	return _charges


func get_max_charges() -> int:
	if config == null:
		return 0

	return config.max_charges


func is_on_cooldown(
	current_time_s: float
) -> bool:
	return current_time_s < _cooldown_until_s


func _on_motor_landed(
	_impact_speed_mps: float
) -> void:
	if _is_dashing:
		dash_landed.emit(
			_dash_velocity
		)

	_restore_all_charges()


func _on_motor_wall_touched() -> void:
	_restore_all_charges()


func _on_motor_wall_jumped() -> void:
	_restore_all_charges()


func restore_charges(
	amount: int,
	resets_cooldown: bool = true
) -> int:
	if amount <= 0:
		return 0

	var previous_charges: int = _charges

	if resets_cooldown:
		_cooldown_until_s = -INF

	_set_charges(
		_charges + amount,
		false
	)

	return _charges - previous_charges


func _restore_all_charges() -> void:
	if config == null:
		return

	_set_charges(
		config.max_charges,
		true
	)


func _set_charges(
	value: int,
	can_reset_cooldown: bool
) -> void:
	if config == null:
		return

	var previous_charges: int = _charges

	var next_charges: int = clampi(
		value,
		0,
		config.max_charges
	)

	if next_charges == previous_charges:
		return

	_charges = next_charges

	var has_restored_charge: bool = (
		_charges > previous_charges
	)

	if can_reset_cooldown \
	and has_restored_charge \
	and config.reset_cooldown_on_charge_restore:
		_cooldown_until_s = -INF

	charges_changed.emit(
		_charges,
		config.max_charges
	)

func get_wave_dash_window_s() -> float:
	if config == null:
		return 0.0

	return config.wave_dash_window_s


func get_wave_dash_minimum_normal_impact_speed_mps() -> float:
	if config == null:
		return INF

	return config.wave_dash_minimum_normal_impact_speed_mps


func get_wave_dash_velocity_retention() -> float:
	if config == null:
		return 0.0

	return config.wave_dash_velocity_retention


func get_walk_input_suppression_after_landing_s() -> float:
	if config == null:
		return 0.0

	return config.walk_input_suppression_after_landing_s
