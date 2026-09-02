class_name DashConfig
extends Resource

@export_category("charges")
@export_range(1, 4, 1) var max_charges: int = 1

@export_category("movement")
@export_range(0.01, 2.0, 0.01, "suffix:s") var duration_s: float = 0.14
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var minimum_speed_mps: float = 12.0
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var speed_bonus_mps: float = 4.0

@export_category("cooldown")
@export_range(0.0, 3.0, 0.01, "suffix:s") var cooldown_s: float = 0.24

@export_category("wave dash")

@export_range(0.01, 1.0, 0.01, "suffix:s")
var wave_dash_window_s: float = 0.2

@export_range(0.0, 30.0, 0.01, "suffix:m/s")
var wave_dash_minimum_normal_impact_speed_mps: float = 1.0

@export_range(0.0, 2.0, 0.01)
var wave_dash_velocity_retention: float = 1.0

@export_range(0.0, 2.0, 0.01, "suffix:s")
var walk_input_suppression_after_landing_s: float = 0.32

@export var reset_cooldown_on_charge_restore: bool = true
