class_name WallContact
extends RefCounted

enum Side {
	NONE,
	LEFT,
	RIGHT,
}

var side: int = Side.NONE
var point: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.ZERO
var distance_m: float = INF
var collider: CollisionObject3D

func is_valid() -> bool:
	return side != Side.NONE and is_instance_valid(collider)
