class_name CursorFrame
extends Control

@export_group("Corners")
@export var top_left: TextureRect
@export var top_right: TextureRect
@export var bottom_left: TextureRect
@export var bottom_right: TextureRect

@export_group("Hover Targets")
@export var hover_targets: Array[Control] = []

@export_group("Free Cursor Frame")
@export var free_size_px: Vector2 = Vector2(
	38.0,
	38.0
)

@export_group("Target Frame")
@export_range(0.0, 100.0, 1.0) var target_padding_px: float = 12.0

@export_group("Smoothing")
@export_range(1.0, 60.0, 0.1) var follow_speed: float = 22.0
@export_range(1.0, 60.0, 0.1) var resize_speed: float = 18.0

var _hover_target: Control = null
var _target_rect: Rect2 = Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_validate_references()
	_connect_hover_targets()

	size = free_size_px
	_layout_corners()


func _process(
	delta: float
) -> void:
	var desired_rect: Rect2 = _get_desired_rect()

	var follow_weight: float = 1.0 - exp(
		-follow_speed
		* delta
	)

	var resize_weight: float = 1.0 - exp(
		-resize_speed
		* delta
	)

	global_position = global_position.lerp(
		desired_rect.position,
		follow_weight
	)

	size = size.lerp(
		desired_rect.size,
		resize_weight
	)

	_layout_corners()


func _validate_references() -> void:
	if top_left == null:
		push_error(
			"CursorFrame requires a TopLeft corner."
		)

	if top_right == null:
		push_error(
			"CursorFrame requires a TopRight corner."
		)

	if bottom_left == null:
		push_error(
			"CursorFrame requires a BottomLeft corner."
		)

	if bottom_right == null:
		push_error(
			"CursorFrame requires a BottomRight corner."
		)


func _connect_hover_targets() -> void:
	for target: Control in hover_targets:
		if target == null:
			continue

		target.mouse_entered.connect(
			_on_hover_target_mouse_entered.bind(
				target
			)
		)

		target.mouse_exited.connect(
			_on_hover_target_mouse_exited.bind(
				target
			)
		)

		target.focus_entered.connect(
			_on_hover_target_focus_entered.bind(
				target
			)
		)


func _get_desired_rect() -> Rect2:
	if (
		_hover_target != null
		and is_instance_valid(
			_hover_target
		)
		and _hover_target.visible
	):
		return _hover_target.get_global_rect().grow(
			target_padding_px
		)

	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	return Rect2(
		mouse_position
		- free_size_px * 0.5,
		free_size_px
	)


func _layout_corners() -> void:
	if (
		top_left == null
		or top_right == null
		or bottom_left == null
		or bottom_right == null
	):
		return

	top_left.position = Vector2.ZERO

	top_right.position = Vector2(
		size.x
		- top_right.size.x,
		0.0
	)

	bottom_left.position = Vector2(
		0.0,
		size.y
		- bottom_left.size.y
	)

	bottom_right.position = Vector2(
		size.x
		- bottom_right.size.x,
		size.y
		- bottom_right.size.y
	)


func _on_hover_target_mouse_entered(
	target: Control
) -> void:
	_hover_target = target


func _on_hover_target_mouse_exited(
	target: Control
) -> void:
	if _hover_target != target:
		return

	_hover_target = null


func _on_hover_target_focus_entered(
	target: Control
) -> void:
	_hover_target = target
