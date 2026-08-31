class_name InGameHud
extends CanvasLayer

@export var hud_toggle_action: StringName = &"toggle_hud"
@export var crosshair: CrosshairHudElement
@export var speed_hud: SpeedHudElement
@export var fall_danger_hud: FallDangerHud
@export var reverse_stamina_hud: ReverseStaminaHud
@export var dash_charges_hud: ChargeFrameHud
@export var wall_jump_charges_hud: ChargeFrameHud

@export_category("viewport composite")
@export var ui_viewport: SubViewport
@export var hud_root: Control
@export var ui_composite: TextureRect

var _is_hud_visible: bool = true
var _movement_motor: MovementMotor

func _ready() -> void:
	if crosshair == null:
		push_error("InGameHud requires Crosshair.")
		set_process_input(false)
		return
		
	if speed_hud == null:
		push_error("InGameHud requires SpeedHud.")
		set_process_input(false)
		return
		
	if fall_danger_hud == null:
		push_error("InGameHud requires FallDangerHud.")
		set_process_input(false)
		return
		
	if reverse_stamina_hud == null:
		push_error(
			"InGameHud requires ReverseStaminaHud."
		)
		set_process_input(false)
		return
		
	if dash_charges_hud == null:
		push_error(
			"InGameHud requires DashChargesHud."
		)
		set_process_input(false)
		return

	if wall_jump_charges_hud == null:
		push_error(
			"InGameHud requires WallJumpChargesHud."
		)
		set_process_input(false)
		return
		
	if ui_viewport == null:
		push_error("InGameHud requires UiViewport.")
		set_process_input(false)
		return

	if ui_composite == null:
		push_error("InGameHud requires UiComposite.")
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

	var composite_material: ShaderMaterial = (
		ui_composite.material as ShaderMaterial
	)

	if composite_material == null:
		push_error("UiComposite requires ShaderMaterial.")
		set_process_input(false)
		return

	composite_material.set_shader_parameter(
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
			roundi(visible_size.x)
		),
		maxi(
			1,
			roundi(visible_size.y)
		)
	)

	ui_viewport.size = target_viewport_size

	hud_root.position = Vector2.ZERO
	hud_root.size = visible_size

func set_player(player: Player) -> void:
	if player == null:
		push_error("InGameHud requires Player.")
		return

	crosshair.set_player(player)
	speed_hud.set_player(player)

	var fall_tracker: FallTracker = player.get_fall_tracker()

	if fall_tracker == null:
		push_error("InGameHud could not get FallTracker from Player.")
		return

	fall_danger_hud.set_fall_tracker(fall_tracker)
	var reverse_stamina: ReverseStamina = (
		player.get_reverse_stamina()
	)

	if reverse_stamina == null:
		push_error(
			"InGameHud could not get ReverseStamina from Player."
		)
		return

	reverse_stamina_hud.set_reverse_stamina(
		reverse_stamina
	)
	_movement_motor = player.get_movement_motor()

	if _movement_motor == null:
		push_error(
			"InGameHud could not get MovementMotor from Player."
		)
		return

	dash_charges_hud.set_charge_state(
		_movement_motor.get_dash_charges(),
		_movement_motor.can_dash()
	)

	wall_jump_charges_hud.set_charge_state(
		_movement_motor.get_wall_jump_charges(),
		_movement_motor.can_wall_jump()
	)

	_movement_motor.dash_charges_changed.connect(
		_on_dash_charges_changed
	)

	_movement_motor.dash_availability_changed.connect(
		_on_dash_availability_changed
	)

	_movement_motor.wall_jump_charges_changed.connect(
		_on_wall_jump_charges_changed
	)

	_movement_motor.wall_jump_availability_changed.connect(
		_on_wall_jump_availability_changed
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(hud_toggle_action):
		set_hud_visible(not _is_hud_visible)
		get_viewport().set_input_as_handled()
		return

	if not _is_hud_visible:
		return

	if event is InputEventMouseMotion:
		crosshair.register_look_delta(
			event.screen_relative
		)

func register_look_delta(
	mouse_delta: Vector2
) -> void:
	if not _is_hud_visible:
		return

	crosshair.register_look_delta(mouse_delta)

	speed_hud.register_look_delta(mouse_delta)

	fall_danger_hud.register_look_delta(mouse_delta)

	reverse_stamina_hud.register_look_delta(
		mouse_delta
	)

	dash_charges_hud.register_look_delta(
		mouse_delta
	)

	wall_jump_charges_hud.register_look_delta(
		mouse_delta
	)

func set_hud_visible(value: bool) -> void:
	_is_hud_visible = value
	visible = _is_hud_visible

func is_hud_visible() -> bool:
	return _is_hud_visible

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
