class_name MovementConfig
extends Resource

@export_category("ground")
@export var run_speed_forward_mps: float = 10.0
@export_range(0.0, 1.0, 0.01)
var run_speed_side_multiplier: float = 0.85
@export_range(0.0, 1.0, 0.01)
var run_speed_back_multiplier: float = 0.65
@export var walk_speed_multiplier: float = 0.35
@export var ground_acceleration_mps2: float = 44.0
@export var ground_deceleration_mps2: float = 36.0

@export_category("ground momentum")

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var ground_speed_decay_mps2: float = 12.0

@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:s"
) var continuous_run_delay_s: float = 0.4

@export_range(
	0.0,
	20.0,
	0.001,
	"suffix:m/s²"
) var continuous_run_acceleration_mps2: float = 0.35

@export_range(
	0.0,
	20.0,
	0.01,
	"suffix:m/s"
) var continuous_run_entry_tolerance_mps: float = 0.5

@export_category("air movement")
@export var air_control_acceleration_mps2: float = 35.0

@export_category("air momentum")
@export_range(0.0, 5.0, 0.01, "suffix:s")
var air_momentum_grace_duration_s: float = 0.75

@export_range(0.0, 5.0, 0.01, "suffix:s")
var air_momentum_grace_min_duration_s: float = 0.16

@export_range(
	0.0,
	2.0,
	0.001,
	"suffix:1/(m/s)"
) var air_momentum_grace_exponential_decay: float = 0.11

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var air_excess_speed_decay_at_reference_mps2: float = 3.0

@export_range(
	0.1,
	100.0,
	0.01,
	"suffix:m/s"
) var air_excess_speed_reference_mps: float = 6.0

@export_range(
	1.0,
	4.0,
	0.01
) var air_excess_speed_decay_exponent: float = 1.65

@export_category("momentum grace")

@export_range(
	0.0,
	5.0,
	0.01,
	"suffix:s"
) var momentum_grace_duration_s: float = 0.9

@export_range(
	0.0,
	1.0,
	0.01
) var momentum_grace_recovery_multiplier: float = 0.85

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var momentum_grace_minimum_saved_speed_mps: float = 8.0

@export_range(
	0.0,
	1.0,
	0.01
) var momentum_grace_collision_loss_ratio: float = 0.6

@export_category("vertical")
@export var gravity_mps2: float = 28.0
@export var terminal_fall_speed_mps: float = 50.0
@export var jump_speed_mps: float = 9.5
@export var coyote_time_s: float = 0.10
@export var jump_buffer_s: float = 0.12
@export var jump_hold_duration_s: float = 0.16
@export_range(0.0, 1.0, 0.01)
var jump_hold_gravity_multiplier: float = 0.35
@export_range(0.0, 1.0, 0.01)
var jump_release_velocity_multiplier: float = 0.45

@export_category("collision")
@export_range(1.0, 89.0, 1.0) var max_floor_angle_deg: float = 50.0
