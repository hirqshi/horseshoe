class_name SlideConfig
extends Resource

@export_category("start")
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var minimum_start_speed_mps: float = 3.5
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var minimum_slide_speed_mps: float = 6.0
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var start_speed_bonus_mps: float = 3.0

@export_category("movement")
@export_range(0.0, 100.0, 0.01, "suffix:m/s²") var flat_deceleration_mps2: float = 7.5
@export_range(0.0, 100.0, 0.01, "suffix:m/s²") var downhill_acceleration_mps2: float = 20.0
@export_range(0.0, 50.0, 0.01, "suffix:1/s") var steering_lerp_per_second: float = 2.5
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var end_speed_mps: float = 2.0

@export_category("landing queue")
@export_range(0.0, 2.0, 0.01, "suffix:s") var landing_queue_window_s: float = 0.25
@export_range(0.0, 10.0, 0.01, "suffix:m") var landing_queue_distance_m: float = 1.1

@export_category("ground cooldown")
@export_range(0.0, 3.0, 0.01, "suffix:s") var ground_cooldown_s: float = 0.2
