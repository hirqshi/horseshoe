class_name HandAnimationController
extends Node

const LOOP_RUN: StringName = &"run"
const LOOP_SLIDE: StringName = &"slide"
const LOOP_AIRBORNE: StringName = &"airborne"
const LOOP_GRAPPLE: StringName = &"grapple"
const LOOP_WALLRUN_LEFT: StringName = &"wallrun_left"
const LOOP_WALLRUN_RIGHT: StringName = &"wallrun_right"

@export var motor: MovementMotor
@export var hand_rig: HandRig
@export var animation_tree: AnimationTree

@export_category("run speed")
@export var run_playback_reference_speed_mps: float = 10.0
@export var run_speed_scale_max: float = 2.0
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var min_run_speed_mps: float = 2.0

@export_category("parameter paths")
@export var loop_transition_path: String = "parameters/loop_transition/transition_request"
@export var run_timescale_path: String = "parameters/run_timescale/scale"
@export var walljump_front_request_path: String = "parameters/walljump_front_oneshot/request"
@export var walljump_left_request_path: String = "parameters/walljump_left_oneshot/request"
@export var walljump_right_request_path: String = "parameters/walljump_right_oneshot/request"
@export var dash_request_path: String = "parameters/dash_oneshot/request"

var _is_wallrunning: bool = false
var _is_wallrun_left: bool = false
var _is_sliding: bool = false
var _current_loop: StringName = &""


func _ready() -> void:
	if motor == null or hand_rig == null or animation_tree == null:
		push_error(
			"HandAnimationController requires MovementMotor, "
			+ "HandRig and AnimationTree."
		)
		set_process(false)
		return

	motor.wallrun_started.connect(_on_wallrun_started)
	motor.wallrun_finished.connect(_on_wallrun_finished)
	motor.wall_jumped.connect(_on_wall_jumped)
	motor.slide_started.connect(_on_slide_started)
	motor.slide_finished.connect(_on_slide_finished)
	motor.dash_started.connect(_on_dash_started)


func _process(_delta: float) -> void:
	var is_gliding: bool = motor.is_gliding()

	var grapple_action: GrappleAction = motor.get_grapple_action()
	var is_grappling: bool = (
		grapple_action != null and grapple_action.is_active()
	)

	var body: CharacterBody3D = motor.get_body()
	var is_on_floor: bool = body != null and body.is_on_floor()

	var horizontal_speed_mps: float = 0.0

	if body != null:
		horizontal_speed_mps = Vector2(
			body.velocity.x,
			body.velocity.z
		).length()

	var is_below_run_threshold: bool = (
		is_on_floor
		and not _is_sliding
		and not _is_wallrunning
		and not is_grappling
		and horizontal_speed_mps < min_run_speed_mps
	)

	hand_rig.set_hidden(is_gliding or is_below_run_threshold)
	hand_rig.set_airborne(not is_on_floor)

	if is_below_run_threshold:
		return

	var target_loop: StringName = _resolve_loop(
		is_on_floor,
		is_grappling
	)

	_set_loop(target_loop)

	if target_loop != LOOP_RUN:
		return

	animation_tree.set(
		run_timescale_path,
		clampf(
			horizontal_speed_mps
			/ maxf(run_playback_reference_speed_mps, 0.001),
			0.0,
			run_speed_scale_max
		)
	)


func _resolve_loop(
	is_on_floor: bool,
	is_grappling: bool
) -> StringName:
	if is_grappling:
		return LOOP_GRAPPLE

	if _is_sliding:
		return LOOP_SLIDE

	if _is_wallrunning:
		return (
			LOOP_WALLRUN_LEFT
			if _is_wallrun_left
			else LOOP_WALLRUN_RIGHT
		)

	if not is_on_floor:
		return LOOP_AIRBORNE

	return LOOP_RUN


func _set_loop(loop_name: StringName) -> void:
	if loop_name == _current_loop:
		return

	_current_loop = loop_name
	animation_tree.set(loop_transition_path, loop_name)


func _on_wallrun_started(wall_normal: Vector3) -> void:
	_is_wallrunning = true

	var body: CharacterBody3D = motor.get_body()

	if body == null:
		return

	var player_right: Vector3 = body.global_transform.basis.x
	_is_wallrun_left = wall_normal.dot(player_right) > 0.0


func _on_wallrun_finished() -> void:
	_is_wallrunning = false


func _on_wall_jumped() -> void:
	var request_path: String = walljump_front_request_path

	if _is_wallrunning:
		request_path = (
			walljump_left_request_path
			if _is_wallrun_left
			else walljump_right_request_path
		)

	animation_tree.set(
		request_path,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)

	_is_wallrunning = false


func _on_slide_started() -> void:
	_is_sliding = true


func _on_slide_finished() -> void:
	_is_sliding = false


func _on_dash_started() -> void:
	animation_tree.set(
		dash_request_path,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)
