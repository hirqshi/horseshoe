extends Node

@export_category("audio players")
@export var click_player: AudioStreamPlayer
@export var hover_player: AudioStreamPlayer
@export var game_start_player: AudioStreamPlayer
@export var pause_open_player: AudioStreamPlayer
@export var pause_close_player: AudioStreamPlayer
@export var quit_to_menu_player: AudioStreamPlayer
@export var settings_close_player: AudioStreamPlayer

@export_category("polyphony")
@export_range(1, 16, 1) var click_max_polyphony: int = 4
@export_range(1, 16, 1) var hover_max_polyphony: int = 4

@export_category("streams")
@export var click_streams: Array[AudioStream] = []
@export var hover_streams: Array[AudioStream] = []
@export var game_start_streams: Array[AudioStream] = []
@export var pause_open_streams: Array[AudioStream] = []
@export var pause_close_streams: Array[AudioStream] = []
@export var quit_to_menu_streams: Array[AudioStream] = []
@export var settings_close_streams: Array[AudioStream] = []

@export_category("random pitch")
@export_range(0.1, 3.0, 0.01) var click_pitch_min: float = 0.97
@export_range(0.1, 3.0, 0.01) var click_pitch_max: float = 1.03
@export_range(0.1, 3.0, 0.01) var hover_pitch_min: float = 0.97
@export_range(0.1, 3.0, 0.01) var hover_pitch_max: float = 1.03

@export_category("global click detection")
@export var global_click_bus: StringName = &"UiSfx"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_validate_players()
	_configure_audio_players()


func _input(event: InputEvent) -> void:
	if not _is_ui_context_active():
		return

	var mouse_button_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_button_event == null:
		return

	if not mouse_button_event.pressed:
		return

	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return

	play_click()


func _is_ui_context_active() -> bool:
	return Input.mouse_mode != Input.MOUSE_MODE_CAPTURED


func play_click() -> void:
	_play_random_stream(
		click_player,
		click_streams,
		click_pitch_min,
		click_pitch_max
	)


func play_hover() -> void:
	_play_random_stream(
		hover_player,
		hover_streams,
		hover_pitch_min,
		hover_pitch_max
	)


func play_game_start() -> void:
	_play_random_stream(
		game_start_player,
		game_start_streams,
		1.0,
		1.0
	)


func play_pause_open() -> void:
	_play_random_stream(
		pause_open_player,
		pause_open_streams,
		1.0,
		1.0
	)


func play_pause_close() -> void:
	_play_random_stream(
		pause_close_player,
		pause_close_streams,
		1.0,
		1.0
	)


func play_quit_to_menu() -> void:
	_play_random_stream(
		quit_to_menu_player,
		quit_to_menu_streams,
		1.0,
		1.0
	)


func play_settings_close() -> void:
	_play_random_stream(
		settings_close_player,
		settings_close_streams,
		1.0,
		1.0
	)


func connect_button(button: Button) -> void:
	if button == null:
		return

	if not button.mouse_entered.is_connected(play_hover):
		button.mouse_entered.connect(play_hover)


func connect_buttons(buttons: Array[Button]) -> void:
	for button: Button in buttons:
		connect_button(button)


func _play_random_stream(
	audio_player: AudioStreamPlayer,
	streams: Array[AudioStream],
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

	audio_player.stream = streams[stream_index]
	audio_player.pitch_scale = randf_range(
		random_pitch_min,
		random_pitch_max
	)
	audio_player.play()


func _validate_players() -> void:
	if click_player == null:
		push_warning("UiAudio has no ClickPlayer.")

	if hover_player == null:
		push_warning("UiAudio has no HoverPlayer.")

	if game_start_player == null:
		push_warning("UiAudio has no GameStartPlayer.")

	if pause_open_player == null:
		push_warning("UiAudio has no PauseOpenPlayer.")

	if pause_close_player == null:
		push_warning("UiAudio has no PauseClosePlayer.")

	if quit_to_menu_player == null:
		push_warning("UiAudio has no QuitToMenuPlayer.")

	if settings_close_player == null:
		push_warning("UiAudio has no SettingsClosePlayer.")


func _configure_audio_players() -> void:
	_configure_player(click_player, click_max_polyphony)
	_configure_player(hover_player, hover_max_polyphony)
	_configure_player(game_start_player, 1)
	_configure_player(pause_open_player, 1)
	_configure_player(pause_close_player, 1)
	_configure_player(quit_to_menu_player, 1)
	_configure_player(settings_close_player, 1)


func _configure_player(
	audio_player: AudioStreamPlayer,
	max_polyphony: int
) -> void:
	if audio_player == null:
		return

	audio_player.bus = global_click_bus
	audio_player.max_polyphony = max_polyphony
