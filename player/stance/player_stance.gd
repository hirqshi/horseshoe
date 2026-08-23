class_name PlayerStance
extends Node

signal stance_changed(is_crouching: bool)

@export_category("nodes")
@export var standing_collider: CollisionShape3D
@export var crouching_collider: CollisionShape3D
@export var head: Node3D

@export_category("collision")
@export var clearance_collision_mask: int = 1
@export_range(0.0, 0.1, 0.005) var clearance_margin_m: float = 0.02

@export_category("camera")
@export var standing_head_height_m: float = 1.6
@export var crouching_head_height_m: float = 0.95
@export var camera_transition_speed_mps: float = 8.0

var _body: CharacterBody3D
var _is_crouching: bool = false
var _wants_to_stand: bool = false

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error("PlayerStance must be a child of CharacterBody3D.")
		set_process(false)
		return

	if standing_collider == null:
		push_error("PlayerStance requires StandingCollider.")
		set_process(false)
		return

	if crouching_collider == null:
		push_error("PlayerStance requires CrouchingCollider.")
		set_process(false)
		return

	if head == null:
		push_error("PlayerStance requires Head.")
		set_process(false)
		return

	_is_crouching = standing_collider.disabled
	_apply_head_height(true)

func _process(delta: float) -> void:
	_apply_head_height(false, delta)

func _physics_process(_delta: float) -> void:
	if not _wants_to_stand:
		return

	if not can_stand():
		return

	_set_crouching(false)
	_wants_to_stand = false

func is_crouching() -> bool:
	return _is_crouching

func try_set_crouching(value: bool) -> bool:
	if value:
		_wants_to_stand = false

		if _is_crouching:
			return true

		_set_crouching(true)
		return true

	_wants_to_stand = true

	if not _is_crouching:
		_wants_to_stand = false
		return true

	if not can_stand():
		return false

	_set_crouching(false)
	_wants_to_stand = false
	return true

func force_crouching() -> void:
	try_set_crouching(true)

func can_stand() -> bool:
	if standing_collider.shape == null:
		return false

	var query: PhysicsShapeQueryParameters3D = (
		PhysicsShapeQueryParameters3D.new()
	)

	query.shape = standing_collider.shape
	var probe_transform: Transform3D = standing_collider.global_transform
	probe_transform.origin.y += clearance_margin_m

	query.transform = probe_transform
	query.collision_mask = clearance_collision_mask
	query.exclude = [_body.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.margin = 0.0

	var space_state: PhysicsDirectSpaceState3D = (
		_body.get_world_3d().direct_space_state
	)

	var overlaps: Array[Dictionary] = (
		space_state.intersect_shape(query, 1)
	)

	return overlaps.is_empty()

func _apply_head_height(is_immediate: bool, delta: float = 0.0) -> void:
	var target_height_m: float = (
		crouching_head_height_m
		if _is_crouching
		else standing_head_height_m
	)

	if is_immediate:
		head.position.y = target_height_m
		return

	head.position.y = move_toward(
		head.position.y,
		target_height_m,
		camera_transition_speed_mps * delta
	)

func _set_crouching(value: bool) -> void:
	_is_crouching = value
	standing_collider.set_deferred("disabled", _is_crouching)
	crouching_collider.set_deferred("disabled", not _is_crouching)
	stance_changed.emit(_is_crouching)
