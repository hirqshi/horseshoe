class_name GrappleWrapPoint
extends RefCounted

var position: Vector3
var surface_normal: Vector3


func _init(
	initial_position: Vector3,
	initial_surface_normal: Vector3
) -> void:
	position = initial_position

	if initial_surface_normal.length_squared() <= 0.0001:
		surface_normal = Vector3.UP
		return

	surface_normal = initial_surface_normal.normalized()
