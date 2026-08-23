class_name MovementContext
extends RefCounted

var body: CharacterBody3D
var view_pivot: Node3D
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

	var forward: Vector3 = -view_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = view_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction: Vector3 = (
		right * player_input.move.x
		+ forward * -player_input.move.y
	)

	return direction.normalized()

func get_target_speed_mps() -> float:
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

func get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)

func set_horizontal_velocity(horizontal_velocity: Vector3) -> void:
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
