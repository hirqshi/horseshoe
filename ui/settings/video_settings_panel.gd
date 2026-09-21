class_name VideoSettingsPanel
extends Control

@export var fullscreen_button: Button
@export var resolution_option_button: OptionButton
@export var vsync_option_button: OptionButton
@export var fps_option_button: OptionButton
@export var brightness_slider: HSlider
@export var brightness_value_label: Label

@export_category("hud toggles")
@export var hud_toggle_rows: Array[HudToggleRow] = []

var _is_refreshing: bool = false

var _resolution_options: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var _fps_options: Array[int] = [
	0,
	30,
	60,
	120,
	144,
	165,
	240,
]


func _ready() -> void:
	_validate_references()
	_setup_controls()
	_connect_signals()

	refresh()


func refresh() -> void:
	if not _has_required_references():
		return

	_is_refreshing = true

	fullscreen_button.button_pressed = (
		GameSettings.is_fullscreen
	)

	_select_resolution(
		GameSettings.windowed_size
	)

	_select_vsync_mode(
		GameSettings.vsync_mode
	)

	_select_max_fps(
		GameSettings.max_fps
	)

	brightness_slider.value = (
		GameSettings.brightness
	)

	_refresh_brightness_label()

	_is_refreshing = false

	_refresh_hud_toggles()


func _validate_references() -> void:
	if fullscreen_button == null:
		push_error(
			"VideoSettingsPanel requires a FullscreenButton."
		)

	if resolution_option_button == null:
		push_error(
			"VideoSettingsPanel requires a ResolutionOptionButton."
		)

	if vsync_option_button == null:
		push_error(
			"VideoSettingsPanel requires a VsyncOptionButton."
		)

	if fps_option_button == null:
		push_error(
			"VideoSettingsPanel requires an FpsOptionButton."
		)

	if brightness_slider == null:
		push_error(
			"VideoSettingsPanel requires a BrightnessSlider."
		)

	if brightness_value_label == null:
		push_error(
			"VideoSettingsPanel requires a BrightnessValueLabel."
		)


func _setup_controls() -> void:
	if fullscreen_button != null:
		fullscreen_button.toggle_mode = true

	if brightness_slider != null:
		brightness_slider.min_value = 0.5
		brightness_slider.max_value = 1.5
		brightness_slider.step = 0.01

	if resolution_option_button != null:
		resolution_option_button.clear()

		for resolution_index: int in range(
			_resolution_options.size()
		):
			var resolution: Vector2i = (
				_resolution_options[resolution_index]
			)

			resolution_option_button.add_item(
				"%d x %d"
				% [
					resolution.x,
					resolution.y,
				],
				resolution_index
			)

	if vsync_option_button != null:
		vsync_option_button.clear()

		vsync_option_button.add_item(
			"OFF",
			DisplayServer.VSYNC_DISABLED
		)

		vsync_option_button.add_item(
			"ON",
			DisplayServer.VSYNC_ENABLED
		)

		vsync_option_button.add_item(
			"ADAPTIVE",
			DisplayServer.VSYNC_ADAPTIVE
		)

		vsync_option_button.add_item(
			"MAILBOX",
			DisplayServer.VSYNC_MAILBOX
		)

	if fps_option_button != null:
		fps_option_button.clear()

		for fps_index: int in range(
			_fps_options.size()
		):
			var fps_value: int = _fps_options[fps_index]

			var label: String = (
				"UNLIMITED"
				if fps_value == 0
				else "%d FPS" % fps_value
			)

			fps_option_button.add_item(
				label,
				fps_value
			)

	for hud_toggle_row: HudToggleRow in hud_toggle_rows:
		if hud_toggle_row == null:
			continue

		hud_toggle_row.setup()


func _connect_signals() -> void:
	if fullscreen_button != null:
		fullscreen_button.toggled.connect(
			_on_fullscreen_toggled
		)

	if resolution_option_button != null:
		resolution_option_button.item_selected.connect(
			_on_resolution_selected
		)

	if vsync_option_button != null:
		vsync_option_button.item_selected.connect(
			_on_vsync_selected
		)

	if fps_option_button != null:
		fps_option_button.item_selected.connect(
			_on_fps_selected
		)

	if brightness_slider != null:
		brightness_slider.value_changed.connect(
			_on_brightness_changed
		)


func _select_resolution(
	target_resolution: Vector2i
) -> void:
	if resolution_option_button == null:
		return

	var matching_index: int = -1

	for resolution_index: int in range(
		_resolution_options.size()
	):
		if _resolution_options[resolution_index] == target_resolution:
			matching_index = resolution_index
			break

	if matching_index < 0:
		_resolution_options.append(
			target_resolution
		)

		matching_index = _resolution_options.size() - 1

		resolution_option_button.add_item(
			"%d x %d"
			% [
				target_resolution.x,
				target_resolution.y,
			],
			matching_index
		)

	resolution_option_button.select(
		matching_index
	)


func _select_vsync_mode(
	target_vsync_mode: int
) -> void:
	if vsync_option_button == null:
		return

	for option_index: int in range(
		vsync_option_button.item_count
	):
		if (
			vsync_option_button.get_item_id(
				option_index
			)
			== target_vsync_mode
		):
			vsync_option_button.select(
				option_index
			)
			return

	vsync_option_button.select(
		0
	)


func _select_max_fps(
	target_max_fps: int
) -> void:
	if fps_option_button == null:
		return

	for option_index: int in range(
		fps_option_button.item_count
	):
		if (
			fps_option_button.get_item_id(
				option_index
			)
			== target_max_fps
		):
			fps_option_button.select(
				option_index
			)
			return

	fps_option_button.select(
		0
	)


func _refresh_brightness_label() -> void:
	if brightness_value_label == null:
		return

	brightness_value_label.text = (
		"%d%%"
		% roundi(
			brightness_slider.value * 100.0
		)
	)


func _refresh_hud_toggles() -> void:
	for hud_toggle_row: HudToggleRow in hud_toggle_rows:
		if hud_toggle_row == null:
			continue

		hud_toggle_row.refresh()


func _on_fullscreen_toggled(
	is_pressed: bool
) -> void:
	if _is_refreshing:
		return

	GameSettings.set_fullscreen(
		is_pressed
	)


func _on_resolution_selected(
	option_index: int
) -> void:
	if _is_refreshing:
		return

	if (
		option_index < 0
		or option_index >= _resolution_options.size()
	):
		return

	GameSettings.set_windowed_size(
		_resolution_options[option_index]
	)


func _on_vsync_selected(
	option_index: int
) -> void:
	if _is_refreshing:
		return

	if vsync_option_button == null:
		return

	GameSettings.set_vsync_mode(
		vsync_option_button.get_item_id(
			option_index
		)
	)


func _on_fps_selected(
	option_index: int
) -> void:
	if _is_refreshing:
		return

	if fps_option_button == null:
		return

	GameSettings.set_max_fps(
		fps_option_button.get_item_id(
			option_index
		)
	)


func _on_brightness_changed(
	value: float
) -> void:
	if _is_refreshing:
		return

	GameSettings.set_brightness(
		value
	)

	_refresh_brightness_label()


func _has_required_references() -> bool:
	return (
		fullscreen_button != null
		and resolution_option_button != null
		and vsync_option_button != null
		and fps_option_button != null
		and brightness_slider != null
		and brightness_value_label != null
	)
