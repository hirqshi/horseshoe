class_name MomentumGrace
extends RefCounted

const MINIMUM_RECOVERY_DIRECTION_ALIGNMENT: float = 0.70

var _saved_horizontal_speed_mps: float = 0.0

var _saved_horizontal_direction: Vector3 = Vector3.ZERO

var _grace_until_s: float = -INF

var _had_move_input: bool = false
var _is_recovery_armed: bool = false


func update_before_locomotion(
	context: MovementContext
) -> void:
	_clear_expired_grace(
		context.time_s
	)

	var has_move_input: bool = (
		not context.player_input.move.is_zero_approx()
	)

	var has_reengaged_movement: bool = (
		has_move_input
		and not _had_move_input
	)

	if not has_reengaged_movement:
		return

	if not _is_recovery_armed:
		return

	if context.time_s > _grace_until_s:
		_clear_grace()
		return

	var wish_direction: Vector3 = (
		context.get_wish_direction()
	)

	if wish_direction.is_zero_approx():
		return
		
	if _saved_horizontal_direction.is_zero_approx():
		_clear_grace()
		return

	var direction_alignment: float = (
		wish_direction.dot(
			_saved_horizontal_direction
		)
	)

	if direction_alignment < (
		MINIMUM_RECOVERY_DIRECTION_ALIGNMENT
	):
		_clear_grace()
		return
		
	var current_horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	var recovered_speed_mps: float = (
		_saved_horizontal_speed_mps
		* context.config.momentum_grace_recovery_multiplier
	)

	if recovered_speed_mps <= current_horizontal_speed_mps:
		_clear_grace()
		return

	context.set_horizontal_velocity(
		wish_direction
		* recovered_speed_mps
	)

	_clear_grace()


func update_after_move(
	context: MovementContext,
	pre_move_horizontal_speed_mps: float,
	had_slide_collision: bool
) -> void:
	_clear_expired_grace(
		context.time_s
	)

	var has_move_input: bool = (
		not context.player_input.move.is_zero_approx()
	)

	var horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	if _had_move_input \
	and not has_move_input:
		_arm_grace(
			context,
			pre_move_horizontal_speed_mps
		)

	if has_move_input \
	and not _is_recovery_armed:
		var horizontal_velocity: Vector3 = (
			context.get_horizontal_velocity()
		)

		if horizontal_speed_mps >= (
			_saved_horizontal_speed_mps
		):
			_saved_horizontal_speed_mps = (
				horizontal_speed_mps
			)

			if not horizontal_velocity.is_zero_approx():
				_saved_horizontal_direction = (
					horizontal_velocity.normalized()
				)

	if had_slide_collision:
		_try_arm_collision_grace(
			context,
			pre_move_horizontal_speed_mps,
			horizontal_speed_mps
		)

	_had_move_input = has_move_input


func reset() -> void:
	_saved_horizontal_speed_mps = 0.0
	_saved_horizontal_direction = Vector3.ZERO
	_grace_until_s = -INF
	_had_move_input = false
	_is_recovery_armed = false


func _try_arm_collision_grace(
	context: MovementContext,
	pre_move_horizontal_speed_mps: float,
	post_move_horizontal_speed_mps: float
) -> void:
	if pre_move_horizontal_speed_mps < (
		context.config.momentum_grace_minimum_saved_speed_mps
	):
		return

	var loss_ratio: float = (
		post_move_horizontal_speed_mps
		/ maxf(
			pre_move_horizontal_speed_mps,
			0.001
		)
	)

	if loss_ratio > (
		context.config.momentum_grace_collision_loss_ratio
	):
		return

	_arm_grace(
		context,
		pre_move_horizontal_speed_mps
	)


func _arm_grace(
	context: MovementContext,
	speed_mps: float
) -> void:
	if speed_mps < (
		context.config.momentum_grace_minimum_saved_speed_mps
	):
		return

	_saved_horizontal_speed_mps = maxf(
		_saved_horizontal_speed_mps,
		speed_mps
	)

	_grace_until_s = (
		context.time_s
		+ context.config.momentum_grace_duration_s
	)

	_is_recovery_armed = true


func _clear_expired_grace(
	current_time_s: float
) -> void:
	if not _is_recovery_armed:
		return

	if current_time_s <= _grace_until_s:
		return

	_clear_grace()


func _clear_grace() -> void:
	_saved_horizontal_speed_mps = 0.0
	_saved_horizontal_direction = Vector3.ZERO
	_grace_until_s = -INF
	_is_recovery_armed = false
