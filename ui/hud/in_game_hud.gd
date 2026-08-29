class_name InGameHud
extends CanvasLayer

@export var crosshair: CrosshairHudElement
@export var hud_toggle_action: StringName = &"toggle_hud"
@export var speed_hud: SpeedHudElement
@export var fall_danger_hud: FallDangerHud

var _is_hud_visible: bool = true

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
		
	visible = _is_hud_visible

func _on_player_dash_started() -> void:
	crosshair.play_dash_impulse()

func _on_player_slide_started() -> void:
	crosshair.play_slide_impulse()

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

func register_look_delta(mouse_delta: Vector2) -> void:
	if not _is_hud_visible:
		return

	crosshair.register_look_delta(mouse_delta)
	speed_hud.register_look_delta(mouse_delta)
	fall_danger_hud.register_look_delta(mouse_delta)
	

func set_hud_visible(value: bool) -> void:
	_is_hud_visible = value
	visible = _is_hud_visible

func is_hud_visible() -> bool:
	return _is_hud_visible
