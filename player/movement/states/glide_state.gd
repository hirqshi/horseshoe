class_name GlideState
extends LocomotionState

const ID: StringName = &"glide"

signal glide_charges_changed(
	current_charges: int,
	max_charges: int
)

signal glide_started()
signal glide_finished()

@export var config: GlideConfig
@export var look_controller: PlayerLookController

var _motor: MovementMotor

var _charges: int = 0
var _requires_glide_release: bool = false
var _is_active: bool = false

var _flight_rotation: Quaternion = Quaternion.IDENTITY
var _bank_angle_rad: float = 0.0
var _bank_target_rad: float = 0.0


func _ready() -> void:
	_motor = get_parent() as MovementMotor

	if _motor == null:
		push_error(
			"GlideState must be a child of MovementMotor."
		)
		set_process(false)
		return

	if config == null:
		push_error(
			"GlideState requires GlideConfig."
		)
		set_process(false)
		return

	_restore_all_charges(
		false
	)


func is_deploy_available(
	context: MovementContext
) -> bool:
	if config == null:
		return false

	if context.is_grounded:
		return false

	if _requires_glide_release:
		return false

	if _charges <= 0:
		return false

	if context.sensors.is_ground_near(
		config.auto_exit_ground_distance_m
	):
		return false

	var horizontal_speed_mps: float = (
		context.get_horizontal_velocity().length()
	)

	return horizontal_speed_mps >= (
		config.minimum_entry_speed_mps
	)


func can_enter(
	context: MovementContext
) -> bool:
	if not context.player_input.is_glide_held:
		return false

	return is_deploy_available(context)


func can_continue(
	context: MovementContext
) -> bool:
	if not _is_active:
		return false

	if context.player_input.is_glide_released:
		return false

	if not context.player_input.is_glide_held:
		return false

	if context.sensors.is_ground_near(
		config.auto_exit_ground_distance_m
	):
		_requires_glide_release = true
		return false

	return true


func register_look_delta(
	_context: MovementContext,
	mouse_delta: Vector2,
	mouse_sensitivity: float
) -> void:
	if not _is_active:
		return

	var sensitivity: float = (
		mouse_sensitivity
		* config.look_sensitivity_multiplier
	)

	var yaw_delta_rad: float = (
		-mouse_delta.x
		* sensitivity
	)

	var pitch_delta_rad: float = (
		-mouse_delta.y
		* sensitivity
	)

	var current_basis: Basis = Basis(
		_flight_rotation
	)

	var pitch_axis: Vector3 = (
		current_basis.x
	).normalized()

	var yaw_rotation: Quaternion = Quaternion(
		Vector3.UP,
		yaw_delta_rad
	)

	var pitch_rotation: Quaternion = Quaternion(
		pitch_axis,
		pitch_delta_rad
	)

	_flight_rotation = (
		yaw_rotation
		* pitch_rotation
		* _flight_rotation
	).normalized()

	var max_bank_rad: float = deg_to_rad(
		config.maximum_bank_angle_deg
	)

	_bank_target_rad = clampf(
		mouse_delta.x
		* sensitivity
		* config.bank_input_strength,
		-max_bank_rad,
		max_bank_rad
	)


func enter(
	context: MovementContext
) -> void:
	if not can_enter(context):
		return

	_is_active = true
	
	_flight_rotation = (
		context.view_pivot.global_basis
		.get_rotation_quaternion()
	)
	
	_bank_angle_rad = 0.0
	_bank_target_rad = 0.0
	
	_set_charges(
		_charges - 1
	)

	_motor.stance.set_is_gliding(true)
	
	_apply_flight_rotation(
		context
	)
	
	glide_started.emit()


func exit(
	context: MovementContext
) -> void:
	if not _is_active:
		return

	_is_active = false

	_restore_normal_look(
		context
	)

	_motor.stance.set_is_gliding(false)

	glide_finished.emit()


func _restore_normal_look(
	context: MovementContext
) -> void:
	var flight_forward: Vector3 = (
		-context.view_pivot.global_basis.z
	).normalized()

	if look_controller != null:
		look_controller.begin_glide_recovery(
			flight_forward
		)

		return

	var horizontal_forward: Vector3 = Vector3(
		flight_forward.x,
		0.0,
		flight_forward.z
	)

	if horizontal_forward.length_squared() <= 0.0001:
		return

	horizontal_forward = horizontal_forward.normalized()

	context.body.rotation.y = atan2(
		-horizontal_forward.x,
		-horizontal_forward.z
	)

	var local_forward: Vector3 = (
		context.body.global_basis.inverse()
		* flight_forward
	)

	var pitch_rad: float = asin(
		clampf(
			local_forward.y,
			-1.0,
			1.0
		)
	)

	context.view_pivot.rotation = Vector3(
		pitch_rad,
		0.0,
		0.0
	)


func physics_tick(
	context: MovementContext
) -> StringName:
	if not can_continue(context):
		return &""

	_update_bank(
		context
	)

	_apply_flight_rotation(
		context
	)

	_apply_flight_physics(
		context
	)

	return ID


func _update_bank(
	context: MovementContext
) -> void:
	var follow_weight: float = (
		1.0
		- exp(
			-config.bank_response_speed
			* context.delta
		)
	)

	_bank_angle_rad = lerpf(
		_bank_angle_rad,
		_bank_target_rad,
		follow_weight
	)

	var return_weight: float = (
		1.0
		- exp(
			-config.bank_return_speed
			* context.delta
		)
	)

	_bank_target_rad = lerpf(
		_bank_target_rad,
		0.0,
		return_weight
	)


func _apply_flight_rotation(
	context: MovementContext
) -> void:
	var flight_basis: Basis = Basis(
		_flight_rotation
	)

	var flight_forward: Vector3 = (
		-flight_basis.z
	).normalized()

	var bank_rotation: Quaternion = Quaternion(
		flight_forward,
		_bank_angle_rad
	)

	var visual_rotation: Quaternion = (
		bank_rotation
		* _flight_rotation
	).normalized()

	context.view_pivot.global_basis = Basis(
		visual_rotation
	)


func update_input_state(
	context: MovementContext
) -> void:
	if not _requires_glide_release:
		return

	if not context.player_input.is_glide_released:
		return

	_requires_glide_release = false


func force_exit(
	context: MovementContext
) -> void:
	if not _is_active:
		return

	_requires_glide_release = true

	exit(context)


func is_active() -> bool:
	return _is_active


func get_bank_angle_rad() -> float:
	return _bank_angle_rad


func reset_after_respawn(
	context: MovementContext
) -> void:
	_requires_glide_release = false

	if not _is_active:
		return

	_is_active = false

	_restore_normal_look(
		context
	)

	_motor.stance.set_is_gliding(false)

	glide_finished.emit()

func get_charges() -> int:
	return _charges


func get_max_charges() -> int:
	if config == null:
		return 0

	return config.max_charges


func can_glide(
	context: MovementContext
) -> bool:
	return can_enter(context)


func restore_all_charges() -> void:
	_restore_all_charges(
		true
	)


func _restore_all_charges(
	should_emit: bool
) -> void:
	if config == null:
		return

	var previous_charges: int = _charges

	_charges = config.max_charges

	if not should_emit:
		return

	if _charges == previous_charges:
		return

	glide_charges_changed.emit(
		_charges,
		config.max_charges
	)


func _set_charges(
	value: int
) -> void:
	if config == null:
		return

	var next_charges: int = clampi(
		value,
		0,
		config.max_charges
	)

	if next_charges == _charges:
		return

	_charges = next_charges

	glide_charges_changed.emit(
		_charges,
		config.max_charges
	)


func _apply_flight_physics(
	context: MovementContext
) -> void:
	var flight_basis: Basis = Basis(
		_flight_rotation
	)

	var flight_forward: Vector3 = (
		-flight_basis.z
	).normalized()

	var flight_up: Vector3 = (
		flight_basis.y
	).normalized()

	var velocity: Vector3 = (
		context.velocity
	)

	var speed_mps: float = velocity.length()

	if speed_mps <= 0.001:
		velocity += (
			Vector3.DOWN
			* context.config.gravity_mps2
			* context.delta
		)

		context.velocity = velocity
		return

	var velocity_direction: Vector3 = (
		velocity.normalized()
	)

	var horizontal_velocity: Vector2 = Vector2(
		velocity.x,
		velocity.z
	)

	var horizontal_forward: Vector2 = Vector2(
		flight_forward.x,
		flight_forward.z
	)

	if horizontal_velocity.length_squared() > 0.0001 \
	and horizontal_forward.length_squared() > 0.0001:
		var current_heading: Vector2 = (
			horizontal_velocity.normalized()
		)

		var target_heading: Vector2 = (
			horizontal_forward.normalized()
		)

		var heading_angle_rad: float = (
			current_heading.angle_to(
				target_heading
			)
		)

		var maximum_heading_turn_rad: float = deg_to_rad(
			config.heading_turn_speed_deg_s
		) * context.delta

		var clamped_heading_turn_rad: float = clampf(
			heading_angle_rad,
			-maximum_heading_turn_rad,
			maximum_heading_turn_rad
		)

		var turned_heading: Vector2 = (
			current_heading.rotated(
				clamped_heading_turn_rad
			)
		)

		var horizontal_speed_mps: float = (
			horizontal_velocity.length()
		)

		velocity.x = (
			turned_heading.x
			* horizontal_speed_mps
		)

		velocity.z = (
			turned_heading.y
			* horizontal_speed_mps
		)

	speed_mps = velocity.length()

	var speed_ratio: float = clampf(
		speed_mps
		/ config.maximum_flight_speed_mps,
		0.0,
		1.0
	)

	var can_generate_lift: bool = (
		speed_mps >= config.stall_speed_mps
	)

	if can_generate_lift:
		var pitch_follow_strength: float = (
			deg_to_rad(
				config.pitch_follow_speed_deg_s
			)
			* speed_ratio
			* context.delta
		)

		var current_direction: Vector3 = (
			velocity.normalized()
		)

		var pitch_axis: Vector3 = (
			current_direction.cross(
				flight_forward
			)
		)

		if pitch_axis.length_squared() > 0.0001:
			var pitch_angle_rad: float = acos(
				clampf(
					current_direction.dot(
						flight_forward
					),
					-1.0,
					1.0
				)
			)

			var pitch_turn_rad: float = minf(
				pitch_angle_rad,
				pitch_follow_strength
			)

			var pitch_rotation: Quaternion = Quaternion(
				pitch_axis.normalized(),
				pitch_turn_rad
			)

			velocity = (
				pitch_rotation
				* velocity
			)

		var current_velocity_direction: Vector3 = (
			velocity.normalized()
		)

		var aerodynamic_lift_direction: Vector3 = (
			flight_up
			- current_velocity_direction
			* flight_up.dot(
				current_velocity_direction
			)
		)

		if not aerodynamic_lift_direction.is_zero_approx():
			aerodynamic_lift_direction = (
				aerodynamic_lift_direction.normalized()
			)

			var lift_strength_mps2: float = (
				config.lift_acceleration_mps2
				* speed_ratio
				* speed_ratio
			)

			velocity += (
				aerodynamic_lift_direction
				* lift_strength_mps2
				* context.delta
			)

		var level_assist_direction: Vector3 = (
			Vector3.UP
			- current_velocity_direction
			* Vector3.UP.dot(
				current_velocity_direction
			)
		)

		if not level_assist_direction.is_zero_approx():
			level_assist_direction = (
				level_assist_direction.normalized()
			)

			velocity += (
				level_assist_direction
				* context.config.gravity_mps2
				* config.level_flight_assist
				* context.delta
			)
	else:
		velocity += (
			Vector3.DOWN
			* config.stall_fall_acceleration_mps2
			* context.delta
		)

	velocity += (
		Vector3.DOWN
		* context.config.gravity_mps2
		* context.delta
	)

	speed_mps = velocity.length()

	if speed_mps > 0.001:
		var drag_speed_ratio: float = maxf(
			speed_mps
			/ config.maximum_flight_speed_mps,
			0.0
		)

		var drag_strength_mps2: float = (
			config.maximum_drag_deceleration_mps2
			* pow(
				drag_speed_ratio,
				config.drag_speed_exponent
			)
		)
		velocity -= (
			velocity.normalized()
			* drag_strength_mps2
			* context.delta
		)

	context.velocity = velocity
