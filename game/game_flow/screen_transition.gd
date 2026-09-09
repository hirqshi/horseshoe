class_name ScreenTransition
extends CanvasLayer

signal cover_finished()
signal reveal_finished()

@export var overlay: ColorRect

var _shader_material: ShaderMaterial
var _transition_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if overlay == null:
		push_error(
			"ScreenTransition requires an Overlay ColorRect."
		)
		return

	_shader_material = overlay.material as ShaderMaterial

	if _shader_material == null:
		push_error(
			"ScreenTransition Overlay requires a ShaderMaterial."
		)
		return

	_set_progress(
		0.0
	)

	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func cover(
	duration_s: float
) -> void:
	if not _is_ready_for_transition():
		return

	_kill_active_tween()

	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if duration_s <= 0.0:
		_set_progress(
			1.0
		)

		cover_finished.emit()
		return

	_transition_tween = create_tween()

	_transition_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_transition_tween.set_ease(
		Tween.EASE_IN
	)

	_transition_tween.tween_method(
		_set_progress,
		0.0,
		1.0,
		duration_s
	)

	await _transition_tween.finished

	if not is_instance_valid(
		overlay
	):
		return

	_set_progress(
		1.0
	)

	cover_finished.emit()


func reveal(
	duration_s: float
) -> void:
	if not _is_ready_for_transition():
		return

	_kill_active_tween()

	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if duration_s <= 0.0:
		_finish_reveal()
		return

	_transition_tween = create_tween()

	_transition_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_transition_tween.set_ease(
		Tween.EASE_OUT
	)

	_transition_tween.tween_method(
		_set_progress,
		1.0,
		0.0,
		duration_s
	)

	await _transition_tween.finished

	if not is_instance_valid(
		overlay
	):
		return

	_finish_reveal()


func cover_immediately() -> void:
	if not _is_ready_for_transition():
		return

	_kill_active_tween()

	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	_set_progress(
		1.0
	)


func reveal_immediately() -> void:
	if not _is_ready_for_transition():
		return

	_kill_active_tween()
	_finish_reveal()


func _finish_reveal() -> void:
	_set_progress(
		0.0
	)

	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	reveal_finished.emit()


func _set_progress(
	value: float
) -> void:
	if _shader_material == null:
		return

	_shader_material.set_shader_parameter(
		"progress_trans",
		clampf(
			value,
			0.0,
			1.0
		)
	)


func _is_ready_for_transition() -> bool:
	if overlay == null:
		push_error(
			"ScreenTransition has no Overlay."
		)
		return false

	if _shader_material == null:
		push_error(
			"ScreenTransition has no ShaderMaterial."
		)
		return false

	return true


func _kill_active_tween() -> void:
	if _transition_tween == null:
		return

	if _transition_tween.is_valid():
		_transition_tween.kill()

	_transition_tween = null
