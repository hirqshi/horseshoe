class_name Menu3DPreview
extends Control

@export_group("Preview Scene")
@export var preview_scene: PackedScene
@export var target_scale: Vector3 = Vector3.ONE

@export_group("References")
@export var output_texture: TextureRect
@export var preview_viewport: SubViewport
@export var preview_anchor: Node3D

@export_group("Animation")
@export_range(0.0, 3.0, 0.01) var intro_duration_s: float = 0.22
@export_range(0.0, 5.0, 0.01) var intro_delay_s: float = 0.0

@export_range(0.0, 5.0, 0.01) var float_amplitude_m: float = 0.08
@export_range(0.0, 10.0, 0.01) var float_speed: float = 1.2

@export var rotation_speed_deg_s: Vector3 = Vector3(
	0.0,
	12.0,
	0.0
)

@export_group("Rendering")
@export_range(0.1, 1.0, 0.05) var render_scale: float = 0.75

var _preview_instance: Node3D = null
var _base_anchor_position: Vector3 = Vector3.ZERO
var _base_anchor_rotation: Vector3 = Vector3.ZERO
var _intro_tween: Tween = null
var _is_active: bool = false
var _time_s: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not _validate_references():
		return

	preview_viewport.transparent_bg = true

	preview_viewport.render_target_clear_mode = (
		SubViewport.CLEAR_MODE_ALWAYS
	)

	preview_viewport.render_target_update_mode = (
		SubViewport.UPDATE_DISABLED
	)

	output_texture.texture = preview_viewport.get_texture()

	_base_anchor_position = preview_anchor.position
	_base_anchor_rotation = preview_anchor.rotation

	resized.connect(
		_sync_viewport_size
	)

	_sync_viewport_size()
	_instantiate_preview()


func _process(
	delta: float
) -> void:
	if not _is_active:
		return

	if preview_anchor == null:
		return

	_time_s += delta

	_update_preview_motion()


func set_active(
	value: bool
) -> void:
	if _is_active == value:
		return

	_is_active = value

	if preview_viewport != null:
		preview_viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS
			if _is_active
			else SubViewport.UPDATE_DISABLED
		)

	if not _is_active:
		_kill_intro_tween()

		if preview_anchor != null:
			preview_anchor.scale = target_scale

		return

	play_intro()


func play_intro() -> void:
	if not _is_active:
		return

	if preview_anchor == null:
		return

	_kill_intro_tween()

	preview_anchor.scale = Vector3.ZERO

	if intro_duration_s <= 0.0:
		preview_anchor.scale = target_scale
		return

	_intro_tween = create_tween()

	_intro_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_intro_tween.set_ease(
		Tween.EASE_OUT
	)

	_intro_tween.tween_property(
		preview_anchor,
		"scale",
		target_scale,
		intro_duration_s
	).set_delay(
		intro_delay_s
	)


func _instantiate_preview() -> void:
	if preview_scene == null:
		return

	_preview_instance = preview_scene.instantiate() as Node3D

	if _preview_instance == null:
		push_error(
			"Menu3DPreview failed to instantiate Preview Scene."
		)
		return

	preview_anchor.add_child(
		_preview_instance
	)


func _update_preview_motion() -> void:
	var vertical_offset: float = sin(
		_time_s
		* float_speed
	) * float_amplitude_m

	preview_anchor.position = (
		_base_anchor_position
		+ Vector3(
			0.0,
			vertical_offset,
			0.0
		)
	)

	preview_anchor.rotation = (
		_base_anchor_rotation
		+ Vector3(
			deg_to_rad(
				rotation_speed_deg_s.x
			) * _time_s,
			deg_to_rad(
				rotation_speed_deg_s.y
			) * _time_s,
			deg_to_rad(
				rotation_speed_deg_s.z
			) * _time_s
		)
	)


func _sync_viewport_size() -> void:
	if preview_viewport == null:
		return

	var scaled_size: Vector2 = size * render_scale

	preview_viewport.size = Vector2i(
		maxi(
			64,
			roundi(
				scaled_size.x
			)
		),
		maxi(
			64,
			roundi(
				scaled_size.y
			)
		)
	)


func _validate_references() -> bool:
	if output_texture == null:
		push_error(
			"Menu3DPreview requires an OutputTexture."
		)
		return false

	if preview_viewport == null:
		push_error(
			"Menu3DPreview requires a PreviewViewport."
		)
		return false

	if preview_anchor == null:
		push_error(
			"Menu3DPreview requires a PreviewAnchor."
		)
		return false

	return true


func _kill_intro_tween() -> void:
	if _intro_tween == null:
		return

	if _intro_tween.is_valid():
		_intro_tween.kill()

	_intro_tween = null
