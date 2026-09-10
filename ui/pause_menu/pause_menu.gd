class_name PauseMenu
extends CanvasLayer

enum ConfirmationAction {
	NONE,
	RESTART_CHAPTER,
	RETURN_TO_MAIN_MENU,
}

@export_group("Panels")
@export var pause_panel: Control
@export var settings_menu: SettingsMenu
@export var confirm_panel: ConfirmPanel

@export_group("Buttons")
@export var resume_button: Button
@export var settings_button: Button
@export var restart_button: Button
@export var main_menu_button: Button

@export_group("Input")
@export var pause_action: StringName = &"pause"

var is_open: bool = false

var _player: Player = null
var _look_controller: PlayerLookController = null
var _pending_confirmation_action: int = (
	ConfirmationAction.NONE
)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_validate_references()
	_connect_signals()

	visible = false

	if pause_panel != null:
		pause_panel.visible = false

	if settings_menu != null:
		settings_menu.visible = false


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event.is_action_pressed(
		pause_action
	):
		return

	if confirm_panel != null and confirm_panel.is_open():
		return

	if settings_menu != null and settings_menu.visible:
		return

	if is_open:
		resume()
	else:
		open()

	get_viewport().set_input_as_handled()


func setup(
	player: Player
) -> void:
	if _player != null:
		push_warning(
			"PauseMenu.setup() was called more than once."
		)
		return

	if player == null:
		push_error(
			"PauseMenu requires a Player."
		)
		return

	_player = player

	_look_controller = _player.get_look_controller()

	if _look_controller == null:
		push_error(
			"PauseMenu could not get PlayerLookController from Player."
		)


func open() -> void:
	if is_open:
		return

	if _player == null:
		push_error(
			"PauseMenu cannot open before setup."
		)
		return

	is_open = true

	if pause_panel != null:
		pause_panel.visible = true

	visible = true

	if _look_controller != null:
		_look_controller.set_is_enabled(
			false
		)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().paused = true

	if resume_button != null:
		resume_button.grab_focus()


func resume() -> void:
	if not is_open:
		return

	_pending_confirmation_action = (
		ConfirmationAction.NONE
	)

	if confirm_panel != null and confirm_panel.is_open():
		confirm_panel.cancel()

	if settings_menu != null:
		settings_menu.visible = false

	if pause_panel != null:
		pause_panel.visible = false

	get_tree().paused = false

	if _look_controller != null:
		_look_controller.set_is_enabled(
			true
		)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	is_open = false
	visible = false


func _close_for_scene_change() -> void:
	_pending_confirmation_action = (
		ConfirmationAction.NONE
	)

	if confirm_panel != null and confirm_panel.is_open():
		confirm_panel.cancel()

	if settings_menu != null:
		settings_menu.visible = false

	if pause_panel != null:
		pause_panel.visible = false

	get_tree().paused = false

	is_open = false
	visible = false


func _validate_references() -> void:
	if pause_panel == null:
		push_error(
			"PauseMenu requires a PausePanel."
		)

	if settings_menu == null:
		push_error(
			"PauseMenu requires a SettingsMenu."
		)

	if confirm_panel == null:
		push_error(
			"PauseMenu requires a ConfirmPanel."
		)

	if resume_button == null:
		push_error(
			"PauseMenu requires a ResumeButton."
		)

	if settings_button == null:
		push_error(
			"PauseMenu requires a SettingsButton."
		)

	if restart_button == null:
		push_error(
			"PauseMenu requires a RestartButton."
		)

	if main_menu_button == null:
		push_error(
			"PauseMenu requires a MainMenuButton."
		)


func _connect_signals() -> void:
	if resume_button != null:
		resume_button.pressed.connect(
			_on_resume_button_pressed
		)

	if settings_button != null:
		settings_button.pressed.connect(
			_on_settings_button_pressed
		)

	if restart_button != null:
		restart_button.pressed.connect(
			_on_restart_button_pressed
		)

	if main_menu_button != null:
		main_menu_button.pressed.connect(
			_on_main_menu_button_pressed
		)

	if settings_menu != null:
		settings_menu.closed.connect(
			_on_settings_menu_closed
		)

	if confirm_panel != null:
		confirm_panel.confirmed.connect(
			_on_confirm_panel_confirmed
		)

		confirm_panel.cancelled.connect(
			_on_confirm_panel_cancelled
		)


func _on_resume_button_pressed() -> void:
	resume()


func _on_settings_button_pressed() -> void:
	if settings_menu == null:
		return

	if pause_panel != null:
		pause_panel.visible = false

	settings_menu.present(
		SettingsMenu.Page.VIDEO
	)


func _on_restart_button_pressed() -> void:
	if confirm_panel == null:
		return

	_pending_confirmation_action = (
		ConfirmationAction.RESTART_CHAPTER
	)

	confirm_panel.present(
		"RESTART CHAPTER",
		(
			"RESTART THE CURRENT CHAPTER?\n"
			+ "YOU WILL RETURN TO THE INITIAL SPAWN."
		),
		"RESTART",
		"CANCEL"
	)


func _on_main_menu_button_pressed() -> void:
	if confirm_panel == null:
		return

	_pending_confirmation_action = (
		ConfirmationAction.RETURN_TO_MAIN_MENU
	)

	confirm_panel.present(
		"RETURN TO MAIN MENU",
		(
			"RETURN TO MAIN MENU?\n"
			+ "CURRENT PROGRESS HAS BEEN SAVED."
		),
		"RETURN",
		"CANCEL"
	)


func _on_settings_menu_closed() -> void:
	if not is_open:
		return

	if pause_panel != null:
		pause_panel.visible = true

	if settings_button != null:
		settings_button.grab_focus()


func _on_confirm_panel_confirmed() -> void:
	if (
		_pending_confirmation_action
		== ConfirmationAction.RESTART_CHAPTER
	):
		_close_for_scene_change()

		SceneManager.restart_current_chapter()
		return

	if (
		_pending_confirmation_action
		== ConfirmationAction.RETURN_TO_MAIN_MENU
	):
		_close_for_scene_change()

		SceneManager.return_to_main_menu()
		return

	_pending_confirmation_action = (
		ConfirmationAction.NONE
	)


func _on_confirm_panel_cancelled() -> void:
	_pending_confirmation_action = (
		ConfirmationAction.NONE
	)
