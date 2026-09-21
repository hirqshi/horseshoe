class_name PlayerSelfie
extends Control

@export_group("References")
@export var portrait_viewport: SubViewport
@export var portrait_camera: Camera3D

@export_group("Camera Offset")
@export var camera_offset_local: Vector3 = Vector3(
	0.42,
	0.05,
	-0.82
)

@export var look_target_offset_local: Vector3 = Vector3(
	0.0,
	0.0,
	0.0
)

@export_group("Camera Follow")
@export_range(1.0, 100.0, 0.1) var rotation_follow_speed: float = 12.0
@export_range(1.0, 100.0, 0.1) var horizontal_follow_speed: float = 13.0
@export_range(1.0, 100.0, 0.1) var vertical_follow_speed: float = 8.0
@export_range(1.0, 100.0, 0.1) var depth_follow_speed: float = 22.0

var _player: Player = null
var _portrait_avatar: PortraitAvatar = null
var _face_anchor: Node3D = null
var _has_camera_transform: bool = false
var _smoothed_camera_local_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if portrait_viewport == null:
		push_error(
			"PlayerSelfie requires a PortraitViewport."
		)
		return

	if portrait_camera == null:
		push_error(
			"PlayerSelfie requires a PortraitCamera."
		)
		return

	portrait_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	portrait_viewport.render_target_clear_mode = (
		SubViewport.CLEAR_MODE_ALWAYS
	)

	portrait_camera.make_current()


func setup(
	player: Player
) -> void:
	if _player != null:
		push_warning(
			"PlayerSelfie.setup() was called more than once."
		)
		return

	if player == null:
		push_error(
			"PlayerSelfie requires a Player."
		)
		return

	if portrait_viewport == null:
		push_error(
			"PlayerSelfie has no PortraitViewport."
		)
		return

	if portrait_camera == null:
		push_error(
			"PlayerSelfie has no PortraitCamera."
		)
		return

	_player = player

	_portrait_avatar = _player.get_portrait_avatar()

	if _portrait_avatar == null:
		push_error(
			"PlayerSelfie could not get PortraitAvatar from Player."
		)
		return

	var source_camera: Camera3D = _player.get_gameplay_camera()

	if source_camera == null:
		push_error(
			"PlayerSelfie could not get GameplayCamera from Player."
		)
		return

	var shared_world: World3D = source_camera.get_world_3d()

	if shared_world == null:
		push_error(
			"PlayerSelfie could not get World3D from GameplayCamera."
		)
		return

	_face_anchor = _portrait_avatar.get_face_anchor()

	if _face_anchor == null:
		push_error(
			"PlayerSelfie could not get FaceAnchor from PortraitAvatar."
		)
		return

	portrait_viewport.world_3d = shared_world

	_portrait_avatar.setup(
		_player,
		source_camera
	)


func _process(
	delta: float
) -> void:
	if _face_anchor == null:
		return

	if portrait_camera == null:
		return

	if not is_instance_valid(
		_face_anchor
	):
		return

	_update_portrait_camera(
		delta
	)


func _update_portrait_camera(
	delta: float
) -> void:
	if _player == null:
		return

	if not is_instance_valid(
		_player
	):
		return

	var face_basis: Basis = (
		_face_anchor.global_basis.orthonormalized()
	)

	var target_camera_position: Vector3 = (
		_face_anchor.global_position
		+ face_basis
		* camera_offset_local
	)

	var target_look_position: Vector3 = (
		_face_anchor.global_position
		+ face_basis
		* look_target_offset_local
	)

	var target_camera_local_position: Vector3 = (
		_player.to_local(
			target_camera_position
		)
	)

	if not _has_camera_transform:
		_smoothed_camera_local_position = (
			target_camera_local_position
		)

		var initial_basis: Basis = Basis.looking_at(
			target_look_position
			- target_camera_position,
			face_basis.y
		)

		portrait_camera.global_transform = Transform3D(
			initial_basis,
			target_camera_position
		)

		_has_camera_transform = true
		return

	var horizontal_weight: float = (
		1.0
		- exp(
			-horizontal_follow_speed
			* delta
		)
	)

	var vertical_weight: float = (
		1.0
		- exp(
			-vertical_follow_speed
			* delta
		)
	)

	var depth_weight: float = (
		1.0
		- exp(
			-depth_follow_speed
			* delta
		)
	)

	_smoothed_camera_local_position.x = lerpf(
		_smoothed_camera_local_position.x,
		target_camera_local_position.x,
		horizontal_weight
	)

	_smoothed_camera_local_position.y = lerpf(
		_smoothed_camera_local_position.y,
		target_camera_local_position.y,
		vertical_weight
	)

	_smoothed_camera_local_position.z = lerpf(
		_smoothed_camera_local_position.z,
		target_camera_local_position.z,
		depth_weight
	)

	var smoothed_camera_position: Vector3 = (
		_player.to_global(
			_smoothed_camera_local_position
		)
	)

	var target_basis: Basis = Basis.looking_at(
		target_look_position
		- smoothed_camera_position,
		face_basis.y
	)

	var target_rotation: Quaternion = (
		target_basis
		.orthonormalized()
		.get_rotation_quaternion()
	)

	var current_rotation: Quaternion = (
		portrait_camera.global_basis
		.orthonormalized()
		.get_rotation_quaternion()
	)

	var rotation_weight: float = (
		1.0
		- exp(
			-rotation_follow_speed
			* delta
		)
	)

	var smoothed_rotation: Quaternion = (
		current_rotation.slerp(
			target_rotation,
			rotation_weight
		)
	)

	portrait_camera.global_transform = Transform3D(
		Basis(
			smoothed_rotation
		),
		smoothed_camera_position
	)
