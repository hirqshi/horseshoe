class_name MovementMotor
extends Node

@export var config: MovementConfig
@export var view_pivot: Node3D

var _body: CharacterBody3D

var _last_grounded_time_s: float = -INF
var _jump_buffer_until_s: float = -INF

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if _body == null:
		push_error("MovementMotor must be a child of CharacterBody3D.")
		set_physics_process(false)
		return

	if view_pivot == null:
		push_error("MovementMotor requires a view pivot.")
		set_physics_process(false)
		return

	if config == null:
		push_error("MovementMotor requires MovementConfig.")
		set_physics_process(false)
		return

	_body.floor_max_angle = deg_to_rad(config.max_floor_angle_deg)

func _physics_process(delta: float) -> void:
	var player_input: PlayerInput = PlayerInput.read()
	var current_time_s: float = Time.get_ticks_msec() * 0.001

	_update_grounded_time(current_time_s)
	_update_jump_buffer(player_input, current_time_s)

	var wish_direction: Vector3 = _get_wish_direction(player_input.move)

	_apply_vertical_movement(delta)
	_apply_horizontal_movement(wish_direction, player_input, delta)
	_try_consume_jump(current_time_s)

	_body.move_and_slide()

func _update_grounded_time(current_time_s: float) -> void:
	if _body.is_on_floor():
		_last_grounded_time_s = current_time_s

func _update_jump_buffer(
	player_input: PlayerInput,
	current_time_s: float
) -> void:
	if player_input.is_jump_pressed:
		_jump_buffer_until_s = current_time_s + config.jump_buffer_s

func _apply_vertical_movement(delta: float) -> void:
	if _body.is_on_floor() and _body.velocity.y < 0.0:
		_body.velocity.y = -0.1
		return

	_body.velocity.y = maxf(
		_body.velocity.y - config.gravity_mps2 * delta,
		-config.terminal_fall_speed_mps
	)

func _apply_horizontal_movement(
	wish_direction: Vector3,
	player_input: PlayerInput,
	delta: float
) -> void:
	var current_horizontal: Vector3 = _get_horizontal_velocity()
	var target_speed_mps: float = _get_target_speed(player_input)
	var target_horizontal: Vector3 = wish_direction * target_speed_mps

	var is_grounded: bool = _body.is_on_floor()
	var has_move_input: bool = not wish_direction.is_zero_approx()

	if not is_grounded:
		target_horizontal *= config.air_control

	var acceleration_mps2: float = _get_acceleration(
		is_grounded,
		has_move_input
	)

	current_horizontal = current_horizontal.move_toward(
		target_horizontal,
		acceleration_mps2 * delta
	)

	_set_horizontal_velocity(current_horizontal)

func _get_acceleration(is_grounded: bool, has_move_input: bool) -> float:
	if is_grounded:
		if has_move_input:
			return config.ground_acceleration_mps2
		return config.ground_deceleration_mps2

	if has_move_input:
		return config.air_acceleration_mps2
	return config.air_deceleration_mps2

func _try_consume_jump(current_time_s: float) -> void:
	var has_buffered_jump: bool = current_time_s <= _jump_buffer_until_s
	var can_coyote_jump: bool = (
		current_time_s <= _last_grounded_time_s + config.coyote_time_s
	)

	if not has_buffered_jump or not can_coyote_jump:
		return

	_body.velocity.y = config.jump_speed_mps
	_jump_buffer_until_s = -INF
	_last_grounded_time_s = -INF

func _get_wish_direction(move_input: Vector2) -> Vector3:
	if move_input.is_zero_approx():
		return Vector3.ZERO

	var forward: Vector3 = -view_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = view_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction: Vector3 = right * move_input.x + forward * -move_input.y
	return direction.normalized()

func _get_target_speed(player_input: PlayerInput) -> float:
	var forward_input: float = -player_input.move.y
	var side_input: float = absf(player_input.move.x)
	var target_speed_mps: float = 0.0

	if forward_input > 0.0:
		target_speed_mps = config.run_speed_forward_mps * forward_input
	elif forward_input < 0.0:
		target_speed_mps = config.run_speed_back_mps * absf(forward_input)

	target_speed_mps = maxf(
		target_speed_mps,
		config.run_speed_side_mps * side_input
	)

	if player_input.is_walk_pressed:
		target_speed_mps *= config.walk_speed_multiplier

	return target_speed_mps

func _get_horizontal_velocity() -> Vector3:
	return Vector3(_body.velocity.x, 0.0, _body.velocity.z)

func _set_horizontal_velocity(horizontal_velocity: Vector3) -> void:
	_body.velocity.x = horizontal_velocity.x
	_body.velocity.z = horizontal_velocity.z
