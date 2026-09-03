class_name PlayerMovementParticles
extends Node3D

@export_category("references")
@export var movement_motor: MovementMotor
@export var camera_visual_rig: CameraVisualRig

@export var ground_jump_burst_pool: ParticleBurstPool3D
@export var wall_jump_burst_pool: ParticleBurstPool3D

@export var light_landing_burst_pool: ParticleBurstPool3D
@export var heavy_landing_burst_pool: ParticleBurstPool3D

@export var slide_start_burst_pool: ParticleBurstPool3D
@export var walk_step_burst_pool: ParticleBurstPool3D
@export var slide_trail_particles: GPUParticles3D
@export var slide_trail_local_offset: Vector3 = Vector3(
	0.0,
	-0.65,
	0.20
)

@export_category("ground placement")
@export_range(
	0.0,
	3.0,
	0.01,
	"suffix:m"
) var fallback_ground_offset_m: float = 0.75

@export_category("landing")
@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var light_landing_threshold_mps: float = 3.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var heavy_landing_threshold_mps: float = 10.0

@export_category("walk particles")
@export var uses_bob_synced_walk_particles: bool = true

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var walk_particle_min_speed_mps: float = 1.0

@export_range(
	0.0,
	1.0,
	0.01,
	"suffix:m"
) var walk_foot_lateral_offset_m: float = 0.16

@export_range(
	-1.0,
	1.0,
	0.01,
	"suffix:m"
) var walk_foot_forward_offset_m: float = 0.06

var _body: CharacterBody3D
var _skip_next_ground_jump_burst: bool = false
var _is_sliding: bool = false

var _next_walk_step_is_right: bool = true

@export var is_debug_enabled: bool = false


func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error(
			"PlayerMovementParticles must be a child of Player."
		)
		set_process(false)
		return

	if movement_motor == null:
		push_error(
			"PlayerMovementParticles requires MovementMotor."
		)
		set_process(false)
		return

	movement_motor.jumped.connect(
		_on_jumped
	)

	movement_motor.wall_jumped.connect(
		_on_wall_jumped
	)

	movement_motor.landed.connect(
		_on_landed
	)

	movement_motor.slide_started.connect(
		_on_slide_started
	)

	movement_motor.slide_finished.connect(
		_on_slide_finished
	)
	
	_connect_camera_visual_rig()
	_setup_slide_trail()


func _connect_camera_visual_rig() -> void:
	if not uses_bob_synced_walk_particles:
		return

	if camera_visual_rig == null:
		push_warning(
			"PlayerMovementParticles requires CameraVisualRig "
			+ "for bob synced walk particles."
		)
		return

	camera_visual_rig.bob_step.connect(
		_on_camera_bob_step
	)


func _on_camera_bob_step() -> void:
	if not uses_bob_synced_walk_particles:
		return

	if _body == null:
		return

	if _is_sliding:
		return

	if not _body.is_on_floor():
		return

	if walk_step_burst_pool == null:
		return

	var horizontal_speed_mps: float = Vector2(
		_body.velocity.x,
		_body.velocity.z
	).length()

	if horizontal_speed_mps < walk_particle_min_speed_mps:
		return

	var surface_position: Vector3 = (
		_get_ground_burst_position()
	)

	var surface_normal: Vector3 = (
		_get_ground_surface_normal()
	)

	var foot_position: Vector3 = (
		_get_walk_foot_position(
			surface_position,
			surface_normal
		)
	)

	walk_step_burst_pool.emit_burst(
		foot_position,
		surface_normal
	)

	_next_walk_step_is_right = (
		not _next_walk_step_is_right
	)


func _get_walk_foot_position(
	surface_position: Vector3,
	surface_normal: Vector3
) -> Vector3:
	if _body == null:
		return surface_position

	var foot_side_multiplier: float = (
		1.0
		if _next_walk_step_is_right
		else -1.0
	)

	var player_right: Vector3 = (
		_body.global_basis.x
	)

	var surface_right: Vector3 = (
		player_right
		- surface_normal
		* player_right.dot(
			surface_normal
		)
	)

	if surface_right.length_squared() <= 0.0001:
		surface_right = Vector3.RIGHT
	else:
		surface_right = surface_right.normalized()

	var player_forward: Vector3 = (
		-_body.global_basis.z
	)

	var surface_forward: Vector3 = (
		player_forward
		- surface_normal
		* player_forward.dot(
			surface_normal
		)
	)

	if surface_forward.length_squared() <= 0.0001:
		surface_forward = Vector3.FORWARD
	else:
		surface_forward = surface_forward.normalized()

	return surface_position \
		+ surface_right \
		* walk_foot_lateral_offset_m \
		* foot_side_multiplier \
		+ surface_forward \
		* walk_foot_forward_offset_m


func _setup_slide_trail() -> void:
	if slide_trail_particles == null:
		return

	slide_trail_particles.top_level = true
	slide_trail_particles.emitting = false
	slide_trail_particles.visible = false

	_update_slide_trail_transform()


func _process(_delta: float) -> void:
	if not _is_sliding:
		return

	_update_slide_trail_transform()


func _update_slide_trail_transform() -> void:
	if slide_trail_particles == null:
		return

	if _body == null:
		return

	slide_trail_particles.global_position = (
		_body.to_global(
			slide_trail_local_offset
		)
	)

	slide_trail_particles.global_basis = (
		_body.global_basis
	)


func _on_jumped() -> void:
	if _skip_next_ground_jump_burst:
		_skip_next_ground_jump_burst = false
		return

	if ground_jump_burst_pool == null:
		return

	var surface_position: Vector3 = (
		_get_ground_burst_position()
	)

	var surface_normal: Vector3 = (
		_get_ground_surface_normal()
	)

	ground_jump_burst_pool.emit_burst(
		surface_position,
		surface_normal
	)


func _on_wall_jumped() -> void:
	_skip_next_ground_jump_burst = true

	if wall_jump_burst_pool == null:
		if is_debug_enabled:
			print(
				"WALL_JUMP_PARTICLES reject | no pool"
			)

		return

	var wall_contact: WallContact = (
		movement_motor.sensors.get_wall_jump_contact()
	)

	if wall_contact.is_valid():
		if is_debug_enabled:
			print(
				"WALL_JUMP_PARTICLES emit | contact point=",
				wall_contact.point,
				" | normal=",
				wall_contact.normal
			)

		wall_jump_burst_pool.emit_burst(
			wall_contact.point,
			wall_contact.normal
		)

		return

	var fallback_normal: Vector3 = (
		_body.global_basis.z
	)

	if is_debug_enabled:
		print(
			"WALL_JUMP_PARTICLES fallback emit | position=",
			_body.global_position,
			" | normal=",
			fallback_normal
		)

	wall_jump_burst_pool.emit_burst(
		_body.global_position,
		fallback_normal
	)


func _on_landed(
	impact_speed_mps: float
) -> void:
	if impact_speed_mps < light_landing_threshold_mps:
		return

	var surface_position: Vector3 = (
		_get_ground_burst_position()
	)

	var surface_normal: Vector3 = (
		_get_ground_surface_normal()
	)

	if impact_speed_mps >= heavy_landing_threshold_mps:
		if heavy_landing_burst_pool != null:
			heavy_landing_burst_pool.emit_burst(
				surface_position,
				surface_normal
			)

		return

	if light_landing_burst_pool != null:
		light_landing_burst_pool.emit_burst(
			surface_position,
			surface_normal
		)


func _on_slide_started() -> void:
	_is_sliding = true

	var surface_position: Vector3 = (
		_get_ground_burst_position()
	)

	var surface_normal: Vector3 = (
		_get_ground_surface_normal()
	)

	if slide_start_burst_pool != null:
		slide_start_burst_pool.emit_burst(
			surface_position,
			surface_normal
		)

	if slide_trail_particles == null:
		return
		
	_update_slide_trail_transform()
	
	slide_trail_particles.visible = true
	slide_trail_particles.restart()
	slide_trail_particles.emitting = true


func _on_slide_finished() -> void:
	_is_sliding = false

	if slide_trail_particles == null:
		return

	slide_trail_particles.emitting = false
	slide_trail_particles.visible = false


func _get_ground_burst_position() -> Vector3:
	if _body == null:
		return global_position

	var collision_count: int = (
		_body.get_slide_collision_count()
	)

	for collision_index: int in range(collision_count):
		var collision: KinematicCollision3D = (
			_body.get_slide_collision(
				collision_index
			)
		)

		var collision_normal: Vector3 = (
			collision.get_normal()
		)

		if collision_normal.dot(Vector3.UP) < 0.5:
			continue

		return collision.get_position()

	return _body.global_position + (
		Vector3.DOWN
		* fallback_ground_offset_m
	)


func _get_ground_surface_normal() -> Vector3:
	if _body == null:
		return Vector3.UP

	var collision_count: int = (
		_body.get_slide_collision_count()
	)

	for collision_index: int in range(collision_count):
		var collision: KinematicCollision3D = (
			_body.get_slide_collision(
				collision_index
			)
		)

		var collision_normal: Vector3 = (
			collision.get_normal()
		)

		if collision_normal.dot(Vector3.UP) < 0.5:
			continue

		return collision_normal.normalized()

	if _body.is_on_floor():
		var floor_normal: Vector3 = (
			_body.get_floor_normal()
		)

		if not floor_normal.is_zero_approx():
			return floor_normal.normalized()

	return Vector3.UP
