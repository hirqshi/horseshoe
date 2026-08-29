class_name AirborneLocomotionState
extends LocomotionState

const ID: StringName = &"airborne"

func physics_tick(context: MovementContext) -> StringName:
	_apply_vertical_movement(context)
	_apply_horizontal_movement(context)

	return &""

func _apply_vertical_movement(context: MovementContext) -> void:
	context.velocity.y = maxf(
		context.velocity.y - context.config.gravity_mps2 * context.delta,
		-context.config.terminal_fall_speed_mps
	)

func _apply_horizontal_movement(context: MovementContext) -> void:
	var wish_direction: Vector3 = context.get_wish_direction()

	if wish_direction.is_zero_approx():
		return

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity()
	)

	var target_speed_mps: float = (
		context.get_target_speed_mps(true)
	)

	var target_velocity: Vector3 = (
		wish_direction * target_speed_mps
	)

	var accelerated_velocity: Vector3 = (
		horizontal_velocity.move_toward(
			target_velocity,
			context.config.air_control_acceleration_mps2
			* context.delta
		)
	)

	context.set_horizontal_velocity(accelerated_velocity)
