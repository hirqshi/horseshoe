class_name DeathOverlay
extends CanvasLayer

@export var screen_cover: ColorRect

var _material: ShaderMaterial
var _reveal_tween: Tween


func _ready() -> void:
	if screen_cover == null:
		push_error(
			"DeathOverlay requires a ScreenCover."
		)
		return

	var source_material: ShaderMaterial = (
		screen_cover.material
		as ShaderMaterial
	)

	if source_material == null:
		push_error(
			"DeathOverlay ScreenCover requires a ShaderMaterial."
		)
		return

	_material = source_material.duplicate() as ShaderMaterial

	if _material == null:
		push_error(
			"DeathOverlay could not duplicate its ShaderMaterial."
		)
		return

	screen_cover.material = _material
	screen_cover.hide()

	_set_reveal_progress(0.0)


func cover_immediately() -> void:
	if screen_cover == null:
		return

	if _material == null:
		return

	_kill_reveal_tween()

	_set_reveal_progress(0.0)

	screen_cover.modulate = Color.WHITE
	screen_cover.show()


func reveal(
	duration: float
) -> void:
	if screen_cover == null:
		return

	if _material == null:
		return

	_kill_reveal_tween()

	if duration <= 0.0:
		_set_reveal_progress(1.1)
		screen_cover.hide()
		return

	_reveal_tween = create_tween()

	_reveal_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	_reveal_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_reveal_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	_reveal_tween.tween_method(
		_set_reveal_progress,
		0.0,
		1.1,
		duration
	)

	await _reveal_tween.finished

	if is_instance_valid(screen_cover):
		screen_cover.hide()


func _set_reveal_progress(
	progress: float
) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(
		"reveal_progress",
		clamp(
			progress,
			0.0,
			1.1
		)
	)


func _kill_reveal_tween() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
		_reveal_tween = null
