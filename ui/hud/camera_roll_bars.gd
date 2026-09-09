class_name CameraRollBarsHud
extends HudElement

@export_category("references")
@export var left_bar: TextureRect
@export var right_bar: TextureRect

@export_category("rotation")
@export var rotation_multiplier: float = -1.0

@export var glide_rotation_multiplier: float = -1.0

@export_range(
	0.0,
	180.0,
	0.1,
	"suffix:deg"
) var maximum_rotation_degrees: float = 45.0

@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var roll_follow_speed: float = 20.0

@export_category("rotation pivot")
@export var use_control_center_as_pivot: bool = true

@export var pivot_offset_adjustment_px: Vector2 = Vector2.ZERO

var _base_root_rotation: float = 0.0

var _target_roll_radians: float = 0.0
var _displayed_roll_radians: float = 0.0
var _is_gliding: bool = false


func _ready() -> void:
	super._ready()

	if left_bar == null:
		push_error(
			"%s requires LeftBar."
			% name
		)
		set_process(false)
		return

	if right_bar == null:
		push_error(
			"%s requires RightBar."
			% name
		)
		set_process(false)
		return

	_base_root_rotation = rotation

	call_deferred(
		"_configure_rotation_pivot"
	)


func _process(
	delta: float
) -> void:
	super._process(delta)

	var follow_weight: float = (
		1.0
		- exp(
			-roll_follow_speed
			* delta
		)
	)

	_displayed_roll_radians = lerp_angle(
		_displayed_roll_radians,
		_target_roll_radians,
		follow_weight
	)

	_apply_rotation()


func set_roll_degrees(
	roll_degrees: float,
	is_gliding: bool
) -> void:
	_is_gliding = is_gliding

	var clamped_roll_degrees: float = clampf(
		roll_degrees,
		-maximum_rotation_degrees,
		maximum_rotation_degrees
	)

	_target_roll_radians = deg_to_rad(
		clamped_roll_degrees
	)


func _configure_rotation_pivot() -> void:
	if not use_control_center_as_pivot:
		return

	pivot_offset = (
		size
		* 0.5
		+ pivot_offset_adjustment_px
	)


func _apply_rotation() -> void:
	var current_rotation_multiplier: float = (
		rotation_multiplier
	)

	if _is_gliding:
		current_rotation_multiplier *= (
			glide_rotation_multiplier
		)

	var rotation_offset: float = (
		_displayed_roll_radians
		* current_rotation_multiplier
	)

	rotation = (
		_base_root_rotation
		+ rotation_offset
	)
