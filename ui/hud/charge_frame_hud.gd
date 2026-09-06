class_name ChargeFrameHud
extends HudElement

@export_category("references")
@export var charge_count_label: Label
@export var cooldown_label: Label

@export_category("cooldown")
@export var is_cooldown_display_enabled: bool = false
@export var cooldown_label_prefix: String = ""
@export var cooldown_label_suffix: String = ""

@export_category("alpha")
@export_range(
	0.0,
	1.0,
	0.01
) var default_alpha: float = 0.75

@export_range(
	0.0,
	1.0,
	0.01
) var unavailable_alpha: float = 0.22

@export_range(
	0.0,
	1.0,
	0.01
) var empty_alpha: float = 0.0

@export_range(
	0.0,
	1.0,
	0.01
) var pulse_alpha: float = 1.0

@export_category("pulse")
@export_range(
	1.0,
	3.0,
	0.01
) var pulse_scale: float = 1.2

@export_range(
	0.01,
	1.0,
	0.01,
	"suffix:s"
) var pulse_in_duration_s: float = 0.06

@export_range(
	0.01,
	1.0,
	0.01,
	"suffix:s"
) var pulse_out_duration_s: float = 0.13

@export_category("transition")
@export_range(
	0.01,
	1.0,
	0.01,
	"suffix:s"
) var alpha_transition_duration_s: float = 0.12

var _available_charges: int = 0
var _is_move_available: bool = false
var _is_initialized: bool = false

var _current_alpha: float = 1.0
var _target_alpha: float = 1.0

var _base_modulate: Color = Color.WHITE
var _base_scale: Vector2 = Vector2.ONE

var _is_pulsing: bool = false
var _state_tween: Tween


func _ready() -> void:
	super._ready()

	if charge_count_label == null:
		push_error(
			"%s requires ChargeCountLabel."
			% name
		)
		set_process(false)
		return

	if is_cooldown_display_enabled \
	and cooldown_label == null:
		push_error(
			"%s requires CooldownLabel "
			+ "when cooldown display is enabled."
			% name
		)
		set_process(false)
		return

	_base_modulate = modulate
	_base_scale = scale

	charge_count_label.text = "0"

	if cooldown_label != null:
		cooldown_label.visible = false
		cooldown_label.text = ""

	_target_alpha = empty_alpha

	_set_alpha(
		empty_alpha
	)


func set_charge_state(
	available_charges: int,
	is_move_available: bool
) -> void:
	var previous_charges: int = _available_charges

	_available_charges = max(
		available_charges,
		0
	)

	_is_move_available = is_move_available

	charge_count_label.text = str(
		_available_charges
	)

	_target_alpha = _get_target_alpha()

	var charges_changed: bool = (
		_available_charges
		!= previous_charges
	)

	var should_pulse: bool = (
		_is_initialized
		and charges_changed
	)

	if should_pulse:
		_play_pulse()
	elif not _is_pulsing:
		_tween_to(
			_target_alpha,
			alpha_transition_duration_s
		)

	_is_initialized = true


func set_cooldown_remaining_s(
	cooldown_remaining_s: float
) -> void:
	if not is_cooldown_display_enabled:
		return

	if cooldown_label == null:
		return

	var clamped_remaining_s: float = maxf(
		cooldown_remaining_s,
		0.0
	)

	var is_on_cooldown: bool = (
		clamped_remaining_s > 0.0
	)

	cooldown_label.visible = is_on_cooldown

	if not is_on_cooldown:
		cooldown_label.text = ""
		return

	cooldown_label.text = (
		cooldown_label_prefix
		+ "%.1f" % clamped_remaining_s
		+ cooldown_label_suffix
	)


func _get_target_alpha() -> float:
	if _available_charges <= 0:
		return empty_alpha

	if not _is_move_available:
		return unavailable_alpha

	return default_alpha


func _play_pulse() -> void:
	_kill_state_tween()

	_is_pulsing = true

	_state_tween = create_tween()

	var grow_tween: Tween = _state_tween.set_parallel(
		true
	)

	grow_tween.tween_method(
		_set_alpha,
		_current_alpha,
		pulse_alpha,
		pulse_in_duration_s
	)

	grow_tween.tween_property(
		self,
		"scale",
		_base_scale
		* pulse_scale,
		pulse_in_duration_s
	)

	var settle_tween: Tween = _state_tween.chain().set_parallel(
		true
	)

	settle_tween.tween_method(
		_set_alpha,
		pulse_alpha,
		_target_alpha,
		pulse_out_duration_s
	)

	settle_tween.tween_property(
		self,
		"scale",
		_base_scale,
		pulse_out_duration_s
	)

	_state_tween.chain().tween_callback(
		_finish_pulse
	)


func _finish_pulse() -> void:
	_is_pulsing = false
	_state_tween = null

	scale = _base_scale

	_set_alpha(
		_target_alpha
	)


func _tween_to(
	target_alpha: float,
	duration_s: float
) -> void:
	_kill_state_tween()

	if is_equal_approx(
		_current_alpha,
		target_alpha
	):
		return

	_state_tween = create_tween()

	_state_tween.tween_method(
		_set_alpha,
		_current_alpha,
		target_alpha,
		duration_s
	)


func _set_alpha(
	alpha: float
) -> void:
	_current_alpha = clampf(
		alpha,
		0.0,
		1.0
	)

	modulate = Color(
		_base_modulate.r,
		_base_modulate.g,
		_base_modulate.b,
		_base_modulate.a
		* _current_alpha
	)


func _kill_state_tween() -> void:
	if _state_tween != null:
		_state_tween.kill()

	_state_tween = null
	_is_pulsing = false
