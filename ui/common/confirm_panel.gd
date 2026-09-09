class_name ConfirmPanel
extends Control

signal confirmed()
signal cancelled()

@export var title_label: Label
@export var message_label: Label
@export var confirm_button: Button
@export var cancel_button: Button

var _is_open: bool = false


func _ready() -> void:
	if confirm_button == null:
		push_error(
			"ConfirmPanel requires a ConfirmButton."
		)
		return

	if cancel_button == null:
		push_error(
			"ConfirmPanel requires a CancelButton."
		)
		return

	confirm_button.pressed.connect(
		_on_confirm_button_pressed
	)

	cancel_button.pressed.connect(
		_on_cancel_button_pressed
	)

	visible = false


func _unhandled_input(
	event: InputEvent
) -> void:
	if not _is_open:
		return

	if not event.is_action_pressed(
		"ui_cancel"
	):
		return

	cancel()
	get_viewport().set_input_as_handled()


func present(
	title: String,
	message: String,
	confirm_text: String = "CONFIRM",
	cancel_text: String = "CANCEL"
) -> void:
	if title_label != null:
		title_label.text = title

	if message_label != null:
		message_label.text = message

	if confirm_button != null:
		confirm_button.text = confirm_text

	if cancel_button != null:
		cancel_button.text = cancel_text

	_is_open = true
	visible = true

	if cancel_button != null:
		cancel_button.grab_focus()


func confirm() -> void:
	if not _is_open:
		return

	_is_open = false
	visible = false

	confirmed.emit()


func cancel() -> void:
	if not _is_open:
		return

	_is_open = false
	visible = false

	cancelled.emit()


func is_open() -> bool:
	return _is_open


func _on_confirm_button_pressed() -> void:
	confirm()


func _on_cancel_button_pressed() -> void:
	cancel()
