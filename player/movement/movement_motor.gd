class_name MovementMotor
extends Node

signal landed(impact_speed_mps: float)
signal left_ground()
signal jumped()

@export var config: MovementConfig
@export var view_pivot: Node3D
@export var sensors: PlayerSensors
@export var stance: PlayerStance

@onready var _grounded_state: GroundedLocomotionState = (
	get_node_or_null("GroundedState") as GroundedLocomotionState
)
@onready var _airborne_state: AirborneLocomotionState = (
	get_node_or_null("AirborneState") as AirborneLocomotionState
)
@onready var _action_controller: ActionController = (
	get_node_or_null("ActionController") as ActionController
)

var _body: CharacterBody3D
var _player_input: PlayerInput = PlayerInput.new()
var _context: MovementContext = MovementContext.new()
var _active_state: LocomotionState

var _last_grounded_time_s: float = -INF
var _jump_buffer_until_s: float = -INF
var _was_on_floor: bool = false

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

	if _body == null:
		push_error("MovementMotor must be a child of CharacterBody3D.")
		set_physics_process(false)
		return

	if config == null:
		push_error("MovementMotor requires MovementConfig.")
		set_physics_process(false)
		return

	if view_pivot == null:
		push_error("MovementMotor requires a view pivot.")
		set_physics_process(false)
		return

	if sensors == null:
		push_error("MovementMotor requires PlayerSensors.")
		set_physics_process(false)
		return
		
	if stance == null:
		push_error("MovementMotor requires PlayerStance.")
		set_physics_process(false)
		return
		
	if _grounded_state == null or _airborne_state == null:
		push_error("MovementMotor requires GroundedState and AirborneState.")
		set_physics_process(false)
		return
		
	if _action_controller == null:
		push_error("MovementMotor requires ActionController.")
		set_physics_process(false)
		return
		
	_body.floor_max_angle = deg_to_rad(config.max_floor_angle_deg)

	_context.body = _body
	_context.view_pivot = view_pivot
	_context.sensors = sensors
	_context.config = config
	_context.player_input = _player_input

	_was_on_floor = _body.is_on_floor()

	if _was_on_floor:
		_active_state = _grounded_state
	else:
		_active_state = _airborne_state

	_active_state.enter(_context)

func _physics_process(delta: float) -> void:
	var current_time_s: float = Time.get_ticks_msec() * 0.001
	var pre_move_vertical_speed_mps: float = _body.velocity.y

	sensors.update_contacts()
	_player_input.update_from_input()
	_context.update(delta, current_time_s)

	_update_grounded_time(current_time_s)
	_update_jump_buffer(current_time_s)

	_active_state.physics_tick(_context)
	_action_controller.apply(_context)
	_try_consume_jump(current_time_s)

	_body.velocity = _context.velocity
	_body.move_and_slide()

	_process_post_move(pre_move_vertical_speed_mps)
	_update_locomotion_state()

func _update_grounded_time(current_time_s: float) -> void:
	if _context.is_grounded:
		_last_grounded_time_s = current_time_s

func _update_jump_buffer(current_time_s: float) -> void:
	if _player_input.is_jump_pressed:
		_jump_buffer_until_s = current_time_s + config.jump_buffer_s

func _try_consume_jump(current_time_s: float) -> void:
	var has_buffered_jump: bool = current_time_s <= _jump_buffer_until_s
	var can_coyote_jump: bool = (
		current_time_s <= _last_grounded_time_s + config.coyote_time_s
	)

	if not has_buffered_jump or not can_coyote_jump:
		return

	_context.velocity.y = config.jump_speed_mps
	_jump_buffer_until_s = -INF
	_last_grounded_time_s = -INF
	jumped.emit()

func _process_post_move(pre_move_vertical_speed_mps: float) -> void:
	var is_on_floor_now: bool = _body.is_on_floor()

	if not _was_on_floor and is_on_floor_now:
		landed.emit(maxf(0.0, -pre_move_vertical_speed_mps))

	if _was_on_floor and not is_on_floor_now:
		left_ground.emit()

	_was_on_floor = is_on_floor_now

func _update_locomotion_state() -> void:
	var next_state: LocomotionState

	if _body.is_on_floor():
		next_state = _grounded_state
	else:
		next_state = _airborne_state

	if next_state == _active_state:
		return

	_active_state.exit(_context)
	_active_state = next_state
	_active_state.enter(_context)
