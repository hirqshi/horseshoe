class_name AirborneLocomotionState
extends LocomotionState

const ID: StringName = &"airborne"

var _airborne_elapsed_s: float = 0.0
var _current_grace_duration_s: float = 0.0


func enter(
	context: MovementContext
) -> void:
	_refresh_momentum_grace(
		context
	)


func physics_tick(
	context: MovementContext
) -> StringName:
	_airborne_elapsed_s += context.delta

	_apply_vertical_movement(context)
	_apply_horizontal_movement(context)
	_apply_excess_speed_decay(context)

	return &""


func _apply_vertical_movement(
	context: MovementContext
) -> void:
	context.velocity.y = maxf(
		context.velocity.y
		- context.config.gravity_mps2
		* context.delta,
		-context.config.terminal_fall_speed_mps
	)


func _apply_horizontal_movement(
	context: MovementContext
) -> void:
	var wish_direction: Vector3 = (
		context.get_wish_direction()
	)

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity()
	)

	var horizontal_speed_mps: float = (
		horizontal_velocity.length()
	)

	var target_speed_mps: float = (
		context.get_target_speed_mps(true)
	)

	if wish_direction.is_zero_approx():
		return

	if horizontal_speed_mps < target_speed_mps:
		var target_velocity: Vector3 = (
			wish_direction
			* target_speed_mps
		)

		var accelerated_velocity: Vector3 = (
			horizontal_velocity.move_toward(
				target_velocity,
				context.config.air_control_acceleration_mps2
				* context.delta
			)
		)

		context.set_horizontal_velocity(
			accelerated_velocity
		)

		return

	if horizontal_velocity.is_zero_approx():
		return

	var current_direction: Vector3 = (
		horizontal_velocity.normalized()
	)

	var steering_weight: float = minf(
		(
			context.config.air_control_acceleration_mps2
			/ maxf(
				horizontal_speed_mps,
				0.001
			)
		)
		* context.delta,
		1.0
	)

	var steered_direction: Vector3 = (
		current_direction.slerp(
			wish_direction,
			steering_weight
		)
	).normalized()

	context.set_horizontal_velocity(
		steered_direction
		* horizontal_speed_mps
	)


func _apply_excess_speed_decay(
	context: MovementContext
) -> void:
	if _airborne_elapsed_s < _current_grace_duration_s:
		return

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity()
	)

	var horizontal_speed_mps: float = (
		horizontal_velocity.length()
	)

	if horizontal_velocity.is_zero_approx():
		return

	var target_speed_mps: float = (
		context.get_target_speed_mps(true)
	)

	if horizontal_speed_mps <= target_speed_mps:
		return

	var excess_speed_mps: float = (
		horizontal_speed_mps
		- target_speed_mps
	)

	var normalized_excess_speed: float = (
		excess_speed_mps
		/ maxf(
			context.config.air_excess_speed_reference_mps,
			0.001
		)
	)

	var speed_decay_mps2: float = (
		context.config.air_excess_speed_decay_at_reference_mps2
		* pow(
			normalized_excess_speed,
			context.config.air_excess_speed_decay_exponent
		)
	)

	var decayed_speed_mps: float = maxf(
		target_speed_mps,
		horizontal_speed_mps
		- speed_decay_mps2
		* context.delta
	)

	context.set_horizontal_velocity(
		horizontal_velocity.normalized()
		* decayed_speed_mps
	)


func refresh_momentum_grace(
	context: MovementContext
) -> void:
	_refresh_momentum_grace(
		context
	)


func _refresh_momentum_grace(
	context: MovementContext
) -> void:
	_airborne_elapsed_s = 0.0

	var horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	var target_speed_mps: float = (
		context.get_target_speed_mps(true)
	)

	var excess_speed_mps: float = maxf(
		0.0,
		horizontal_speed_mps
		- target_speed_mps
	)

	var exponential_multiplier: float = exp(
		-excess_speed_mps
		* context.config.air_momentum_grace_exponential_decay
	)

	_current_grace_duration_s = maxf(
		context.config.air_momentum_grace_min_duration_s,
		context.config.air_momentum_grace_duration_s
		* exponential_multiplier
	)
