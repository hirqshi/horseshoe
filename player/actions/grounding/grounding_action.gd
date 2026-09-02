class_name GroundingAction
extends MovementAction

signal grounding_landed(
	grounding_drop_distance_m: float,
	entry_horizontal_velocity: Vector3
)

@export var config: GroundingConfig

var _motor: MovementMotor

var _remaining_time_s: float = 0.0

var _entry_horizontal_velocity: Vector3 = Vector3.ZERO
var _grounding_horizontal_velocity: Vector3 = Vector3.ZERO

var _grounding_start_y: float = 0.0
var _is_active: bool = false


func setup(
	motor: MovementMotor
) -> void:
	_motor = motor

	if config == null:
		push_error(
			"GroundingAction requires GroundingConfig."
		)
		set_process(false)
		return

	_motor.landed.connect(
		_on_motor_landed
	)


func can_start(
	context: MovementContext
) -> bool:
	return (
		not context.is_grounded
		and context.player_input.is_slide_pressed
	)


func start(
	context: MovementContext
) -> void:
	_remaining_time_s = config.duration_s
	_is_active = true

	_grounding_start_y = (
		context.body.global_position.y
	)

	_entry_horizontal_velocity = (
		context.get_horizontal_velocity()
	)

	_grounding_horizontal_velocity = (
		_entry_horizontal_velocity
		* config.horizontal_velocity_retention
	)

	context.set_horizontal_velocity(
		_grounding_horizontal_velocity
	)

	context.velocity.y = minf(
		context.velocity.y,
		-config.downward_speed_mps
	)


func physics_tick(
	context: MovementContext
) -> bool:
	if context.is_grounded:
		return false

	_remaining_time_s -= context.delta

	context.set_horizontal_velocity(
		_grounding_horizontal_velocity
	)

	context.velocity.y = minf(
		context.velocity.y,
		-config.downward_speed_mps
	)

	return _remaining_time_s > 0.0


func finish(
	_context: MovementContext
) -> void:
	_remaining_time_s = 0.0
	_is_active = false


func get_ground_boost_window_s() -> float:
	if config == null:
		return 0.0

	return config.ground_boost_window_s


func get_grounding_slide_window_s() -> float:
	if config == null:
		return 0.0

	return config.grounding_slide_window_s


func get_ground_boost_jump_speed_mps(
	movement_config: MovementConfig,
	grounding_drop_distance_m: float
) -> float:
	if config == null:
		return movement_config.jump_speed_mps

	var max_jump_height_m: float = (
		_get_max_jump_height_m(
			movement_config
		)
	)

	var clamped_drop_distance_m: float = minf(
		grounding_drop_distance_m,
		max_jump_height_m
	)

	var drop_progress: float = clampf(
		clamped_drop_distance_m
		/ maxf(
			max_jump_height_m,
			0.001
		),
		0.0,
		1.0
	)

	var jump_multiplier: float = lerpf(
		1.0,
		config.ground_boost_jump_speed_multiplier,
		drop_progress
	)

	return (
		movement_config.jump_speed_mps
		* jump_multiplier
	)


func _get_max_jump_height_m(
	movement_config: MovementConfig
) -> float:
	var gravity_mps2: float = maxf(
		movement_config.gravity_mps2,
		0.001
	)

	var jump_speed_mps: float = (
		movement_config.jump_speed_mps
	)

	var hold_gravity_multiplier: float = (
		movement_config.jump_hold_gravity_multiplier
	)

	var hold_duration_s: float = (
		movement_config.jump_hold_duration_s
	)

	var velocity_after_hold_mps: float = maxf(
		0.0,
		jump_speed_mps
		- gravity_mps2
		* hold_gravity_multiplier
		* hold_duration_s
	)

	var height_during_hold_m: float = (
		jump_speed_mps
		* hold_duration_s
		- 0.5
		* gravity_mps2
		* hold_gravity_multiplier
		* hold_duration_s
		* hold_duration_s
	)

	var height_after_hold_m: float = (
		velocity_after_hold_mps
		* velocity_after_hold_mps
		/ (
			2.0
			* gravity_mps2
		)
	)

	return height_during_hold_m + height_after_hold_m


func _on_motor_landed(
	_impact_speed_mps: float
) -> void:
	if not _is_active:
		return

	var body: CharacterBody3D = (
		_motor.get_body()
	)

	if body == null:
		return

	var grounding_drop_distance_m: float = maxf(
		0.0,
		_grounding_start_y
		- body.global_position.y
	)

	grounding_landed.emit(
		grounding_drop_distance_m,
		_entry_horizontal_velocity
	)


func blocks_locomotion_transition() -> bool:
	return true
