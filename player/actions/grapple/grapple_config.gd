class_name GrappleConfig
extends Resource

enum GrappleMode {
	SWING_ON_HOLD_RELEASE_PULL,
	PULL_ON_HOLD_RELEASE_CANCEL,
}

@export_category("mode")
@export var grapple_mode: GrappleMode = (
	GrappleMode.SWING_ON_HOLD_RELEASE_PULL
)

@export_category("targeting")
@export_range(
	0.0,
	100.0,
	0.1,
	"suffix:m"
) var minimum_target_distance_m: float = 2.0

@export_range(
	1.0,
	200.0,
	0.1,
	"suffix:m"
) var maximum_target_distance_m: float = 35.0

@export_category("hook flight")
@export_range(
	1.0,
	500.0,
	0.1,
	"suffix:m/s"
) var hook_travel_speed_mps: float = 110.0

@export_category("hook return")
@export_range(
	1.0,
	500.0,
	0.1,
	"suffix:m/s"
) var hook_return_speed_mps: float = 145.0

@export_category("swing")
@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:m"
) var rope_slack_m: float = 0.15

@export_range(
	0.0,
	500.0,
	0.1,
	"suffix:m/s² per m"
) var rope_constraint_acceleration_per_m: float = 95.0

@export_range(
	0.0,
	100.0,
	0.1,
	"suffix:m/s²"
) var maximum_rope_correction_mps2: float = 60.0

@export_category("pull")
@export_range(
	0.0,
	500.0,
	0.1,
	"suffix:m/s²"
) var pull_acceleration_mps2: float = 75.0

@export_range(
	1.0,
	200.0,
	0.1,
	"suffix:m/s"
) var maximum_pull_speed_mps: float = 32.0

@export_range(
	0.1,
	10.0,
	0.01,
	"suffix:m"
) var pull_arrival_distance_m: float = 1.25

@export_category("cooldown")
@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:s"
) var cooldown_s: float = 0.65

@export_category("rope wrapping")
@export_range(
	0,
	8,
	1,
	"suffix:points"
) var maximum_wrap_points: int = 3

@export_range(
	0.001,
	0.5,
	0.001,
	"suffix:m"
) var wrap_surface_offset_m: float = 0.04

@export_range(
	0.001,
	1.0,
	0.001,
	"suffix:m"
) var wrap_endpoint_tolerance_m: float = 0.08

func is_hold_to_pull_mode() -> bool:
	return grapple_mode == (
		GrappleMode.PULL_ON_HOLD_RELEASE_CANCEL
	)
