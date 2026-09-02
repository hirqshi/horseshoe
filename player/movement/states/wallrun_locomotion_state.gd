class_name WallrunLocomotionState
extends LocomotionState

const ID: StringName = &"wallrun"

signal wall_jump_charges_changed(
	current_charges: int,
	max_charges: int
)
signal wall_jump_failed()

@export var config: WallrunConfig

var _wall_normal: Vector3 = Vector3.ZERO
var _elapsed_time_s: float = 0.0
var _reentry_cooldown_remaining_s: float = 0.0
var _wall_jump_charges: int = 0
var _last_debug_time_s: float = -INF

func _ready() -> void:
	if config == null:
		push_error("WallrunLocomotionState requires WallrunConfig.")
		set_process(false)
	restore_wall_jump_charges()

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
	
	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity()
	)

	var horizontal_speed_mps: float = (
		horizontal_velocity.length()
	)

	if horizontal_speed_mps <= 0.001:
		return

	var tangential_velocity: Vector3 = (
		_project_onto_wall(
			horizontal_velocity
		)
	)

	var tangential_direction: Vector3 = Vector3.ZERO

	if tangential_velocity.length() > (
		config.tangential_entry_deadzone_mps
	):
		tangential_direction = tangential_velocity.normalized()
	else:
		var input_direction: Vector3 = (
			context.get_wish_direction()
		)

		var tangential_input: Vector3 = (
			_project_onto_wall(
				input_direction
			)
		)

		if not tangential_input.is_zero_approx():
			tangential_direction = tangential_input.normalized()
		else:
			var camera_forward: Vector3 = (
				-context.view_pivot.global_basis.z
			)

			camera_forward.y = 0.0

			var tangential_camera_forward: Vector3 = (
				_project_onto_wall(
					camera_forward
				)
			)

			if tangential_camera_forward.is_zero_approx():
				return

			tangential_direction = (
				tangential_camera_forward.normalized()
			)

		var retained_speed_mps: float = (
			horizontal_speed_mps
			* config.entry_horizontal_momentum_retention
		)

		context.set_horizontal_velocity(
			tangential_direction
			* retained_speed_mps
		)

func exit(_context: MovementContext) -> void:
	if _elapsed_time_s >= config.duration_s:
		_reentry_cooldown_remaining_s = config.reentry_cooldown_s

	_wall_normal = Vector3.ZERO
	_elapsed_time_s = 0.0

func can_enter(context: MovementContext) -> bool:
	if _reentry_cooldown_remaining_s > 0.0:
		_debug(
			context,
			"WR_ENTER reject | reason: cooldown"
		)
		return false

	if context.body.is_on_floor():
		return false

	var forward_wall: WallContact = (
		context.sensors.get_forward_wall()
	)

	if forward_wall.is_valid():
		_debug(
			context,
			"WR_ENTER reject | reason: front wall contact"
		)
		return false

	var wall_contact: WallContact = (
		context.sensors.get_best_wall()
	)

	if not wall_contact.is_valid():
		return false

	var camera_forward: Vector3 = (
		-context.view_pivot.global_basis.z
	)
	camera_forward.y = 0.0

	if camera_forward.is_zero_approx():
		return false

	camera_forward = camera_forward.normalized()

	var look_dot: float = (
		camera_forward.dot(-wall_contact.normal)
	)

	var horizontal_velocity: Vector3 = (
		context.get_horizontal_velocity()
	)

	var tangential_velocity: Vector3 = (
		_project_onto_normal(
			horizontal_velocity,
			wall_contact.normal
		)
	)

	var input_direction: Vector3 = (
		context.get_wish_direction()
	)

	var tangential_input: Vector3 = (
		_project_onto_normal(
			input_direction,
			wall_contact.normal
		)
	)

	var is_looking_into_wall: bool = (
		look_dot >= config.perpendicular_look_normal_dot
	)

	var has_tangential_speed: bool = (
		tangential_velocity.length()
		>= config.minimum_tangential_entry_speed_mps
	)

	var has_tangential_input: bool = (
		tangential_input.length()
		>= config.minimum_tangential_input
	)

	_debug(
		context,
		(
			"WR_ENTER | look_dot: %.3f / %.3f"
			% [
				look_dot,
				config.perpendicular_look_normal_dot,
			]
		)
		+ (
			" | tangent_speed: %.3f / %.3f"
			% [
				tangential_velocity.length(),
				config.minimum_tangential_entry_speed_mps,
			]
		)
		+ (
			" | tangent_input: %.3f / %.3f"
			% [
				tangential_input.length(),
				config.minimum_tangential_input,
			]
		)
		+ (
			" | normal: %s"
			% [wall_contact.normal]
		)
	)

	if is_looking_into_wall:
		_debug(
			context,
			"WR_ENTER reject | reason: looking into wall"
		)
		return false

	if has_tangential_speed:
		_debug(
			context,
			"WR_ENTER accept | reason: tangential speed"
		)
		return true

	if has_tangential_input:
		_debug(
			context,
			"WR_ENTER accept | reason: tangential input"
		)
		return true

	_debug(
		context,
		"WR_ENTER reject | reason: no tangent"
	)

	return false

func can_continue(context: MovementContext) -> bool:
	if context.body.is_on_floor():
		return false

	if _elapsed_time_s >= config.duration_s:
		return false

	var forward_wall: WallContact = (
		context.sensors.get_forward_wall()
	)

	if forward_wall.is_valid():
		_debug(
			context,
			(
				"WR_EXIT | reason: front wall contact"
				+ " | normal: %s"
				% [forward_wall.normal]
			),
			true
		)
		return false

	var wall_contact: WallContact = (
		context.sensors.get_best_wall()
	)

	if not wall_contact.is_valid():
		return false

	var normal_alignment: float = (
		wall_contact.normal.dot(_wall_normal)
	)

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

func _apply_horizontal_movement(
	context: MovementContext
) -> void:
	var current_horizontal: Vector3 = (
		context.get_horizontal_velocity()
	)

	var normal_speed_mps: float = (
		current_horizontal.dot(_wall_normal)
	)

	var wall_parallel_velocity: Vector3 = (
		current_horizontal
		- _wall_normal
		* normal_speed_mps
	)

	var world_input_direction: Vector3 = (
		context.get_wish_direction()
	)

	var wall_input_direction: Vector3 = (
		world_input_direction
		- _wall_normal
		* world_input_direction.dot(_wall_normal)
	)

	if wall_input_direction.is_zero_approx():
		context.set_horizontal_velocity(
			wall_parallel_velocity
		)
		return

	wall_input_direction = wall_input_direction.normalized()

	var current_speed_mps: float = (
		wall_parallel_velocity.length()
	)

	var target_speed_mps: float = maxf(
		current_speed_mps,
		maxf(
			context.get_target_speed_mps(),
			config.minimum_control_speed_mps
		)
	)

	if current_speed_mps < target_speed_mps:
		var target_velocity: Vector3 = (
			wall_input_direction
			* target_speed_mps
		)

		wall_parallel_velocity = (
			wall_parallel_velocity.move_toward(
				target_velocity,
				config.steering_acceleration_mps2
				* context.delta
			)
		)

		context.set_horizontal_velocity(
			wall_parallel_velocity
		)
		return

	if wall_parallel_velocity.is_zero_approx():
		return

	var steering_weight: float = minf(
		(
			config.steering_acceleration_mps2
			/ maxf(
				current_speed_mps,
				0.001
			)
		)
		* context.delta,
		1.0
	)

	var steered_direction: Vector3 = (
		wall_parallel_velocity.normalized().slerp(
			wall_input_direction,
			steering_weight
		)
	).normalized()

	context.set_horizontal_velocity(
		steered_direction
		* current_speed_mps
	)

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

func try_wall_jump(context: MovementContext) -> bool:
	var debug_contact: WallContact = (
		context.sensors.get_wall_jump_contact()
	)

	_debug(
		context,
		(
			"WR_JUMP attempt"
			+ " | charges: %d"
			% [_wall_jump_charges]
		)
		+ (
			" | grounded: %s"
			% [context.body.is_on_floor()]
		)
		+ (
			" | sensor_valid: %s"
			% [debug_contact.is_valid()]
		)
		+ (
			" | sensor_normal: %s"
			% [debug_contact.normal]
		),
		true
	)

	if _wall_jump_charges <= 0:
		if not context.body.is_on_floor() \
		and debug_contact.is_valid():
			wall_jump_failed.emit()

		_debug(
			context,
			"WR_JUMP reject | reason: no charges",
			true
		)
		return false

	if context.body.is_on_floor():
		_debug(
			context,
			"WR_JUMP reject | reason: grounded",
			true
		)
		return false

	var jump_normal: Vector3 = _get_wall_jump_normal(context)

	if jump_normal.is_zero_approx():
		_debug(
			context,
			"WR_JUMP reject | reason: no wall normal",
			true
		)
		return false

	var input_direction: Vector3 = (
		context.get_wish_direction()
	)

	var is_holding_toward_wall: bool = (
		not input_direction.is_zero_approx()
		and input_direction.dot(-jump_normal)
		>= config.toward_wall_threshold
	)

	var input_tangent: Vector3 = (
		_project_onto_normal(
			input_direction,
			jump_normal
		)
	)

	var has_tangential_input: bool = (
		input_tangent.length()
		>= config.wall_jump_tangent_input_threshold
	)

	var jump_tangent: Vector3 = Vector3.ZERO

	if has_tangential_input:
		jump_tangent = input_tangent.normalized()

	var outward_speed_mps: float = (
		config.wall_jump_away_outward_speed_mps
	)

	var forward_speed_mps: float = (
		config.wall_jump_away_forward_speed_mps
	)

	var upward_speed_mps: float = (
		config.wall_jump_upward_speed_mps
	)

	if not has_tangential_input:
		outward_speed_mps = (
			config.wall_jump_perpendicular_outward_speed_mps
		)
		forward_speed_mps = 0.0
		upward_speed_mps = (
			config.wall_jump_perpendicular_upward_speed_mps
		)
	elif is_holding_toward_wall:
		outward_speed_mps = (
			config.wall_jump_toward_outward_speed_mps
		)
		forward_speed_mps = (
			config.wall_jump_toward_forward_speed_mps
		)
		upward_speed_mps *= (
			config.wall_jump_toward_upward_multiplier
		)

	var current_horizontal: Vector3 = (
		context.get_horizontal_velocity()
	)

	var current_outward_speed_mps: float = maxf(
		current_horizontal.dot(jump_normal),
		0.0
	)

	var preserved_tangential_velocity: Vector3 = (
		_project_onto_normal(
			current_horizontal,
			jump_normal
		)
		* config.wall_jump_tangential_momentum_retention
	)

	if has_tangential_input:
		var preserved_tangential_speed_mps: float = (
			preserved_tangential_velocity.length()
		)

		preserved_tangential_velocity = (
			jump_tangent
			* preserved_tangential_speed_mps
		)

		preserved_tangential_velocity += (
			jump_tangent
			* forward_speed_mps
		)

	var preserved_outward_speed_mps: float = (
		current_outward_speed_mps
		* config.wall_jump_outward_momentum_retention
	)

	var final_outward_speed_mps: float = (
		preserved_outward_speed_mps
		+ outward_speed_mps
	)

	var wall_jump_horizontal_velocity: Vector3 = (
		preserved_tangential_velocity
		+ jump_normal
		* final_outward_speed_mps
	)

	context.set_horizontal_velocity(
		wall_jump_horizontal_velocity
	)

	context.velocity.y = upward_speed_mps

	_wall_jump_charges -= 1
	_reentry_cooldown_remaining_s = maxf(
		_reentry_cooldown_remaining_s,
		config.reentry_cooldown_s
	)

	wall_jump_charges_changed.emit(
		_wall_jump_charges,
		config.max_wall_jump_charges
	)

	_debug(
		context,
		(
			"WR_JUMP success"
			+ " | normal: %s"
			% [jump_normal]
		)
		+ (
			" | tangent: %s"
			% [jump_tangent]
		)
		+ (
			" | has_tangent: %s"
			% [has_tangential_input]
		)
		+ (
			" | velocity: %s"
			% [context.velocity]
		),
		true
	)

	return true

func _get_wall_jump_normal(
	context: MovementContext
) -> Vector3:
	var wall_contact: WallContact = (
		context.sensors.get_wall_jump_contact()
	)

	if wall_contact.is_valid():
		return wall_contact.normal.normalized()

	if not _wall_normal.is_zero_approx():
		return _wall_normal

	return Vector3.ZERO

func restore_wall_jump_charges() -> void:
	if _wall_jump_charges == config.max_wall_jump_charges:
		return

	_wall_jump_charges = config.max_wall_jump_charges

	wall_jump_charges_changed.emit(
		_wall_jump_charges,
		config.max_wall_jump_charges
	)

func get_wall_jump_charges() -> int:
	return _wall_jump_charges

func get_max_wall_jump_charges() -> int:
	if config == null:
		return 0

	return config.max_wall_jump_charges

func _project_onto_wall(direction: Vector3) -> Vector3:
	return direction - _wall_normal * direction.dot(_wall_normal)

func _project_onto_normal(
	direction: Vector3,
	normal: Vector3
) -> Vector3:
	return direction - normal * direction.dot(normal)

func _debug(
	context: MovementContext,
	message: String,
	force: bool = false
) -> void:
	if not config.is_debug_enabled:
		return

	if not force and (
		context.time_s
		< _last_debug_time_s + config.debug_interval_s
	):
		return

	_last_debug_time_s = context.time_s
	print(message)
