class_name MovementMotor
extends Node

@export var config: MovementConfig
@export var view_pivot: Node3D
@export var sensors: PlayerSensors

@onready var _grounded_state: GroundedLocomotionState = (
	get_node_or_null("GroundedState") as GroundedLocomotionState
)
@onready var _airborne_state: AirborneLocomotionState = (
	get_node_or_null("AirborneState") as AirborneLocomotionState
)

var _body: CharacterBody3D
var _player_input: PlayerInput = PlayerInput.new()
var _context: MovementContext = MovementContext.new()
var _active_state: LocomotionState

var _last_grounded_time_s: float = -INF
var _jump_buffer_until_s: float = -INF

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

	if _grounded_state == null or _airborne_state == null:
		push_error("MovementMotor requires GroundedState and AirborneState.")
		set_physics_process(false)
		return

	_body.floor_max_angle = deg_to_rad(config.max_floor_angle_deg)

	_context.body = _body
	_context.view_pivot = view_pivot
	_context.sensors = sensors
	_context.config = config
	_context.player_input = _player_input

	_active_state = _grounded_state
	_active_state.enter(_context)

func _physics_process(delta: float) -> void:
	var current_time_s: float = Time.get_ticks_msec() * 0.001

	sensors.update_contacts()
	_player_input.update_from_input()
	_context.update(delta, current_time_s)

	_update_grounded_time(current_time_s)
	_update_jump_buffer(current_time_s)

	var next_state_id: StringName = _active_state.physics_tick(_context)
	_try_consume_jump(current_time_s)
	_switch_state(next_state_id)

	_body.velocity = _context.velocity
	_body.move_and_slide()

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

func _switch_state(next_state_id: StringName) -> void:
	if next_state_id.is_empty():
		return

	var next_state: LocomotionState = _get_state(next_state_id)
	if next_state == null or next_state == _active_state:
		return

	_active_state.exit(_context)
	_active_state = next_state
	_active_state.enter(_context)

func _get_state(state_id: StringName) -> LocomotionState:
	match state_id:
		GroundedLocomotionState.ID:
			return _grounded_state
		AirborneLocomotionState.ID:
			return _airborne_state
		_:
			push_error("Unknown locomotion state: %s." % state_id)
			return null
