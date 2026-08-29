class_name MovementContext
extends RefCounted

var body: CharacterBody3D
var view_pivot: Node3D
var movement_yaw_pivot: Node3D
var sensors: PlayerSensors
var config: MovementConfig
var player_input: PlayerInput

var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var delta: float = 0.0
var time_s: float = 0.0

func update(
	new_delta: float,
	new_time_s: float
) -> void:
	delta = new_delta
	time_s = new_time_s
	velocity = body.velocity
	is_grounded = body.is_on_floor()

func get_wish_direction() -> Vector3:
	if player_input.move.is_zero_approx():
		return Vector3.ZERO

	var forward: Vector3 = (
		-movement_yaw_pivot.global_basis.z
	)
	forward.y = 0.0

	if forward.length_squared() <= 0.0001:
		return Vector3.ZERO

	forward = forward.normalized()

	var right: Vector3 = (
		movement_yaw_pivot.global_basis.x
	)
	right.y = 0.0

	if right.length_squared() <= 0.0001:
		return Vector3.ZERO

	right = right.normalized()

	var direction: Vector3 = (
		right * player_input.move.x
		+ forward * -player_input.move.y
	)

	return direction.normalized()

func get_target_speed_mps(
	ignore_walk_input: bool = false
) -> float:
	if player_input.move.is_zero_approx():
		return 0.0

	var input_strength: float = player_input.move.length()

	var normalized_input: Vector2 = (
		player_input.move / input_strength
	)

	var forward_multiplier: float = 1.0

	if normalized_input.y > 0.0:
		forward_multiplier = config.run_speed_back_multiplier

	var scaled_side: float = (
		normalized_input.x
		* config.run_speed_side_multiplier
	)

	var scaled_forward: float = (
		normalized_input.y
		* forward_multiplier
	)

	var directional_multiplier: float = Vector2(
		scaled_side,
		scaled_forward
	).length()

	var target_speed_mps: float = (
		config.run_speed_forward_mps
		* directional_multiplier
		* input_strength
	)

	if player_input.is_walk_pressed \
			and not ignore_walk_input:
		target_speed_mps *= config.walk_speed_multiplier

	return target_speed_mps

func get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)

func set_horizontal_velocity(horizontal_velocity: Vector3) -> void:
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
