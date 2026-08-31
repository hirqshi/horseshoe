class_name DashAction
extends MovementAction

@export var config: DashConfig

signal charges_changed(
	current_charges: int,
	max_charges: int
)

var _motor: MovementMotor
var _charges: int = 0
var _remaining_time_s: float = 0.0
var _dash_velocity: Vector3 = Vector3.ZERO

func setup(motor: MovementMotor) -> void:
	_motor = motor

	if config == null:
		push_error("DashAction requires DashConfig.")
		set_process(false)
		return

	_set_charges(
		config.max_charges
	)

	_motor.landed.connect(_on_motor_landed)
	_motor.wall_touched.connect(_on_motor_wall_touched)
	_motor.wall_jumped.connect(_on_motor_wall_jumped)

func _on_motor_wall_jumped() -> void:
	_set_charges(
		config.max_charges
	)

func can_start(context: MovementContext) -> bool:
	return (
		not context.is_grounded
		and context.player_input.is_walk_just_pressed
		and _charges > 0
	)

func start(context: MovementContext) -> void:
	_set_charges(
		_charges - 1
	)
	_remaining_time_s = config.duration_s

	var dash_direction: Vector3 = -context.view_pivot.global_basis.z
	dash_direction = dash_direction.normalized()

	var current_speed_mps: float = context.velocity.length()
	var dash_speed_mps: float = minf(
		maxf(
			current_speed_mps,
			config.minimum_speed_mps
		) + config.speed_bonus_mps,
		config.max_speed_mps
	)

	_dash_velocity = dash_direction * dash_speed_mps
	context.velocity = _dash_velocity
	_motor.dash_started.emit()

func physics_tick(context: MovementContext) -> bool:
	_remaining_time_s -= context.delta
	context.velocity = _dash_velocity

	return _remaining_time_s > 0.0

func finish(_context: MovementContext) -> void:
	_remaining_time_s = 0.0

func _on_motor_landed(_impact_speed_mps: float) -> void:
	_set_charges(
		config.max_charges
	)

func _on_motor_wall_touched() -> void:
	_set_charges(
		config.max_charges
	)

func get_charges() -> int:
	return _charges


func get_max_charges() -> int:
	if config == null:
		return 0

	return config.max_charges


func _set_charges(value: int) -> void:
	if config == null:
		return

	var next_charges: int = clampi(
		value,
		0,
		config.max_charges
	)

	if next_charges == _charges:
		return

	_charges = next_charges

	charges_changed.emit(
		_charges,
		config.max_charges
	)
