class_name MainMenu
extends Control

@export_group("Panels")
@export var main_panel: Control
@export var save_slot_select: SaveSlotSelect
@export var chapter_select: ChapterSelect
@export var settings_menu: SettingsMenu

@export_group("Main Buttons")
@export var continue_button: Button
@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var status_label: Label

@export_group("Dialogs")
@export var confirm_panel: ConfirmPanel

var _pending_clear_slot_index: int = -1


func _ready() -> void:
	_validate_references()
	_connect_signals()

	_show_main_panel()


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event.is_action_pressed(
		"ui_cancel"
	):
		return

	if confirm_panel != null and confirm_panel.is_open():
		confirm_panel.cancel()

		get_viewport().set_input_as_handled()
		return

	if chapter_select != null and chapter_select.visible:
		_show_save_slot_select()

		get_viewport().set_input_as_handled()
		return

	if save_slot_select != null and save_slot_select.visible:
		_show_main_panel()

		get_viewport().set_input_as_handled()


func _validate_references() -> void:
	if main_panel == null:
		push_error(
			"MainMenu requires a MainPanel."
		)

	if save_slot_select == null:
		push_error(
			"MainMenu requires a SaveSlotSelect."
		)

	if chapter_select == null:
		push_error(
			"MainMenu requires a ChapterSelect."
		)
		
	if settings_menu == null:
		push_error(
			"MainMenu requires a SettingsMenu."
		)
		
	if continue_button == null:
		push_error(
			"MainMenu requires a ContinueButton."
		)

	if start_button == null:
		push_error(
			"MainMenu requires a StartButton."
		)

	if settings_button == null:
		push_error(
			"MainMenu requires a SettingsButton."
		)

	if quit_button == null:
		push_error(
			"MainMenu requires a QuitButton."
		)

	if confirm_panel == null:
		push_error(
			"MainMenu requires a ConfirmPanel."
		)


func _connect_signals() -> void:
	if continue_button != null:
		continue_button.pressed.connect(
			_on_continue_button_pressed
		)

	if start_button != null:
		start_button.pressed.connect(
			_on_start_button_pressed
		)

	if settings_button != null:
		settings_button.pressed.connect(
			_on_settings_button_pressed
		)

	if quit_button != null:
		quit_button.pressed.connect(
			_on_quit_button_pressed
		)

	if save_slot_select != null:
		save_slot_select.slot_selected.connect(
			_on_save_slot_selected
		)

		save_slot_select.clear_requested.connect(
			_on_save_slot_clear_requested
		)

		save_slot_select.back_requested.connect(
			_show_main_panel
		)

	if chapter_select != null:
		chapter_select.back_requested.connect(
			_show_save_slot_select
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

	if GameSettings != null:
		GameSettings.last_selected_save_slot_changed.connect(
			_on_last_selected_save_slot_changed
		)


func _show_main_panel() -> void:
	if main_panel != null:
		main_panel.visible = true

	if save_slot_select != null:
		save_slot_select.visible = false

	if chapter_select != null:
		chapter_select.visible = false

	_pending_clear_slot_index = -1

	_set_status_text(
		""
	)

	_refresh_continue_button()

	if continue_button != null and not continue_button.disabled:
		continue_button.grab_focus()
	elif start_button != null:
		start_button.grab_focus()


func _show_save_slot_select() -> void:
	if main_panel != null:
		main_panel.visible = false

	if save_slot_select != null:
		save_slot_select.visible = true
		save_slot_select.refresh()

	if chapter_select != null:
		chapter_select.visible = false

	_pending_clear_slot_index = -1


func _show_chapter_select() -> void:
	if main_panel != null:
		main_panel.visible = false

	if save_slot_select != null:
		save_slot_select.visible = false

	if chapter_select != null:
		chapter_select.visible = true
		chapter_select.refresh()

	_pending_clear_slot_index = -1


func _refresh_continue_button() -> void:
	if continue_button == null:
		return

	continue_button.disabled = not GameSettings.has_continue_slot()


func _set_status_text(
	value: String
) -> void:
	if status_label == null:
		return

	status_label.text = value


func _on_continue_button_pressed() -> void:
	if not GameSettings.has_continue_slot():
		_refresh_continue_button()
		return

	var slot_index: int = (
		GameSettings.last_selected_save_slot_index
	)

	var was_loaded: bool = SaveManager.load_or_create_profile(
		slot_index
	)

	if not was_loaded:
		_set_status_text(
			"FAILED TO LOAD SAVE SLOT."
		)

		_refresh_continue_button()
		return

	SceneManager.continue_active_profile()


func _on_start_button_pressed() -> void:
	_show_save_slot_select()


func _on_settings_button_pressed() -> void:
	if settings_menu == null:
		return

	if main_panel != null:
		main_panel.visible = false

	settings_menu.present(
		SettingsMenu.Page.VIDEO
	)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_save_slot_selected(
	slot_index: int
) -> void:
	GameSettings.set_last_selected_save_slot(
		slot_index
	)

	_show_chapter_select()


func _on_save_slot_clear_requested(
	slot_index: int
) -> void:
	if confirm_panel == null:
		push_error(
			"MainMenu requires a ConfirmPanel."
		)
		return

	_pending_clear_slot_index = slot_index

	confirm_panel.present(
		"DELETE SAVE SLOT",
		(
			"DELETE SAVE SLOT %d PERMANENTLY?\n"
			+ "THIS ACTION CANNOT BE UNDONE."
		)
		% (
			slot_index + 1
		),
		"DELETE",
		"CANCEL"
	)


func _on_confirm_panel_confirmed() -> void:
	if _pending_clear_slot_index < 0:
		return

	var deleted_slot_index: int = _pending_clear_slot_index

	var was_deleted: bool = SaveManager.delete_profile(
		deleted_slot_index
	)

	if not was_deleted:
		_set_status_text(
			"FAILED TO DELETE SAVE SLOT %d."
			% (
				deleted_slot_index + 1
			)
		)
	else:
		if (
			GameSettings.last_selected_save_slot_index
			== deleted_slot_index
		):
			GameSettings.set_last_selected_save_slot(
				-1
			)

		_set_status_text(
			"SAVE SLOT %d CLEARED."
			% (
				deleted_slot_index + 1
			)
		)

		if save_slot_select != null:
			save_slot_select.refresh()

	_refresh_continue_button()

	_pending_clear_slot_index = -1


func _on_confirm_panel_cancelled() -> void:
	_pending_clear_slot_index = -1


func _on_last_selected_save_slot_changed(
	_slot_index: int
) -> void:
	_refresh_continue_button()


func _on_settings_menu_closed() -> void:
	_show_main_panel()
