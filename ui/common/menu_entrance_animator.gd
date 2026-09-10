class_name MenuEntranceAnimator
extends Node

@export_group("UI")
@export var animated_controls: Array[Control] = []

@export_group("3D")
@export var preview_anchors: Array[Node3D] = []

@export_group("Timing")
@export_range(0.0, 2.0, 0.01) var duration_s: float = 0.18
@export_range(0.0, 1.0, 0.01) var ui_stagger_s: float = 0.035
@export_range(0.0, 1.0, 0.01) var preview_delay_s: float = 0.0

@export_group("Behavior")
@export var auto_center_control_pivots: bool = true

var _owner_panel: Control = null
var _control_base_scales: Dictionary[Control, Vector2] = {}
var _preview_base_scales: Dictionary[Node3D, Vector3] = {}

var _open_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_owner_panel = get_parent() as Control

	if _owner_panel == null:
		push_error(
			"MenuEntranceAnimator must be a child of a Control panel."
		)
		return

	_owner_panel.visibility_changed.connect(
		_on_owner_panel_visibility_changed
	)

	_cache_initial_scales()

	call_deferred(
		&"_play_if_owner_is_visible"
	)


func _exit_tree() -> void:
	if _owner_panel == null:
		return

	if _owner_panel.visibility_changed.is_connected(
		_on_owner_panel_visibility_changed
	):
		_owner_panel.visibility_changed.disconnect(
			_on_owner_panel_visibility_changed
		)


func _on_owner_panel_visibility_changed() -> void:
	if not _owner_panel.is_visible_in_tree():
		_kill_open_tween()
		return

	play_open()


func _play_if_owner_is_visible() -> void:
	if _owner_panel == null:
		return

	if not _owner_panel.is_visible_in_tree():
		return

	play_open()


func play_open() -> void:
	_kill_open_tween()

	if duration_s <= 0.0:
		_restore_final_scales()
		return

	_open_tween = create_tween()

	_open_tween.set_parallel(
		true
	)

	_animate_ui_controls()
	_animate_preview_anchors()


func _cache_initial_scales() -> void:
	for control: Control in animated_controls:
		if control == null:
			continue

		_control_base_scales[control] = control.scale

		if auto_center_control_pivots:
			control.pivot_offset = control.size * 0.5

	for preview_anchor: Node3D in preview_anchors:
		if preview_anchor == null:
			continue

		_preview_base_scales[preview_anchor] = (
			preview_anchor.scale
		)


func _animate_ui_controls() -> void:
	for control_index: int in range(
		animated_controls.size()
	):
		var control: Control = animated_controls[
			control_index
		]

		if control == null:
			continue

		var target_scale: Vector2 = _get_control_base_scale(
			control
		)

		if auto_center_control_pivots:
			control.pivot_offset = control.size * 0.5

		control.scale = Vector2(
			target_scale.x,
			0.0
		)

		_open_tween.tween_property(
			control,
			"scale",
			target_scale,
			duration_s
		).set_delay(
			float(control_index)
			* ui_stagger_s
		)


func _animate_preview_anchors() -> void:
	for preview_index: int in range(
		preview_anchors.size()
	):
		var preview_anchor: Node3D = preview_anchors[
			preview_index
		]

		if preview_anchor == null:
			continue

		var target_scale: Vector3 = _get_preview_base_scale(
			preview_anchor
		)

		preview_anchor.scale = Vector3.ZERO

		_open_tween.tween_property(
			preview_anchor,
			"scale",
			target_scale,
			duration_s
		).set_delay(
			preview_delay_s
			+ float(preview_index)
			* ui_stagger_s
		)


func _restore_final_scales() -> void:
	for control: Control in animated_controls:
		if control == null:
			continue

		control.scale = _get_control_base_scale(
			control
		)

	for preview_anchor: Node3D in preview_anchors:
		if preview_anchor == null:
			continue

		preview_anchor.scale = _get_preview_base_scale(
			preview_anchor
		)


func _get_control_base_scale(
	control: Control
) -> Vector2:
	if _control_base_scales.has(
		control
	):
		return _control_base_scales[control]

	_control_base_scales[control] = control.scale

	return control.scale


func _get_preview_base_scale(
	preview_anchor: Node3D
) -> Vector3:
	if _preview_base_scales.has(
		preview_anchor
	):
		return _preview_base_scales[preview_anchor]

	_preview_base_scales[preview_anchor] = (
		preview_anchor.scale
	)

	return preview_anchor.scale


func _kill_open_tween() -> void:
	if _open_tween == null:
		return

	if _open_tween.is_valid():
		_open_tween.kill()

	_open_tween = null
