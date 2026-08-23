class_name CrouchAction
extends MovementAction

@export var max_start_speed_mps: float = 4.0
@export var crouch_max_speed_mps: float = 3.5
@export var crouch_deceleration_mps2: float = 48.0

var _motor: MovementMotor

func setup(motor: MovementMotor) -> void:
	_motor = motor

func can_start(context: MovementContext) -> bool:
	var horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	return (
		context.is_grounded
		and context.player_input.is_slide_held
		and horizontal_speed_mps <= max_start_speed_mps
	)

func start(_context: MovementContext) -> void:
	_motor.stance.try_set_crouching(true)

func physics_tick(context: MovementContext) -> bool:
	if not context.player_input.is_slide_held:
		return false

	_limit_horizontal_speed(context)
	return true

func finish(_context: MovementContext) -> void:
	_motor.stance.try_set_crouching(false)

func _limit_horizontal_speed(context: MovementContext) -> void:
	var horizontal_velocity: Vector3 = context.get_horizontal_velocity()
	var current_speed_mps: float = horizontal_velocity.length()

	if current_speed_mps <= crouch_max_speed_mps:
		return

	var target_velocity: Vector3 = (
		horizontal_velocity.normalized() * crouch_max_speed_mps
	)

	horizontal_velocity = horizontal_velocity.move_toward(
		target_velocity,
		crouch_deceleration_mps2 * context.delta
	)

	context.set_horizontal_velocity(horizontal_velocity)
