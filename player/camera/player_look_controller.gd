class_name PlayerLookController
extends Node

signal look_delta_received(mouse_delta: Vector2)

@export_category("references")
@export var body: CharacterBody3D
@export var head: Node3D
@export var visual_rig: CameraVisualRig

@export_category("look")
@export_range(0.0001, 0.05, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(1.0, 89.0, 1.0, "suffix:deg") var max_ground_pitch_deg: float = 85.0
@export_range(1.0, 1440.0, 1.0, "suffix:deg/s") var ground_pitch_recovery_speed_deg_s: float = 420.0
@export_range(0.0, 1.0, 0.01) var upside_down_switch_threshold: float = 0.15


var _pitch_rad: float = 0.0
var _is_enabled: bool = true
var _is_camera_upside_down: bool = false
var _is_recovering_from_glide: bool = false
var _glide_recovery_target_body_yaw_rad: float = 0.0
var _glide_recovery_target_head_rotation: Quaternion = (
	Quaternion.IDENTITY
)

@export_category("glide recovery")
@export_range(
	0.1,
	50.0,
	0.1,
	"suffix:1/s"
) var glide_recovery_response_speed: float = 10.0

func _ready() -> void:
	if body == null:
		push_error("PlayerLookController requires a player body.")
		set_process(false)
		set_process_input(false)
		return

	if head == null:
		push_error("PlayerLookController requires a head pivot.")
		set_process(false)
		set_process_input(false)
		return
		
	if visual_rig == null:
		push_error("PlayerLookController requires CameraVisualRig.")
		set_process(false)
		set_process_input(false)
		return
		
	_pitch_rad = head.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not _is_enabled:
		return

	if _is_recovering_from_glide:
		_update_glide_recovery(delta)
		return

	if not body.is_on_floor():
		return

	_recover_ground_pitch(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		set_is_enabled(false)
		return

	if event is InputEventMouseButton and event.pressed:
		set_is_enabled(true)
		return

	if event is InputEventMouseMotion \
			and _is_enabled \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.screen_relative)

func set_is_enabled(value: bool) -> void:
	_is_enabled = value

	if _is_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_mouse_look(mouse_delta: Vector2) -> void:
	look_delta_received.emit(mouse_delta)
	visual_rig.register_look_delta(mouse_delta)

	if _is_recovering_from_glide:
		return

	var movement_motor: MovementMotor = (
		body.get_node_or_null(
			"MovementMotor"
		) as MovementMotor
	)

	if movement_motor != null \
	and movement_motor.is_gliding():
		movement_motor.register_glide_look_delta(
			mouse_delta,
			mouse_sensitivity
		)
		return
		
	var yaw_multiplier: float = (
		-1.0
		if _is_camera_upside_down
		else 1.0
	)

	var yaw_delta_rad: float = (
		-mouse_delta.x
		* mouse_sensitivity
		* yaw_multiplier
	)

	var pitch_delta_rad: float = (
		-mouse_delta.y
		* mouse_sensitivity
	)

	body.rotate_y(yaw_delta_rad)

	if body.is_on_floor() and _is_ground_pitch_valid(_pitch_rad):
		var ground_center_rad: float = (
			_get_nearest_ground_pitch(_pitch_rad)
		)

		var max_pitch_rad: float = deg_to_rad(
			max_ground_pitch_deg
		)

		_pitch_rad = clampf(
			_pitch_rad + pitch_delta_rad,
			ground_center_rad - max_pitch_rad,
			ground_center_rad + max_pitch_rad
		)
	else:
		_pitch_rad += pitch_delta_rad

	head.rotation.x = _pitch_rad

	_update_upside_down_state()

func _update_upside_down_state() -> void:
	var head_up_dot: float = (
		head.global_transform.basis.y.dot(Vector3.UP)
	)

	if _is_camera_upside_down:
		if head_up_dot > upside_down_switch_threshold:
			_is_camera_upside_down = false
		return

	if head_up_dot < -upside_down_switch_threshold:
		_is_camera_upside_down = true

func _recover_ground_pitch(delta: float) -> void:
	var target_pitch_rad: float = (
		_get_nearest_ground_pitch(_pitch_rad)
	)

	if is_equal_approx(_pitch_rad, target_pitch_rad):
		return

	var recovery_speed_rad_s: float = deg_to_rad(
		ground_pitch_recovery_speed_deg_s
	)

	_pitch_rad = move_toward(
		_pitch_rad,
		target_pitch_rad,
		recovery_speed_rad_s * delta
	)

	head.rotation.x = _pitch_rad

func _is_ground_pitch_valid(pitch_rad: float) -> bool:
	var nearest_valid_pitch_rad: float = (
		_get_nearest_ground_pitch(pitch_rad)
	)

	return is_equal_approx(
		pitch_rad,
		nearest_valid_pitch_rad
	)

func _get_nearest_ground_pitch(
	pitch_rad: float
) -> float:
	var max_pitch_rad: float = deg_to_rad(
		max_ground_pitch_deg
	)

	var nearest_pitch_rad: float = pitch_rad
	var nearest_distance_rad: float = INF
	var base_turn: int = roundi(pitch_rad / TAU)

	for turn_offset: int in range(-1, 2):
		var turn: int = base_turn + turn_offset
		var turn_center_rad: float = float(turn) * TAU

		var candidate_pitch_rad: float = clampf(
			pitch_rad,
			turn_center_rad - max_pitch_rad,
			turn_center_rad + max_pitch_rad
		)

		var candidate_distance_rad: float = absf(
			candidate_pitch_rad - pitch_rad
		)

		if candidate_distance_rad < nearest_distance_rad:
			nearest_distance_rad = candidate_distance_rad
			nearest_pitch_rad = candidate_pitch_rad

	return nearest_pitch_rad


func sync_from_glide(
	pitch_rad: float
) -> void:
	_pitch_rad = pitch_rad
	_is_camera_upside_down = false


func begin_glide_recovery(
	flight_forward: Vector3
) -> void:
	var horizontal_forward: Vector3 = Vector3(
		flight_forward.x,
		0.0,
		flight_forward.z
	)

	if horizontal_forward.length_squared() <= 0.0001:
		horizontal_forward = (
			-body.global_basis.z
		)

	horizontal_forward = horizontal_forward.normalized()

	_glide_recovery_target_body_yaw_rad = atan2(
		-horizontal_forward.x,
		-horizontal_forward.z
	)

	var target_body_basis: Basis = Basis(
		Vector3.UP,
		_glide_recovery_target_body_yaw_rad
	)

	var local_forward: Vector3 = (
		target_body_basis.inverse()
		* flight_forward.normalized()
	)

	var target_pitch_rad: float = asin(
		clampf(
			local_forward.y,
			-1.0,
			1.0
		)
	)

	_glide_recovery_target_head_rotation = (
		target_body_basis
		* Basis(
			Vector3.RIGHT,
			target_pitch_rad
		)
	).get_rotation_quaternion()

	_is_recovering_from_glide = true


func _update_glide_recovery(
	delta: float
) -> void:
	var response_weight: float = (
		1.0
		- exp(
			-glide_recovery_response_speed
			* delta
		)
	)

	body.rotation.y = lerp_angle(
		body.rotation.y,
		_glide_recovery_target_body_yaw_rad,
		response_weight
	)

	var current_head_rotation: Quaternion = (
		head.global_basis
		.get_rotation_quaternion()
	)

	var recovered_head_rotation: Quaternion = (
		current_head_rotation.slerp(
			_glide_recovery_target_head_rotation,
			response_weight
		)
	)

	head.global_basis = Basis(
		recovered_head_rotation
	)

	var remaining_angle_rad: float = (
		recovered_head_rotation.angle_to(
			_glide_recovery_target_head_rotation
		)
	)

	if remaining_angle_rad > 0.01:
		return

	head.global_basis = Basis(
		_glide_recovery_target_head_rotation
	)

	var local_head_rotation: Quaternion = (
		body.global_basis
		.get_rotation_quaternion()
		.inverse()
		* _glide_recovery_target_head_rotation
	)

	var local_head_basis: Basis = Basis(
		local_head_rotation
	)

	_pitch_rad = asin(
		clampf(
			-local_head_basis.z.y,
			-1.0,
			1.0
		)
	)

	head.rotation = Vector3(
		_pitch_rad,
		0.0,
		0.0
	)

	_is_camera_upside_down = false
	_is_recovering_from_glide = false
