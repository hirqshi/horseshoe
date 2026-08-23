class_name PlayerSensors
extends Node3D

@export_category("collision")
@export var traversal_collision_mask: int = 1

@export_category("wall probes")
@export var wall_probe_left: RayCast3D
@export var wall_probe_right: RayCast3D
@export var wall_probe_height_m: float = 1.1
@export var wall_probe_distance_m: float = 0.7
@export_range(0.0, 1.0, 0.01) var max_wall_normal_y: float = 0.2

@export var is_wall_probe_debug_enabled: bool = false

var _body: CharacterBody3D
var _left_wall: WallContact = WallContact.new()
var _right_wall: WallContact = WallContact.new()

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error("PlayerSensors must be a child of CharacterBody3D.")
		set_process(false)
		return

	if wall_probe_left == null or wall_probe_right == null:
		push_error("PlayerSensors requires left and right wall probes.")
		set_process(false)
		return

	_setup_wall_probe(
		wall_probe_left,
		Vector3.LEFT * wall_probe_distance_m
	)
	_setup_wall_probe(
		wall_probe_right,
		Vector3.RIGHT * wall_probe_distance_m
	)

func update_contacts() -> void:
	wall_probe_left.force_raycast_update()
	wall_probe_right.force_raycast_update()

	_left_wall = _read_wall_probe(
		wall_probe_left,
		WallContact.Side.LEFT
	)
	_right_wall = _read_wall_probe(
		wall_probe_right,
		WallContact.Side.RIGHT
	)
	if is_wall_probe_debug_enabled:
		_debug_wall_probe(wall_probe_left, "left")
		_debug_wall_probe(wall_probe_right, "right")

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

func _setup_wall_probe(
	probe: RayCast3D,
	target_position: Vector3
) -> void:
	probe.position = Vector3.UP * wall_probe_height_m
	probe.target_position = target_position
	probe.collision_mask = traversal_collision_mask
	probe.collide_with_areas = false
	probe.collide_with_bodies = true
	probe.enabled = true
	probe.add_exception(_body)

func _read_wall_probe(
	probe: RayCast3D,
	side: int
) -> WallContact:
	if not probe.is_colliding():
		return WallContact.new()

	var normal: Vector3 = probe.get_collision_normal()

	if absf(normal.y) > max_wall_normal_y:
		return WallContact.new()

	var collider: Object = probe.get_collider()
	if not is_instance_valid(collider):
		return WallContact.new()

	var contact: WallContact = WallContact.new()
	contact.side = side
	contact.point = probe.get_collision_point()
	contact.normal = normal.normalized()
	contact.distance_m = probe.global_position.distance_to(contact.point)
	contact.collider = collider

	return contact

func _debug_wall_probe(
	probe: RayCast3D,
	probe_name: String
) -> void:
	var from: Vector3 = probe.global_position
	var to: Vector3 = probe.to_global(probe.target_position)

	print(
		"%s | player: %s | probe: %s -> %s | hit: %s"
		% [
			probe_name,
			_body.global_position,
			from,
			to,
			probe.is_colliding(),
		]
	)

	if not probe.is_colliding():
		return

	print(
		"%s hit | collider: %s | point: %s | normal: %s"
		% [
			probe_name,
			probe.get_collider(),
			probe.get_collision_point(),
			probe.get_collision_normal(),
		]
	)
