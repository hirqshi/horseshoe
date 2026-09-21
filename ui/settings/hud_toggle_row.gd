class_name HudToggleRow
extends Control

## if left empty, the id is derived from this node's name
## (e.g. node "PitchIndicatorRow" -> "pitch_indicator",
## stripping a trailing "_row" if present).
@export var element_id: StringName = &""

@export var element_label: Label
@export var enabled_checkbox: CheckBox


func setup() -> void:
	if enabled_checkbox == null:
		push_error(
			"HudToggleRow requires an EnabledCheckbox."
		)
		return

	if element_id == &"":
		element_id = _derive_id_from_node_name()

	if not enabled_checkbox.toggled.is_connected(
		_on_toggled
	):
		enabled_checkbox.toggled.connect(
			_on_toggled
		)

	if element_label != null:
		element_label.text = String(
			element_id
		).to_upper().replace(
			"_",
			" "
		)

	if UiAudio != null:
		UiAudio.connect_button(enabled_checkbox)


func refresh() -> void:
	if enabled_checkbox == null:
		return

	if element_id == &"":
		visible = false
		return

	if GameSettings == null:
		visible = false
		return

	visible = true

	enabled_checkbox.set_pressed_no_signal(
		GameSettings.is_hud_element_enabled(
			element_id
		)
	)


func _derive_id_from_node_name() -> StringName:
	var snake_case_name: String = name.to_snake_case()

	if snake_case_name.ends_with("_row"):
		snake_case_name = snake_case_name.substr(
			0,
			snake_case_name.length() - 4
		)

	return StringName(snake_case_name)


func _on_toggled(
	is_pressed: bool
) -> void:
	if element_id == &"":
		return

	if GameSettings == null:
		return

	GameSettings.set_hud_element_enabled(
		element_id,
		is_pressed
	)
