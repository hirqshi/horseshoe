class_name PlayerLookController
extends Node

@export_category("references")
@export var body: CharacterBody3D
@export var head: Node3D
@export var visual_rig: CameraVisualRig

@export_category("look")
@export_range(0.0001, 0.05, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(1.0, 89.0, 1.0, "suffix:deg") var max_ground_pitch_deg: float = 85.0
@export_range(1.0, 1440.0, 1.0, "suffix:deg/s") var ground_pitch_recovery_speed_deg_s: float = 420.0


var _pitch_rad: float = 0.0
var _is_enabled: bool = true

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
	
	visual_rig.register_look_delta(mouse_delta)
	
	var yaw_delta_rad: float = (
		-mouse_delta.x * mouse_sensitivity
	)
	var pitch_delta_rad: float = (
		-mouse_delta.y * mouse_sensitivity
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
