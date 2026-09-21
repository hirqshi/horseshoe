class_name InputBindingRow
extends Control

signal binding_requested(
	action_id: StringName,
	slot_index: int
)

@export var action_id: StringName = &""
@export var action_label: Label
@export var primary_bind_button: Button
@export var secondary_bind_button: Button


func _ready() -> void:
	if action_id.is_empty():
		push_error(
			"InputBindingRow '%s' requires an action_id."
			% name
		)
		return

	if primary_bind_button != null:
		primary_bind_button.pressed.connect(
			_on_primary_bind_button_pressed
		)

	if secondary_bind_button != null:
		secondary_bind_button.pressed.connect(
			_on_secondary_bind_button_pressed
		)

	_connect_ui_audio()

	refresh()


func refresh() -> void:
	if action_id.is_empty():
		return

	var slot_count: int = GameSettings.get_action_bind_slot_count(
		action_id
	)

	if action_label != null:
		action_label.text = _get_display_label()

	if primary_bind_button != null:
		primary_bind_button.visible = true
		primary_bind_button.text = (
			GameSettings.get_action_binding_display_name(
				action_id,
				0
			)
		)

	if secondary_bind_button != null:
		secondary_bind_button.visible = slot_count > 1

		if slot_count > 1:
			secondary_bind_button.text = (
				GameSettings.get_action_binding_display_name(
					action_id,
					1
				)
			)


func _connect_ui_audio() -> void:
	if UiAudio == null:
		return

	if primary_bind_button != null:
		UiAudio.connect_button(primary_bind_button)

	if secondary_bind_button != null:
		UiAudio.connect_button(secondary_bind_button)


func _get_display_label() -> String:
	return String(
		action_id
	).replace(
		"_",
		" "
	).to_upper()


func _on_primary_bind_button_pressed() -> void:
	binding_requested.emit(
		action_id,
		0
	)


func _on_secondary_bind_button_pressed() -> void:
	binding_requested.emit(
		action_id,
		1
	)
