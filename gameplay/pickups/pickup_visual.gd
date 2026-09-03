class_name PickupVisual
extends Node3D

@export_category("references")
@export var mesh_instance: MeshInstance3D

@export_category("levitation")
@export_range(
	0.0,
	2.0,
	0.001,
	"suffix:m"
) var float_height_m: float = 0.12

@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:hz"
) var float_frequency_hz: float = 0.9

@export_category("rotation")
@export var rotation_speed_deg_per_s: Vector3 = Vector3(
	12.0,
	32.0,
	8.0
)
@export var idle_particles: Array[GPUParticles3D] = []

var _base_position: Vector3 = Vector3.ZERO
var _float_phase: float = 0.0
var _is_collected: bool = false


func _ready() -> void:
	_base_position = position
	_float_phase = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	if _is_collected:
		return

	_float_phase += (
		TAU
		* float_frequency_hz
		* delta
	)

	position.y = (
		_base_position.y
		+ sin(_float_phase)
		* float_height_m
	)

	rotation += Vector3(
		deg_to_rad(
			rotation_speed_deg_per_s.x
		),
		deg_to_rad(
			rotation_speed_deg_per_s.y
		),
		deg_to_rad(
			rotation_speed_deg_per_s.z
		)
	) * delta


func apply_definition(
	definition: PickupDefinition
) -> void:
	if definition == null:
		return

	if mesh_instance == null:
		return

	if definition.visual_material == null:
		return

	mesh_instance.material_override = (
		definition.visual_material
	)


func hide_after_collect() -> void:
	_is_collected = true
	visible = false

	for particles: GPUParticles3D in idle_particles:
		if particles == null:
			continue

		particles.emitting = false
		particles.visible = false


func show_after_respawn() -> void:
	_is_collected = false
	visible = true

	for particles: GPUParticles3D in idle_particles:
		if particles == null:
			continue

		particles.visible = true
		particles.restart()
		particles.emitting = true
