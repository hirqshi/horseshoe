class_name CameraVisualConfig
extends Resource

@export_category("fov")
@export_range(0.0, 60.0, 0.1, "suffix:deg") var speed_fov_bonus_deg: float = 8.0
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var speed_fov_cap_mps: float = 10.0
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var fov_response_speed: float = 10.0

@export_category("breathing")
@export_range(0.0, 0.1, 0.0001, "suffix:m") var breathing_horizontal_m: float = 0.004
@export_range(0.0, 0.1, 0.0001, "suffix:m") var breathing_vertical_m: float = 0.007
@export_range(0.0, 5.0, 0.01, "suffix:hz") var breathing_frequency_hz: float = 0.8

@export_category("movement bob")
@export_range(0.0, 0.2, 0.0001, "suffix:m") var bob_horizontal_m: float = 0.025
@export_range(0.0, 0.2, 0.0001, "suffix:m") var bob_vertical_m: float = 0.035
@export_range(0.0, 20.0, 0.01, "suffix:hz") var bob_base_frequency_hz: float = 1.2
@export_range(0.0, 20.0, 0.01, "suffix:hz") var bob_speed_frequency_hz: float = 7.0
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var bob_speed_cap_mps: float = 9.0
@export_range(0.0, 1.0, 0.01) var bob_min_speed_ratio: float = 0.08
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var bob_weight_response_speed: float = 14.0

@export_category("landing bob suppression")
@export_range(0.0, 1.0, 0.01) var landing_bob_suppression: float = 0.65
@export_range(0.0, 1.0, 0.01) var landing_run_bob_suppression_bonus: float = 0.2
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var landing_bob_restore_speed: float = 9.0
@export_range(1.0, 4.0, 0.05) var landing_run_offset_multiplier: float = 1.8

@export_category("strafe lean")
@export_range(0.0, 30.0, 0.1, "suffix:deg") var strafe_lean_deg: float = 4.0
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var strafe_lean_response_speed: float = 12.0

@export_category("wallrun lean")
@export_range(0.0, 45.0, 0.1, "suffix:deg") var wallrun_lean_deg: float = 13.0
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var wallrun_lean_response_speed: float = 15.0

@export_category("look inertia")
@export_range(0.0, 20.0, 0.01, "suffix:deg") var look_yaw_roll_deg: float = 4.0
@export_range(0.0, 20.0, 0.01, "suffix:deg") var look_pitch_offset_deg: float = 1.5
@export_range(0.0, 1.0, 0.0001) var mouse_delta_to_inertia: float = 0.018
@export_range(0.1, 50.0, 0.1, "suffix:1/s") var look_inertia_response_speed: float = 16.0

@export_category("vertical spring")
@export_range(0.0, 5.0, 0.001, "suffix:m") var landing_max_offset_m: float = 0.085
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var landing_max_speed_mps: float = 22.0
@export_range(0.0, 1000.0, 0.1) var landing_spring_strength: float = 55.0
@export_range(0.0, 100.0, 0.1) var landing_spring_damping: float = 13.0
@export_range(0.0, 10.0, 0.01, "suffix:m/s") var jump_spring_impulse_mps: float = 0.4

@export_category("dash fov")
@export_range(0.0, 30.0, 0.1, "suffix:deg") var dash_fov_peak_bonus_deg: float = 12.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var dash_fov_attack_s: float = 0.05
@export_range(0.01, 2.0, 0.01, "suffix:s") var dash_fov_release_s: float = 0.20

@export_category("slide fov")
@export_range(0.0, 30.0, 0.1, "suffix:deg") var slide_fov_bonus_deg: float = 4.0
@export_range(0.0, 30.0, 0.1, "suffix:deg") var slide_fov_pulse_bonus_deg: float = 5.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var slide_fov_attack_s: float = 0.08
@export_range(0.01, 2.0, 0.01, "suffix:s") var slide_fov_release_s: float = 0.18

@export_category("screenshake")
@export_range(0.0, 0.1, 0.0001, "suffix:m") var dash_shake_position_m: float = 0.008
@export_range(0.0, 10.0, 0.01, "suffix:deg") var dash_shake_rotation_deg: float = 1.1
@export_range(0.01, 1.0, 0.01, "suffix:s") var dash_shake_duration_s: float = 0.10
@export_range(1.0, 120.0, 1.0, "suffix:hz") var dash_shake_frequency_hz: float = 30.0

@export_range(0.0, 0.1, 0.0001, "suffix:m") var slide_shake_position_m: float = 0.003
@export_range(0.0, 10.0, 0.01, "suffix:deg") var slide_shake_rotation_deg: float = 0.35
@export_range(0.01, 1.0, 0.01, "suffix:s") var slide_shake_duration_s: float = 0.08
@export_range(1.0, 120.0, 1.0, "suffix:hz") var slide_shake_frequency_hz: float = 22.0

@export_category("grapple fov")
@export_range(
	0.0,
	30.0,
	0.1,
	"suffix:deg"
) var grapple_outgoing_fov_bonus_deg: float = 8.0

@export_range(
	0.0,
	30.0,
	0.1,
	"suffix:deg"
) var grapple_returning_fov_bonus_deg: float = 6.0

@export_range(
	0.1,
	50.0,
	0.1,
	"suffix:1/s"
) var grapple_fov_response_speed: float = 12.0

func is_valid() -> bool:
	return (
		speed_fov_cap_mps > 0.0
		and fov_response_speed > 0.0
		and bob_speed_cap_mps > 0.0
		and bob_weight_response_speed > 0.0
		and strafe_lean_response_speed > 0.0
		and look_inertia_response_speed > 0.0
		and landing_max_speed_mps > 0.0
		and landing_spring_strength > 0.0
		and landing_spring_damping >= 0.0
		and landing_bob_restore_speed > 0.0
		and landing_run_offset_multiplier >= 1.0
		and wallrun_lean_response_speed > 0.0
		and dash_fov_attack_s > 0.0
		and dash_fov_release_s > 0.0
		and slide_fov_attack_s > 0.0
		and slide_fov_release_s > 0.0
		and grapple_fov_response_speed > 0.0
	)
