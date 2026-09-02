class_name GroundingConfig
extends Resource

@export_category("timing")
@export_range(0.01, 2.0, 0.01, "suffix:s") var duration_s: float = 0.12

@export_category("movement")
@export_range(0.0, 1.0, 0.01) var horizontal_velocity_retention: float = 0.4
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var downward_speed_mps: float = 16.0

@export_category("ground boost")
@export_range(0.01, 1.0, 0.01, "suffix:s") var ground_boost_window_s: float = 0.18

@export_range(1.0, 3.0, 0.01)
var ground_boost_jump_speed_multiplier: float = 1.35

@export_category("grounding slide")
@export_range(0.01, 1.0, 0.01, "suffix:s") var grounding_slide_window_s: float = 0.2
