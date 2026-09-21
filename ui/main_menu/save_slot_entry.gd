class_name SaveSlotEntry
extends Control

signal slot_selected(
	slot_index: int
)

signal clear_requested(
	slot_index: int
)

@export var title_label: Label
@export var stats_label: Label
@export var select_button: Button
@export var clear_button: Button

var _slot_index: int = -1


func _ready() -> void:
	if select_button == null:
		push_error(
			"SaveSlotEntry requires a SelectButton."
		)
		return

	if clear_button == null:
		push_error(
			"SaveSlotEntry requires a ClearButton."
		)
		return

	select_button.pressed.connect(
		_on_select_button_pressed
	)

	clear_button.pressed.connect(
		_on_clear_button_pressed
	)

	if UiAudio != null:
		UiAudio.connect_button(select_button)
		UiAudio.connect_button(clear_button)


func set_slot_summary(
	slot_index: int,
	summary: Dictionary[String, Variant]
) -> void:
	_slot_index = slot_index

	var has_save: bool = bool(
		summary.get(
			"has_save",
			false
		)
	)

	if title_label != null:
		title_label.text = "SAVE SLOT %d" % (
			slot_index + 1
		)

	if stats_label != null:
		if has_save:
			var total_play_time_s: float = float(
				summary.get(
					"total_play_time_s",
					0.0
				)
			)

			var total_deaths: int = int(
				summary.get(
					"total_deaths",
					0
				)
			)

			var highest_chapter_index: int = int(
				summary.get(
					"highest_unlocked_chapter_index",
					0
				)
			)

			stats_label.text = (
				"TIME: %s\n"
				+ "DEATHS: %d\n"
				+ "CHAPTERS UNLOCKED: %d"
			) % [
				_format_duration(
					total_play_time_s
				),
				total_deaths,
				highest_chapter_index + 1,
			]
		else:
			stats_label.text = "EMPTY SLOT"

	if select_button != null:
		select_button.text = (
			"CONTINUE"
			if has_save
			else "NEW GAME"
		)

	if clear_button != null:
		clear_button.disabled = not has_save


func _on_select_button_pressed() -> void:
	if _slot_index < 0:
		return

	slot_selected.emit(
		_slot_index
	)


func _on_clear_button_pressed() -> void:
	if _slot_index < 0:
		return

	clear_requested.emit(
		_slot_index
	)


func _format_duration(
	duration_s: float
) -> String:
	var total_seconds: int = max(
		0,
		roundi(
			duration_s
		)
	)

	var hours: int = total_seconds / 3600
	var minutes: int = (
		total_seconds % 3600
	) / 60
	var seconds: int = total_seconds % 60

	return "%02d:%02d:%02d" % [
		hours,
		minutes,
		seconds,
	]
