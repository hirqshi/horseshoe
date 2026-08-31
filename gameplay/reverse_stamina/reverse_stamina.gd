class_name ReverseStamina
extends Node

signal value_changed(
	current_value: float,
	max_value: float,
	normalized_value: float
)

signal depleted()

@export_category("capacity")
@export_range(1.0, 1000.0, 0.1) var max_value: float = 100.0
@export_range(0.0, 1000.0, 0.1) var starting_value: float = 100.0

@export_category("speed thresholds")
@export_range(0.0, 20.0, 0.01, "suffix:m/s") var idle_speed_mps: float = 0.15
@export_range(0.1, 50.0, 0.01, "suffix:m/s") var safe_speed_mps: float = 7.0
@export_range(0.1, 50.0, 0.01, "suffix:m/s") var max_recovery_speed_mps: float = 14.0

@export_category("drain")
@export_range(0.0, 100.0, 0.01, "suffix:points/s") var idle_drain_per_second: float = 18.0
@export_range(0.0, 100.0, 0.01, "suffix:points/s") var slow_movement_drain_per_second: float = 5.0

@export_category("recovery")
@export_range(0.0, 100.0, 0.01, "suffix:points/s") var max_recovery_per_second: float = 14.0

@export_category("slowdown grace")
@export_range(0.0, 10.0, 0.01, "suffix:s") var slowdown_grace_duration: float = 0.85

@export_category("rest zone recovery")
@export_range(0.0, 100.0, 0.01, "suffix:points/s") var rest_recovery_per_second: float = 45.0

var current_value: float
var is_depleted: bool = false
var is_resting: bool = false
var slowdown_grace_remaining: float = 0.0

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player

	if _player == null:
		push_error(
			"ReverseStamina must be a child of Player."
		)
		set_physics_process(false)
		return

	if max_recovery_speed_mps < safe_speed_mps:
		push_warning(
			"ReverseStamina max_recovery_speed_mps must be greater than safe_speed_mps."
		)

	current_value = clampf(
		starting_value,
		0.0,
		max_value
	)

	slowdown_grace_remaining = slowdown_grace_duration

	_emit_value_changed()


func _physics_process(delta: float) -> void:
	if is_depleted:
		return

	if is_resting:
		_change_value(
			rest_recovery_per_second * delta
		)
		return

	var horizontal_speed_mps: float = Vector2(
		_player.velocity.x,
		_player.velocity.z
	).length()

	if horizontal_speed_mps >= safe_speed_mps:
		slowdown_grace_remaining = slowdown_grace_duration
	else:
		slowdown_grace_remaining = maxf(
			0.0,
			slowdown_grace_remaining - delta
		)

		if slowdown_grace_remaining > 0.0:
			return

	var value_change_per_second: float = (
		_get_value_change_per_second(
			horizontal_speed_mps
		)
	)

	if is_zero_approx(value_change_per_second):
		return

	_change_value(
		value_change_per_second * delta
	)

	if is_zero_approx(current_value):
		is_depleted = true
		depleted.emit()


func get_normalized_value() -> float:
	if max_value <= 0.0:
		return 0.0

	return current_value / max_value


func restore_full() -> void:
	current_value = max_value
	is_depleted = false

	slowdown_grace_remaining = slowdown_grace_duration

	_emit_value_changed()


func set_resting(value: bool) -> void:
	if is_resting == value:
		return

	is_resting = value

	if not is_resting:
		slowdown_grace_remaining = slowdown_grace_duration


func _change_value(
	value_delta: float
) -> void:
	var previous_value: float = current_value

	current_value = clampf(
		current_value + value_delta,
		0.0,
		max_value
	)

	if !is_equal_approx(
		previous_value,
		current_value
	):
		_emit_value_changed()


func _get_value_change_per_second(
	horizontal_speed_mps: float
) -> float:
	if horizontal_speed_mps <= idle_speed_mps:
		return -idle_drain_per_second

	if horizontal_speed_mps < safe_speed_mps:
		var slow_speed_progress: float = inverse_lerp(
			idle_speed_mps,
			safe_speed_mps,
			horizontal_speed_mps
		)

		return -lerpf(
			slow_movement_drain_per_second,
			0.0,
			slow_speed_progress
		)

	if horizontal_speed_mps >= max_recovery_speed_mps:
		return max_recovery_per_second

	var recovery_progress: float = inverse_lerp(
		safe_speed_mps,
		max_recovery_speed_mps,
		horizontal_speed_mps
	)

	return lerpf(
		0.0,
		max_recovery_per_second,
		recovery_progress
	)


func _emit_value_changed() -> void:
	value_changed.emit(
		current_value,
		max_value,
		get_normalized_value()
	)
