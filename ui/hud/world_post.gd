class_name WorldPost
extends ColorRect

var _shader_material: ShaderMaterial = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_shader_material = material as ShaderMaterial

	if _shader_material == null:
		push_error(
			"WorldPost requires a ShaderMaterial."
		)
		return

	_apply_brightness()

	if not GameSettings.brightness_changed.is_connected(
		_on_brightness_changed
	):
		GameSettings.brightness_changed.connect(
			_on_brightness_changed
		)


func _exit_tree() -> void:
	if GameSettings.brightness_changed.is_connected(
		_on_brightness_changed
	):
		GameSettings.brightness_changed.disconnect(
			_on_brightness_changed
		)


func _apply_brightness() -> void:
	if _shader_material == null:
		return

	_shader_material.set_shader_parameter(
		&"brightness",
		GameSettings.brightness
	)


func _on_brightness_changed(
	value: float
) -> void:
	if _shader_material == null:
		return

	_shader_material.set_shader_parameter(
		&"brightness",
		value
	)
