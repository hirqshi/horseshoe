class_name FallOrgan
extends ColorRect

@export_category("motion")
@export_range(0.1, 30.0, 0.1) var risk_rise_speed: float = 4.0
@export_range(0.1, 30.0, 0.1) var risk_clear_speed: float = 12.0

@export_category("shader")
@export var shader_material: ShaderMaterial

var _display_risk: float = 0.0
var _is_displaying_lethal_state: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if shader_material == null:
		shader_material = material as ShaderMaterial

	if shader_material == null:
		push_error(
			"FallOrgan requires a ShaderMaterial."
		)
		set_process(false)
		return

	var local_material: ShaderMaterial = (
		shader_material.duplicate() as ShaderMaterial
	)

	if local_material == null:
		push_error(
			"FallOrgan could not duplicate its ShaderMaterial."
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
	var target_risk: float = clampf(
		state.fall_risk_ratio,
		0.0,
		1.0
	)

	var response_speed: float = risk_clear_speed

	if target_risk > _display_risk:
		response_speed = risk_rise_speed

	_display_risk = move_toward(
		_display_risk,
		target_risk,
		response_speed * delta
	)

	_is_displaying_lethal_state = (
		state.is_fall_lethal
	)

	visible = true

	shader_material.set_shader_parameter(
		"risk_ratio",
		_display_risk
	)

	shader_material.set_shader_parameter(
		"is_lethal",
		_is_displaying_lethal_state
	)
