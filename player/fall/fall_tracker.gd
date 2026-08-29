class_name FallTracker
extends Node

signal fall_started(start_height_y_m: float)
signal fall_updated(
	fall_distance_m: float,
	fall_progress: float,
	downward_speed_mps: float,
	fall_time_s: float,
	is_critical: bool
)
signal fall_ended(
	fall_distance_m: float,
	impact_speed_mps: float
)
signal fall_damage_requested(
	damage: float,
	fall_distance_m: float,
	impact_speed_mps: float
)
signal fatal_fall_detected(
	fall_distance_m: float,
	impact_speed_mps: float
)
signal fall_ui_hidden()

@export_category("references")
@export var config: FallConfig
@export var movement_motor: MovementMotor

var _body: CharacterBody3D

var _is_tracking_fall: bool = false
var _is_falling: bool = false
var _is_fall_ui_visible: bool = false

var _peak_height_y_m: float = 0.0
var _fall_time_s: float = 0.0

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error("FallTracker must be a child of CharacterBody3D.")
		set_physics_process(false)
		return

	if config == null:
		push_error("FallTracker requires FallConfig.")
		set_physics_process(false)
		return

	if not config.is_valid():
		push_error("FallTracker has invalid FallConfig values.")
		set_physics_process(false)
		return

	if movement_motor == null:
		push_error("FallTracker requires MovementMotor.")
		set_physics_process(false)
		return

	movement_motor.left_ground.connect(_on_movement_motor_left_ground)
	movement_motor.jumped.connect(_on_movement_motor_jumped)
	movement_motor.landed.connect(_on_movement_motor_landed)

func _hide_fall_ui() -> void:
	if not _is_fall_ui_visible:
		return

	_is_fall_ui_visible = false
	fall_ui_hidden.emit()

func _physics_process(delta: float) -> void:
	if not _is_tracking_fall:
		return

	if _body.is_on_floor():
		return

	_peak_height_y_m = maxf(
		_peak_height_y_m,
		_body.global_position.y
	)

	var downward_speed_mps: float = maxf(
		-_body.velocity.y,
		0.0
	)

	_is_falling = (
		downward_speed_mps
		>= config.minimum_downward_speed_mps
	)

	if not _is_falling:
		_fall_time_s = 0.0
		_hide_fall_ui()
		return

	_fall_time_s += delta

	if _fall_time_s < config.fall_ui_delay_s:
		return

	_is_fall_ui_visible = true

	var fall_distance_m: float = _get_current_fall_distance_m()
	var fall_progress: float = _get_fall_progress(
		fall_distance_m
	)

	fall_updated.emit(
		fall_distance_m,
		fall_progress,
		downward_speed_mps,
		_fall_time_s,
		fall_progress >= config.critical_progress
	)

func _on_movement_motor_left_ground() -> void:
	_begin_tracking_fall()

func _on_movement_motor_jumped() -> void:
	_begin_tracking_fall()

func _on_movement_motor_landed(
	impact_speed_mps: float
) -> void:
	if not _is_tracking_fall:
		return

	var fall_distance_m: float = _get_current_fall_distance_m()

	fall_ended.emit(
		fall_distance_m,
		impact_speed_mps
	)

	_resolve_landing(
		fall_distance_m,
		impact_speed_mps
	)

	_reset_fall()

func _begin_tracking_fall() -> void:
	_is_tracking_fall = true
	_is_falling = false
	_is_fall_ui_visible = false
	_fall_time_s = 0.0
	_peak_height_y_m = _body.global_position.y

	fall_started.emit(_peak_height_y_m)

func _resolve_landing(
	fall_distance_m: float,
	impact_speed_mps: float
) -> void:
	var is_fatal_fall: bool = (
		fall_distance_m >= config.lethal_distance_m
		and impact_speed_mps >= config.lethal_impact_speed_mps
	)

	if is_fatal_fall:
		fatal_fall_detected.emit(
			fall_distance_m,
			impact_speed_mps
		)
		return

	var damage: float = _calculate_fall_damage(
		fall_distance_m,
		impact_speed_mps
	)

	if damage <= 0.0:
		return

	fall_damage_requested.emit(
		damage,
		fall_distance_m,
		impact_speed_mps
	)

func _calculate_fall_damage(
	fall_distance_m: float,
	impact_speed_mps: float
) -> float:
	var distance_factor: float = inverse_lerp(
		config.damage_start_distance_m,
		config.lethal_distance_m,
		fall_distance_m
	)

	var impact_factor: float = inverse_lerp(
		config.damage_start_impact_speed_mps,
		config.lethal_impact_speed_mps,
		impact_speed_mps
	)

	var damage_factor: float = clampf(
		minf(
			distance_factor,
			impact_factor
		),
		0.0,
		1.0
	)

	return damage_factor * config.maximum_damage

func _get_current_fall_distance_m() -> float:
	return maxf(
		_peak_height_y_m - _body.global_position.y,
		0.0
	)

func _get_fall_progress(
	fall_distance_m: float
) -> float:
	return clampf(
		fall_distance_m / config.lethal_distance_m,
		0.0,
		1.0
	)

func _reset_fall() -> void:
	_hide_fall_ui()

	_is_tracking_fall = false
	_is_falling = false
	_peak_height_y_m = _body.global_position.y
	_fall_time_s = 0.0
