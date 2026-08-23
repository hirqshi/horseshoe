class_name GroundingConfig
extends Resource

@export_category("timing")
@export var duration_s: float = 0.12

@export_category("movement")
@export_range(0.0, 1.0, 0.01) var horizontal_velocity_retention: float = 0.40
@export var downward_speed_mps: float = 16.0
