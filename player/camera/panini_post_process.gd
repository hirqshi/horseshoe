class_name PaniniPostProcess
extends CanvasLayer

@export var panini_rect: ColorRect
@export var is_panini_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var panini_distance: float = 0.55
@export_range(0.5, 2.0, 0.01) var crop_to_fit: float = 1.0

var _material: ShaderMaterial

func _ready() -> void:
	if panini_rect == null:
		push_error("PaniniPostProcess requires PaniniRect.")
		set_process(false)
		return

	var source_material: ShaderMaterial = (
		panini_rect.material as ShaderMaterial
	)

	if source_material == null:
		push_error("PaniniRect requires ShaderMaterial.")
		set_process(false)
		return

	_material = source_material.duplicate() as ShaderMaterial
	panini_rect.material = _material

	_apply_settings()

func set_panini_enabled(value: bool) -> void:
	is_panini_enabled = value
	_apply_settings()

func set_panini_distance(value: float) -> void:
	panini_distance = clampf(value, 0.0, 1.0)
	_apply_settings()

func set_crop_to_fit(value: float) -> void:
	crop_to_fit = maxf(value, 0.5)
	_apply_settings()

func _apply_settings() -> void:
	if _material == null:
		return

	panini_rect.visible = is_panini_enabled

	_material.set_shader_parameter(
		"panini_distance",
		panini_distance
	)

	_material.set_shader_parameter(
		"crop_to_fit",
		crop_to_fit
	)
