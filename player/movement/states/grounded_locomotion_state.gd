class_name GroundedLocomotionState
extends LocomotionState

const ID: StringName = &"grounded"
const AIRBORNE_STATE_ID: StringName = &"airborne"

func physics_tick(context: MovementContext) -> StringName:
	_apply_vertical_movement(context)
	_apply_horizontal_movement(context)

	if not context.is_grounded:
		return AIRBORNE_STATE_ID

	return &""

func _apply_vertical_movement(context: MovementContext) -> void:
	if context.velocity.y < 0.0:
		context.velocity.y = -0.1

func _apply_horizontal_movement(context: MovementContext) -> void:
	var wish_direction: Vector3 = context.get_wish_direction()
	var target_horizontal: Vector3 = (
		wish_direction * context.get_target_speed_mps()
	)

	var has_move_input: bool = not wish_direction.is_zero_approx()
	var acceleration_mps2: float = (
		context.config.ground_acceleration_mps2
		if has_move_input
		else context.config.ground_deceleration_mps2
	)

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity().move_toward(
			target_horizontal,
			acceleration_mps2 * context.delta
		)
	)

	context.set_horizontal_velocity(horizontal_velocity)
