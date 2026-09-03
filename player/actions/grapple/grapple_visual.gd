class_name GrappleVisual
extends Node3D

signal hook_outgoing_started()
signal hook_attached()
signal hook_returning_started()
signal hook_hidden()

enum VisualState {
	HIDDEN,
	OUTGOING,
	ATTACHED,
	RETURNING,
}

@export_category("references")
@export var movement_motor: MovementMotor
@export var hook_origin: Marker3D
@export var hook_mesh: MeshInstance3D

@export_category("hook orientation")
@export var hook_local_rotation_offset_deg: Vector3 = Vector3(
	-90.0,
	0.0,
	0.0
)

@export_category("motion")
@export_range(
	0.1,
	5.0,
	0.01
) var outgoing_ease_power: float = 1.65

@export_range(
	0.1,
	5.0,
	0.01
) var return_ease_power: float = 1.45

var _grapple_action: GrappleAction
var _visual_state: VisualState = (
	VisualState.HIDDEN
)

var _target_position: Vector3 = Vector3.ZERO
var _anchor_normal: Vector3 = Vector3.UP
var _flight_elapsed_s: float = 0.0
var _flight_duration_s: float = 0.0

var _return_start_position: Vector3 = Vector3.ZERO
var _return_elapsed_s: float = 0.0
var _return_duration_s: float = 0.0


func _ready() -> void:
	if movement_motor == null:
		push_error(
			"GrappleVisual requires MovementMotor."
		)

		set_process(false)
		return

	if hook_origin == null:
		push_error(
			"GrappleVisual requires HookOrigin."
		)

		set_process(false)
		return

	if hook_mesh == null:
		push_error(
			"GrappleVisual requires HookMesh."
		)

		set_process(false)
		return

	hook_mesh.visible = false

	call_deferred(
		"_connect_grapple_action"
	)


func _connect_grapple_action() -> void:
	if not is_instance_valid(movement_motor):
		push_error(
			"GrappleVisual lost MovementMotor before setup."
		)

		set_process(false)
		return

	_grapple_action = movement_motor.get_grapple_action()

	if _grapple_action == null:
		push_error(
			"GrappleVisual could not get GrappleAction "
			+ "after deferred setup."
		)

		set_process(false)
		return

	if not _grapple_action.hook_fired.is_connected(
		_on_hook_fired
	):
		_grapple_action.hook_fired.connect(
			_on_hook_fired
		)

	if not _grapple_action.hook_attached.is_connected(
		_on_hook_attached
	):
		_grapple_action.hook_attached.connect(
			_on_hook_attached
		)

	if not _grapple_action.hook_finished.is_connected(
		_on_hook_finished
	):
		_grapple_action.hook_finished.connect(
			_on_hook_finished
		)

	if not _grapple_action.hook_reset.is_connected(
		_on_hook_reset
	):
		_grapple_action.hook_reset.connect(
			_on_hook_reset
		)


func _process(
	delta: float
) -> void:
	match _visual_state:
		VisualState.OUTGOING:
			_update_outgoing(
				delta
			)

		VisualState.ATTACHED:
			_update_attached()

		VisualState.RETURNING:
			_update_returning(
				delta
			)


func _on_hook_fired(
	target_position: Vector3,
	travel_duration_s: float
) -> void:
	_target_position = target_position

	_flight_elapsed_s = 0.0
	_flight_duration_s = maxf(
		travel_duration_s,
		0.001
	)

	_visual_state = VisualState.OUTGOING

	hook_mesh.global_position = (
		hook_origin.global_position
	)

	hook_mesh.visible = true

	hook_outgoing_started.emit()


func _on_hook_attached(
	anchor_position: Vector3,
	_rope_length_m: float,
	anchor_normal: Vector3
) -> void:
	_target_position = anchor_position

	if anchor_normal.length_squared() > 0.0001:
		_anchor_normal = anchor_normal.normalized()
	else:
		_anchor_normal = Vector3.UP

	_visual_state = VisualState.ATTACHED

	hook_mesh.global_position = (
		_target_position
	)

	_rotate_hook_into_surface(
		_anchor_normal
	)

	hook_attached.emit()


func _on_hook_finished(
_was_cancelled: bool
) -> void:
	if not hook_mesh.visible:
		return

	_return_start_position = (
		hook_mesh.global_position
	)

	var return_distance_m: float = (
		_return_start_position.distance_to(
			hook_origin.global_position
		)
	)

	var return_speed_mps: float = (
		_grapple_action.get_hook_return_speed_mps()
	)

	_return_duration_s = (
		return_distance_m
		/ maxf(
			return_speed_mps,
			0.001
		)
	)

	_return_elapsed_s = 0.0

	_visual_state = VisualState.RETURNING

	hook_returning_started.emit()


func _update_outgoing(
	delta: float
) -> void:
	_flight_elapsed_s = minf(
		_flight_elapsed_s
		+ delta,
		_flight_duration_s
	)

	var flight_progress: float = clampf(
		_flight_elapsed_s
		/ _flight_duration_s,
		0.0,
		1.0
	)

	var eased_progress: float = pow(
		flight_progress,
		outgoing_ease_power
	)

	var origin_position: Vector3 = (
		hook_origin.global_position
	)

	hook_mesh.global_position = origin_position.lerp(
		_target_position,
		eased_progress
	)

	_rotate_hook_toward(
		_target_position
	)

	if flight_progress < 1.0:
		return

	hook_mesh.global_position = (
		_target_position
	)


func _update_attached() -> void:
	hook_mesh.global_position = (
		_target_position
	)


func _update_returning(
	delta: float
) -> void:
	_return_elapsed_s = minf(
		_return_elapsed_s
		+ delta,
		_return_duration_s
	)

	var return_progress: float = clampf(
		_return_elapsed_s
		/ maxf(
			_return_duration_s,
			0.001
		),
		0.0,
		1.0
	)

	var eased_progress: float = pow(
		return_progress,
		return_ease_power
	)

	var origin_position: Vector3 = (
		hook_origin.global_position
	)

	hook_mesh.global_position = _return_start_position.lerp(
		origin_position,
		eased_progress
	)

	_rotate_hook_toward(
		origin_position
	)

	if return_progress < 1.0:
		return

	hook_mesh.visible = false

	_visual_state = VisualState.HIDDEN

	hook_hidden.emit()


func _rotate_hook_into_surface(
	surface_normal: Vector3
) -> void:
	if surface_normal.length_squared() <= 0.0001:
		return

	var hook_forward_direction: Vector3 = (
		-surface_normal.normalized()
	)

	_apply_hook_rotation(
		hook_forward_direction
	)


func _rotate_hook_toward(
	target_position: Vector3
) -> void:
	var direction: Vector3 = (
		target_position
		- hook_mesh.global_position
	)

	if direction.length_squared() <= 0.0001:
		return

	_apply_hook_rotation(
		direction.normalized()
	)


func _apply_hook_rotation(
	forward_direction: Vector3
) -> void:
	if forward_direction.length_squared() <= 0.0001:
		return

	var up_direction: Vector3 = Vector3.UP

	if absf(
		forward_direction.normalized().dot(
			up_direction
		)
	) > 0.99:
		up_direction = Vector3.FORWARD

	hook_mesh.look_at(
		hook_mesh.global_position
		+ forward_direction.normalized(),
		up_direction,
		true
	)

	hook_mesh.rotate_object_local(
		Vector3.RIGHT,
		deg_to_rad(
			hook_local_rotation_offset_deg.x
		)
	)

	hook_mesh.rotate_object_local(
		Vector3.UP,
		deg_to_rad(
			hook_local_rotation_offset_deg.y
		)
	)

	hook_mesh.rotate_object_local(
		Vector3.FORWARD,
		deg_to_rad(
			hook_local_rotation_offset_deg.z
		)
	)


func is_hook_visible() -> bool:
	return hook_mesh.visible


func is_hook_attached() -> bool:
	return _visual_state == VisualState.ATTACHED


func get_hook_position() -> Vector3:
	return hook_mesh.global_position


func get_wrap_positions() -> PackedVector3Array:
	if _grapple_action == null:
		return PackedVector3Array()

	return _grapple_action.get_wrap_positions()


func _on_hook_reset() -> void:
	_flight_elapsed_s = 0.0
	_flight_duration_s = 0.0

	_return_elapsed_s = 0.0
	_return_duration_s = 0.0

	_visual_state = VisualState.HIDDEN

	hook_mesh.visible = false

	hook_hidden.emit()
