class_name ParticleBurstPool3D
extends Node3D

@export_category("pool")
@export var particle_scene: PackedScene

@export_range(1, 32, 1) var pool_size: int = 4

@export_range(
	0.0,
	2.0,
	0.01,
	"suffix:s"
) var release_padding_s: float = 0.15

@export_category("debug")
@export var is_debug_enabled: bool = false

var _emitters: Array[GPUParticles3D] = []
var _is_emitter_available: Array[bool] = []
var _release_time_s: Array[float] = []


func _ready() -> void:
	if particle_scene == null:
		push_error(
			"%s requires a GPUParticles3D particle scene."
			% name
		)
		set_process(false)
		return

	for emitter_index: int in range(pool_size):
		var emitter_node: Node = (
			particle_scene.instantiate()
		)

		var emitter: GPUParticles3D = (
			emitter_node as GPUParticles3D
		)

		if emitter == null:
			push_error(
				"%s particle_scene root must be GPUParticles3D."
				% name
			)

			emitter_node.queue_free()
			continue

		add_child(emitter)

		emitter.top_level = true
		emitter.one_shot = true
		emitter.emitting = false
		emitter.visible = false

		_emitters.append(emitter)
		_is_emitter_available.append(true)
		_release_time_s.append(-INF)


func _process(_delta: float) -> void:
	var current_time_s: float = (
		Time.get_ticks_msec()
		* 0.001
	)

	for emitter_index: int in range(
		_emitters.size()
	):
		if _is_emitter_available[emitter_index]:
			continue

		if current_time_s < (
			_release_time_s[emitter_index]
		):
			continue

		var emitter: GPUParticles3D = (
			_emitters[emitter_index]
		)

		emitter.emitting = false
		emitter.visible = false

		_is_emitter_available[emitter_index] = true
		_release_time_s[emitter_index] = -INF

		if is_debug_enabled:
			print(
				"PARTICLE_POOL release | ",
				name,
				" | slot=",
				emitter_index
			)


func emit_burst(
	world_position: Vector3,
	surface_normal: Vector3 = Vector3.UP
) -> void:
	var emitter_index: int = (
		_get_available_emitter_index()
	)

	if emitter_index < 0:
		if is_debug_enabled:
			print(
				"PARTICLE_POOL full | ",
				name
			)

		return

	var emitter: GPUParticles3D = (
		_emitters[emitter_index]
	)

	var normalized_normal: Vector3 = (
		surface_normal.normalized()
	)

	if normalized_normal.is_zero_approx():
		normalized_normal = Vector3.UP

	emitter.global_transform = _get_surface_transform(
		world_position,
		normalized_normal
	)

	emitter.emitting = false
	emitter.visible = true
	emitter.restart()
	emitter.emitting = true

	_is_emitter_available[emitter_index] = false

	var current_time_s: float = (
		Time.get_ticks_msec()
		* 0.001
	)

	_release_time_s[emitter_index] = (
		current_time_s
		+ emitter.lifetime
		+ release_padding_s
	)

	if is_debug_enabled:
		print(
			"PARTICLE_POOL emit | ",
			name,
			" | slot=",
			emitter_index,
			" | position=",
			world_position,
			" | release_in=",
			emitter.lifetime
			+ release_padding_s
		)


func _get_available_emitter_index() -> int:
	for emitter_index: int in range(
		_is_emitter_available.size()
	):
		if _is_emitter_available[emitter_index]:
			return emitter_index

	return -1


func _get_surface_transform(
	world_position: Vector3,
	surface_normal: Vector3
) -> Transform3D:
	var up: Vector3 = surface_normal.normalized()

	var right: Vector3 = (
		Vector3.FORWARD.cross(up)
	)

	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT.cross(up)

	right = right.normalized()

	var forward: Vector3 = (
		up.cross(right).normalized()
	)

	var basis: Basis = Basis(
		right,
		up,
		forward
	).orthonormalized()

	return Transform3D(
		basis,
		world_position
	)
