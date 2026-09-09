class_name AudioSettingRow
extends Control

@export var bus_name: StringName = &"Master"
@export var bus_label: Label
@export var volume_slider: HSlider
@export var volume_value_label: Label


func _ready() -> void:
	if volume_slider == null:
		push_error(
			"AudioSettingRow requires a VolumeSlider."
		)
		return

	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0

	volume_slider.value_changed.connect(
		_on_volume_changed
	)

	refresh()


func refresh() -> void:
	var bus_index: int = AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		visible = false
		return

	visible = true

	if bus_label != null:
		bus_label.text = String(
			bus_name
		).to_upper()

	var volume_db: float = GameSettings.get_bus_volume_db(
		bus_name
	)

	var volume_linear: float = _db_to_linear_safe(
		volume_db
	)

	volume_slider.set_value_no_signal(
		roundf(
			volume_linear * 100.0
		)
	)

	_refresh_value_label()


func _on_volume_changed(
	value: float
) -> void:
	var volume_linear: float = value / 100.0

	GameSettings.set_bus_volume_db(
		bus_name,
		_linear_to_db_safe(
			volume_linear
		)
	)

	_refresh_value_label()


func _refresh_value_label() -> void:
	if volume_value_label == null:
		return

	volume_value_label.text = "%d%%" % roundi(
		volume_slider.value
	)


func _linear_to_db_safe(
	value: float
) -> float:
	if value <= 0.0001:
		return GameSettings.MIN_BUS_VOLUME_DB

	return linear_to_db(
		value
	)


func _db_to_linear_safe(
	value_db: float
) -> float:
	if value_db <= GameSettings.MIN_BUS_VOLUME_DB:
		return 0.0

	return db_to_linear(
		value_db
	)
