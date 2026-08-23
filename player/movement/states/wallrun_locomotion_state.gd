class_name WallrunLocomotionState
extends LocomotionState

const ID: StringName = &"wallrun"

@export var config: WallrunConfig

var _wall_normal: Vector3 = Vector3.ZERO
var _elapsed_time_s: float = 0.0
var _reentry_cooldown_remaining_s: float = 0.0

func _ready() -> void:
	if config == null:
		push_error("WallrunLocomotionState requires WallrunConfig.")
		set_process(false)

func enter(context: MovementContext) -> void:
	var wall_contact: WallContact = context.sensors.get_best_wall()

	_wall_normal = wall_contact.normal.normalized()
	_elapsed_time_s = 0.0

	if context.velocity.y <= 0.0:
		return

	context.velocity.y = minf(
		context.velocity.y
		* config.entry_upward_velocity_retention,
		config.max_entry_upward_speed_mps
	)

func exit(_context: MovementContext) -> void:
	if _elapsed_time_s >= config.duration_s:
		_reentry_cooldown_remaining_s = config.reentry_cooldown_s

	_wall_normal = Vector3.ZERO
	_elapsed_time_s = 0.0

func can_enter(context: MovementContext) -> bool:
	
	if _reentry_cooldown_remaining_s > 0.0:
		return false

	if context.body.is_on_floor():
		return false

	var wall_contact: WallContact = context.sensors.get_best_wall()
	return wall_contact.is_valid()

func can_continue(context: MovementContext) -> bool:
	if context.body.is_on_floor():
		return false

	if _elapsed_time_s >= config.duration_s:
		return false

	var wall_contact: WallContact = context.sensors.get_best_wall()

	if not wall_contact.is_valid():
		return false

	var normal_alignment: float = wall_contact.normal.dot(_wall_normal)

	return normal_alignment >= config.minimum_normal_alignment

func physics_tick(context: MovementContext) -> StringName:
	if not can_continue(context):
		return &""

	_elapsed_time_s += context.delta

	_apply_horizontal_movement(context)
	_apply_vertical_movement(context)

	return &""

func update_reentry_cooldown(delta: float) -> void:
	_reentry_cooldown_remaining_s = maxf(
		_reentry_cooldown_remaining_s - delta,
		0.0
	)

func get_wall_normal() -> Vector3:
	return _wall_normal

func _apply_horizontal_movement(context: MovementContext) -> void:
	var current_horizontal: Vector3 = context.get_horizontal_velocity()

	var normal_speed_mps: float = current_horizontal.dot(_wall_normal)

	var wall_parallel_velocity: Vector3 = (
		current_horizontal
		- _wall_normal * normal_speed_mps
	)

	var world_input_direction: Vector3 = context.get_wish_direction()
	var wall_input_direction: Vector3 = (
		world_input_direction
		- _wall_normal
		* world_input_direction.dot(_wall_normal)
	)

	if wall_input_direction.is_zero_approx():
		context.set_horizontal_velocity(wall_parallel_velocity)
		return

	wall_input_direction = wall_input_direction.normalized()

	var target_speed_mps: float = maxf(
		wall_parallel_velocity.length(),
		maxf(
			context.get_target_speed_mps(),
			config.minimum_control_speed_mps
		)
	)

	var target_velocity: Vector3 = (
		wall_input_direction
		* target_speed_mps
	)

	wall_parallel_velocity = wall_parallel_velocity.move_toward(
		target_velocity,
		config.steering_acceleration_mps2 * context.delta
	)

	context.set_horizontal_velocity(wall_parallel_velocity)

func _apply_vertical_movement(context: MovementContext) -> void:
	var fall_elapsed_s: float = maxf(
		_elapsed_time_s - config.fall_delay_s,
		0.0
	)

	var fall_duration_s: float = maxf(
		config.duration_s - config.fall_delay_s,
		0.001
	)

	var fall_progress: float = clampf(
		fall_elapsed_s / fall_duration_s,
		0.0,
		1.0
	)

	var current_gravity_multiplier: float = lerpf(
		0.0,
		config.gravity_multiplier,
		fall_progress
	)

	context.velocity.y = maxf(
		context.velocity.y
		- context.config.gravity_mps2
		* current_gravity_multiplier
		* context.delta,
		-config.max_fall_speed_mps
	)
