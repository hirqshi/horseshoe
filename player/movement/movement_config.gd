class_name MovementConfig
extends Resource

@export_category("ground")
@export var run_speed_forward_mps: float = 10.0
@export var run_speed_side_mps: float = 8.5
@export var run_speed_back_mps: float = 6.5
@export var walk_speed_multiplier: float = 0.35
@export var ground_acceleration_mps2: float = 44.0
@export var ground_deceleration_mps2: float = 36.0

@export_category("air")
@export var air_acceleration_mps2: float = 14.0
@export var air_deceleration_mps2: float = 2.5
@export_range(0.0, 1.0, 0.01) var air_control: float = 0.65

@export_category("vertical")
@export var gravity_mps2: float = 28.0
@export var terminal_fall_speed_mps: float = 50.0
@export var jump_speed_mps: float = 9.5
@export var coyote_time_s: float = 0.10
@export var jump_buffer_s: float = 0.12

@export_category("collision")
@export_range(1.0, 89.0, 1.0) var max_floor_angle_deg: float = 50.0
