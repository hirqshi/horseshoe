class_name InputCapturePanel
extends Control

signal binding_captured(
	action_id: StringName,
	slot_index: int,
	input_event: InputEvent
)

signal capture_cancelled()

@export var title_label: Label
@export var message_label: Label
@export var cancel_button: Button

var _is_capturing: bool = false
var _target_action_id: StringName = &""
var _target_slot_index: int = -1


func _ready() -> void:
	if cancel_button != null:
		cancel_button.pressed.connect(
			cancel_capture
		)

	visible = false


func _input(
	event: InputEvent
) -> void:
	if not _is_capturing:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = (
			event as InputEventKey
		)

		if not key_event.pressed:
			return

		if key_event.echo:
			return

		if (
			key_event.physical_keycode == Key.KEY_ESCAPE
			and _target_action_id != &"pause"
		):
			cancel_capture()

			get_viewport().set_input_as_handled()
			return

		_complete_capture(
			key_event
		)

		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)

		if not mouse_event.pressed:
			return

		if not _is_supported_mouse_button(
			mouse_event.button_index
		):
			return

		_complete_capture(
			mouse_event
		)

		get_viewport().set_input_as_handled()


func begin_capture(
	action_id: StringName,
	slot_index: int
) -> void:
	if action_id.is_empty():
		return

	if slot_index < 0:
		return

	_target_action_id = action_id
	_target_slot_index = slot_index

	if title_label != null:
		title_label.text = "ASSIGN INPUT"

	if message_label != null:
		message_label.text = (
			"%s - SLOT %d\n\nPRESS A KEY OR MOUSE BUTTON\nESC TO CANCEL"
			% [
				String(action_id).replace(
					"_",
					" "
				).to_upper(),
				slot_index + 1,
			]
		)

	_is_capturing = true
	visible = true

	if cancel_button != null:
		cancel_button.grab_focus()


func cancel_capture() -> void:
	if not _is_capturing:
		return

	_is_capturing = false
	_target_action_id = &""
	_target_slot_index = -1

	visible = false

	capture_cancelled.emit()


func _complete_capture(
	input_event: InputEvent
) -> void:
	if not _is_capturing:
		return

	var captured_action_id: StringName = _target_action_id
	var captured_slot_index: int = _target_slot_index

	_is_capturing = false
	_target_action_id = &""
	_target_slot_index = -1

	visible = false

	binding_captured.emit(
		captured_action_id,
		captured_slot_index,
		input_event
	)


func _is_supported_mouse_button(
	button_index: MouseButton
) -> bool:
	return (
		button_index == MOUSE_BUTTON_LEFT
		or button_index == MOUSE_BUTTON_RIGHT
		or button_index == MOUSE_BUTTON_MIDDLE
		or button_index == MOUSE_BUTTON_XBUTTON1
		or button_index == MOUSE_BUTTON_XBUTTON2
	)
