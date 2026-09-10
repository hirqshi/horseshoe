class_name InputSettingsPanel
extends Control

@export_group("Mouse Look")
@export var sensitivity_slider: HSlider
@export var sensitivity_value_label: Label
@export var invert_horizontal_button: Button
@export var invert_vertical_button: Button

@export_group("Bindings")
@export var binding_rows: Array[InputBindingRow] = []
@export var reset_defaults_button: Button

@export_group("Overlays")
@export var input_capture_panel: InputCapturePanel
@export var confirm_panel: ConfirmPanel

var _is_refreshing: bool = false
var _is_reset_confirmation_pending: bool = false


func _ready() -> void:
	_validate_references()
	_setup_controls()
	_connect_signals()

	refresh()


func refresh() -> void:
	_is_refreshing = true

	if sensitivity_slider != null:
		sensitivity_slider.value = (
			GameSettings.mouse_sensitivity
		)

	if invert_horizontal_button != null:
		invert_horizontal_button.button_pressed = (
			GameSettings.is_horizontal_look_inverted
		)

	if invert_vertical_button != null:
		invert_vertical_button.button_pressed = (
			GameSettings.is_vertical_look_inverted
		)

	_refresh_sensitivity_label()

	for binding_row: InputBindingRow in binding_rows:
		if binding_row == null:
			continue

		binding_row.refresh()

	_is_refreshing = false


func _validate_references() -> void:
	if sensitivity_slider == null:
		push_error(
			"InputSettingsPanel requires a SensitivitySlider."
		)

	if sensitivity_value_label == null:
		push_error(
			"InputSettingsPanel requires a SensitivityValueLabel."
		)

	if invert_horizontal_button == null:
		push_error(
			"InputSettingsPanel requires an InvertHorizontalButton."
		)

	if invert_vertical_button == null:
		push_error(
			"InputSettingsPanel requires an InvertVerticalButton."
		)

	if input_capture_panel == null:
		push_error(
			"InputSettingsPanel requires an InputCapturePanel."
		)

	if confirm_panel == null:
		push_error(
			"InputSettingsPanel requires a ConfirmPanel."
		)


func _setup_controls() -> void:
	if sensitivity_slider != null:
		sensitivity_slider.min_value = (
			GameSettings.MIN_MOUSE_SENSITIVITY
		)

		sensitivity_slider.max_value = (
			GameSettings.MAX_MOUSE_SENSITIVITY
		)

		sensitivity_slider.step = 0.0001

	if invert_horizontal_button != null:
		invert_horizontal_button.toggle_mode = true

	if invert_vertical_button != null:
		invert_vertical_button.toggle_mode = true


func _connect_signals() -> void:
	if sensitivity_slider != null:
		sensitivity_slider.value_changed.connect(
			_on_sensitivity_changed
		)

	if invert_horizontal_button != null:
		invert_horizontal_button.toggled.connect(
			_on_invert_horizontal_toggled
		)

	if invert_vertical_button != null:
		invert_vertical_button.toggled.connect(
			_on_invert_vertical_toggled
		)

	for binding_row: InputBindingRow in binding_rows:
		if binding_row == null:
			continue

		binding_row.binding_requested.connect(
			_on_binding_requested
		)

	if reset_defaults_button != null:
		reset_defaults_button.pressed.connect(
			_on_reset_defaults_pressed
		)

	if input_capture_panel != null:
		input_capture_panel.binding_captured.connect(
			_on_binding_captured
		)

	if confirm_panel != null:
		confirm_panel.confirmed.connect(
			_on_confirm_panel_confirmed
		)

		confirm_panel.cancelled.connect(
			_on_confirm_panel_cancelled
		)


func _refresh_sensitivity_label() -> void:
	if sensitivity_value_label == null:
		return

	var normalized_sensitivity: float = inverse_lerp(
		GameSettings.MIN_MOUSE_SENSITIVITY,
		GameSettings.MAX_MOUSE_SENSITIVITY,
		sensitivity_slider.value
	)

	sensitivity_value_label.text = "%d%%" % roundi(
		normalized_sensitivity * 100.0
	)


func _on_sensitivity_changed(
	value: float
) -> void:
	if _is_refreshing:
		return

	GameSettings.set_mouse_look_settings(
		value,
		GameSettings.is_horizontal_look_inverted,
		GameSettings.is_vertical_look_inverted
	)

	_refresh_sensitivity_label()


func _on_invert_horizontal_toggled(
	is_pressed: bool
) -> void:
	if _is_refreshing:
		return

	GameSettings.set_mouse_look_settings(
		GameSettings.mouse_sensitivity,
		is_pressed,
		GameSettings.is_vertical_look_inverted
	)


func _on_invert_vertical_toggled(
	is_pressed: bool
) -> void:
	if _is_refreshing:
		return

	GameSettings.set_mouse_look_settings(
		GameSettings.mouse_sensitivity,
		GameSettings.is_horizontal_look_inverted,
		is_pressed
	)


func _on_binding_requested(
	action_id: StringName,
	slot_index: int
) -> void:
	if input_capture_panel == null:
		return

	input_capture_panel.begin_capture(
		action_id,
		slot_index
	)


func _on_binding_captured(
	action_id: StringName,
	slot_index: int,
	input_event: InputEvent
) -> void:
	var was_rebound: bool = GameSettings.rebind_action_slot(
		action_id,
		slot_index,
		input_event
	)

	if not was_rebound:
		return

	refresh()


func _on_reset_defaults_pressed() -> void:
	if confirm_panel == null:
		return

	_is_reset_confirmation_pending = true

	confirm_panel.present(
		"RESET INPUT",
		"RESET ALL INPUT BINDINGS TO DEFAULTS?",
		"RESET",
		"CANCEL"
	)


func _on_confirm_panel_confirmed() -> void:
	if not _is_reset_confirmation_pending:
		return

	GameSettings.reset_input_bindings_to_defaults()

	_is_reset_confirmation_pending = false

	refresh()


func _on_confirm_panel_cancelled() -> void:
	_is_reset_confirmation_pending = false
