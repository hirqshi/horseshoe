class_name GrappleReadyOrgan
extends ColorRect

@export_category("motion")
@export_range(0.1, 30.0, 0.1) var appear_speed: float = 10.0
@export_range(0.1, 30.0, 0.1) var disappear_speed: float = 15.0
@export_range(0.0, 3.0, 0.01) var ready_pulse_frequency_hz: float = 0.75
@export_range(0.0, 1.0, 0.01) var ready_pulse_strength: float = 0.12

@export_category("shader")
@export var shader_material: ShaderMaterial

var _ready_amount: float = 0.0
var _pulse_phase: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if shader_material == null:
		shader_material = material as ShaderMaterial

	if shader_material == null:
		push_error(
			"GrappleReadyOrgan requires a ShaderMaterial."
		)
		set_process(false)
		return

	var local_material: ShaderMaterial = (
		shader_material.duplicate() as ShaderMaterial
	)

	if local_material == null:
		push_error(
			"GrappleReadyOrgan could not duplicate its ShaderMaterial."
		)
		set_process(false)
		return

	shader_material = local_material
	material = shader_material

	shader_material.set_shader_parameter(
		"preview_enabled",
		false
	)


func apply_hud_state(
	state: RetinalHudState,
	delta: float
) -> void:
	var target_amount: float = 0.0

	if state.is_grapple_ready:
		target_amount = 1.0

	var response_speed: float = disappear_speed

	if target_amount > _ready_amount:
		response_speed = appear_speed

	_ready_amount = move_toward(
		_ready_amount,
		target_amount,
		response_speed * delta
	)

	_pulse_phase += (
		TAU
		* ready_pulse_frequency_hz
		* delta
	)

	var pulse: float = (
		0.5
		+ 0.5
		* sin(_pulse_phase)
	)

	var pulse_amount: float = (
		pulse
		* ready_pulse_strength
		* _ready_amount
	)

	visible = _ready_amount > 0.001

	shader_material.set_shader_parameter(
		"ready_amount",
		_ready_amount
	)

	shader_material.set_shader_parameter(
		"pulse_amount",
		pulse_amount
	)
