class_name RetinalHud
extends CanvasLayer

@export_category("references")
@export var retinal_fly: RetinalFly
@export var grapple_ready_organ: GrappleReadyOrgan
@export var stamina_helix: StaminaHelix
@export var fall_organ: FallOrgan

var _player: Player
var _movement_motor: MovementMotor
var _reverse_stamina: ReverseStamina
var _fall_tracker: FallTracker
var _grapple_action: GrappleAction

var _state: RetinalHudState = RetinalHudState.new()
var _previous_velocity: Vector3 = Vector3.ZERO
var _has_previous_velocity: bool = false


func set_player(
	player: Player
) -> void:
	_disconnect_player_signals()

	_player = player
	_movement_motor = null
	_reverse_stamina = null
	_fall_tracker = null
	_grapple_action = null
	_has_previous_velocity = false

	if _player == null:
		push_error("RetinalHud requires a Player.")
		return

	_movement_motor = _player.get_movement_motor()
	_reverse_stamina = _player.get_reverse_stamina()
	_fall_tracker = _player.get_fall_tracker()

	if _movement_motor != null:
		_grapple_action = _movement_motor.get_grapple_action()

	_player.look_delta_received.connect(
		_on_player_look_delta_received
	)

	if _reverse_stamina != null:
		_reverse_stamina.value_changed.connect(
			_on_reverse_stamina_value_changed
		)

	if _fall_tracker != null:
		_fall_tracker.fall_updated.connect(
			_on_fall_updated
		)
		_fall_tracker.fall_ui_hidden.connect(
			_on_fall_ui_hidden
		)


func _process(
	delta: float
) -> void:
	if _player == null:
		return

	_update_motion_state(delta)
	_update_grapple_state()

	if retinal_fly != null:
		retinal_fly.apply_hud_state(
			_state,
			delta
		)
		
	if grapple_ready_organ != null:
		grapple_ready_organ.apply_hud_state(
			_state,
			delta
		)
		
	if stamina_helix != null:
		stamina_helix.apply_hud_state(
			_state,
			delta
		)
		
	if fall_organ != null:
		fall_organ.apply_hud_state(
			_state,
			delta
		)
		
	_state.look_delta = Vector2.ZERO
	_state.look_speed = 0.0


func _exit_tree() -> void:
	_disconnect_player_signals()


func _update_motion_state(
	delta: float
) -> void:
	var world_velocity: Vector3 = _player.velocity

	_state.world_velocity = world_velocity
	_state.speed_mps = world_velocity.length()

	if _has_previous_velocity:
		_state.acceleration_mps2 = (
			world_velocity
			- _previous_velocity
		).length() / maxf(delta, 0.0001)
	else:
		_state.acceleration_mps2 = 0.0
		_has_previous_velocity = true

	_previous_velocity = world_velocity

	var camera: Camera3D = _player.get_gameplay_camera()

	if camera == null:
		_state.local_velocity = world_velocity
	else:
		_state.local_velocity = (
			camera.global_basis.inverse()
			* world_velocity
		)

	if _movement_motor != null:
		_state.is_gliding = _movement_motor.is_gliding()

	if _reverse_stamina != null:
		_state.reverse_stamina_ratio = (
			_reverse_stamina.get_normalized_value()
		)
	if _fall_tracker != null:
		_state.fall_risk_ratio = (
			_fall_tracker.get_live_risk_ratio()
		)

		_state.is_fall_lethal = (
			_fall_tracker.is_live_fall_lethal()
		)


func _update_grapple_state() -> void:
	if _grapple_action == null:
		_state.is_grapple_ready = false
		_state.is_grapple_active = false
		return

	var current_time_s: float = (
		Time.get_ticks_msec() * 0.001
	)

	_state.is_grapple_ready = (
		_grapple_action.is_ready(current_time_s)
	)

	_state.is_grapple_active = (
		_grapple_action.is_active()
	)


func _on_player_look_delta_received(
	mouse_delta: Vector2
) -> void:
	_state.look_delta = mouse_delta
	_state.look_speed = mouse_delta.length()


func _on_reverse_stamina_value_changed(
	_current_value: float,
	_max_value: float,
	normalized_value: float
) -> void:
	_state.reverse_stamina_ratio = normalized_value


func _on_fall_updated(
	_fall_distance_m: float,
	fall_progress: float,
	_downward_speed_mps: float,
	_fall_time_s: float,
	is_critical: bool
) -> void:
	_state.fall_progress = fall_progress
	_state.is_fall_critical = is_critical


func _on_fall_ui_hidden() -> void:
	_state.fall_progress = 0.0
	_state.is_fall_critical = false


func _disconnect_player_signals() -> void:
	if _player != null \
	and _player.look_delta_received.is_connected(
		_on_player_look_delta_received
	):
		_player.look_delta_received.disconnect(
			_on_player_look_delta_received
		)

	if _reverse_stamina != null \
	and _reverse_stamina.value_changed.is_connected(
		_on_reverse_stamina_value_changed
	):
		_reverse_stamina.value_changed.disconnect(
			_on_reverse_stamina_value_changed
		)

	if _fall_tracker != null \
	and _fall_tracker.fall_updated.is_connected(
		_on_fall_updated
	):
		_fall_tracker.fall_updated.disconnect(
			_on_fall_updated
		)

	if _fall_tracker != null \
	and _fall_tracker.fall_ui_hidden.is_connected(
		_on_fall_ui_hidden
	):
		_fall_tracker.fall_ui_hidden.disconnect(
			_on_fall_ui_hidden
		)
