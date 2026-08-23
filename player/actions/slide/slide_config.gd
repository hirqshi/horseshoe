class_name SlideConfig
extends Resource

@export_category("start")
@export var minimum_start_speed_mps: float = 3.5
@export var minimum_slide_speed_mps: float = 6.0
@export var start_speed_bonus_mps: float = 3.0
@export var max_slide_speed_mps: float = 18.0

@export_category("movement")
@export var flat_deceleration_mps2: float = 7.5
@export var downhill_acceleration_mps2: float = 20.0
@export var steering_lerp_per_second: float = 2.5
@export var end_speed_mps: float = 2.0
