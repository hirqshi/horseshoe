class_name CheckpointVisual
extends Node3D

@export var visual_mesh: MeshInstance3D

@export_group("Inactive Colors")
@export var inactive_primary_color: Color = Color(
	0.06,
	0.1,
	0.24,
	1.0
)
@export var inactive_secondary_color: Color = Color(
	0.12,
	0.3,
	0.52,
	1.0
)

@export_group("Active Colors")
@export var active_primary_color: Color = Color(
	0.12,
	0.62,
	1.0,
	1.0
)
@export var active_secondary_color: Color = Color(
	0.76,
	0.96,
	1.0,
	1.0
)

@export_group("Transition")
@export_range(0.0, 3.0, 0.01) var color_transition_duration: float = 0.35

var is_active: bool = false

var _material: ShaderMaterial
var _color_tween: Tween
var _current_primary_color: Color
var _current_secondary_color: Color


func _ready() -> void:
	_create_unique_material()

	if _material == null:
		return

	_current_primary_color = inactive_primary_color
	_current_secondary_color = inactive_secondary_color

	_apply_colors(
		_current_primary_color,
		_current_secondary_color
	)


func set_active(value: bool) -> void:
	if is_active == value:
		return

	is_active = value

	if _material == null:
		return

	var target_primary_color: Color = inactive_primary_color
	var target_secondary_color: Color = inactive_secondary_color

	if is_active:
		target_primary_color = active_primary_color
		target_secondary_color = active_secondary_color

	_transition_to_colors(
		target_primary_color,
		target_secondary_color
	)


func _create_unique_material() -> void:
	if visual_mesh == null:
		push_error(
			"%s requires a VisualMesh."
			% name
		)
		return

	var source_material: Material = visual_mesh.get_active_material(0)
	var source_shader_material: ShaderMaterial = source_material as ShaderMaterial

	if source_shader_material == null:
		push_error(
			"%s VisualMesh requires a ShaderMaterial on surface 0."
			% name
		)
		return

	_material = source_shader_material.duplicate() as ShaderMaterial

	if _material == null:
		push_error(
			"%s could not duplicate its ShaderMaterial."
			% name
		)
		return

	visual_mesh.material_override = _material


func _transition_to_colors(
	target_primary_color: Color,
	target_secondary_color: Color
) -> void:
	if _color_tween != null:
		_color_tween.kill()

	if color_transition_duration <= 0.0:
		_apply_colors(
			target_primary_color,
			target_secondary_color
		)
		return

	_color_tween = create_tween()
	_color_tween.set_parallel(true)

	_color_tween.tween_method(
		_set_primary_color,
		_current_primary_color,
		target_primary_color,
		color_transition_duration
	)

	_color_tween.tween_method(
		_set_secondary_color,
		_current_secondary_color,
		target_secondary_color,
		color_transition_duration
	)


func _apply_colors(
	primary_color: Color,
	secondary_color: Color
) -> void:
	_set_primary_color(primary_color)
	_set_secondary_color(secondary_color)


func _set_primary_color(
	color: Color
) -> void:
	_current_primary_color = color

	if _material != null:
		_material.set_shader_parameter(
			"primary_color",
			color
		)


func _set_secondary_color(
	color: Color
) -> void:
	_current_secondary_color = color

	if _material != null:
		_material.set_shader_parameter(
			"secondary_color",
			color
		)
