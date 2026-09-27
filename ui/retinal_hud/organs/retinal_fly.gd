class_name RetinalFly
extends ColorRect

@export_category("membrane motion")
@export_range(0.0, 8.0, 0.01) var membrane_impulse_px_per_mouse_unit: float = 0.16
@export_range(1.0, 500.0, 1.0) var membrane_spring_strength: float = 85.0
@export_range(1.0, 100.0, 0.1) var membrane_damping: float = 15.0
@export_range(0.0, 160.0, 1.0, "suffix:px") var membrane_max_offset_px: float = 18.0

@export_category("core motion")
@export_range(0.0, 8.0, 0.01) var core_impulse_px_per_mouse_unit: float = 0.34
@export_range(1.0, 500.0, 1.0) var core_spring_strength: float = 54.0
@export_range(1.0, 100.0, 0.1) var core_damping: float = 9.0
@export_range(0.0, 160.0, 1.0, "suffix:px") var core_max_offset_px: float = 46.0

@export_category("shader")
@export var shader_material: ShaderMaterial

var _membrane_offset_px: Vector2 = Vector2.ZERO
var _membrane_velocity_px_s: Vector2 = Vector2.ZERO

var _core_offset_px: Vector2 = Vector2.ZERO
var _core_velocity_px_s: Vector2 = Vector2.ZERO

var _smoothed_turn_speed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if shader_material == null:
		shader_material = material as ShaderMaterial

	if shader_material == null:
		push_error("RetinalFly requires a ShaderMaterial.")
		set_process(false)
		return

	var local_material: ShaderMaterial = (
		shader_material.duplicate() as ShaderMaterial
	)

	if local_material == null:
		push_error("RetinalFly could not duplicate its ShaderMaterial.")
		set_process(false)
		return

	shader_material = local_material
	material = shader_material


func apply_hud_state(
	state: RetinalHudState,
	delta: float
) -> void:
	_apply_look_impulse(
		state.look_delta
	)

	_update_springs(delta)

	_smoothed_turn_speed = move_toward(
		_smoothed_turn_speed,
		state.look_speed,
		1600.0 * delta
	)

	_smoothed_turn_speed = move_toward(
		_smoothed_turn_speed,
		0.0,
		460.0 * delta
	)

	_apply_shader_parameters(
		state
	)


func reset_motion() -> void:
	_membrane_offset_px = Vector2.ZERO
	_membrane_velocity_px_s = Vector2.ZERO
	_core_offset_px = Vector2.ZERO
	_core_velocity_px_s = Vector2.ZERO
	_smoothed_turn_speed = 0.0


func _apply_look_impulse(
	look_delta: Vector2
) -> void:
	if look_delta.is_zero_approx():
		return

	_membrane_velocity_px_s -= (
		look_delta
		* membrane_impulse_px_per_mouse_unit
		* 60.0
	)

	_core_velocity_px_s += (
		look_delta
		* core_impulse_px_per_mouse_unit
		* 60.0
	)


func _update_springs(
	delta: float
) -> void:
	var membrane_acceleration_px_s2: Vector2 = (
		-_membrane_offset_px
		* membrane_spring_strength
		- _membrane_velocity_px_s
		* membrane_damping
	)

	_membrane_velocity_px_s += (
		membrane_acceleration_px_s2
		* delta
	)

	_membrane_offset_px += (
		_membrane_velocity_px_s
		* delta
	)

	_core_velocity_px_s += (
		(
			-_core_offset_px
			* core_spring_strength
			- _core_velocity_px_s
			* core_damping
		)
		* delta
	)

	_core_offset_px += (
		_core_velocity_px_s
		* delta
	)

	_clamp_spring(
		_membrane_offset_px,
		_membrane_velocity_px_s,
		membrane_max_offset_px
	)

	_clamp_spring(
		_core_offset_px,
		_core_velocity_px_s,
		core_max_offset_px
	)


func _clamp_spring(
	offset: Vector2,
	velocity: Vector2,
	maximum_length_px: float
) -> void:
	if offset.length_squared() <= (
		maximum_length_px
		* maximum_length_px
	):
		return

	var clamped_offset: Vector2 = (
		offset.normalized()
		* maximum_length_px
	)

	if offset == _membrane_offset_px:
		_membrane_offset_px = clamped_offset
		_membrane_velocity_px_s *= 0.35
		return

	_core_offset_px = clamped_offset
	_core_velocity_px_s *= 0.35


func _apply_shader_parameters(
	state: RetinalHudState
) -> void:
	if shader_material == null:
		return

	var tether_vector_px: Vector2 = (
		_core_offset_px
		- _membrane_offset_px
	)

	shader_material.set_shader_parameter(
		"organism_size_px",
		size
	)

	shader_material.set_shader_parameter(
		"membrane_offset_px",
		_membrane_offset_px
	)

	shader_material.set_shader_parameter(
		"core_offset_px",
		_core_offset_px
	)

	shader_material.set_shader_parameter(
		"tether_length_px",
		tether_vector_px.length()
	)

	shader_material.set_shader_parameter(
		"turn_speed",
		_smoothed_turn_speed
	)

	shader_material.set_shader_parameter(
		"is_gliding",
		state.is_gliding
	)
