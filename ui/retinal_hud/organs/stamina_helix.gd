class_name StaminaHelix
extends ColorRect

@export_category("motion")
@export_range(0.1, 30.0, 0.1) var drain_response_speed: float = 12.0
@export_range(0.1, 30.0, 0.1) var recovery_response_speed: float = 5.0

@export_category("shader")
@export var shader_material: ShaderMaterial

var _display_ratio: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if shader_material == null:
		shader_material = material as ShaderMaterial

	if shader_material == null:
		push_error(
			"StaminaHelix requires a ShaderMaterial."
		)
		set_process(false)
		return

	var local_material: ShaderMaterial = (
		shader_material.duplicate() as ShaderMaterial
	)

	if local_material == null:
		push_error(
			"StaminaHelix could not duplicate its ShaderMaterial."
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
	var target_ratio: float = clampf(
		state.reverse_stamina_ratio,
		0.0,
		1.0
	)

	var response_speed: float = recovery_response_speed

	if target_ratio < _display_ratio:
		response_speed = drain_response_speed

	_display_ratio = move_toward(
		_display_ratio,
		target_ratio,
		response_speed * delta
	)

	shader_material.set_shader_parameter(
		"charge_ratio",
		_display_ratio
	)
