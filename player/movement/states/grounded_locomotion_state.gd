class_name GroundedLocomotionState
extends LocomotionState

const ID: StringName = &"grounded"

var _continuous_run_elapsed_s: float = 0.0
var _continuous_run_bonus_speed_mps: float = 0.0


func enter(
	_context: MovementContext
) -> void:
	_continuous_run_elapsed_s = 0.0
	_continuous_run_bonus_speed_mps = 0.0


func physics_tick(
	context: MovementContext
) -> StringName:
	_apply_vertical_movement(context)
	_apply_horizontal_movement(context)

	return &""


func _apply_vertical_movement(
	context: MovementContext
) -> void:
	if context.velocity.y < 0.0:
		context.velocity.y = -0.1


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

	var has_move_input: bool = (
		not wish_direction.is_zero_approx()
	)

	if not has_move_input:
		_reset_continuous_run()

		var decelerated_velocity: Vector3 = (
			horizontal_velocity.move_toward(
				Vector3.ZERO,
				context.config.ground_speed_decay_mps2
				* context.delta
			)
		)

		context.set_horizontal_velocity(
			decelerated_velocity
		)

		return

	var base_target_speed_mps: float = (
		context.get_target_speed_mps()
	)

	var continuous_target_speed_mps: float = (
		base_target_speed_mps
		+ _continuous_run_bonus_speed_mps
	)

	var maximum_speed_for_continuous_run_mps: float = (
		continuous_target_speed_mps
		+ context.config.continuous_run_entry_tolerance_mps
	)

	var can_build_continuous_speed: bool = (
		not context.player_input.is_walk_pressed
		and horizontal_speed_mps
		>= base_target_speed_mps
		and horizontal_speed_mps
		<= maximum_speed_for_continuous_run_mps
	)

	if can_build_continuous_speed:
		_continuous_run_elapsed_s += context.delta

		if _continuous_run_elapsed_s >= (
			context.config.continuous_run_delay_s
		):
			_continuous_run_bonus_speed_mps += (
				context.config.continuous_run_acceleration_mps2
				* context.delta
			)
	else:
		_continuous_run_elapsed_s = 0.0

	if horizontal_speed_mps < continuous_target_speed_mps:
		var target_velocity: Vector3 = (
			wish_direction
			* continuous_target_speed_mps
		)

		var accelerated_velocity: Vector3 = (
			horizontal_velocity.move_toward(
				target_velocity,
				context.config.ground_acceleration_mps2
				* context.delta
			)
		)

		context.set_horizontal_velocity(
			accelerated_velocity
		)

		return

	if horizontal_velocity.is_zero_approx():
		return

	var steering_weight: float = minf(
		(
			context.config.ground_acceleration_mps2
			/ maxf(
				horizontal_speed_mps,
				0.001
			)
		)
		* context.delta,
		1.0
	)

	var steered_direction: Vector3 = (
		horizontal_velocity.normalized().slerp(
			wish_direction,
			steering_weight
		)
	).normalized()

	var final_speed_mps: float = horizontal_speed_mps

	if horizontal_speed_mps > continuous_target_speed_mps:
		final_speed_mps = maxf(
			continuous_target_speed_mps,
			horizontal_speed_mps
			- context.config.ground_speed_decay_mps2
			* context.delta
		)

	context.set_horizontal_velocity(
		steered_direction
		* final_speed_mps
	)


func _reset_continuous_run() -> void:
	_continuous_run_elapsed_s = 0.0
	_continuous_run_bonus_speed_mps = 0.0
