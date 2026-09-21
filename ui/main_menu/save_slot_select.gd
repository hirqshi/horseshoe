class_name SaveSlotSelect
extends Control

signal slot_selected(
	slot_index: int
)

signal clear_requested(
	slot_index: int
)

signal back_requested()

@export var slot_entries: Array[SaveSlotEntry] = []
@export var back_button: Button


func _ready() -> void:
	if slot_entries.size() != SaveManager.SLOT_COUNT:
		push_error(
			"SaveSlotSelect requires exactly %d slot entries."
			% SaveManager.SLOT_COUNT
		)

	for slot_entry: SaveSlotEntry in slot_entries:
		if slot_entry == null:
			continue

		slot_entry.slot_selected.connect(
			_on_slot_entry_selected
		)

		slot_entry.clear_requested.connect(
			_on_slot_entry_clear_requested
		)

	if back_button != null:
		back_button.pressed.connect(
			_on_back_button_pressed
		)

	_connect_ui_audio()


func refresh() -> void:
	for slot_index: int in range(
		slot_entries.size()
	):
		var slot_entry: SaveSlotEntry = (
			slot_entries[slot_index]
		)

		if slot_entry == null:
			continue

		var summary: Dictionary[String, Variant] = (
			SaveManager.get_slot_summary(
				slot_index
			)
		)

		slot_entry.set_slot_summary(
			slot_index,
			summary
		)


func _connect_ui_audio() -> void:
	if UiAudio == null:
		return

	if back_button != null:
		UiAudio.connect_button(back_button)


func _on_slot_entry_selected(
	slot_index: int
) -> void:
	var was_loaded: bool = SaveManager.load_or_create_profile(
		slot_index
	)

	if not was_loaded:
		return

	GameSettings.set_last_selected_save_slot(
		slot_index
	)

	slot_selected.emit(
		slot_index
	)


func _on_slot_entry_clear_requested(
	slot_index: int
) -> void:
	clear_requested.emit(
		slot_index
	)


func _on_back_button_pressed() -> void:
	back_requested.emit()
