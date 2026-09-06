class_name GrappleDistanceHud
extends HudElement

enum DisplayState {
	DEFAULT,
	TARGET_AVAILABLE,
	COOLDOWN,
}

@export_category("references")
@export var state_icon: TextureRect
@export var distance_label: Label

@export_category("distance display")
@export var unavailable_text: String = "n/a"
@export var distance_prefix: String = ""
@export var distance_suffix: String = ""

@export_category("icon alpha")
@export_range(
	0.0,
	1.0,
	0.01
) var default_icon_alpha: float = 0.30

@export_range(
	0.0,
	1.0,
	0.01
) var target_available_icon_alpha: float = 1.0

@export_range(
	0.0,
	1.0,
	0.01
) var cooldown_icon_alpha: float = 0.50

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

var _base_icon_self_modulate: Color = Color.WHITE


func _ready() -> void:
	super._ready()

	if state_icon == null:
		push_error(
			"%s requires StateIcon."
			% name
		)
		set_process(false)
		return

	if distance_label == null:
		push_error(
			"%s requires DistanceLabel."
			% name
		)
		set_process(false)
		return

	_base_icon_self_modulate = state_icon.self_modulate

	distance_label.text = unavailable_text

	_set_display_state(
		DisplayState.DEFAULT
	)


func _process(
	delta: float
) -> void:
	super._process(delta)

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


func set_target_distance_m(
	target_distance_m: float,
	max_target_distance_m: float
) -> void:
	var has_raycast_hit: bool = (
		target_distance_m >= 0.0
	)

	var is_inside_hook_range: bool = (
		max_target_distance_m > 0.0
		and target_distance_m <= max_target_distance_m
	)

	if not has_raycast_hit \
	or not is_inside_hook_range:
		distance_label.text = unavailable_text
		return

	distance_label.text = (
		distance_prefix
		+ "%.2f" % target_distance_m
		+ distance_suffix
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

	state_icon.rotation = 0.0

	_set_display_state(
		DisplayState.COOLDOWN
	)


func finish_cooldown() -> void:
	_cooldown_remaining_s = 0.0
	_cooldown_duration_s = 0.0
	_cooldown_rotation_speed_rad_s = 0.0

	state_icon.rotation = 0.0

	if _has_target:
		_set_display_state(
			DisplayState.TARGET_AVAILABLE
		)
		return

	_set_display_state(
		DisplayState.DEFAULT
	)


func _update_cooldown(
	delta: float
) -> void:
	_cooldown_remaining_s = maxf(
		_cooldown_remaining_s
		- delta,
		0.0
	)

	state_icon.rotation += (
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

	var target_alpha: float = default_icon_alpha

	match _display_state:
		DisplayState.DEFAULT:
			target_alpha = default_icon_alpha

		DisplayState.TARGET_AVAILABLE:
			target_alpha = target_available_icon_alpha

		DisplayState.COOLDOWN:
			target_alpha = cooldown_icon_alpha

	state_icon.self_modulate = Color(
		_base_icon_self_modulate.r,
		_base_icon_self_modulate.g,
		_base_icon_self_modulate.b,
		_base_icon_self_modulate.a
		* target_alpha
	)
