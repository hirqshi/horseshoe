class_name SlideAction
extends MovementAction

@export var config: SlideConfig

var _motor: MovementMotor
var _slide_velocity: Vector3 = Vector3.ZERO

func setup(motor: MovementMotor) -> void:
	_motor = motor

	if config == null:
		push_error("SlideAction requires SlideConfig.")
		set_process(false)

func can_start(context: MovementContext) -> bool:
	var horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	return (
		context.is_grounded
		and context.player_input.is_slide_held
		and horizontal_speed_mps >= config.minimum_start_speed_mps
	)

func start(context: MovementContext) -> void:
	var current_horizontal: Vector3 = context.get_horizontal_velocity()
	var input_direction: Vector3 = context.get_wish_direction()
	var slide_direction: Vector3 = _get_slide_direction(
		current_horizontal,
		input_direction
	)

	var start_speed_mps: float = minf(
		maxf(
			current_horizontal.length(),
			config.minimum_slide_speed_mps
		) + config.start_speed_bonus_mps,
		config.max_slide_speed_mps
	)

	_slide_velocity = slide_direction * start_speed_mps
	_motor.stance.force_crouching()

func physics_tick(context: MovementContext) -> bool:
	if not context.player_input.is_slide_held:
		context.set_horizontal_velocity(_slide_velocity)
		return false

	if not context.is_grounded:
		context.set_horizontal_velocity(_slide_velocity)
		return false

	_apply_steering(context)
	_apply_slope_acceleration(context)
	_apply_deceleration(context)

	context.set_horizontal_velocity(_slide_velocity)

	return _slide_velocity.length() > config.end_speed_mps

func finish(context: MovementContext) -> void:
	_slide_velocity = Vector3.ZERO

	if context.player_input.is_slide_held:
		return

	_motor.stance.try_set_crouching(false)

func _get_slide_direction(
	current_horizontal: Vector3,
	input_direction: Vector3
) -> Vector3:
	if not input_direction.is_zero_approx():
		return input_direction.normalized()

	return current_horizontal.normalized()

func _apply_steering(context: MovementContext) -> void:
	var input_direction: Vector3 = context.get_wish_direction()

	if input_direction.is_zero_approx():
		return

	var current_speed_mps: float = _slide_velocity.length()
	var current_direction: Vector3 = _slide_velocity.normalized()

	var steering_weight: float = minf(
		config.steering_lerp_per_second * context.delta,
		1.0
	)

	var steered_direction: Vector3 = current_direction.lerp(
		input_direction,
		steering_weight
	).normalized()

	_slide_velocity = steered_direction * current_speed_mps

func _apply_slope_acceleration(context: MovementContext) -> void:
	var floor_normal: Vector3 = context.body.get_floor_normal()

	var downhill: Vector3 = (
		Vector3.DOWN
		- floor_normal * Vector3.DOWN.dot(floor_normal)
	)

	var downhill_horizontal: Vector3 = Vector3(
		downhill.x,
		0.0,
		downhill.z
	)

	if downhill_horizontal.is_zero_approx():
		return

	downhill_horizontal = downhill_horizontal.normalized()

	_slide_velocity += (
		downhill_horizontal
		* config.downhill_acceleration_mps2
		* context.delta
	)

	_slide_velocity = _slide_velocity.limit_length(
		config.max_slide_speed_mps
	)

func _apply_deceleration(context: MovementContext) -> void:
	_slide_velocity = _slide_velocity.move_toward(
		Vector3.ZERO,
		config.flat_deceleration_mps2 * context.delta
	)
