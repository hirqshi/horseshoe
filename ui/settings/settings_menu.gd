class_name SettingsMenu
extends Control

signal closed()

enum Page {
	VIDEO,
	AUDIO,
	INPUT,
}

@export_group("Tabs")
@export var video_tab_button: Button
@export var audio_tab_button: Button
@export var input_tab_button: Button

@export_group("Panels")
@export var video_panel: VideoSettingsPanel
@export var audio_panel: AudioSettingsPanel
@export var input_panel: Control

@export_group("Navigation")
@export var back_button: Button

var _current_page: int = Page.VIDEO


func _ready() -> void:
	_validate_references()
	_connect_signals()
	_connect_ui_audio()

	visible = false


func _unhandled_input(
	event: InputEvent
) -> void:
	if not visible:
		return

	if not event.is_action_pressed(
		"ui_cancel"
	):
		return

	close()
	get_viewport().set_input_as_handled()


func present(
	initial_page: int = Page.VIDEO
) -> void:
	visible = true

	show_page(
		initial_page
	)


func close() -> void:
	visible = false

	closed.emit()


func show_page(
	page: int
) -> void:
	if (
		page != Page.VIDEO
		and page != Page.AUDIO
		and page != Page.INPUT
	):
		push_error(
			"SettingsMenu received an invalid page id %d."
			% page
		)
		return

	_current_page = page

	if video_panel != null:
		video_panel.visible = (
			_current_page == Page.VIDEO
		)

	if audio_panel != null:
		audio_panel.visible = (
			_current_page == Page.AUDIO
		)

	if input_panel != null:
		input_panel.visible = (
			_current_page == Page.INPUT
		)

	_refresh_current_page()
	_refresh_tab_visuals()
	_focus_current_tab()


func _validate_references() -> void:
	if video_tab_button == null:
		push_error(
			"SettingsMenu requires a VideoTabButton."
		)

	if audio_tab_button == null:
		push_error(
			"SettingsMenu requires an AudioTabButton."
		)

	if input_tab_button == null:
		push_error(
			"SettingsMenu requires an InputTabButton."
		)

	if video_panel == null:
		push_error(
			"SettingsMenu requires a VideoPanel."
		)

	if audio_panel == null:
		push_error(
			"SettingsMenu requires an AudioPanel."
		)

	if input_panel == null:
		push_error(
			"SettingsMenu requires an InputPanel."
		)

	if back_button == null:
		push_error(
			"SettingsMenu requires a BackButton."
		)


func _connect_signals() -> void:
	if video_tab_button != null:
		video_tab_button.pressed.connect(
			_on_video_tab_button_pressed
		)

	if audio_tab_button != null:
		audio_tab_button.pressed.connect(
			_on_audio_tab_button_pressed
		)

	if input_tab_button != null:
		input_tab_button.pressed.connect(
			_on_input_tab_button_pressed
		)

	if back_button != null:
		back_button.pressed.connect(
			_on_back_button_pressed
		)


func _connect_ui_audio() -> void:
	if UiAudio == null:
		return

	var buttons: Array[Button] = [
		video_tab_button,
		audio_tab_button,
		input_tab_button,
		back_button,
	]

	UiAudio.connect_buttons(buttons)


func _refresh_current_page() -> void:
	if _current_page == Page.VIDEO:
		if video_panel != null:
			video_panel.refresh()
		return

	if _current_page == Page.AUDIO:
		if audio_panel != null:
			audio_panel.refresh()
		return


func _refresh_tab_visuals() -> void:
	if video_tab_button != null:
		video_tab_button.button_pressed = (
			_current_page == Page.VIDEO
		)

	if audio_tab_button != null:
		audio_tab_button.button_pressed = (
			_current_page == Page.AUDIO
		)

	if input_tab_button != null:
		input_tab_button.button_pressed = (
			_current_page == Page.INPUT
		)


func _focus_current_tab() -> void:
	if _current_page == Page.VIDEO:
		if video_tab_button != null:
			video_tab_button.grab_focus()
		return

	if _current_page == Page.AUDIO:
		if audio_tab_button != null:
			audio_tab_button.grab_focus()
		return

	if _current_page == Page.INPUT:
		if input_tab_button != null:
			input_tab_button.grab_focus()


func _on_video_tab_button_pressed() -> void:
	show_page(
		Page.VIDEO
	)


func _on_audio_tab_button_pressed() -> void:
	show_page(
		Page.AUDIO
	)


func _on_input_tab_button_pressed() -> void:
	show_page(
		Page.INPUT
	)


func _on_back_button_pressed() -> void:
	close()
