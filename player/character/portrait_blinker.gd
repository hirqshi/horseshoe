class_name PortraitBlinker
extends Node

@export_group("References")
@export var face_mesh: MeshInstance3D
@export_range(0, 16, 1) var material_surface: int = 0

@export_group("Eye Textures")
@export var open_eyes_texture: Texture2D
@export var closed_eyes_texture: Texture2D

@export_group("Blink Timing")
@export_range(0.04, 0.3, 0.01) var blink_duration_s: float = 0.09
@export_range(0.5, 10.0, 0.1) var minimum_interval_s: float = 2.2
@export_range(0.5, 10.0, 0.1) var maximum_interval_s: float = 5.0

var _blink_timer: Timer = null
var _face_material: StandardMaterial3D = null
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _is_blinking: bool = false


func _ready() -> void:
	if face_mesh == null:
		push_error(
			"PortraitBlinker requires a FaceMesh."
		)
		set_process(
			false
		)
		return

	if open_eyes_texture == null:
		push_error(
			"PortraitBlinker requires an OpenEyesTexture."
		)
		set_process(
			false
		)
		return

	if closed_eyes_texture == null:
		push_error(
			"PortraitBlinker requires a ClosedEyesTexture."
		)
		set_process(
			false
		)
		return

	var source_material: Material = (
		face_mesh.get_active_material(
			material_surface
		)
	)

	if source_material == null:
		push_error(
			"PortraitBlinker could not find a face material."
		)
		set_process(
			false
		)
		return

	_face_material = (
		source_material.duplicate()
		as StandardMaterial3D
	)

	if _face_material == null:
		push_error(
			"PortraitBlinker requires StandardMaterial3D on FaceMesh."
		)
		set_process(
			false
		)
		return

	face_mesh.set_surface_override_material(
		material_surface,
		_face_material
	)

	_face_material.albedo_texture = open_eyes_texture

	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(
		_on_blink_timer_timeout
	)

	add_child(
		_blink_timer
	)

	_schedule_next_blink()


func _on_blink_timer_timeout() -> void:
	if _face_material == null:
		return

	if _is_blinking:
		_face_material.albedo_texture = open_eyes_texture
		_is_blinking = false

		_schedule_next_blink()
		return

	_face_material.albedo_texture = closed_eyes_texture
	_is_blinking = true

	_blink_timer.start(
		blink_duration_s
	)


func _schedule_next_blink() -> void:
	if _blink_timer == null:
		return

	var minimum_interval: float = minf(
		minimum_interval_s,
		maximum_interval_s
	)

	var maximum_interval: float = maxf(
		minimum_interval_s,
		maximum_interval_s
	)

	var next_interval: float = _random.randf_range(
		minimum_interval,
		maximum_interval
	)

	_blink_timer.start(
		next_interval
	)
