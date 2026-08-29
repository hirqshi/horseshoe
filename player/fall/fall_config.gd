class_name FallConfig
extends Resource

@export_category("fall detection")
@export_range(0.0, 1000.0, 0.1, "suffix:m") var damage_start_distance_m: float = 4.0
@export_range(0.1, 1000.0, 0.1, "suffix:m") var lethal_distance_m: float = 20.0

@export_range(0.0, 1000.0, 0.1, "suffix:m/s") var damage_start_impact_speed_mps: float = 8.0
@export_range(0.1, 1000.0, 0.1, "suffix:m/s") var lethal_impact_speed_mps: float = 20.0

@export_range(0.0, 100.0, 0.1) var maximum_damage: float = 100.0

@export_category("fall state")
@export_range(0.0, 10.0, 0.01, "suffix:s") var fall_ui_delay_s: float = 0.35
@export_range(0.0, 1000.0, 0.1, "suffix:m/s") var minimum_downward_speed_mps: float = 2.0
@export_range(0.0, 1.0, 0.01) var critical_progress: float = 0.75

func is_valid() -> bool:
	return (
		damage_start_distance_m >= 0.0
		and lethal_distance_m > damage_start_distance_m
		and damage_start_impact_speed_mps >= 0.0
		and lethal_impact_speed_mps > damage_start_impact_speed_mps
		and maximum_damage > 0.0
		and fall_ui_delay_s >= 0.0
		and minimum_downward_speed_mps >= 0.0
		and critical_progress > 0.0
		and critical_progress <= 1.0
	)
