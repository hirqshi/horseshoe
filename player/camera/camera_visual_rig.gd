class_name CameraVisualRig
extends Node3D

signal bob_step()

@export var config: CameraVisualConfig
@export var body: CharacterBody3D
@export var camera: Camera3D
@export var movement_motor: MovementMotor
@export var stance: PlayerStance
@export var grapple_visual: GrappleVisual

@export_category("audio sync")
@export_range(0.25, 1.0, 0.01) var bob_step_rate_scale: float = 0.5

var _base_position: Vector3 = Vector3.ZERO
var _base_fov_deg: float = 75.0
var _current_fov_deg: float = 75.0
var _state_fov_bonus_deg: float = 0.0

var _grapple_fov_bonus_deg: float = 0.0
var _grapple_fov_target_bonus_deg: float = 0.0

var _dash_fov_elapsed_s: float = -1.0
var _dash_fov_bonus_deg: float = 0.0
var _dash_release_shake_played: bool = false

var _slide_fov_elapsed_s: float = -1.0
var _slide_fov_pulse_deg: float = 0.0
var _slide_release_shake_played: bool = false

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake_remaining_s: float = 0.0
var _shake_duration_s: float = 0.0
var _shake_frequency_hz: float = 0.0
var _shake_sample_elapsed_s: float = 0.0
var _shake_position_amplitude_m: float = 0.0
var _shake_rotation_amplitude_rad: float = 0.0
var _shake_position: Vector3 = Vector3.ZERO
var _shake_rotation_rad: Vector3 = Vector3.ZERO
var _shake_position_target: Vector3 = Vector3.ZERO
var _shake_rotation_target_rad: Vector3 = Vector3.ZERO

var _breathing_phase: float = 0.0
var _bob_phase: float = 0.0
var _bob_weight: float = 0.0
var _bob_step_phase: float = 0.0

var _is_sliding: bool = false
var _is_wallrunning: bool = false

var _wallrun_roll_rad: float = 0.0
var _wallrun_roll_target_rad: float = 0.0

var _landing_bob_suppression: float = 0.0

var _strafe_roll_rad: float = 0.0
var _look_roll_rad: float = 0.0
var _look_pitch_rad: float = 0.0
var _look_roll_target_rad: float = 0.0
var _look_pitch_target_rad: float = 0.0

var _spring_offset_y: float = 0.0
var _spring_target_y: float = 0.0
var _spring_velocity_y: float = 0.0

func _ready() -> void:
	if config == null or not config.is_valid():
		push_error("CameraVisualRig requires a valid CameraVisualConfig.")
		set_process(false)
		return

	if body == null:
		push_error("CameraVisualRig requires a player body.")
		set_process(false)
		return

	if camera == null:
		push_error("CameraVisualRig requires Camera3D.")
		set_process(false)
		return

	if movement_motor == null:
		push_error("CameraVisualRig requires MovementMotor.")
		set_process(false)
		return
		
	if stance == null:
		push_error("CameraVisualRig requires PlayerStance.")
		set_process(false)
		return
		
	if grapple_visual == null:
		push_error(
			"CameraVisualRig requires GrappleVisual."
		)

		set_process(false)
		return

	_base_position = position
	_base_fov_deg = camera.fov
	_current_fov_deg = _base_fov_deg

	movement_motor.landed.connect(_on_landed)
	movement_motor.jumped.connect(_on_jumped)
	movement_motor.wallrun_started.connect(
		_on_wallrun_started
	)
	movement_motor.wallrun_finished.connect(
		_on_wallrun_finished
	)
	movement_motor.dash_started.connect(_on_dash_started)
	movement_motor.dash_finished.connect(_on_dash_finished)
	movement_motor.impulse_applied.connect(
		_on_impulse_applied
	)
	movement_motor.slide_started.connect(_on_slide_started)
	movement_motor.slide_finished.connect(_on_slide_finished)
	
	grapple_visual.hook_outgoing_started.connect(
		_on_grapple_hook_outgoing_started
	)

	grapple_visual.hook_attached.connect(
		_on_grapple_hook_attached
	)

	grapple_visual.hook_returning_started.connect(
		_on_grapple_hook_returning_started
	)

	grapple_visual.hook_hidden.connect(
		_on_grapple_hook_hidden
	)


func _process(delta: float) -> void:
	var horizontal_speed_mps: float = Vector2(
		body.velocity.x,
		body.velocity.z
	).length()

	_update_fov_pulses(delta)
	_update_shake(delta)
	_update_fov(delta, horizontal_speed_mps)
	_update_bob(delta, horizontal_speed_mps)
	_update_strafe_lean(delta)
	_update_wallrun_lean(delta)
	_update_look_inertia(delta)
	_update_vertical_spring(delta)
	_apply_transform()

func register_look_delta(mouse_delta: Vector2) -> void:
	_look_roll_target_rad = clampf(
		-mouse_delta.x * config.mouse_delta_to_inertia,
		-deg_to_rad(config.look_yaw_roll_deg),
		deg_to_rad(config.look_yaw_roll_deg)
	)

	_look_pitch_target_rad = clampf(
		mouse_delta.y * config.mouse_delta_to_inertia,
		-deg_to_rad(config.look_pitch_offset_deg),
		deg_to_rad(config.look_pitch_offset_deg)
	)

func set_state_fov_bonus(fov_bonus_deg: float) -> void:
	_state_fov_bonus_deg = fov_bonus_deg

func _on_landed(impact_speed_mps: float) -> void:
	var impact_ratio: float = clampf(
		impact_speed_mps / config.landing_max_speed_mps,
		0.0,
		1.0
	)

	if impact_ratio <= 0.0:
		return

	var horizontal_speed_mps: float = Vector2(
		body.velocity.x,
		body.velocity.z
	).length()

	var run_ratio: float = clampf(
		horizontal_speed_mps / config.bob_speed_cap_mps,
		0.0,
		1.0
	)

	var run_offset_multiplier: float = lerpf(
		1.0,
		config.landing_run_offset_multiplier,
		run_ratio
	)

	var landing_offset_m: float = (
		config.landing_max_offset_m
		* impact_ratio
		* run_offset_multiplier
	)

	_spring_target_y = minf(
		_spring_target_y - landing_offset_m,
		-config.landing_max_offset_m
	)

	var suppression: float = (
		config.landing_bob_suppression
		+ config.landing_run_bob_suppression_bonus
		* run_ratio
	)

	_landing_bob_suppression = maxf(
		_landing_bob_suppression,
		clampf(suppression * impact_ratio, 0.0, 0.95)
	)

func _on_jumped() -> void:
	_spring_velocity_y += config.jump_spring_impulse_mps

func _update_fov(
	delta: float,
	horizontal_speed_mps: float
) -> void:
	var speed_ratio: float = clampf(
		horizontal_speed_mps / config.speed_fov_cap_mps,
		0.0,
		1.0
	)

	var slide_state_bonus_deg: float = 0.0

	if _is_sliding:
		slide_state_bonus_deg = config.slide_fov_bonus_deg
		
	_grapple_fov_bonus_deg = lerpf(
		_grapple_fov_bonus_deg,
		_grapple_fov_target_bonus_deg,
		_get_smoothing_weight(
			config.grapple_fov_response_speed,
			delta
		)
	)
	
	var target_fov_deg: float = (
		_base_fov_deg
		+ config.speed_fov_bonus_deg * speed_ratio
		+ _state_fov_bonus_deg
		+ slide_state_bonus_deg
		+ _dash_fov_bonus_deg
		+ _slide_fov_pulse_deg
		+ _grapple_fov_bonus_deg
	)

	_current_fov_deg = lerpf(
		_current_fov_deg,
		target_fov_deg,
		_get_smoothing_weight(
			config.fov_response_speed,
			delta
		)
	)

	camera.fov = _current_fov_deg

func _update_bob(
	delta: float,
	horizontal_speed_mps: float
) -> void:
	_breathing_phase += (
		TAU
		* config.breathing_frequency_hz
		* delta
	)

	var speed_ratio: float = clampf(
		horizontal_speed_mps / config.bob_speed_cap_mps,
		0.0,
		1.0
	)

	var can_bob: bool = (
		(
			body.is_on_floor()
			and not _is_sliding
		)
		or _is_wallrunning
	)

	var can_emit_bob_step: bool = (
		can_bob
		and speed_ratio >= config.bob_min_speed_ratio
	)

	if can_emit_bob_step:
		var bob_frequency_hz: float = (
			config.bob_base_frequency_hz
			+ config.bob_speed_frequency_hz
			* speed_ratio
		)

		var bob_phase_delta: float = (
			TAU
			* bob_frequency_hz
			* delta
		)

		_bob_phase += bob_phase_delta

		_bob_step_phase += (
			bob_phase_delta
			* bob_step_rate_scale
		)

		if _bob_step_phase >= PI:
			_bob_step_phase = fposmod(
				_bob_step_phase,
				PI
			)

			bob_step.emit()

	var target_bob_weight: float = 0.0

	if can_bob:
		target_bob_weight = smoothstep(
			config.bob_min_speed_ratio,
			1.0,
			speed_ratio
		)

	_bob_weight = lerpf(
		_bob_weight,
		target_bob_weight,
		_get_smoothing_weight(
			config.bob_weight_response_speed,
			delta
		)
	)

func _update_strafe_lean(delta: float) -> void:
	var move_input: Vector2 = movement_motor.get_move_input()

	var target_roll_rad: float = deg_to_rad(
		-config.strafe_lean_deg * move_input.x
	)

	_strafe_roll_rad = lerpf(
		_strafe_roll_rad,
		target_roll_rad,
		_get_smoothing_weight(
			config.strafe_lean_response_speed,
			delta
		)
	)

func _update_look_inertia(delta: float) -> void:
	var response_weight: float = _get_smoothing_weight(
		config.look_inertia_response_speed,
		delta
	)

	_look_roll_rad = lerpf(
		_look_roll_rad,
		_look_roll_target_rad,
		response_weight
	)

	_look_pitch_rad = lerpf(
		_look_pitch_rad,
		_look_pitch_target_rad,
		response_weight
	)

	_look_roll_target_rad = lerpf(
		_look_roll_target_rad,
		0.0,
		response_weight
	)

	_look_pitch_target_rad = lerpf(
		_look_pitch_target_rad,
		0.0,
		response_weight
	)

func _update_vertical_spring(delta: float) -> void:
	_spring_target_y = lerpf(
		_spring_target_y,
		0.0,
		_get_smoothing_weight(20.0, delta)
	)

	var acceleration_y: float = (
		(_spring_target_y - _spring_offset_y)
		* config.landing_spring_strength
		- _spring_velocity_y * config.landing_spring_damping
	)

	_spring_velocity_y += acceleration_y * delta
	_spring_offset_y += _spring_velocity_y * delta
	_landing_bob_suppression = lerpf(
		_landing_bob_suppression,
		0.0,
		_get_smoothing_weight(
			config.landing_bob_restore_speed,
			delta
		)
	)

func _apply_transform() -> void:
	var breathing_offset: Vector3 = Vector3(
		cos(_breathing_phase)
		* config.breathing_horizontal_m,
		sin(_breathing_phase)
		* config.breathing_vertical_m,
		0.0
	)

	var bob_multiplier: float = (
		1.0 - _landing_bob_suppression
	)

	var bob_offset: Vector3 = Vector3(
		cos(_bob_phase)
		* config.bob_horizontal_m
		* _bob_weight
		* bob_multiplier,
		absf(sin(_bob_phase))
		* config.bob_vertical_m
		* _bob_weight
		* bob_multiplier,
		0.0
	)

	position = (
		_base_position
		+ breathing_offset
		+ bob_offset
		+ Vector3.UP * _spring_offset_y
		+ _shake_position
	)

	rotation = Vector3(
		_look_pitch_rad,
		0.0,
		_strafe_roll_rad
		+ _wallrun_roll_rad
		+ _look_roll_rad
	) + _shake_rotation_rad

func _get_smoothing_weight(
	response_speed: float,
	delta: float
) -> float:
	return 1.0 - exp(-response_speed * delta)

func set_is_sliding(value: bool) -> void:
	_is_sliding = value

func _on_wallrun_started(wall_normal: Vector3) -> void:
	_is_wallrunning = true

	var player_right: Vector3 = body.global_basis.x
	player_right.y = 0.0

	if player_right.length_squared() <= 0.0001:
		_wallrun_roll_target_rad = 0.0
		return

	player_right = player_right.normalized()

	var wall_side: float = wall_normal.dot(player_right)

	_wallrun_roll_target_rad = (
		-deg_to_rad(config.wallrun_lean_deg)
		* wall_side
	)

func _on_wallrun_finished() -> void:
	_is_wallrunning = false
	_wallrun_roll_target_rad = 0.0

func _update_wallrun_lean(delta: float) -> void:
	_wallrun_roll_rad = lerpf(
		_wallrun_roll_rad,
		_wallrun_roll_target_rad,
		_get_smoothing_weight(
			config.wallrun_lean_response_speed,
			delta
		)
	)

func _on_impulse_applied(
	_impulse_speed_mps: float
) -> void:
	_on_dash_started()

func _on_dash_started() -> void:
	_dash_fov_elapsed_s = 0.0
	_dash_fov_bonus_deg = 0.0
	_dash_release_shake_played = false

func _on_dash_finished() -> void:
	pass

func _on_slide_started() -> void:
	_is_sliding = true
	_bob_weight = 0.0

	stance.set_is_sliding(true)

	_slide_fov_elapsed_s = 0.0
	_slide_fov_pulse_deg = 0.0
	_slide_release_shake_played = false

	play_shake(
		config.slide_shake_position_m,
		config.slide_shake_rotation_deg,
		config.slide_shake_duration_s,
		config.slide_shake_frequency_hz
	)

func _on_slide_finished() -> void:
	_is_sliding = false
	stance.set_is_sliding(false)

func _update_fov_pulses(delta: float) -> void:
	_update_dash_fov_pulse(delta)
	_update_slide_fov_pulse(delta)

func _update_dash_fov_pulse(delta: float) -> void:
	if _dash_fov_elapsed_s < 0.0:
		_dash_fov_bonus_deg = 0.0
		return

	_dash_fov_elapsed_s += delta

	var attack_s: float = config.dash_fov_attack_s
	var release_s: float = config.dash_fov_release_s
	var total_s: float = attack_s + release_s

	if _dash_fov_elapsed_s <= attack_s:
		var attack_ratio: float = clampf(
			_dash_fov_elapsed_s / attack_s,
			0.0,
			1.0
		)

		_dash_fov_bonus_deg = lerpf(
			0.0,
			config.dash_fov_peak_bonus_deg,
			smoothstep(0.0, 1.0, attack_ratio)
		)
		return

	if not _dash_release_shake_played:
		_dash_release_shake_played = true

		play_shake(
			config.dash_shake_position_m,
			config.dash_shake_rotation_deg,
			config.dash_shake_duration_s,
			config.dash_shake_frequency_hz
		)

	var release_ratio: float = clampf(
		(_dash_fov_elapsed_s - attack_s) / release_s,
		0.0,
		1.0
	)

	_dash_fov_bonus_deg = lerpf(
		config.dash_fov_peak_bonus_deg,
		0.0,
		smoothstep(0.0, 1.0, release_ratio)
	)

	if _dash_fov_elapsed_s >= total_s:
		_dash_fov_elapsed_s = -1.0
		_dash_fov_bonus_deg = 0.0

func _update_slide_fov_pulse(delta: float) -> void:
	if _slide_fov_elapsed_s < 0.0:
		_slide_fov_pulse_deg = 0.0
		return

	_slide_fov_elapsed_s += delta

	var attack_s: float = config.slide_fov_attack_s
	var release_s: float = config.slide_fov_release_s
	var total_s: float = attack_s + release_s

	if _slide_fov_elapsed_s <= attack_s:
		var attack_ratio: float = clampf(
			_slide_fov_elapsed_s / attack_s,
			0.0,
			1.0
		)

		_slide_fov_pulse_deg = lerpf(
			0.0,
			config.slide_fov_pulse_bonus_deg,
			smoothstep(0.0, 1.0, attack_ratio)
		)
		return

	var release_ratio: float = clampf(
		(_slide_fov_elapsed_s - attack_s) / release_s,
		0.0,
		1.0
	)

	_slide_fov_pulse_deg = lerpf(
		config.slide_fov_pulse_bonus_deg,
		0.0,
		smoothstep(0.0, 1.0, release_ratio)
	)

	if _slide_fov_elapsed_s >= total_s:
		_slide_fov_elapsed_s = -1.0
		_slide_fov_pulse_deg = 0.0

func play_shake(
	position_amplitude_m: float,
	rotation_amplitude_deg: float,
	duration_s: float,
	frequency_hz: float
) -> void:
	if duration_s <= 0.0:
		return

	_shake_position_amplitude_m = maxf(
		_shake_position_amplitude_m,
		position_amplitude_m
	)

	_shake_rotation_amplitude_rad = maxf(
		_shake_rotation_amplitude_rad,
		deg_to_rad(rotation_amplitude_deg)
	)

	_shake_duration_s = maxf(
		_shake_duration_s,
		duration_s
	)

	_shake_remaining_s = maxf(
		_shake_remaining_s,
		duration_s
	)

	_shake_frequency_hz = maxf(
		_shake_frequency_hz,
		frequency_hz
	)

func _update_shake(delta: float) -> void:
	if _shake_remaining_s <= 0.0:
		_shake_position = Vector3.ZERO
		_shake_rotation_rad = Vector3.ZERO
		return

	_shake_remaining_s = maxf(
		_shake_remaining_s - delta,
		0.0
	)

	_shake_sample_elapsed_s += delta

	var sample_interval_s: float = 1.0 / maxf(
		_shake_frequency_hz,
		1.0
	)

	if _shake_sample_elapsed_s >= sample_interval_s:
		_shake_sample_elapsed_s = 0.0

		_shake_position_target = Vector3(
			_random.randf_range(-1.0, 1.0)
			* _shake_position_amplitude_m,
			_random.randf_range(-1.0, 1.0)
			* _shake_position_amplitude_m,
			0.0
		)

		_shake_rotation_target_rad = Vector3(
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad,
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad,
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad
		)

	var fade_ratio: float = (
		_shake_remaining_s
		/ maxf(_shake_duration_s, 0.001)
	)

	var response_weight: float = _get_smoothing_weight(
		maxf(_shake_frequency_hz, 1.0) * 2.5,
		delta
	)

	_shake_position = _shake_position.lerp(
		_shake_position_target * fade_ratio,
		response_weight
	)

	_shake_rotation_rad = _shake_rotation_rad.lerp(
		_shake_rotation_target_rad * fade_ratio,
		response_weight
	)

	if _shake_remaining_s <= 0.0:
		_shake_position_amplitude_m = 0.0
		_shake_rotation_amplitude_rad = 0.0
		_shake_duration_s = 0.0
		_shake_sample_elapsed_s = 0.0


func _on_grapple_hook_outgoing_started() -> void:
	_grapple_fov_target_bonus_deg = (
		config.grapple_outgoing_fov_bonus_deg
	)


func _on_grapple_hook_attached() -> void:
	_grapple_fov_target_bonus_deg = 0.0


func _on_grapple_hook_returning_started() -> void:
	_grapple_fov_target_bonus_deg = (
		config.grapple_returning_fov_bonus_deg
	)


func _on_grapple_hook_hidden() -> void:
	_grapple_fov_target_bonus_deg = 0.0
