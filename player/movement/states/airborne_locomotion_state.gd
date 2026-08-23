class_name AirborneLocomotionState
extends LocomotionState

const ID: StringName = &"airborne"
const GROUNDED_STATE_ID: StringName = &"grounded"

func physics_tick(context: MovementContext) -> StringName:
	_apply_vertical_movement(context)
	_apply_horizontal_movement(context)

	if context.is_grounded:
		return GROUNDED_STATE_ID

	return &""

func _apply_vertical_movement(context: MovementContext) -> void:
	context.velocity.y = maxf(
		context.velocity.y - context.config.gravity_mps2 * context.delta,
		-context.config.terminal_fall_speed_mps
	)

func _apply_horizontal_movement(context: MovementContext) -> void:
	var wish_direction: Vector3 = context.get_wish_direction()
	var target_horizontal: Vector3 = (
		wish_direction
		* context.get_target_speed_mps()
		* context.config.air_control
	)

	var has_move_input: bool = not wish_direction.is_zero_approx()
	var acceleration_mps2: float = (
		context.config.air_acceleration_mps2
		if has_move_input
		else context.config.air_deceleration_mps2
	)

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity().move_toward(
			target_horizontal,
			acceleration_mps2 * context.delta
		)
	)

	context.set_horizontal_velocity(horizontal_velocity)
