class_name GrappleRopeVisual
extends MeshInstance3D

@export_category("references")
@export var grapple_visual: GrappleVisual
@export var hook_origin: Marker3D
@export var movement_motor: MovementMotor

@export_category("geometry")
@export_range(
	3,
	32,
	1,
	"suffix:rings"
) var ring_count: int = 12

@export_range(
	3,
	24,
	1,
	"suffix:sides"
) var radial_segments: int = 8

@export_range(
	0.001,
	1.0,
	0.001,
	"suffix:m"
) var rope_radius_m: float = 0.025

@export_category("shape")
@export_range(
	0.0,
	1.0,
	0.01
) var attached_sag_ratio: float = 0.055

@export_range(
	0.0,
	5.0,
	0.01,
	"suffix:m"
) var maximum_sag_m: float = 1.15

@export_range(
	0.0,
	1.0,
	0.01
) var outgoing_sag_multiplier: float = 0.08

@export_range(
	0.0,
	1.0,
	0.01
) var returning_sag_multiplier: float = 0.12

@export_range(
	0.0,
	0.25,
	0.001,
	"suffix:m per m/s"
) var swing_velocity_bend_per_mps: float = 0.018

@export_range(
	0.0,
	5.0,
	0.01,
	"suffix:m"
) var maximum_swing_bend_m: float = 0.85

var _array_mesh: ArrayMesh = ArrayMesh.new()

var _is_rope_visible: bool = false
var _is_hook_attached: bool = false
var _is_hook_returning: bool = false


func _ready() -> void:
	if grapple_visual == null:
		push_error(
			"GrappleRopeVisual requires GrappleVisual."
		)

		set_process(false)
		return

	if hook_origin == null:
		push_error(
			"GrappleRopeVisual requires HookOrigin."
		)

		set_process(false)
		return

	if movement_motor == null:
		push_error(
			"GrappleRopeVisual requires MovementMotor."
		)

		set_process(false)
		return

	mesh = _array_mesh

	_warm_up_rope_mesh()

	visible = false

	call_deferred(
		"_connect_grapple_visual"
	)


func _warm_up_rope_mesh() -> void:
	var warmup_length_m: float = 1.0

	var warmup_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	warmup_positions.append(
		Vector3.ZERO
	)

	warmup_positions.append(
		Vector3(
			0.0,
			0.0,
			-warmup_length_m
		)
	)

	_build_rope_mesh_from_polyline(
		warmup_positions
	)


func _process(
	_delta: float
) -> void:
	if not _is_rope_visible:
		return

	if not grapple_visual.is_hook_visible():
		_hide_rope()
		return

	_rebuild_rope_mesh()


func _connect_grapple_visual() -> void:
	if not is_instance_valid(grapple_visual):
		push_error(
			"GrappleRopeVisual lost GrappleVisual before setup."
		)

		set_process(false)
		return

	if not grapple_visual.hook_outgoing_started.is_connected(
		_on_hook_outgoing_started
	):
		grapple_visual.hook_outgoing_started.connect(
			_on_hook_outgoing_started
		)

	if not grapple_visual.hook_attached.is_connected(
		_on_hook_attached
	):
		grapple_visual.hook_attached.connect(
			_on_hook_attached
		)

	if not grapple_visual.hook_returning_started.is_connected(
		_on_hook_returning_started
	):
		grapple_visual.hook_returning_started.connect(
			_on_hook_returning_started
		)

	if not grapple_visual.hook_hidden.is_connected(
		_on_hook_hidden
	):
		grapple_visual.hook_hidden.connect(
			_on_hook_hidden
		)


func _on_hook_outgoing_started() -> void:
	_is_rope_visible = true
	_is_hook_attached = false
	_is_hook_returning = false

	visible = true


func _on_hook_attached() -> void:
	_is_rope_visible = true
	_is_hook_attached = true
	_is_hook_returning = false

	visible = true


func _on_hook_returning_started() -> void:
	_is_rope_visible = true
	_is_hook_attached = false
	_is_hook_returning = true

	visible = true


func _on_hook_hidden() -> void:
	_hide_rope()


func _hide_rope() -> void:
	_is_rope_visible = false
	_is_hook_attached = false
	_is_hook_returning = false

	visible = false

	if _array_mesh.get_surface_count() > 0:
		_array_mesh.clear_surfaces()


func _rebuild_rope_mesh() -> void:
	var wrap_positions: PackedVector3Array = (
		grapple_visual.get_wrap_positions()
	)

	if wrap_positions.is_empty():
		_rebuild_direct_rope_mesh()
		return

	_rebuild_wrapped_rope_mesh(
		wrap_positions
	)


func _rebuild_direct_rope_mesh() -> void:
	var global_origin: Vector3 = (
		hook_origin.global_position
	)

	var global_hook_position: Vector3 = (
		grapple_visual.get_hook_position()
	)

	var start_position: Vector3 = to_local(
		global_origin
	)

	var end_position: Vector3 = to_local(
		global_hook_position
	)

	var rope_vector: Vector3 = (
		end_position
		- start_position
	)

	var rope_length_m: float = rope_vector.length()

	if rope_length_m <= 0.01:
		_hide_rope()
		return

	var rope_direction: Vector3 = (
		rope_vector
		/ rope_length_m
	)

	var sag_multiplier: float = _get_sag_multiplier()

	var sag_m: float = minf(
		rope_length_m
		* attached_sag_ratio
		* sag_multiplier,
		maximum_sag_m
	)

	var local_down: Vector3 = (
		global_transform.basis.inverse()
		* Vector3.DOWN
	)

	if local_down.length_squared() <= 0.0001:
		local_down = Vector3.DOWN
	else:
		local_down = local_down.normalized()

	var sag_offset: Vector3 = (
		local_down
		* sag_m
	)

	var swing_bend_offset: Vector3 = (
		_get_swing_bend_offset(
			rope_direction
		)
	)

	var control_position: Vector3 = (
		start_position.lerp(
			end_position,
			0.5
		)
		+ sag_offset
		+ swing_bend_offset
	)

	var vertices: PackedVector3Array = (
		PackedVector3Array()
	)

	var normals: PackedVector3Array = (
		PackedVector3Array()
	)

	var indices: PackedInt32Array = (
		PackedInt32Array()
	)

	vertices.resize(
		ring_count
		* radial_segments
	)

	normals.resize(
		ring_count
		* radial_segments
	)

	indices.resize(
		(ring_count - 1)
		* radial_segments
		* 6
	)

	_build_rope_vertices(
		start_position,
		control_position,
		end_position,
		vertices,
		normals
	)

	_build_rope_indices(
		indices,
		ring_count
	)

	_build_array_mesh(
		vertices,
		normals,
		indices
	)


func _rebuild_wrapped_rope_mesh(
	global_wrap_positions: PackedVector3Array
) -> void:
	var global_route_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	global_route_positions.append(
		hook_origin.global_position
	)

	for wrap_position: Vector3 in global_wrap_positions:
		global_route_positions.append(
			wrap_position
		)

	global_route_positions.append(
		grapple_visual.get_hook_position()
	)

	var local_route_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	for global_position: Vector3 in global_route_positions:
		local_route_positions.append(
			to_local(
				global_position
			)
		)

	var sampled_route_positions: PackedVector3Array = (
		_sample_wrapped_route(
			local_route_positions
		)
	)

	if sampled_route_positions.size() < 2:
		_hide_rope()
		return

	_build_rope_mesh_from_polyline(
		sampled_route_positions
	)


func _sample_wrapped_route(
	route_positions: PackedVector3Array
) -> PackedVector3Array:
	var sampled_positions: PackedVector3Array = (
		PackedVector3Array()
	)

	if route_positions.size() < 2:
		return sampled_positions

	var total_route_length_m: float = 0.0

	for route_index: int in range(
		route_positions.size() - 1
	):
		total_route_length_m += route_positions[
			route_index
		].distance_to(
			route_positions[
				route_index + 1
			]
		)

	if total_route_length_m <= 0.001:
		return sampled_positions

	var target_segment_length_m: float = (
		total_route_length_m
		/ float(
			maxi(
				ring_count - 1,
				1
			)
		)
	)

	sampled_positions.append(
		route_positions[0]
	)

	for route_index: int in range(
		route_positions.size() - 1
	):
		var segment_start: Vector3 = route_positions[
			route_index
		]

		var segment_end: Vector3 = route_positions[
			route_index + 1
		]

		var segment_length_m: float = (
			segment_start.distance_to(
				segment_end
			)
		)

		if segment_length_m <= 0.001:
			continue

		var subdivisions: int = maxi(
			1,
			ceili(
				segment_length_m
				/ target_segment_length_m
			)
		)

		for subdivision_index: int in range(
			1,
			subdivisions + 1
		):
			var progress: float = (
				float(subdivision_index)
				/ float(subdivisions)
			)

			sampled_positions.append(
				segment_start.lerp(
					segment_end,
					progress
				)
			)

	return sampled_positions


func _build_rope_mesh_from_polyline(
	route_positions: PackedVector3Array
) -> void:
	var route_ring_count: int = (
		route_positions.size()
	)

	if route_ring_count < 2:
		return

	var vertices: PackedVector3Array = (
		PackedVector3Array()
	)

	var normals: PackedVector3Array = (
		PackedVector3Array()
	)

	var indices: PackedInt32Array = (
		PackedInt32Array()
	)

	vertices.resize(
		route_ring_count
		* radial_segments
	)

	normals.resize(
		route_ring_count
		* radial_segments
	)

	indices.resize(
		(route_ring_count - 1)
		* radial_segments
		* 6
	)

	for ring_index: int in range(
		route_ring_count
	):
		var ring_position: Vector3 = route_positions[
			ring_index
		]

		var tangent: Vector3 = _get_polyline_tangent(
			route_positions,
			ring_index
		)

		var ring_side: Vector3 = tangent.cross(
			Vector3.UP
		)

		if ring_side.length_squared() <= 0.0001:
			ring_side = tangent.cross(
				Vector3.RIGHT
			)

		ring_side = ring_side.normalized()

		var ring_up: Vector3 = ring_side.cross(
			tangent
		).normalized()

		for radial_index: int in range(
			radial_segments
		):
			var radial_progress: float = (
				float(radial_index)
				/ float(radial_segments)
			)

			var radial_angle_rad: float = (
				radial_progress
				* TAU
			)

			var radial_direction: Vector3 = (
				ring_side
				* cos(radial_angle_rad)
				+ ring_up
				* sin(radial_angle_rad)
			)

			var vertex_index: int = (
				ring_index
				* radial_segments
				+ radial_index
			)

			vertices[vertex_index] = (
				ring_position
				+ radial_direction
				* rope_radius_m
			)

			normals[vertex_index] = (
				radial_direction
			)

	_build_rope_indices(
		indices,
		route_ring_count
	)

	_build_array_mesh(
		vertices,
		normals,
		indices
	)


func _get_polyline_tangent(
	route_positions: PackedVector3Array,
	route_index: int
) -> Vector3:
	var last_index: int = (
		route_positions.size()
		- 1
	)

	if route_index <= 0:
		var first_tangent: Vector3 = (
			route_positions[1]
			- route_positions[0]
		)

		return _get_safe_tangent(
			first_tangent
		)

	if route_index >= last_index:
		var last_tangent: Vector3 = (
			route_positions[last_index]
			- route_positions[last_index - 1]
		)

		return _get_safe_tangent(
			last_tangent
		)

	var previous_segment: Vector3 = (
		route_positions[route_index]
		- route_positions[route_index - 1]
	)

	var next_segment: Vector3 = (
		route_positions[route_index + 1]
		- route_positions[route_index]
	)

	var combined_tangent: Vector3 = (
		previous_segment.normalized()
		+ next_segment.normalized()
	)

	if combined_tangent.length_squared() <= 0.0001:
		return _get_safe_tangent(
			next_segment
		)

	return combined_tangent.normalized()


func _get_safe_tangent(
	tangent: Vector3
) -> Vector3:
	if tangent.length_squared() <= 0.0001:
		return Vector3.FORWARD

	return tangent.normalized()


func _build_array_mesh(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array
) -> void:
	var surface_arrays: Array[Variant] = []
	surface_arrays.resize(
		Mesh.ARRAY_MAX
	)

	surface_arrays[
		Mesh.ARRAY_VERTEX
	] = vertices

	surface_arrays[
		Mesh.ARRAY_NORMAL
	] = normals

	surface_arrays[
		Mesh.ARRAY_INDEX
	] = indices

	_array_mesh.clear_surfaces()

	_array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface_arrays
	)


func _build_rope_vertices(
	start_position: Vector3,
	control_position: Vector3,
	end_position: Vector3,
	vertices: PackedVector3Array,
	normals: PackedVector3Array
) -> void:
	for ring_index: int in range(ring_count):
		var ring_progress: float = (
			float(ring_index)
			/ float(ring_count - 1)
		)

		var ring_position: Vector3 = (
			_get_quadratic_bezier_point(
				start_position,
				control_position,
				end_position,
				ring_progress
			)
		)

		var tangent: Vector3 = (
			_get_quadratic_bezier_tangent(
				start_position,
				control_position,
				end_position,
				ring_progress
			)
		)

		var ring_side: Vector3 = tangent.cross(
			Vector3.UP
		)

		if ring_side.length_squared() <= 0.0001:
			ring_side = tangent.cross(
				Vector3.RIGHT
			)

		ring_side = ring_side.normalized()

		var ring_up: Vector3 = ring_side.cross(
			tangent
		).normalized()

		for radial_index: int in range(radial_segments):
			var radial_progress: float = (
				float(radial_index)
				/ float(radial_segments)
			)

			var radial_angle_rad: float = (
				radial_progress
				* TAU
			)

			var radial_direction: Vector3 = (
				ring_side
				* cos(radial_angle_rad)
				+ ring_up
				* sin(radial_angle_rad)
			)

			var vertex_index: int = (
				ring_index
				* radial_segments
				+ radial_index
			)

			vertices[vertex_index] = (
				ring_position
				+ radial_direction
				* rope_radius_m
			)

			normals[vertex_index] = (
				radial_direction
			)


func _build_rope_indices(
	indices: PackedInt32Array,
	rope_ring_count: int
) -> void:
	if rope_ring_count < 2:
		return

	var index_cursor: int = 0

	for ring_index: int in range(
		rope_ring_count - 1
	):
		for radial_index: int in range(
			radial_segments
		):
			var next_radial_index: int = (
				(radial_index + 1)
				% radial_segments
			)

			var current_ring_start: int = (
				ring_index
				* radial_segments
			)

			var next_ring_start: int = (
				(ring_index + 1)
				* radial_segments
			)

			var bottom_left: int = (
				current_ring_start
				+ radial_index
			)

			var bottom_right: int = (
				current_ring_start
				+ next_radial_index
			)

			var top_left: int = (
				next_ring_start
				+ radial_index
			)

			var top_right: int = (
				next_ring_start
				+ next_radial_index
			)

			indices[index_cursor] = bottom_left
			indices[index_cursor + 1] = top_left
			indices[index_cursor + 2] = top_right

			indices[index_cursor + 3] = bottom_left
			indices[index_cursor + 4] = top_right
			indices[index_cursor + 5] = bottom_right

			index_cursor += 6


func _get_quadratic_bezier_point(
	start_position: Vector3,
	control_position: Vector3,
	end_position: Vector3,
	progress: float
) -> Vector3:
	var inverse_progress: float = (
		1.0
		- progress
	)

	return (
		start_position
		* inverse_progress
		* inverse_progress
		+ control_position
		* 2.0
		* inverse_progress
		* progress
		+ end_position
		* progress
		* progress
	)


func _get_quadratic_bezier_tangent(
	start_position: Vector3,
	control_position: Vector3,
	end_position: Vector3,
	progress: float
) -> Vector3:
	var first_segment: Vector3 = (
		control_position
		- start_position
	)

	var second_segment: Vector3 = (
		end_position
		- control_position
	)

	var tangent: Vector3 = (
		first_segment
		* 2.0
		* (1.0 - progress)
		+ second_segment
		* 2.0
		* progress
	)

	if tangent.length_squared() <= 0.0001:
		return Vector3.FORWARD

	return tangent.normalized()


func _get_sag_multiplier() -> float:
	if _is_hook_attached:
		return 1.0

	if _is_hook_returning:
		return returning_sag_multiplier

	return outgoing_sag_multiplier


func _get_swing_bend_offset(
	rope_direction: Vector3
) -> Vector3:
	if not _is_hook_attached:
		return Vector3.ZERO

	var body: CharacterBody3D = (
		movement_motor.get_body()
	)

	if body == null:
		return Vector3.ZERO

	var local_velocity: Vector3 = (
		global_transform.basis.inverse()
		* body.velocity
	)

	var tangent_velocity: Vector3 = (
		local_velocity
		- rope_direction
		* local_velocity.dot(
			rope_direction
		)
	)

	var tangent_speed_mps: float = (
		tangent_velocity.length()
	)

	if tangent_speed_mps <= 0.001:
		return Vector3.ZERO

	var bend_m: float = minf(
		tangent_speed_mps
		* swing_velocity_bend_per_mps,
		maximum_swing_bend_m
	)

	return tangent_velocity.normalized() * bend_m
