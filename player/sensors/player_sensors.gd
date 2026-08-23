class_name PlayerSensors
extends Node

@export_category("collision")
@export var traversal_collision_mask: int = 1

@export_category("wall probe")
@export var wall_probe_height_m: float = 1.1
@export var wall_probe_distance_m: float = 0.7
@export_range(0.0, 1.0, 0.01) var max_wall_normal_y: float = 0.2

var _body: CharacterBody3D
var _left_wall: WallContact = WallContact.new()
var _right_wall: WallContact = WallContact.new()

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error("PlayerSensors must be a child of CharacterBody3D.")
		set_process(false)

func update_contacts() -> void:
	if _body == null:
		return

	_left_wall = _query_wall(WallContact.Side.LEFT)
	_right_wall = _query_wall(WallContact.Side.RIGHT)

func get_left_wall() -> WallContact:
	return _left_wall

func get_right_wall() -> WallContact:
	return _right_wall

func get_best_wall() -> WallContact:
	if _left_wall.is_valid() and _right_wall.is_valid():
		if _left_wall.distance_m <= _right_wall.distance_m:
			return _left_wall
		return _right_wall

	if _left_wall.is_valid():
		return _left_wall

	return _right_wall

func _query_wall(side: int) -> WallContact:
	var origin: Vector3 = (
		_body.global_position
		+ Vector3.UP * wall_probe_height_m
	)

	var direction: Vector3 = _get_side_direction(side)
	var hit: Dictionary = _raycast(
		origin,
		origin + direction * wall_probe_distance_m
	)

	if hit.is_empty():
		return WallContact.new()

	var normal: Vector3 = hit["normal"]
	if absf(normal.y) > max_wall_normal_y:
		return WallContact.new()

	var collider: CollisionObject3D = hit["collider"] as CollisionObject3D
	if collider == null:
		return WallContact.new()

	var contact: WallContact = WallContact.new()
	contact.side = side
	contact.point = hit["position"]
	contact.normal = normal
	contact.distance_m = origin.distance_to(contact.point)
	contact.collider = collider

	return contact

func _get_side_direction(side: int) -> Vector3:
	var right: Vector3 = _body.global_basis.x
	right.y = 0.0
	right = right.normalized()

	if side == WallContact.Side.LEFT:
		return -right

	return right

func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			from,
			to,
			traversal_collision_mask,
			[_body.get_rid()]
		)
	)

	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = false

	var space_state: PhysicsDirectSpaceState3D = (
		_body.get_world_3d().direct_space_state
	)

	return space_state.intersect_ray(query)
