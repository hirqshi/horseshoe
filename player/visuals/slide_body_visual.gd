class_name SlideBodyVisual
extends Node3D

@export var camera: Camera3D
@export var motor: MovementMotor
@export var model_root: Node3D
@export var animation_player: AnimationPlayer

@export_category("offset")
@export var view_offset: Vector3 = Vector3(0.0, -0.55, -0.4)

@export_category("orientation")
@export_range(0.0, 60.0, 0.1, "suffix:1/s") var normal_align_speed: float = 12.0

@export_category("animation")
@export var slide_animation_name: StringName = &"slide_loop"

var _is_sliding: bool = false


func _ready() -> void:
	if camera == null or motor == null or model_root == null:
		push_error(
			"SlideBodyVisual requires Camera3D, MovementMotor and model_root."
		)
		set_process(false)
		return

	top_level = true
	model_root.visible = false

	motor.slide_started.connect(_on_slide_started)
	motor.slide_finished.connect(_on_slide_finished)


func _process(delta: float) -> void:
	if not _is_sliding:
		return

	_update_orientation(delta)

	global_transform.origin = (
		camera.global_transform.origin
		+ global_transform.basis * view_offset
	)


func _get_body_forward() -> Vector3:
	var body: CharacterBody3D = motor.get_body()

	if body == null:
		return Vector3.FORWARD

	return -body.global_transform.basis.z


func _get_camera_yaw_basis() -> Basis:
	return Basis.looking_at(
		_get_body_forward(),
		Vector3.UP
	)


func _get_target_basis() -> Basis:
	var yaw_basis: Basis = _get_camera_yaw_basis()

	var body: CharacterBody3D = motor.get_body()

	if body == null or not body.is_on_floor():
		return yaw_basis

	var floor_normal: Vector3 = body.get_floor_normal()

	if floor_normal.is_zero_approx():
		return yaw_basis

	var tilt_axis: Vector3 = Vector3.UP.cross(floor_normal)

	if tilt_axis.length_squared() <= 0.0001:
		return yaw_basis

	var tilt_angle_rad: float = Vector3.UP.angle_to(floor_normal)

	return Basis(
		tilt_axis.normalized(),
		tilt_angle_rad
	) * yaw_basis


func _update_orientation(delta: float) -> void:
	var target_basis: Basis = _get_target_basis()

	var current_quat: Quaternion = Quaternion(
		global_transform.basis.orthonormalized()
	)

	var target_quat: Quaternion = Quaternion(
		target_basis.orthonormalized()
	)

	global_transform.basis = Basis(
		current_quat.slerp(
			target_quat,
			minf(normal_align_speed * delta, 1.0)
		)
	)


func _on_slide_started() -> void:
	_is_sliding = true
	model_root.visible = true

	global_transform.basis = _get_target_basis()

	global_transform.origin = (
		camera.global_transform.origin
		+ global_transform.basis * view_offset
	)

	if animation_player != null:
		animation_player.play(slide_animation_name)


func _on_slide_finished() -> void:
	_is_sliding = false
	model_root.visible = false

	if animation_player != null:
		animation_player.stop()
