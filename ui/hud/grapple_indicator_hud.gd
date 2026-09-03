class_name GrappleIndicatorHud
extends HudElement

enum DisplayState {
	DEFAULT,
	TARGET_AVAILABLE,
	COOLDOWN,
}

@export_category("references")
@export var icon: TextureRect

@export_category("alpha")
@export_range(
	0.0,
	1.0,
	0.01
) var default_alpha: float = 0.30

@export_range(
	0.0,
	1.0,
	0.01
) var target_available_alpha: float = 1.0

@export_range(
	0.0,
	1.0,
	0.01
) var cooldown_alpha: float = 0.50

@export_category("cooldown rotation")
@export_range(
	0.0,
	20.0,
	0.1,
	"suffix:turns"
) var cooldown_rotation_turns: float = 3.0

@export_range(
	0.0,
	7200.0,
	1.0,
	"suffix:deg/s"
) var minimum_rotation_speed_deg_s: float = 360.0

var _display_state: DisplayState = (
	DisplayState.DEFAULT
)

var _has_target: bool = false
var _cooldown_remaining_s: float = 0.0
var _cooldown_duration_s: float = 0.0
var _cooldown_rotation_speed_rad_s: float = 0.0


func _ready() -> void:
	super._ready()

	if icon == null:
		push_error(
			"GrappleIndicatorHud requires an Icon."
		)

		set_process(false)
		return

	_set_display_state(
		DisplayState.DEFAULT
	)


func _process(
	delta: float
) -> void:
	super._process(
		delta
	)

	if _display_state != DisplayState.COOLDOWN:
		return

	_update_cooldown(
		delta
	)


func set_target_available(
	value: bool
) -> void:
	_has_target = value

	if _display_state == DisplayState.COOLDOWN:
		return

	if _has_target:
		_set_display_state(
			DisplayState.TARGET_AVAILABLE
		)

		return

	_set_display_state(
		DisplayState.DEFAULT
	)


func start_cooldown(
	duration_s: float
) -> void:
	if duration_s <= 0.0:
		finish_cooldown()
		return

	_cooldown_duration_s = duration_s
	_cooldown_remaining_s = duration_s

	var requested_rotation_speed_rad_s: float = (
		TAU
		* cooldown_rotation_turns
		/ duration_s
	)

	_cooldown_rotation_speed_rad_s = maxf(
		requested_rotation_speed_rad_s,
		deg_to_rad(
			minimum_rotation_speed_deg_s
		)
	)

	icon.rotation = 0.0

	_set_display_state(
		DisplayState.COOLDOWN
	)


func finish_cooldown() -> void:
	_cooldown_remaining_s = 0.0
	_cooldown_duration_s = 0.0
	_cooldown_rotation_speed_rad_s = 0.0

	icon.rotation = 0.0

	if _has_target:
		_set_display_state(
			DisplayState.TARGET_AVAILABLE
		)

		return

	_set_display_state(
		DisplayState.DEFAULT
	)


func is_on_cooldown() -> bool:
	return _display_state == DisplayState.COOLDOWN


func _update_cooldown(
	delta: float
) -> void:
	_cooldown_remaining_s = maxf(
		_cooldown_remaining_s
		- delta,
		0.0
	)

	icon.rotation += (
		_cooldown_rotation_speed_rad_s
		* delta
	)

	if _cooldown_remaining_s > 0.0:
		return

	finish_cooldown()


func _set_display_state(
	next_state: DisplayState
) -> void:
	if _display_state == next_state:
		return

	_display_state = next_state

	match _display_state:
		DisplayState.DEFAULT:
			set_element_alpha(
				default_alpha
			)

		DisplayState.TARGET_AVAILABLE:
			set_element_alpha(
				target_available_alpha
			)

		DisplayState.COOLDOWN:
			set_element_alpha(
				cooldown_alpha
			)
