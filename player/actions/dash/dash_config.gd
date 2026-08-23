class_name DashConfig
extends Resource

@export_category("charges")
@export_range(1, 4, 1) var max_charges: int = 1

@export_category("movement")
@export var duration_s: float = 0.14
@export var minimum_speed_mps: float = 12.0
@export var speed_bonus_mps: float = 4.0
@export var max_speed_mps: float = 22.0
