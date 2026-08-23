class_name GroundingAction
extends MovementAction

signal grounding_landed(impact_speed_mps: float)

@export var config: GroundingConfig

var _motor: MovementMotor
var _remaining_time_s: float = 0.0
var _grounding_horizontal_velocity: Vector3 = Vector3.ZERO
var _is_active: bool = false

func setup(motor: MovementMotor) -> void:
	_motor = motor

	if config == null:
		push_error("GroundingAction requires GroundingConfig.")
		set_process(false)
		return

	_motor.landed.connect(_on_motor_landed)

func can_start(context: MovementContext) -> bool:
	return (
		not context.is_grounded
		and context.player_input.is_slide_pressed
	)

func start(context: MovementContext) -> void:
	_remaining_time_s = config.duration_s
	_is_active = true

	_grounding_horizontal_velocity = (
		context.get_horizontal_velocity()
		* config.horizontal_velocity_retention
	)

	context.set_horizontal_velocity(_grounding_horizontal_velocity)
	context.velocity.y = minf(
		context.velocity.y,
		-config.downward_speed_mps
	)

func physics_tick(context: MovementContext) -> bool:
	if context.is_grounded:
		return false

	_remaining_time_s -= context.delta

	context.set_horizontal_velocity(_grounding_horizontal_velocity)
	context.velocity.y = minf(
		context.velocity.y,
		-config.downward_speed_mps
	)

	return _remaining_time_s > 0.0

func finish(_context: MovementContext) -> void:
	_remaining_time_s = 0.0
	_is_active = false

func _on_motor_landed(impact_speed_mps: float) -> void:
	if not _is_active:
		return

	grounding_landed.emit(impact_speed_mps)
