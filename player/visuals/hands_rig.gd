class_name HandRig
extends Node3D

@export var camera: Camera3D

@export_category("offset")
@export var view_offset: Vector3 = Vector3(0.18, -0.22, -0.35)
@export var hidden_offset: Vector3 = Vector3(0.6, -0.9, -0.1)

@export_category("rotation follow")
@export_range(0.0, 60.0, 0.1, "suffix:1/s") var yaw_roll_follow_speed: float = 14.0
@export_range(0.0, 1.0, 0.01) var pitch_up_multiplier: float = 0.45
@export_range(0.0, 1.0, 0.01) var pitch_down_multiplier: float = 0.4

@export_category("hide")
@export_range(0.0, 60.0, 0.1, "suffix:1/s") var hide_follow_speed: float = 10.0

var _is_hidden: bool = false
var _is_airborne: bool = false
var _current_offset: Vector3 = Vector3.ZERO


func _ready() -> void:
	if camera == null:
		push_error("HandRig requires a Camera3D reference.")
		set_process(false)
		return

	top_level = true
	_current_offset = view_offset
	global_transform = camera.global_transform


func _process(delta: float) -> void:
	if camera == null:
		return

	_follow_rotation(delta)
	_follow_offset(delta)


func set_hidden(value: bool) -> void:
	_is_hidden = value


func set_airborne(value: bool) -> void:
	_is_airborne = value


func _follow_rotation(delta: float) -> void:
	var camera_euler: Vector3 = (
		camera.global_transform.basis.get_euler()
	)

	var target_pitch_rad: float = camera_euler.x

	if not _is_airborne:
		if target_pitch_rad < 0.0:
			target_pitch_rad *= pitch_up_multiplier
		else:
			target_pitch_rad *= pitch_down_multiplier

	var target_basis: Basis = Basis.from_euler(
		Vector3(
			target_pitch_rad,
			camera_euler.y,
			camera_euler.z
		)
	)

	var follow_weight: float = minf(
		yaw_roll_follow_speed * delta,
		1.0
	)

	var current_quat: Quaternion = Quaternion(
		global_transform.basis.orthonormalized()
	)

	var target_quat: Quaternion = Quaternion(
		target_basis.orthonormalized()
	)

	global_transform.basis = Basis(
		current_quat.slerp(target_quat, follow_weight)
	)


func _follow_offset(delta: float) -> void:
	var target_offset: Vector3 = (
		hidden_offset if _is_hidden else view_offset
	)

	_current_offset = _current_offset.lerp(
		target_offset,
		minf(hide_follow_speed * delta, 1.0)
	)

	global_transform.origin = (
		camera.global_transform.origin
		+ camera.global_transform.basis * _current_offset
	)
