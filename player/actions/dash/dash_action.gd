class_name DashAction
extends MovementAction

@export var config: DashConfig

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

	_charges = config.max_charges
	_motor.landed.connect(_on_motor_landed)

func can_start(context: MovementContext) -> bool:
	return (
		not context.is_grounded
		and context.player_input.is_walk_just_pressed
		and _charges > 0
	)

func start(context: MovementContext) -> void:
	_charges -= 1
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

func physics_tick(context: MovementContext) -> bool:
	_remaining_time_s -= context.delta
	context.velocity = _dash_velocity

	return _remaining_time_s > 0.0

func finish(_context: MovementContext) -> void:
	_remaining_time_s = 0.0

func _on_motor_landed(_impact_speed_mps: float) -> void:
	_charges = config.max_charges
