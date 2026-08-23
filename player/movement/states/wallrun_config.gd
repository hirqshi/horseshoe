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
