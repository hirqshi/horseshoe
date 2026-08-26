class_name WallrunConfig
extends Resource

@export_category("timing")
@export var duration_s: float = 1.10
@export var reentry_cooldown_s: float = 0.12
@export var fall_delay_s: float = 0.18

@export_category("horizontal movement")
@export var steering_acceleration_mps2: float = 20.0
@export var minimum_control_speed_mps: float = 7.0

@export_category("vertical movement")
@export_range(0.0, 2.0, 0.01) var gravity_multiplier: float = 0.75
@export var max_fall_speed_mps: float = 18.0
@export_range(0.0, 1.0, 0.01)
var entry_upward_velocity_retention: float = 0.35

@export var max_entry_upward_speed_mps: float = 3.5

@export_category("contact")
@export_range(-1.0, 1.0, 0.01) var minimum_normal_alignment: float = 0.65

@export_category("wall jump")
@export_range(1, 4, 1) var max_wall_jump_charges: int = 1
@export_range(0.0, 1.0, 0.01) var toward_wall_threshold: float = 0.35
@export var wall_jump_upward_speed_mps: float = 8.0

@export_category("wall jump away")
@export var wall_jump_away_outward_speed_mps: float = 9.0
@export var wall_jump_away_forward_speed_mps: float = 4.0

@export_category("wall jump toward")
@export var wall_jump_toward_outward_speed_mps: float = 2.0
@export var wall_jump_toward_forward_speed_mps: float = 9.0
@export var wall_jump_toward_upward_multiplier: float = 1.12

@export_category("wallrun entry")
@export var minimum_tangential_entry_speed_mps: float = 1.0
@export_range(0.0, 1.0, 0.01)
var minimum_tangential_input: float = 0.15

@export_category("wall jump perpendicular")
@export var wall_jump_contact_distance_m: float = 0.48

@export_category("wall jump perpendicular")
@export var wall_jump_perpendicular_outward_speed_mps: float = 9.0
@export var wall_jump_perpendicular_upward_speed_mps: float = 8.0
@export var wall_jump_tangent_input_threshold: float = 0.15

@export_category("entry")
@export var tangential_entry_deadzone_mps: float = 0.75

@export_category("wallrun entry")
@export_range(0.0, 1.0, 0.01)
var perpendicular_look_normal_dot: float = 0.96

@export_category("debug")
@export var is_debug_enabled: bool = false
@export var debug_interval_s: float = 0.15
