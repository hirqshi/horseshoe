class_name MovementAudio
extends Node

@export_category("audio players")
@export var footstep_player: AudioStreamPlayer
@export var crouch_footstep_player: AudioStreamPlayer

@export var slide_start_player: AudioStreamPlayer
@export var slide_loop_player: AudioStreamPlayer
@export var slide_end_player: AudioStreamPlayer

@export var dash_player: AudioStreamPlayer
@export var dash_fail_player: AudioStreamPlayer

@export var ground_jump_player: AudioStreamPlayer
@export var wall_jump_player: AudioStreamPlayer
@export var wall_jump_fail_player: AudioStreamPlayer

@export var light_landing_player: AudioStreamPlayer
@export var heavy_landing_player: AudioStreamPlayer

@export var wind_player: AudioStreamPlayer

@export_category("glide audio players")
@export var glide_deploy_player: AudioStreamPlayer
@export var glide_loop_player: AudioStreamPlayer
@export var glide_close_player: AudioStreamPlayer
@export var glide_fail_player: AudioStreamPlayer

@export_category("grapple audio players")
@export var grapple_fire_player: AudioStreamPlayer
@export var grapple_loop_player: AudioStreamPlayer
@export var grapple_return_player: AudioStreamPlayer
@export var grapple_fail_player: AudioStreamPlayer

@export_category("polyphony")
@export_range(1, 16, 1) var footstep_max_polyphony: int = 3
@export_range(1, 16, 1) var one_shot_max_polyphony: int = 5
@export_range(1, 16, 1) var fail_sound_max_polyphony: int = 2

@export_category("footstep streams")
@export var walk_run_streams: Array[AudioStream] = []
@export var crouch_streams: Array[AudioStream] = []

@export_category("slide streams")
@export var slide_start_streams: Array[AudioStream] = []
@export var slide_loop_stream: AudioStream
@export var slide_end_streams: Array[AudioStream] = []

@export_category("action streams")
@export var dash_streams: Array[AudioStream] = []
@export var dash_fail_streams: Array[AudioStream] = []

@export var ground_jump_streams: Array[AudioStream] = []
@export var wall_jump_streams: Array[AudioStream] = []
@export var wall_jump_fail_streams: Array[AudioStream] = []

@export_category("landing streams")
@export var light_landing_streams: Array[AudioStream] = []
@export var heavy_landing_streams: Array[AudioStream] = []

@export_category("wind")
@export var wind_stream: AudioStream

@export_category("glide streams")
@export var glide_deploy_streams: Array[AudioStream] = []
@export var glide_loop_stream: AudioStream
@export var glide_close_streams: Array[AudioStream] = []
@export var glide_fail_streams: Array[AudioStream] = []

@export_category("grapple streams")
@export var grapple_fire_streams: Array[AudioStream] = []
@export var grapple_loop_stream: AudioStream
@export var grapple_return_streams: Array[AudioStream] = []
@export var grapple_fail_streams: Array[AudioStream] = []

@export_category("footsteps")
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var footstep_min_speed_mps: float = 1.0
@export_range(0.01, 3.0, 0.01, "suffix:s") var walk_step_interval_s: float = 0.46
@export_range(0.01, 3.0, 0.01, "suffix:s") var run_step_interval_s: float = 0.28
@export_range(0.01, 3.0, 0.01, "suffix:s") var crouch_step_interval_s: float = 0.52
@export_range(0.01, 3.0, 0.01, "suffix:s") var wallrun_step_interval_s: float = 0.23

@export_category("speed pitch")
@export_range(0.1, 100.0, 0.01, "suffix:m/s") var speed_pitch_start_mps: float = 4.0
@export_range(0.1, 100.0, 0.01, "suffix:m/s") var speed_pitch_cap_mps: float = 35.0
@export_range(0.1, 3.0, 0.01) var speed_pitch_min: float = 0.94
@export_range(0.1, 3.0, 0.01) var speed_pitch_max: float = 1.16

@export_category("random pitch")
@export_range(0.1, 3.0, 0.01) var movement_pitch_min: float = 0.94
@export_range(0.1, 3.0, 0.01) var movement_pitch_max: float = 1.06

@export_range(0.1, 3.0, 0.01) var action_pitch_min: float = 0.96
@export_range(0.1, 3.0, 0.01) var action_pitch_max: float = 1.04

@export_category("landing")
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var light_landing_threshold_mps: float = 3.0
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var heavy_landing_threshold_mps: float = 10.0

@export_category("slide loop")
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var slide_loop_min_speed_mps: float = 3.0
@export_range(0.1, 100.0, 0.01, "suffix:m/s") var slide_loop_speed_cap_mps: float = 30.0
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var slide_loop_silent_volume_db: float = -70.0
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var slide_loop_max_volume_db: float = -4.0
@export_range(0.1, 3.0, 0.01) var slide_loop_pitch_min: float = 0.92
@export_range(0.1, 3.0, 0.01) var slide_loop_pitch_max: float = 1.16
@export_range(0.1, 100.0, 0.1, "suffix:1/s") var slide_loop_follow_speed: float = 14.0

@export_category("wind loop")
@export_range(0.0, 100.0, 0.01, "suffix:m/s") var wind_start_speed_mps: float = 7.0
@export_range(0.1, 100.0, 0.01, "suffix:m/s") var wind_speed_cap_mps: float = 45.0
@export_range(-100.0, 6.0, 0.1, "suffix:dB") var wind_silent_volume_db: float = -80.0
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var wind_max_volume_db: float = -3.0
@export_range(0.1, 3.0, 0.01) var wind_pitch_min: float = 0.85
@export_range(0.1, 3.0, 0.01) var wind_pitch_max: float = 1.18
@export_range(0.1, 100.0, 0.1, "suffix:1/s") var wind_follow_speed: float = 7.0

@export_category("glide loop")
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var glide_loop_silent_volume_db: float = -70.0
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var glide_loop_max_volume_db: float = -6.0
@export_range(0.05, 3.0, 0.01, "suffix:s") var glide_loop_fade_in_s: float = 0.35
@export_range(0.05, 3.0, 0.01, "suffix:s") var glide_loop_fade_out_s: float = 0.25

@export_category("grapple loop")
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var grapple_loop_silent_volume_db: float = -70.0
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var grapple_loop_max_volume_db: float = -5.0
@export_range(0.05, 3.0, 0.01, "suffix:s") var grapple_loop_fade_in_s: float = 0.15
@export_range(0.05, 3.0, 0.01, "suffix:s") var grapple_loop_fade_out_s: float = 0.2

@onready var _player: Player = get_parent() as Player

@onready var _movement_motor: MovementMotor = (
	get_node_or_null(
		"../MovementMotor"
	) as MovementMotor
)
@export var camera_visual_rig: CameraVisualRig

@export_category("bob synced footsteps")
@export var uses_bob_synced_footsteps: bool = false

var _step_timer_s: float = 0.0

var _is_sliding: bool = false
var _is_wallrunning: bool = false

var _is_gliding: bool = false
var _glide_loop_target_db: float = -80.0

var _is_grappling: bool = false
var _grapple_loop_target_db: float = -80.0

var _skip_next_ground_jump_sound: bool = false

var _grapple_action: GrappleAction
var _grapple_visual: GrappleVisual


func _ready() -> void:
	if _player == null:
		push_error(
			"MovementAudio must be a child of Player."
		)
		set_process(false)
		return

	if _movement_motor == null:
		push_error(
			"MovementAudio requires Player/MovementMotor."
		)
		set_process(false)
		return

	_validate_players()
	_configure_audio_players()
	_connect_movement_signals()
	_setup_loop_players()
	_connect_camera_visual_signals()
	call_deferred("_connect_grapple_signals")


func _connect_grapple_signals() -> void:
	if _movement_motor.has_method("get_grapple_action"):
		_grapple_action = _movement_motor.get_grapple_action()

	if _grapple_action != null:
		_grapple_action.hook_fired.connect(_on_hook_fired)
		_grapple_action.hook_finished.connect(_on_hook_finished)
		_grapple_action.grapple_failed.connect(_on_grapple_failed)
	else:
		push_warning(
			"MovementAudio could not find GrappleAction; "
			+ "grapple sounds will not play."
		)

	_grapple_visual = get_tree().get_first_node_in_group(
		"grapple_visual"
	) as GrappleVisual

	if _grapple_visual != null:
		_grapple_visual.hook_hidden.connect(_on_hook_returned)
	else:
		push_warning(
			"MovementAudio could not find GrappleVisual "
			+ "(missing group 'grapple_visual'); "
			+ "grapple return sound will not play."
		)


func _process(delta: float) -> void:
	if _player == null:
		return

	var horizontal_speed_mps: float = _get_horizontal_speed_mps()
	var full_speed_mps: float = _get_full_speed_mps()

	_update_footsteps(
		delta,
		horizontal_speed_mps
	)

	_update_slide_loop(
		delta,
		horizontal_speed_mps
	)

	_update_wind_loop(
		delta,
		full_speed_mps
	)

	_update_glide_loop(delta)

	_update_grapple_loop(delta)


func _connect_movement_signals() -> void:
	_movement_motor.landed.connect(
		_on_landed
	)

	_movement_motor.jumped.connect(
		_on_jumped
	)

	_movement_motor.wall_jumped.connect(
		_on_wall_jumped
	)

	_movement_motor.dash_started.connect(
		_on_dash_started
	)

	_movement_motor.dash_failed.connect(
		_on_dash_failed
	)

	_movement_motor.slide_started.connect(
		_on_slide_started
	)

	_movement_motor.slide_finished.connect(
		_on_slide_finished
	)

	_movement_motor.wallrun_started.connect(
		_on_wallrun_started
	)

	_movement_motor.wallrun_finished.connect(
		_on_wallrun_finished
	)

	_movement_motor.wall_jump_failed.connect(
		_on_wall_jump_failed
	)

	_movement_motor.glide_started.connect(
		_on_glide_started
	)

	_movement_motor.glide_finished.connect(
		_on_glide_finished
	)

	_movement_motor.glide_failed.connect(
		_on_glide_failed
	)


func _setup_loop_players() -> void:
	if slide_loop_player != null:
		slide_loop_player.volume_db = (
			slide_loop_silent_volume_db
		)

	if wind_player != null:
		wind_player.volume_db = (
			wind_silent_volume_db
		)

		if wind_player.stream != null:
			wind_player.play()

	if glide_loop_player != null:
		glide_loop_player.volume_db = glide_loop_silent_volume_db
		_glide_loop_target_db = glide_loop_silent_volume_db

	if grapple_loop_player != null:
		grapple_loop_player.volume_db = grapple_loop_silent_volume_db
		_grapple_loop_target_db = grapple_loop_silent_volume_db


func _update_footsteps(
	delta: float,
	horizontal_speed_mps: float
) -> void:
	if uses_bob_synced_footsteps:
		_step_timer_s = 0.0
		return

	if _is_sliding:
		_step_timer_s = 0.0
		return

	var is_on_floor: bool = _player.is_on_floor()

	var can_play_steps: bool = (
		horizontal_speed_mps >= footstep_min_speed_mps
		and (
			is_on_floor
			or _is_wallrunning
		)
	)

	if not can_play_steps:
		_step_timer_s = 0.0
		return

	_step_timer_s -= delta

	if _step_timer_s > 0.0:
		return

	var is_crouching: bool = (
		not _is_wallrunning
		and _movement_motor.stance.is_crouching()
	)

	var interval_s: float = _get_step_interval_s(
		horizontal_speed_mps,
		is_crouching
	)

	_step_timer_s = interval_s

	if is_crouching:
		_play_random_stream(
			crouch_footstep_player,
			crouch_streams,
			false,
			movement_pitch_min,
			movement_pitch_max
		)
		return

	_play_random_stream(
		footstep_player,
		walk_run_streams,
		true,
		movement_pitch_min,
		movement_pitch_max
	)


func _update_slide_loop(
	delta: float,
	horizontal_speed_mps: float
) -> void:
	if slide_loop_player == null:
		return

	var speed_progress: float = _get_speed_progress(
		horizontal_speed_mps,
		slide_loop_min_speed_mps,
		slide_loop_speed_cap_mps
	)

	var target_volume_db: float = (
		slide_loop_silent_volume_db
	)

	if _is_sliding:
		target_volume_db = lerpf(
			slide_loop_silent_volume_db,
			slide_loop_max_volume_db,
			speed_progress
		)

		if not slide_loop_player.playing \
		and slide_loop_player.stream != null:
			slide_loop_player.play()

	var follow_weight: float = (
		1.0 - exp(
			-slide_loop_follow_speed * delta
		)
	)

	slide_loop_player.volume_db = lerpf(
		slide_loop_player.volume_db,
		target_volume_db,
		follow_weight
	)

	slide_loop_player.pitch_scale = lerpf(
		slide_loop_pitch_min,
		slide_loop_pitch_max,
		speed_progress
	)

	if not _is_sliding \
	and slide_loop_player.playing \
	and slide_loop_player.volume_db <= (
		slide_loop_silent_volume_db + 1.0
	):
		slide_loop_player.stop()


func _update_wind_loop(
	delta: float,
	full_speed_mps: float
) -> void:
	if wind_player == null:
		return

	if wind_player.stream == null:
		return

	if not wind_player.playing:
		wind_player.play()

	var speed_progress: float = _get_speed_progress(
		full_speed_mps,
		wind_start_speed_mps,
		wind_speed_cap_mps
	)

	var target_volume_db: float = lerpf(
		wind_silent_volume_db,
		wind_max_volume_db,
		speed_progress
	)

	var follow_weight: float = (
		1.0 - exp(
			-wind_follow_speed * delta
		)
	)

	wind_player.volume_db = lerpf(
		wind_player.volume_db,
		target_volume_db,
		follow_weight
	)

	wind_player.pitch_scale = lerpf(
		wind_pitch_min,
		wind_pitch_max,
		speed_progress
	)


func _update_glide_loop(delta: float) -> void:
	if glide_loop_player == null:
		return

	if _is_gliding and glide_loop_player.stream == null:
		glide_loop_player.stream = glide_loop_stream

	if _is_gliding and not glide_loop_player.playing \
	and glide_loop_player.stream != null:
		glide_loop_player.play()

	var fade_speed: float = (
		1.0 / glide_loop_fade_in_s
		if _is_gliding
		else 1.0 / glide_loop_fade_out_s
	)

	var follow_weight: float = 1.0 - exp(-fade_speed * delta)

	glide_loop_player.volume_db = lerpf(
		glide_loop_player.volume_db,
		_glide_loop_target_db,
		follow_weight
	)

	if not _is_gliding \
	and glide_loop_player.playing \
	and glide_loop_player.volume_db <= (
		glide_loop_silent_volume_db + 1.0
	):
		glide_loop_player.stop()


func _update_grapple_loop(delta: float) -> void:
	if grapple_loop_player == null:
		return

	if _is_grappling and grapple_loop_player.stream == null:
		grapple_loop_player.stream = grapple_loop_stream

	if _is_grappling and not grapple_loop_player.playing \
	and grapple_loop_player.stream != null:
		grapple_loop_player.play()

	var fade_speed: float = (
		1.0 / grapple_loop_fade_in_s
		if _is_grappling
		else 1.0 / grapple_loop_fade_out_s
	)

	var follow_weight: float = 1.0 - exp(-fade_speed * delta)

	grapple_loop_player.volume_db = lerpf(
		grapple_loop_player.volume_db,
		_grapple_loop_target_db,
		follow_weight
	)

	if not _is_grappling \
	and grapple_loop_player.playing \
	and grapple_loop_player.volume_db <= (
		grapple_loop_silent_volume_db + 1.0
	):
		grapple_loop_player.stop()


func _on_landed(
	impact_speed_mps: float
) -> void:
	if impact_speed_mps < light_landing_threshold_mps:
		return

	if impact_speed_mps >= heavy_landing_threshold_mps:
		_play_random_stream(
			heavy_landing_player,
			heavy_landing_streams,
			false,
			action_pitch_min,
			action_pitch_max
		)
		return

	_play_random_stream(
		light_landing_player,
		light_landing_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_jumped() -> void:
	if _skip_next_ground_jump_sound:
		_skip_next_ground_jump_sound = false
		return

	_play_random_stream(
		ground_jump_player,
		ground_jump_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_wall_jumped() -> void:
	_skip_next_ground_jump_sound = true

	_play_random_stream(
		wall_jump_player,
		wall_jump_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_dash_started() -> void:
	_play_random_stream(
		dash_player,
		dash_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_dash_failed() -> void:
	_play_random_stream(
		dash_fail_player,
		dash_fail_streams,
		false,
		1.0,
		1.0
	)


func _on_wall_jump_failed() -> void:
	_play_random_stream(
		wall_jump_fail_player,
		wall_jump_fail_streams,
		false,
		1.0,
		1.0
	)


func _on_slide_started() -> void:
	_is_sliding = true

	_play_random_stream(
		slide_start_player,
		slide_start_streams,
		true,
		movement_pitch_min,
		movement_pitch_max
	)


func _on_slide_finished() -> void:
	_is_sliding = false

	_play_random_stream(
		slide_end_player,
		slide_end_streams,
		true,
		movement_pitch_min,
		movement_pitch_max
	)


func _on_wallrun_started(
	_wall_normal: Vector3
) -> void:
	_is_wallrunning = true


func _on_wallrun_finished() -> void:
	_is_wallrunning = false


func _on_glide_started() -> void:
	_is_gliding = true
	_glide_loop_target_db = glide_loop_max_volume_db

	_play_random_stream(
		glide_deploy_player,
		glide_deploy_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_glide_finished() -> void:
	_is_gliding = false
	_glide_loop_target_db = glide_loop_silent_volume_db

	_play_random_stream(
		glide_close_player,
		glide_close_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_glide_failed() -> void:
	_play_random_stream(
		glide_fail_player,
		glide_fail_streams,
		false,
		1.0,
		1.0
	)


func _on_hook_fired(
	_target_position: Vector3,
	_travel_duration_s: float
) -> void:
	_is_grappling = true
	_grapple_loop_target_db = grapple_loop_max_volume_db

	_play_random_stream(
		grapple_fire_player,
		grapple_fire_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_hook_finished(
	_was_cancelled: bool
) -> void:
	_is_grappling = false
	_grapple_loop_target_db = grapple_loop_silent_volume_db


func _on_hook_returned() -> void:
	_play_random_stream(
		grapple_return_player,
		grapple_return_streams,
		false,
		action_pitch_min,
		action_pitch_max
	)


func _on_grapple_failed() -> void:
	_play_random_stream(
		grapple_fail_player,
		grapple_fail_streams,
		false,
		1.0,
		1.0
	)


func _get_horizontal_speed_mps() -> float:
	return Vector2(
		_player.velocity.x,
		_player.velocity.z
	).length()


func _get_full_speed_mps() -> float:
	return _player.velocity.length()


func _get_step_interval_s(
	horizontal_speed_mps: float,
	is_crouching: bool
) -> float:
	if _is_wallrunning:
		return wallrun_step_interval_s

	if is_crouching:
		return crouch_step_interval_s

	var speed_progress: float = _get_speed_progress(
		horizontal_speed_mps,
		footstep_min_speed_mps,
		speed_pitch_cap_mps
	)

	return lerpf(
		walk_step_interval_s,
		run_step_interval_s,
		speed_progress
	)


func _get_speed_pitch(
	horizontal_speed_mps: float
) -> float:
	var speed_progress: float = _get_speed_progress(
		horizontal_speed_mps,
		speed_pitch_start_mps,
		speed_pitch_cap_mps
	)

	return lerpf(
		speed_pitch_min,
		speed_pitch_max,
		speed_progress
	)


func _get_speed_progress(
	speed_mps: float,
	start_speed_mps: float,
	cap_speed_mps: float
) -> float:
	return clampf(
		(
			speed_mps
			- start_speed_mps
		)
		/ maxf(
			cap_speed_mps
			- start_speed_mps,
			0.001
		),
		0.0,
		1.0
	)


func _play_random_stream(
	audio_player: AudioStreamPlayer,
	streams: Array[AudioStream],
	uses_speed_pitch: bool,
	random_pitch_min: float,
	random_pitch_max: float
) -> void:
	if audio_player == null:
		return

	if streams.is_empty():
		return

	var stream_index: int = randi_range(
		0,
		streams.size() - 1
	)

	var selected_stream: AudioStream = (
		streams[stream_index]
	)

	var pitch_scale: float = randf_range(
		random_pitch_min,
		random_pitch_max
	)

	if uses_speed_pitch:
		pitch_scale *= _get_speed_pitch(
			_get_horizontal_speed_mps()
		)

	audio_player.stream = selected_stream
	audio_player.pitch_scale = pitch_scale
	audio_player.play()


func _validate_players() -> void:
	if footstep_player == null:
		push_warning(
			"MovementAudio has no FootstepPlayer."
		)

	if crouch_footstep_player == null:
		push_warning(
			"MovementAudio has no CrouchFootstepPlayer."
		)

	if slide_start_player == null:
		push_warning(
			"MovementAudio has no SlideStartPlayer."
		)

	if slide_loop_player == null:
		push_warning(
			"MovementAudio has no SlideLoopPlayer."
		)

	if slide_end_player == null:
		push_warning(
			"MovementAudio has no SlideEndPlayer."
		)

	if dash_player == null:
		push_warning(
			"MovementAudio has no DashPlayer."
		)

	if dash_fail_player == null:
		push_warning(
			"MovementAudio has no DashFailPlayer."
		)

	if ground_jump_player == null:
		push_warning(
			"MovementAudio has no GroundJumpPlayer."
		)

	if wall_jump_player == null:
		push_warning(
			"MovementAudio has no WallJumpPlayer."
		)

	if wall_jump_fail_player == null:
		push_warning(
			"MovementAudio has no WallJumpFailPlayer."
		)

	if light_landing_player == null:
		push_warning(
			"MovementAudio has no LightLandingPlayer."
		)

	if heavy_landing_player == null:
		push_warning(
			"MovementAudio has no HeavyLandingPlayer."
		)

	if wind_player == null:
		push_warning(
			"MovementAudio has no WindPlayer."
		)

	if glide_deploy_player == null:
		push_warning(
			"MovementAudio has no GlideDeployPlayer."
		)

	if glide_loop_player == null:
		push_warning(
			"MovementAudio has no GlideLoopPlayer."
		)

	if glide_close_player == null:
		push_warning(
			"MovementAudio has no GlideClosePlayer."
		)

	if glide_fail_player == null:
		push_warning(
			"MovementAudio has no GlideFailPlayer."
		)

	if grapple_fire_player == null:
		push_warning(
			"MovementAudio has no GrappleFirePlayer."
		)

	if grapple_loop_player == null:
		push_warning(
			"MovementAudio has no GrappleLoopPlayer."
		)

	if grapple_return_player == null:
		push_warning(
			"MovementAudio has no GrappleReturnPlayer."
		)

	if grapple_fail_player == null:
		push_warning(
			"MovementAudio has no GrappleFailPlayer."
		)


func _configure_audio_players() -> void:
	_configure_one_shot_player(
		footstep_player,
		footstep_max_polyphony
	)

	_configure_one_shot_player(
		crouch_footstep_player,
		footstep_max_polyphony
	)

	_configure_one_shot_player(
		slide_start_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		slide_end_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		dash_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		ground_jump_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		wall_jump_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		light_landing_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		heavy_landing_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		dash_fail_player,
		fail_sound_max_polyphony
	)

	_configure_one_shot_player(
		wall_jump_fail_player,
		fail_sound_max_polyphony
	)

	_configure_one_shot_player(
		glide_deploy_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		glide_close_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		glide_fail_player,
		fail_sound_max_polyphony
	)

	_configure_one_shot_player(
		grapple_fire_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		grapple_return_player,
		one_shot_max_polyphony
	)

	_configure_one_shot_player(
		grapple_fail_player,
		fail_sound_max_polyphony
	)

	_configure_loop_player(
		slide_loop_player
	)

	_configure_loop_player(
		wind_player
	)

	_configure_loop_player(
		glide_loop_player
	)

	_configure_loop_player(
		grapple_loop_player
	)


func _configure_one_shot_player(
	audio_player: AudioStreamPlayer,
	max_polyphony: int
) -> void:
	if audio_player == null:
		return

	audio_player.bus = &"PlayerSfx"
	audio_player.max_polyphony = max_polyphony


func _configure_loop_player(
	audio_player: AudioStreamPlayer
) -> void:
	if audio_player == null:
		return

	audio_player.bus = &"PlayerSfx"
	audio_player.max_polyphony = 1


func _on_camera_bob_step() -> void:
	if not uses_bob_synced_footsteps:
		return

	if _player == null:
		return

	if _is_sliding:
		return

	var horizontal_speed_mps: float = (
		_get_horizontal_speed_mps()
	)

	if horizontal_speed_mps < footstep_min_speed_mps:
		return

	var can_play_footstep: bool = (
		_player.is_on_floor()
		or _is_wallrunning
	)

	if not can_play_footstep:
		return

	var is_crouching: bool = (
		not _is_wallrunning
		and _movement_motor.stance.is_crouching()
	)

	if is_crouching:
		_play_random_stream(
			crouch_footstep_player,
			crouch_streams,
			false,
			movement_pitch_min,
			movement_pitch_max
		)
		return

	_play_random_stream(
		footstep_player,
		walk_run_streams,
		true,
		movement_pitch_min,
		movement_pitch_max
	)


func _connect_camera_visual_signals() -> void:
	if not uses_bob_synced_footsteps:
		return

	if camera_visual_rig == null:
		push_warning(
			"MovementAudio requires CameraVisualRig "
			+ "when bob synced footsteps are enabled."
		)
		return

	camera_visual_rig.bob_step.connect(
		_on_camera_bob_step
	)
