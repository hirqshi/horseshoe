class_name GlideConfig
extends Resource

@export_category("charges")
@export_range(1, 4, 1) var max_charges: int = 2

@export_category("entry")
@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var minimum_entry_speed_mps: float = 0.0

@export_category("exit")
@export_range(
	0.1,
	10.0,
	0.01,
	"suffix:m"
) var auto_exit_ground_distance_m: float = 1.10

@export_category("flight look")
@export_range(
	0.1,
	3.0,
	0.01
) var look_sensitivity_multiplier: float = 1.0

@export_range(
	0.0,
	89.0,
	0.1,
	"suffix:deg"
) var maximum_bank_angle_deg: float = 35.0

@export_range(
	0.1,
	50.0,
	0.1,
	"suffix:1/s"
) var bank_response_speed: float = 14.0

@export_range(
	0.1,
	50.0,
	0.1,
	"suffix:1/s"
) var bank_return_speed: float = 8.0

@export_range(
	0.0,
	100.0,
	0.01
) var bank_input_strength: float = 26.0

@export_category("flight speed")
@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var minimum_flight_speed_mps: float = 6.0

@export_range(
	1.0,
	150.0,
	0.01,
	"suffix:m/s"
) var maximum_flight_speed_mps: float = 38.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var forward_acceleration_mps2: float = 26.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var heading_turn_acceleration_mps2: float = 42.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var input_steering_acceleration_mps2: float = 4.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var maximum_drag_deceleration_mps2: float = 8.0

@export_range(
	0.1,
	4.0,
	0.01
) var drag_speed_exponent: float = 1.5

@export_category("vertical glide")
@export_range(
	0.0,
	20.0,
	0.01,
	"suffix:m/s"
) var neutral_sink_speed_mps: float = 1.6

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var vertical_response_mps2: float = 14.0

@export_range(
	0.0,
	50.0,
	0.01,
	"suffix:m/s"
) var maximum_dive_sink_speed_mps: float = 18.0

@export_range(
	0.0,
	50.0,
	0.01,
	"suffix:m/s"
) var maximum_climb_speed_mps: float = 11.0

@export_range(
	0.0,
	1.0,
	0.01
) var pitch_direction_start: float = 0.08

@export_range(
	0.01,
	1.0,
	0.01
) var pitch_direction_full: float = 0.45

@export_category("energy flight")
@export_range(
	0.0,
	720.0,
	1.0,
	"suffix:deg/s"
) var pitch_follow_speed_deg_s: float = 150.0

@export_range(
	0.0,
	720.0,
	1.0,
	"suffix:deg/s"
) var heading_turn_speed_deg_s: float = 180.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var lift_acceleration_mps2: float = 30.0

@export_range(
	0.0,
	1.5,
	0.01
) var level_flight_assist: float = 0.88

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s"
) var stall_speed_mps: float = 5.0

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var stall_fall_acceleration_mps2: float = 18.0
