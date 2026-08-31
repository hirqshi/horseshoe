class_name MovementMotor
extends Node

signal landed(impact_speed_mps: float)
signal left_ground()
signal jumped()
signal wall_touched()
signal wallrun_started(wall_normal: Vector3)
signal wallrun_finished()
signal dash_started()
signal dash_finished()
signal slide_started()
signal slide_finished()
signal wall_jumped()
signal dash_charges_changed(
	current_charges: int,
	max_charges: int
)

signal dash_availability_changed(
	is_available: bool
)

signal wall_jump_charges_changed(
	current_charges: int,
	max_charges: int
)

signal wall_jump_availability_changed(
	is_available: bool
)

@export var config: MovementConfig
@export var view_pivot: Node3D
@export var movement_yaw_pivot: Node3D
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
@onready var _wallrun_state: WallrunLocomotionState = (
	get_node_or_null("WallrunState") as WallrunLocomotionState
)

var _body: CharacterBody3D
var _player_input: PlayerInput = PlayerInput.new()
var _context: MovementContext = MovementContext.new()
var _active_state: LocomotionState

var _dash_action: DashAction

var _is_dash_available: bool = false
var _is_wall_jump_available: bool = false

var _last_grounded_time_s: float = -INF
var _jump_buffer_until_s: float = -INF
var _jump_hold_remaining_s: float = 0.0
var _was_on_floor: bool = false
var _was_touching_wall: bool = false

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
		
	if movement_yaw_pivot == null:
		push_error("MovementMotor requires a movement yaw pivot.")
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
		
	if _grounded_state == null \
			or _airborne_state == null \
			or _wallrun_state == null:
		push_error(
			"MovementMotor requires GroundedState, AirborneState and WallrunState."
		)
		set_physics_process(false)
		return
		
	if _action_controller == null:
		push_error("MovementMotor requires ActionController.")
		set_physics_process(false)
		return
		
	_dash_action = _action_controller.get_dash_action()

	if _dash_action == null:
		push_error(
			"MovementMotor requires a DashAction inside ActionController."
		)
		set_physics_process(false)
		return

	_dash_action.charges_changed.connect(
		_on_dash_charges_changed
	)

	_wallrun_state.wall_jump_charges_changed.connect(
		_on_wall_jump_charges_changed
	)
	
	_body.floor_max_angle = deg_to_rad(config.max_floor_angle_deg)

	_context.body = _body
	_context.view_pivot = view_pivot
	_context.movement_yaw_pivot = movement_yaw_pivot
	_context.sensors = sensors
	_context.config = config
	_context.player_input = _player_input

	_was_on_floor = _body.is_on_floor()

	if _was_on_floor:
		_active_state = _grounded_state
	else:
		_active_state = _airborne_state

	_active_state.enter(_context)
	_update_charge_availability()

func _physics_process(delta: float) -> void:
	var current_time_s: float = Time.get_ticks_msec() * 0.001
	var pre_move_vertical_speed_mps: float = _body.velocity.y

	_player_input.update_from_input()
	_context.update(delta, current_time_s)

	_update_grounded_time(current_time_s)
	_update_jump_buffer(current_time_s)

	_active_state.physics_tick(_context)
	_action_controller.apply(_context)
	_try_consume_jump(current_time_s)
	_apply_variable_jump(delta)

	_body.velocity = _context.velocity
	_body.move_and_slide()

	_context.velocity = _body.velocity

	sensors.update_contacts()
	_update_wall_touch_event()
	_process_post_move(pre_move_vertical_speed_mps)
	_wallrun_state.update_reentry_cooldown(delta)
	_update_locomotion_state()
	_update_charge_availability()

	_body.velocity = _context.velocity

func _update_grounded_time(current_time_s: float) -> void:
	if _context.is_grounded:
		_last_grounded_time_s = current_time_s

func _update_jump_buffer(current_time_s: float) -> void:
	if _player_input.is_jump_pressed:
		_jump_buffer_until_s = current_time_s + config.jump_buffer_s

func _try_consume_jump(current_time_s: float) -> void:
	var has_buffered_jump: bool = (
		current_time_s <= _jump_buffer_until_s
	)

	if not has_buffered_jump:
		return

	if _wallrun_state.try_wall_jump(_context):
		_jump_hold_remaining_s = 0.0
		_jump_buffer_until_s = -INF
		_last_grounded_time_s = -INF

		wall_jumped.emit()
		jumped.emit()

		_set_locomotion_state(_airborne_state)

		return

	var can_coyote_jump: bool = (
		current_time_s <= _last_grounded_time_s + config.coyote_time_s
	)

	if not can_coyote_jump:
		return

	if stance.is_crouching():
		var can_exit_crouch: bool = stance.try_set_crouching(false)

		if not can_exit_crouch:
			_jump_buffer_until_s = -INF
			return

	_context.velocity.y = config.jump_speed_mps
	_jump_hold_remaining_s = config.jump_hold_duration_s
	_jump_buffer_until_s = -INF
	_last_grounded_time_s = -INF
	jumped.emit()

func _process_post_move(pre_move_vertical_speed_mps: float) -> void:
	var is_on_floor_now: bool = _body.is_on_floor()

	if not _was_on_floor and is_on_floor_now:
		_wallrun_state.restore_wall_jump_charges()
		landed.emit(maxf(0.0, -pre_move_vertical_speed_mps))

	if _was_on_floor and not is_on_floor_now:
		left_ground.emit()

	_was_on_floor = is_on_floor_now

func _set_locomotion_state(
	next_state: LocomotionState
) -> void:
	if next_state == _active_state:
		return

	var was_wallrunning: bool = (
		_active_state == _wallrun_state
	)

	_active_state.exit(_context)
	_active_state = next_state
	_active_state.enter(_context)

	var is_wallrunning: bool = (
		_active_state == _wallrun_state
	)

	if not was_wallrunning and is_wallrunning:
		wallrun_started.emit(
			_wallrun_state.get_wall_normal()
		)
	elif was_wallrunning and not is_wallrunning:
		wallrun_finished.emit()

func _update_locomotion_state() -> void:
	var next_state: LocomotionState

	if _body.is_on_floor():
		next_state = _grounded_state
	elif _active_state == _wallrun_state \
			and not _wallrun_state.can_continue(_context):
		next_state = _airborne_state
	elif not _action_controller.blocks_locomotion_transition() \
			and _wallrun_state.can_enter(_context):
		next_state = _wallrun_state
	else:
		next_state = _airborne_state

	_set_locomotion_state(next_state)

func _apply_variable_jump(delta: float) -> void:
	if _jump_hold_remaining_s <= 0.0:
		return

	if _context.velocity.y <= 0.0:
		_jump_hold_remaining_s = 0.0
		return

	if not _player_input.is_jump_held:
		_context.velocity.y *= (
			config.jump_release_velocity_multiplier
		)
		_jump_hold_remaining_s = 0.0
		return

	_context.velocity.y += (
		config.gravity_mps2
		* (
			1.0
			- config.jump_hold_gravity_multiplier
		)
		* delta
	)

	_jump_hold_remaining_s = maxf(
		_jump_hold_remaining_s - delta,
		0.0
	)

func _update_wall_touch_event() -> void:
	var is_touching_wall: bool = (
		sensors.get_best_wall().is_valid()
	)

	if not _was_touching_wall and is_touching_wall:
		wall_touched.emit()

	_was_touching_wall = is_touching_wall

func get_move_input() -> Vector2:
	return _player_input.move

func notify_dash_started() -> void:
	dash_started.emit()

func notify_dash_finished() -> void:
	dash_finished.emit()

func notify_slide_started() -> void:
	slide_started.emit()

func notify_slide_finished() -> void:
	slide_finished.emit()

func get_dash_charges() -> int:
	if _dash_action == null:
		return 0

	return _dash_action.get_charges()


func get_dash_max_charges() -> int:
	if _dash_action == null:
		return 0

	return _dash_action.get_max_charges()


func can_dash() -> bool:
	if _dash_action == null:
		return false

	if _body == null:
		return false

	if _body.is_on_floor():
		return false

	if _action_controller.has_active_action():
		return false

	return get_dash_charges() > 0


func get_wall_jump_charges() -> int:
	if _wallrun_state == null:
		return 0

	return _wallrun_state.get_wall_jump_charges()


func get_wall_jump_max_charges() -> int:
	if _wallrun_state == null:
		return 0

	return _wallrun_state.get_max_wall_jump_charges()


func can_wall_jump() -> bool:
	if _body == null:
		return false

	if _body.is_on_floor():
		return false

	if get_wall_jump_charges() <= 0:
		return false

	var wall_contact: WallContact = (
		sensors.get_wall_jump_contact()
	)

	return wall_contact.is_valid()


func _update_charge_availability() -> void:
	var can_use_dash: bool = can_dash()

	if can_use_dash != _is_dash_available:
		_is_dash_available = can_use_dash

		dash_availability_changed.emit(
			_is_dash_available
		)

	var can_use_wall_jump: bool = can_wall_jump()

	if can_use_wall_jump != _is_wall_jump_available:
		_is_wall_jump_available = can_use_wall_jump

		wall_jump_availability_changed.emit(
			_is_wall_jump_available
		)


func _on_dash_charges_changed(
	current_charges: int,
	max_charges: int
) -> void:
	dash_charges_changed.emit(
		current_charges,
		max_charges
	)


func _on_wall_jump_charges_changed(
	current_charges: int,
	max_charges: int
) -> void:
	wall_jump_charges_changed.emit(
		current_charges,
		max_charges
	)
