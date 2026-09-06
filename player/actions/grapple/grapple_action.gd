class_name GrappleAction
extends MovementAction

signal hook_reset()

signal target_availability_changed(
	is_available: bool
)

signal hook_fired(
	target_position: Vector3,
	travel_duration_s: float
)

signal hook_attached(
	anchor_position: Vector3,
	rope_length_m: float,
	anchor_normal: Vector3
)

signal pull_started()

signal hook_finished(
	was_cancelled: bool
)

signal cooldown_started(
	duration_s: float
)

enum GrappleState {
	READY,
	OUTGOING,
	SWINGING,
	PULLING,
}

@export_category("references")
@export var config: GrappleConfig
@export var aim_ray: RayCast3D

var _motor: MovementMotor

var _state: GrappleState = (
	GrappleState.READY
)

var _has_valid_target: bool = false
var _target_position: Vector3 = Vector3.ZERO
var _target_normal: Vector3 = Vector3.UP

var _anchor_position: Vector3 = Vector3.ZERO
var _anchor_normal: Vector3 = Vector3.UP
var _rope_length_m: float = 0.0

var _wrap_points: Array[GrappleWrapPoint] = []

var _outgoing_remaining_s: float = 0.0

var _cooldown_until_s: float = -INF
var _is_active: bool = false

var _has_reached_pull_target: bool = false


func setup(
	motor: MovementMotor
) -> void:
	_motor = motor

	if config == null:
		push_error(
			"GrappleAction requires GrappleConfig."
		)

		set_process(false)
		return

	if aim_ray == null:
		push_error(
			"GrappleAction requires an AimRay."
		)

		set_process(false)
		return

	var body: CharacterBody3D = (
		_motor.get_body()
	)

	if body != null:
		aim_ray.add_exception(
			body
		)

	aim_ray.enabled = true
	aim_ray.collide_with_areas = false


func update(
	context: MovementContext
) -> void:
	_update_target(
		context
	)


func can_start(
	context: MovementContext
) -> bool:
	if not context.player_input.is_grapple_pressed:
		return false

	if is_on_cooldown(
		context.time_s
	):
		return false

	_update_target(
		context
	)

	return _has_valid_target


func start(
	context: MovementContext
) -> void:
	_motor.cancel_glide()

	_state = GrappleState.OUTGOING
	_is_active = true
	_has_reached_pull_target = false

	_anchor_position = _target_position
	_anchor_normal = _target_normal

	var physics_origin: Vector3 = (
		context.body.global_position
	)

	var target_distance_m: float = physics_origin.distance_to(
		_anchor_position
	)

	_rope_length_m = target_distance_m + (
		config.rope_slack_m
	)

	_wrap_points.clear()

	_outgoing_remaining_s = (
		target_distance_m
		/ maxf(
			config.hook_travel_speed_mps,
			0.001
		)
	)

	hook_fired.emit(
		_anchor_position,
		_outgoing_remaining_s
	)


func physics_tick(
	context: MovementContext
) -> bool:
	match _state:
		GrappleState.OUTGOING:
			return _tick_outgoing(
				context
			)

		GrappleState.SWINGING:
			return _tick_swinging(
				context
			)

		GrappleState.PULLING:
			return _tick_pulling(
				context
			)

	return false


func finish(
	context: MovementContext
) -> void:
	if not _is_active:
		return

	var was_cancelled: bool = (
		not _has_reached_pull_target
	)

	_is_active = false
	_state = GrappleState.READY
	_outgoing_remaining_s = 0.0
	_rope_length_m = 0.0
	_has_reached_pull_target = false

	_cooldown_until_s = (
		context.time_s
		+ config.cooldown_s
	)

	hook_finished.emit(
		was_cancelled
	)

	cooldown_started.emit(
		config.cooldown_s
	)


func reset_after_respawn() -> void:
	var had_target: bool = _has_valid_target

	_state = GrappleState.READY
	_is_active = false
	_has_reached_pull_target = false

	_outgoing_remaining_s = 0.0
	_rope_length_m = 0.0
	_cooldown_until_s = -INF

	_anchor_position = Vector3.ZERO
	_anchor_normal = Vector3.UP

	_wrap_points.clear()

	_has_valid_target = false
	_target_position = Vector3.ZERO
	_target_normal = Vector3.UP

	if had_target:
		target_availability_changed.emit(
			false
		)

	hook_reset.emit()


func is_on_cooldown(
	current_time_s: float
) -> bool:
	return current_time_s < _cooldown_until_s


func is_target_available() -> bool:
	return _has_valid_target


func is_active() -> bool:
	return _is_active


func get_anchor_position() -> Vector3:
	return _anchor_position


func get_rope_length_m() -> float:
	return _rope_length_m


func _tick_outgoing(
	context: MovementContext
) -> bool:
	if config.is_hold_to_pull_mode() \
	and not context.player_input.is_grapple_held:
		return false

	_outgoing_remaining_s = maxf(
		_outgoing_remaining_s
		- context.delta,
		0.0
	)

	if _outgoing_remaining_s > 0.0:
		return true

	hook_attached.emit(
		_anchor_position,
		_rope_length_m,
		_anchor_normal
	)

	if config.is_hold_to_pull_mode():
		_begin_pull()
		return true

	_state = GrappleState.SWINGING

	if not context.player_input.is_grapple_held:
		_begin_pull()

	return true


func _tick_swinging(
	context: MovementContext
) -> bool:
	_update_rope_wrapping(
		context
	)

	_apply_rope_constraint(
		context
	)

	if context.player_input.is_grapple_held:
		return true

	_begin_pull()

	return true


func _tick_pulling(
	context: MovementContext
) -> bool:
	if config.is_hold_to_pull_mode() \
	and not context.player_input.is_grapple_held:
		return false

	_update_rope_wrapping(
		context
	)

	var pull_target: Vector3 = _get_pull_target()

	var offset_to_pull_target: Vector3 = (
		pull_target
		- context.body.global_position
	)

	var distance_to_pull_target_m: float = (
		offset_to_pull_target.length()
	)

	var has_wrap_points: bool = (
		not _wrap_points.is_empty()
	)

	if not has_wrap_points \
	and distance_to_pull_target_m <= (
		config.pull_arrival_distance_m
	):
		_has_reached_pull_target = true
		return false

	if distance_to_pull_target_m <= 0.001:
		return true

	_apply_rope_constraint(
		context
	)

	var pull_direction: Vector3 = (
		offset_to_pull_target
		/ distance_to_pull_target_m
	)

	var current_toward_speed_mps: float = (
		context.velocity.dot(
			pull_direction
		)
	)

	var remaining_pull_speed_mps: float = maxf(
		config.maximum_pull_speed_mps
		- current_toward_speed_mps,
		0.0
	)

	var pull_speed_delta_mps: float = minf(
		config.pull_acceleration_mps2
		* context.delta,
		remaining_pull_speed_mps
	)

	context.velocity += (
		pull_direction
		* pull_speed_delta_mps
	)

	return true


func _begin_pull() -> void:
	if _state == GrappleState.PULLING:
		return

	_state = GrappleState.PULLING

	pull_started.emit()


func _apply_rope_constraint(
	context: MovementContext
) -> void:
	var physics_origin: Vector3 = (
		context.body.global_position
	)

	var constraint_target: Vector3 = (
		_get_constraint_target()
	)

	var offset_from_constraint_target: Vector3 = (
		physics_origin
		- constraint_target
	)

	var first_segment_length_m: float = (
		offset_from_constraint_target.length()
	)

	if first_segment_length_m <= 0.001:
		return

	var fixed_route_length_m: float = (
		_get_fixed_route_length_m()
	)

	var allowed_first_segment_length_m: float = maxf(
		_rope_length_m
		- fixed_route_length_m,
		0.0
	)

	if first_segment_length_m <= (
		allowed_first_segment_length_m
	):
		return

	var outward_direction: Vector3 = (
		offset_from_constraint_target
		/ first_segment_length_m
	)

	var outward_speed_mps: float = (
		context.velocity.dot(
			outward_direction
		)
	)

	if outward_speed_mps > 0.0:
		context.velocity -= (
			outward_direction
			* outward_speed_mps
		)

	var rope_stretch_m: float = (
		first_segment_length_m
		- allowed_first_segment_length_m
	)

	var correction_mps2: float = minf(
		rope_stretch_m
		* config.rope_constraint_acceleration_per_m,
		config.maximum_rope_correction_mps2
	)

	context.velocity -= (
		outward_direction
		* correction_mps2
		* context.delta
	)


func _update_target(
	_context: MovementContext
) -> void:
	aim_ray.target_position = Vector3(
		0.0,
		0.0,
		-config.maximum_target_distance_m
	)

	aim_ray.force_raycast_update()

	var previous_target_availability: bool = (
		_has_valid_target
	)

	_has_valid_target = false

	if not aim_ray.is_colliding():
		_emit_target_change_if_needed(
			previous_target_availability
		)

		return

	var collision_position: Vector3 = (
		aim_ray.get_collision_point()
	)
	
	var collision_normal: Vector3 = (
		aim_ray.get_collision_normal()
	)
	
	var target_distance_m: float = aim_ray.global_position.distance_to(
		collision_position
	)

	if target_distance_m < (
		config.minimum_target_distance_m
	):
		_emit_target_change_if_needed(
			previous_target_availability
		)

		return

	_target_position = collision_position

	if collision_normal.length_squared() > 0.0001:
		_target_normal = collision_normal.normalized()
	else:
		_target_normal = Vector3.UP

	_has_valid_target = true

	_emit_target_change_if_needed(
		previous_target_availability
	)


func _emit_target_change_if_needed(
	previous_target_availability: bool
) -> void:
	if previous_target_availability == _has_valid_target:
		return

	target_availability_changed.emit(
		_has_valid_target
	)


func _update_rope_wrapping(
	context: MovementContext
) -> void:
	if config.maximum_wrap_points <= 0:
		return

	_remove_released_wrap_points(
		context
	)

	_add_blocking_wrap_points(
		context
	)


func _remove_released_wrap_points(
	context: MovementContext
) -> void:
	var physics_origin: Vector3 = (
		context.body.global_position
	)

	var previous_position: Vector3 = physics_origin
	var wrap_index: int = 0

	while wrap_index < _wrap_points.size():
		var next_position: Vector3 = (
			_anchor_position
		)

		if wrap_index + 1 < _wrap_points.size():
			next_position = _wrap_points[
				wrap_index + 1
			].position

		if not _is_rope_segment_blocked(
			context,
			previous_position,
			next_position
		):
			_wrap_points.remove_at(
				wrap_index
			)

			continue

		previous_position = _wrap_points[
			wrap_index
		].position

		wrap_index += 1


func _add_blocking_wrap_points(
	context: MovementContext
) -> void:
	while _wrap_points.size() < (
		config.maximum_wrap_points
	):
		var route_positions: PackedVector3Array = (
			_get_physics_route_positions(
				context.body.global_position
			)
		)

		var was_wrap_point_added: bool = false

		for segment_index: int in range(
			route_positions.size() - 1
		):
			var segment_start: Vector3 = route_positions[
				segment_index
			]

			var segment_end: Vector3 = route_positions[
				segment_index + 1
			]

			var hit: Dictionary = _raycast_rope_segment(
				context,
				segment_start,
				segment_end
			)

			if hit.is_empty():
				continue

			var hit_position: Vector3 = hit[
				"position"
			]

			if hit_position.distance_to(
				segment_end
			) <= config.wrap_endpoint_tolerance_m:
				continue

			var hit_normal: Vector3 = hit[
				"normal"
			]

			if hit_normal.length_squared() <= 0.0001:
				continue

			var wrap_position: Vector3 = (
				hit_position
				+ hit_normal.normalized()
				* config.wrap_surface_offset_m
			)

			_wrap_points.insert(
				segment_index,
				GrappleWrapPoint.new(
					wrap_position,
					hit_normal
				)
			)

			was_wrap_point_added = true
			break

		if not was_wrap_point_added:
			return


func _is_rope_segment_blocked(
	context: MovementContext,
	segment_start: Vector3,
	segment_end: Vector3
) -> bool:
	var hit: Dictionary = _raycast_rope_segment(
		context,
		segment_start,
		segment_end
	)

	if hit.is_empty():
		return false

	var hit_position: Vector3 = hit[
		"position"
	]

	return hit_position.distance_to(
		segment_end
	) > config.wrap_endpoint_tolerance_m


func _raycast_rope_segment(
	context: MovementContext,
	segment_start: Vector3,
	segment_end: Vector3
) -> Dictionary:
	if segment_start.distance_to(
		segment_end
	) <= 0.001:
		return {}

	var excluded_rids: Array[RID] = [
		context.body.get_rid(),
	]

	var query: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			segment_start,
			segment_end,
			aim_ray.collision_mask,
			excluded_rids
		)
	)

	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_back_faces = true

	return context.body.get_world_3d().direct_space_state.intersect_ray(
		query
	)


func _get_physics_route_positions(
	physics_origin: Vector3
) -> PackedVector3Array:
	var route_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	route_positions.append(
		physics_origin
	)

	for wrap_point: GrappleWrapPoint in _wrap_points:
		route_positions.append(
			wrap_point.position
		)

	route_positions.append(
		_anchor_position
	)

	return route_positions


func _get_constraint_target() -> Vector3:
	if _wrap_points.is_empty():
		return _anchor_position

	return _wrap_points[0].position


func _get_pull_target() -> Vector3:
	return _get_constraint_target()


func _get_fixed_route_length_m() -> float:
	if _wrap_points.is_empty():
		return 0.0

	var route_length_m: float = 0.0
	var previous_position: Vector3 = _wrap_points[0].position

	for wrap_index: int in range(
		1,
		_wrap_points.size()
	):
		var next_position: Vector3 = _wrap_points[
			wrap_index
		].position

		route_length_m += previous_position.distance_to(
			next_position
		)

		previous_position = next_position

	route_length_m += previous_position.distance_to(
		_anchor_position
	)

	return route_length_m


func get_wrap_positions() -> PackedVector3Array:
	var wrap_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	for wrap_point: GrappleWrapPoint in _wrap_points:
		wrap_positions.append(
			wrap_point.position
		)

	return wrap_positions


func get_hook_travel_speed_mps() -> float:
	if config == null:
		return 0.0

	return config.hook_travel_speed_mps


func get_hook_return_speed_mps() -> float:
	if config == null:
		return 0.0

	return config.hook_return_speed_mps


func get_target_distance_m() -> float:
	if aim_ray == null:
		return -1.0

	if not aim_ray.is_colliding():
		return -1.0

	var collision_position: Vector3 = (
		aim_ray.get_collision_point()
	)

	return aim_ray.global_position.distance_to(
		collision_position
	)


func get_max_target_distance_m() -> float:
	if config == null:
		return 0.0

	return config.maximum_target_distance_m
