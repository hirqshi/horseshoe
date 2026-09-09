class_name InGameHud
extends CanvasLayer

@export var hud_toggle_action: StringName = &"toggle_hud"

@export_category("hud elements")
@export var crosshair: CrosshairHudElement
@export var speed_hud: SpeedHudElement
@export var fall_danger_hud: FallDangerHud
@export var reverse_stamina_hud: ReverseStaminaHud

@export var dash_charges_hud: ChargeFrameHud
@export var wall_jump_charges_hud: ChargeFrameHud
@export var glide_charges_hud: ChargeFrameHud

@export var grapple_distance_hud: GrappleDistanceHud

@export var roll_indicator_hud: RollIndicatorHud
@export var camera_roll_bars_hud: CameraRollBarsHud
@export var compass_hud: CompassHud
@export var pitch_indicator_hud: PitchIndicatorHud

@export_category("viewport composite")
@export var ui_viewport: SubViewport
@export var hud_root: Control
@export var ui_composite: TextureRect

var _is_hud_visible: bool = true

var _movement_motor: MovementMotor
var _grapple_action: GrappleAction
var _camera_visual_rig: CameraVisualRig
var _composite_material: ShaderMaterial


func _ready() -> void:
	if crosshair == null:
		push_error(
			"InGameHud requires Crosshair."
		)
		set_process(false)
		set_process_input(false)
		return
		
	if roll_indicator_hud == null:
		push_error(
			"InGameHud requires RollIndicatorHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if camera_roll_bars_hud == null:
		push_error(
			"InGameHud requires CameraRollBarsHud."
		)
		set_process(false)
		set_process_input(false)
		return
		
	if speed_hud == null:
		push_error(
			"InGameHud requires SpeedHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if fall_danger_hud == null:
		push_error(
			"InGameHud requires FallDangerHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if reverse_stamina_hud == null:
		push_error(
			"InGameHud requires ReverseStaminaHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if dash_charges_hud == null:
		push_error(
			"InGameHud requires DashChargesHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if wall_jump_charges_hud == null:
		push_error(
			"InGameHud requires WallJumpChargesHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if glide_charges_hud == null:
		push_error(
			"InGameHud requires GlideChargesHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if grapple_distance_hud == null:
		push_error(
			"InGameHud requires GrappleDistanceHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if ui_viewport == null:
		push_error(
			"InGameHud requires UiViewport."
		)
		set_process(false)
		set_process_input(false)
		return

	if hud_root == null:
		push_error(
			"InGameHud requires HudRoot."
		)
		set_process(false)
		set_process_input(false)
		return

	if ui_composite == null:
		push_error(
			"InGameHud requires UiComposite."
		)
		set_process(false)
		set_process_input(false)
		return
		
	if compass_hud == null:
		push_error(
			"InGameHud requires CompassHud."
		)
		set_process(false)
		set_process_input(false)
		return

	if pitch_indicator_hud == null:
		push_error(
			"InGameHud requires PitchIndicatorHud."
		)
		set_process(false)
		set_process_input(false)
		return
		
	ui_viewport.transparent_bg = true

	ui_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	ui_viewport.render_target_clear_mode = (
		SubViewport.CLEAR_MODE_ALWAYS
	)

	ui_composite.texture = ui_viewport.get_texture()

	_composite_material = (
		ui_composite.material as ShaderMaterial
	)

	if _composite_material == null:
		push_error(
			"UiComposite requires ShaderMaterial."
		)
		set_process(false)
		set_process_input(false)
		return

	_composite_material.set_shader_parameter(
		&"ui_texture",
		ui_viewport.get_texture()
	)

	var main_viewport: Viewport = get_viewport()

	if not main_viewport.size_changed.is_connected(
		_on_viewport_size_changed
	):
		main_viewport.size_changed.connect(
			_on_viewport_size_changed
		)

	_sync_ui_viewport_size()

	visible = _is_hud_visible


func _exit_tree() -> void:
	var main_viewport: Viewport = get_viewport()

	if main_viewport.size_changed.is_connected(
		_on_viewport_size_changed
	):
		main_viewport.size_changed.disconnect(
			_on_viewport_size_changed
		)

	_disconnect_player_signals()


func _process(
	_delta: float
) -> void:
	if _movement_motor != null:
		dash_charges_hud.set_cooldown_remaining_s(
			_movement_motor.get_dash_cooldown_remaining_s()
		)

	_update_grapple_distance()

	_update_camera_orientation()


func _update_camera_orientation() -> void:
	if _camera_visual_rig == null:
		return

	if roll_indicator_hud == null:
		return

	if camera_roll_bars_hud == null:
		return

	if compass_hud == null:
		return

	if pitch_indicator_hud == null:
		return

	var roll_degrees: float = (
		_camera_visual_rig.get_hud_roll_degrees()
	)

	var heading_degrees: float = (
		_camera_visual_rig.get_hud_heading_degrees()
	)

	var pitch_degrees: float = (
		_camera_visual_rig.get_hud_pitch_degrees()
	)

	roll_indicator_hud.set_roll_degrees(
		roll_degrees
	)

	var is_gliding: bool = (
		_movement_motor.is_gliding()
	)

	camera_roll_bars_hud.set_roll_degrees(
		roll_degrees,
		is_gliding
	)

	compass_hud.set_heading_degrees(
		heading_degrees
	)

	pitch_indicator_hud.set_pitch_degrees(
		pitch_degrees
	)


func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_action_pressed(
		hud_toggle_action
	):
		set_hud_visible(
			not _is_hud_visible
		)

		get_viewport().set_input_as_handled()
		return

	if not _is_hud_visible:
		return

	if event is InputEventMouseMotion:
		register_look_delta(
			event.screen_relative
		)


func set_player(
	player: Player
) -> void:
	if player == null:
		push_error(
			"InGameHud requires Player."
		)
		return

	_disconnect_player_signals()

	var fall_tracker: FallTracker = (
		player.get_fall_tracker()
	)

	if fall_tracker == null:
		push_error(
			"InGameHud could not get FallTracker from Player."
		)
		return

	var reverse_stamina: ReverseStamina = (
		player.get_reverse_stamina()
	)

	if reverse_stamina == null:
		push_error(
			"InGameHud could not get ReverseStamina from Player."
		)
		return

	_movement_motor = player.get_movement_motor()

	if _movement_motor == null:
		push_error(
			"InGameHud could not get MovementMotor from Player."
		)
		return

	_camera_visual_rig = (
		player.get_camera_visual_rig()
	)

	if _camera_visual_rig == null:
		push_error(
			"InGameHud could not get CameraVisualRig from Player."
		)
		_movement_motor = null
		return

	_grapple_action = (
		_movement_motor.get_grapple_action()
	)

	if _grapple_action == null:
		push_error(
			"InGameHud could not get GrappleAction "
			+ "from MovementMotor."
		)
		_movement_motor = null
		return

	crosshair.set_player(
		player
	)

	speed_hud.set_player(
		player
	)

	fall_danger_hud.set_fall_tracker(
		fall_tracker
	)

	reverse_stamina_hud.set_reverse_stamina(
		reverse_stamina
	)

	_connect_player_signals()

	_refresh_charge_hud()

	grapple_distance_hud.set_target_available(
		_grapple_action.is_target_available()
	)

	_update_grapple_distance()


func register_look_delta(
	mouse_delta: Vector2
) -> void:
	if not _is_hud_visible:
		return

	crosshair.register_look_delta(
		mouse_delta
	)

	grapple_distance_hud.register_look_delta(
		mouse_delta
	)
	
	roll_indicator_hud.register_look_delta(
		mouse_delta
	)

	camera_roll_bars_hud.register_look_delta(
		mouse_delta
	)
	
	compass_hud.register_look_delta(
		mouse_delta
	)

	pitch_indicator_hud.register_look_delta(
		mouse_delta
	)
	
	speed_hud.register_look_delta(
		mouse_delta
	)

	fall_danger_hud.register_look_delta(
		mouse_delta
	)

	reverse_stamina_hud.register_look_delta(
		mouse_delta
	)

	dash_charges_hud.register_look_delta(
		mouse_delta
	)

	wall_jump_charges_hud.register_look_delta(
		mouse_delta
	)

	glide_charges_hud.register_look_delta(
		mouse_delta
	)


func set_hud_visible(
	value: bool
) -> void:
	_is_hud_visible = value

	visible = _is_hud_visible


func is_hud_visible() -> bool:
	return _is_hud_visible


func _connect_player_signals() -> void:
	if _movement_motor == null:
		return

	if _grapple_action == null:
		return

	if not _movement_motor.dash_started.is_connected(
		_on_player_dash_started
	):
		_movement_motor.dash_started.connect(
			_on_player_dash_started
		)

	if not _movement_motor.slide_started.is_connected(
		_on_player_slide_started
	):
		_movement_motor.slide_started.connect(
			_on_player_slide_started
		)

	if not _movement_motor.dash_charges_changed.is_connected(
		_on_dash_charges_changed
	):
		_movement_motor.dash_charges_changed.connect(
			_on_dash_charges_changed
		)

	if not _movement_motor.dash_availability_changed.is_connected(
		_on_dash_availability_changed
	):
		_movement_motor.dash_availability_changed.connect(
			_on_dash_availability_changed
		)

	if not _movement_motor.wall_jump_charges_changed.is_connected(
		_on_wall_jump_charges_changed
	):
		_movement_motor.wall_jump_charges_changed.connect(
			_on_wall_jump_charges_changed
		)

	if not _movement_motor.wall_jump_availability_changed.is_connected(
		_on_wall_jump_availability_changed
	):
		_movement_motor.wall_jump_availability_changed.connect(
			_on_wall_jump_availability_changed
		)

	if not _movement_motor.glide_charges_changed.is_connected(
		_on_glide_charges_changed
	):
		_movement_motor.glide_charges_changed.connect(
			_on_glide_charges_changed
		)

	if not _movement_motor.glide_availability_changed.is_connected(
		_on_glide_availability_changed
	):
		_movement_motor.glide_availability_changed.connect(
			_on_glide_availability_changed
		)

	if not _grapple_action.target_availability_changed.is_connected(
		_on_grapple_target_availability_changed
	):
		_grapple_action.target_availability_changed.connect(
			_on_grapple_target_availability_changed
		)

	if not _grapple_action.cooldown_started.is_connected(
		_on_grapple_cooldown_started
	):
		_grapple_action.cooldown_started.connect(
			_on_grapple_cooldown_started
		)


func _disconnect_player_signals() -> void:
	if _movement_motor != null:
		if _movement_motor.dash_started.is_connected(
			_on_player_dash_started
		):
			_movement_motor.dash_started.disconnect(
				_on_player_dash_started
			)

		if _movement_motor.slide_started.is_connected(
			_on_player_slide_started
		):
			_movement_motor.slide_started.disconnect(
				_on_player_slide_started
			)

		if _movement_motor.dash_charges_changed.is_connected(
			_on_dash_charges_changed
		):
			_movement_motor.dash_charges_changed.disconnect(
				_on_dash_charges_changed
			)

		if _movement_motor.dash_availability_changed.is_connected(
			_on_dash_availability_changed
		):
			_movement_motor.dash_availability_changed.disconnect(
				_on_dash_availability_changed
			)

		if _movement_motor.wall_jump_charges_changed.is_connected(
			_on_wall_jump_charges_changed
		):
			_movement_motor.wall_jump_charges_changed.disconnect(
				_on_wall_jump_charges_changed
			)

		if _movement_motor.wall_jump_availability_changed.is_connected(
			_on_wall_jump_availability_changed
		):
			_movement_motor.wall_jump_availability_changed.disconnect(
				_on_wall_jump_availability_changed
			)

		if _movement_motor.glide_charges_changed.is_connected(
			_on_glide_charges_changed
		):
			_movement_motor.glide_charges_changed.disconnect(
				_on_glide_charges_changed
			)

		if _movement_motor.glide_availability_changed.is_connected(
			_on_glide_availability_changed
		):
			_movement_motor.glide_availability_changed.disconnect(
				_on_glide_availability_changed
			)

	if _grapple_action != null:
		if _grapple_action.target_availability_changed.is_connected(
			_on_grapple_target_availability_changed
		):
			_grapple_action.target_availability_changed.disconnect(
				_on_grapple_target_availability_changed
			)

		if _grapple_action.cooldown_started.is_connected(
			_on_grapple_cooldown_started
		):
			_grapple_action.cooldown_started.disconnect(
				_on_grapple_cooldown_started
			)

	_movement_motor = null
	_grapple_action = null
	_camera_visual_rig = null


func _refresh_charge_hud() -> void:
	if _movement_motor == null:
		return

	dash_charges_hud.set_charge_state(
		_movement_motor.get_dash_charges(),
		_movement_motor.can_dash()
	)

	wall_jump_charges_hud.set_charge_state(
		_movement_motor.get_wall_jump_charges(),
		_movement_motor.can_wall_jump()
	)

	glide_charges_hud.set_charge_state(
		_movement_motor.get_glide_charges(),
		_movement_motor.can_glide()
	)

	dash_charges_hud.set_cooldown_remaining_s(
		_movement_motor.get_dash_cooldown_remaining_s()
	)


func _update_grapple_distance() -> void:
	if grapple_distance_hud == null:
		return

	if _grapple_action == null:
		grapple_distance_hud.set_target_distance_m(
			-1.0,
			0.0
		)
		return

	grapple_distance_hud.set_target_distance_m(
		_grapple_action.get_target_distance_m(),
		_grapple_action.get_max_target_distance_m()
	)


func _on_player_dash_started() -> void:
	crosshair.play_dash_impulse()


func _on_player_slide_started() -> void:
	crosshair.play_slide_impulse()


func _on_viewport_size_changed() -> void:
	_sync_ui_viewport_size()


func _sync_ui_viewport_size() -> void:
	if ui_viewport == null:
		return

	if hud_root == null:
		return

	var visible_size: Vector2 = (
		get_viewport()
		.get_visible_rect()
		.size
	)

	var target_viewport_size: Vector2i = Vector2i(
		maxi(
			1,
			roundi(
				visible_size.x
			)
		),
		maxi(
			1,
			roundi(
				visible_size.y
			)
		)
	)

	ui_viewport.size = target_viewport_size

	hud_root.position = Vector2.ZERO
	hud_root.size = visible_size

	if _composite_material == null:
		return

	var texture_pixel_size: Vector2 = Vector2(
		1.0
		/ float(
			target_viewport_size.x
		),
		1.0
		/ float(
			target_viewport_size.y
		)
	)

	_composite_material.set_shader_parameter(
		&"ui_texture_pixel_size",
		texture_pixel_size
	)


func _on_dash_charges_changed(
	current_charges: int,
	_max_charges: int
) -> void:
	if _movement_motor == null:
		return

	dash_charges_hud.set_charge_state(
		current_charges,
		_movement_motor.can_dash()
	)


func _on_dash_availability_changed(
	is_available: bool
) -> void:
	if _movement_motor == null:
		return

	dash_charges_hud.set_charge_state(
		_movement_motor.get_dash_charges(),
		is_available
	)


func _on_wall_jump_charges_changed(
	current_charges: int,
	_max_charges: int
) -> void:
	if _movement_motor == null:
		return

	wall_jump_charges_hud.set_charge_state(
		current_charges,
		_movement_motor.can_wall_jump()
	)


func _on_wall_jump_availability_changed(
	is_available: bool
) -> void:
	if _movement_motor == null:
		return

	wall_jump_charges_hud.set_charge_state(
		_movement_motor.get_wall_jump_charges(),
		is_available
	)


func _on_glide_charges_changed(
	current_charges: int,
	_max_charges: int
) -> void:
	if _movement_motor == null:
		return

	glide_charges_hud.set_charge_state(
		current_charges,
		_movement_motor.can_glide()
	)


func _on_glide_availability_changed(
	is_available: bool
) -> void:
	if _movement_motor == null:
		return

	glide_charges_hud.set_charge_state(
		_movement_motor.get_glide_charges(),
		is_available
	)


func _on_grapple_target_availability_changed(
	is_available: bool
) -> void:
	if grapple_distance_hud == null:
		return

	grapple_distance_hud.set_target_available(
		is_available
	)


func _on_grapple_cooldown_started(
	duration_s: float
) -> void:
	if grapple_distance_hud == null:
		return

	grapple_distance_hud.start_cooldown(
		duration_s
	)
