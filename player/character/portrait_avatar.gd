class_name PortraitAvatar
extends Node3D

@export_group("References")
@export var face_anchor: Node3D

@export_group("Transform Follow")
@export_range(0.0, 1.0, 0.01) var position_follow_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var rotation_follow_multiplier: float = 1.0

var _player: Player = null
var _source_camera: Camera3D = null


func setup(
	player: Player,
	source_camera: Camera3D
) -> void:
	if _player != null:
		push_warning(
			"PortraitAvatar.setup() was called more than once."
		)
		return

	if player == null:
		push_error(
			"PortraitAvatar requires a Player."
		)
		return

	if source_camera == null:
		push_error(
			"PortraitAvatar requires a source Camera3D."
		)
		return

	if face_anchor == null:
		push_error(
			"PortraitAvatar requires a FaceAnchor."
		)
		return

	_player = player
	_source_camera = source_camera


func get_face_anchor() -> Node3D:
	return face_anchor


func _process(
	_delta: float
) -> void:
	if _player == null:
		return

	if _source_camera == null:
		return

	if not is_instance_valid(
		_player
	):
		return

	if not is_instance_valid(
		_source_camera
	):
		return

	_sync_transform()


func _sync_transform() -> void:
	var target_position: Vector3 = (
		_player.global_position.lerp(
			_source_camera.global_position,
			position_follow_multiplier
		)
	)

	var player_rotation: Quaternion = (
		_player.global_basis
		.orthonormalized()
		.get_rotation_quaternion()
	)

	var camera_rotation: Quaternion = (
		_source_camera.global_basis
		.orthonormalized()
		.get_rotation_quaternion()
	)

	var target_rotation: Quaternion = (
		player_rotation.slerp(
			camera_rotation,
			rotation_follow_multiplier
		)
	)

	global_position = target_position
	global_basis = Basis(
		target_rotation
	)
