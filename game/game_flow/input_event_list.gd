class_name InputEventList
extends RefCounted

var events: Array[InputEvent] = []


func set_events(
	source_events: Array[InputEvent]
) -> void:
	events.clear()

	for input_event: InputEvent in source_events:
		var copied_event: InputEvent = (
			input_event.duplicate(
				true
			) as InputEvent
		)

		if copied_event == null:
			continue

		events.append(
			copied_event
		)


func get_events_copy() -> Array[InputEvent]:
	var result: Array[InputEvent] = []

	for input_event: InputEvent in events:
		var copied_event: InputEvent = (
			input_event.duplicate(
				true
			) as InputEvent
		)

		if copied_event == null:
			continue

		result.append(
			copied_event
		)

	return result
