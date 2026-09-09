extends Node

signal settings_loaded()
signal settings_saved()

signal fullscreen_changed(
	is_fullscreen: bool
)

signal windowed_size_changed(
	windowed_size: Vector2i
)

signal vsync_mode_changed(
	vsync_mode: int
)

signal max_fps_changed(
	max_fps: int
)

signal brightness_changed(
	brightness: float
)

signal mouse_look_settings_changed(
	mouse_sensitivity: float,
	is_horizontal_inverted: bool,
	is_vertical_inverted: bool
)

signal bus_volume_changed(
	bus_name: StringName,
	volume_db: float
)

signal last_selected_save_slot_changed(
	slot_index: int
)

const SETTINGS_PATH: String = (
	"user://horseshoe/settings.cfg"
)

const SETTINGS_SECTION_VIDEO: String = "video"
const SETTINGS_SECTION_AUDIO: String = "audio"
const SETTINGS_SECTION_PROFILE: String = "profile"

const DEFAULT_BRIGHTNESS: float = 1.0
const MIN_WINDOW_WIDTH_PX: int = 960
const MIN_WINDOW_HEIGHT_PX: int = 540
const MIN_BUS_VOLUME_DB: float = -80.0
const MAX_BUS_VOLUME_DB: float = 6.0

const DEFAULT_MOUSE_SENSITIVITY: float = 0.0025
const MIN_MOUSE_SENSITIVITY: float = 0.0005
const MAX_MOUSE_SENSITIVITY: float = 0.015

var is_fullscreen: bool = false
var windowed_size: Vector2i = Vector2i(
	1920,
	1080
)

var vsync_mode: int = DisplayServer.VSYNC_ENABLED
var max_fps: int = 0
var brightness: float = DEFAULT_BRIGHTNESS

var mouse_sensitivity: float = 0.0025
var is_horizontal_look_inverted: bool = false
var is_vertical_look_inverted: bool = false

var last_selected_save_slot_index: int = -1

var _bus_volume_db_by_name: Dictionary[StringName, float] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_load_settings()


func set_fullscreen(
	value: bool
) -> void:
	if is_fullscreen == value:
		return

	is_fullscreen = value

	_apply_window_mode()
	save_settings()

	fullscreen_changed.emit(
		is_fullscreen
	)


func set_windowed_size(
	value: Vector2i
) -> void:
	var clamped_size: Vector2i = Vector2i(
		maxi(
			value.x,
			MIN_WINDOW_WIDTH_PX
		),
		maxi(
			value.y,
			MIN_WINDOW_HEIGHT_PX
		)
	)

	if windowed_size == clamped_size:
		return

	windowed_size = clamped_size

	if not is_fullscreen:
		DisplayServer.window_set_size(
			windowed_size
		)

	save_settings()

	windowed_size_changed.emit(
		windowed_size
	)


func set_vsync_mode(
	value: int
) -> void:
	if not _is_valid_vsync_mode(
		value
	):
		push_error(
			"GameSettings: invalid VSync mode %d."
			% value
		)
		return

	if vsync_mode == value:
		return

	vsync_mode = value

	DisplayServer.window_set_vsync_mode(
		vsync_mode
	)

	save_settings()

	vsync_mode_changed.emit(
		vsync_mode
	)


func set_max_fps(
	value: int
) -> void:
	var clamped_max_fps: int = maxi(
		value,
		0
	)

	if max_fps == clamped_max_fps:
		return

	max_fps = clamped_max_fps

	Engine.max_fps = max_fps

	save_settings()

	max_fps_changed.emit(
		max_fps
	)


func set_brightness(
	value: float
) -> void:
	var clamped_brightness: float = clampf(
		value,
		0.5,
		1.5
	)

	if is_equal_approx(
		brightness,
		clamped_brightness
	):
		return

	brightness = clamped_brightness

	save_settings()

	brightness_changed.emit(
		brightness
	)


func set_mouse_look_settings(
	mouse_sensitivity_value: float,
	is_horizontal_inverted: bool,
	is_vertical_inverted: bool
) -> void:
	var clamped_sensitivity: float = clampf(
		mouse_sensitivity_value,
		MIN_MOUSE_SENSITIVITY,
		MAX_MOUSE_SENSITIVITY
	)

	var has_changed: bool = (
		not is_equal_approx(
			mouse_sensitivity,
			clamped_sensitivity
		)
		or is_horizontal_look_inverted
		!= is_horizontal_inverted
		or is_vertical_look_inverted
		!= is_vertical_inverted
	)

	if not has_changed:
		return

	mouse_sensitivity = clamped_sensitivity
	is_horizontal_look_inverted = is_horizontal_inverted
	is_vertical_look_inverted = is_vertical_inverted

	save_settings()

	mouse_look_settings_changed.emit(
		mouse_sensitivity,
		is_horizontal_look_inverted,
		is_vertical_look_inverted
	)


func set_bus_volume_db(
	bus_name: StringName,
	value: float
) -> void:
	var bus_index: int = AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		push_error(
			"GameSettings: audio bus '%s' does not exist."
			% bus_name
		)
		return

	var clamped_volume_db: float = clampf(
		value,
		MIN_BUS_VOLUME_DB,
		MAX_BUS_VOLUME_DB
	)

	var previous_volume_db: float = (
		_bus_volume_db_by_name.get(
			bus_name,
			AudioServer.get_bus_volume_db(
				bus_index
			)
		)
	)

	if is_equal_approx(
		previous_volume_db,
		clamped_volume_db
	):
		return

	_bus_volume_db_by_name[bus_name] = clamped_volume_db

	AudioServer.set_bus_volume_db(
		bus_index,
		clamped_volume_db
	)

	save_settings()

	bus_volume_changed.emit(
		bus_name,
		clamped_volume_db
	)


func get_bus_volume_db(
	bus_name: StringName
) -> float:
	var bus_index: int = AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		push_error(
			"GameSettings: audio bus '%s' does not exist."
			% bus_name
		)
		return 0.0

	return _bus_volume_db_by_name.get(
		bus_name,
		AudioServer.get_bus_volume_db(
			bus_index
		)
	)


func get_audio_bus_names() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()

	for bus_index: int in AudioServer.get_bus_count():
		var bus_name: StringName = AudioServer.get_bus_name(
			bus_index
		)

		result.append(
			String(bus_name)
		)

	return result


func set_last_selected_save_slot(
	slot_index: int
) -> void:
	if slot_index < -1 or slot_index >= SaveManager.SLOT_COUNT:
		push_error(
			"GameSettings: invalid save slot index %d."
			% slot_index
		)
		return

	if last_selected_save_slot_index == slot_index:
		return

	last_selected_save_slot_index = slot_index

	save_settings()

	last_selected_save_slot_changed.emit(
		last_selected_save_slot_index
	)


func has_continue_slot() -> bool:
	if last_selected_save_slot_index < 0:
		return false

	return SaveManager.has_save(
		last_selected_save_slot_index
	)


func save_settings() -> bool:
	_ensure_settings_directory()

	var config: ConfigFile = ConfigFile.new()

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"fullscreen",
		is_fullscreen
	)

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"windowed_width_px",
		windowed_size.x
	)

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"windowed_height_px",
		windowed_size.y
	)

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"vsync_mode",
		vsync_mode
	)

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"max_fps",
		max_fps
	)

	config.set_value(
		SETTINGS_SECTION_VIDEO,
		"brightness",
		brightness
	)
	
	config.set_value(
		"input",
		"mouse_sensitivity",
		mouse_sensitivity
	)

	config.set_value(
		"input",
		"invert_horizontal",
		is_horizontal_look_inverted
	)

	config.set_value(
		"input",
		"invert_vertical",
		is_vertical_look_inverted
	)
	
	config.set_value(
		SETTINGS_SECTION_PROFILE,
		"last_selected_save_slot_index",
		last_selected_save_slot_index
	)

	for bus_name: StringName in _bus_volume_db_by_name:
		config.set_value(
			SETTINGS_SECTION_AUDIO,
			String(bus_name),
			_bus_volume_db_by_name[bus_name]
		)

	var save_error: Error = config.save(
		SETTINGS_PATH
	)

	if save_error != OK:
		push_error(
			"GameSettings: failed to save settings. Error: %d."
			% save_error
		)
		return false

	settings_saved.emit()

	return true


func _load_settings() -> void:
	_set_runtime_defaults()

	var config: ConfigFile = ConfigFile.new()

	var load_error: Error = config.load(
		SETTINGS_PATH
	)

	if load_error == ERR_FILE_NOT_FOUND:
		_apply_all_settings()
		save_settings()
		settings_loaded.emit()
		return

	if load_error != OK:
		push_warning(
			(
				"GameSettings: failed to load settings. "
				+ "Using runtime defaults. Error: %d."
			)
			% load_error
		)

		_apply_all_settings()
		settings_loaded.emit()
		return

	is_fullscreen = bool(
		config.get_value(
			SETTINGS_SECTION_VIDEO,
			"fullscreen",
			is_fullscreen
		)
	)

	windowed_size = Vector2i(
		int(
			config.get_value(
				SETTINGS_SECTION_VIDEO,
				"windowed_width_px",
				windowed_size.x
			)
		),
		int(
			config.get_value(
				SETTINGS_SECTION_VIDEO,
				"windowed_height_px",
				windowed_size.y
			)
		)
	)

	vsync_mode = int(
		config.get_value(
			SETTINGS_SECTION_VIDEO,
			"vsync_mode",
			vsync_mode
		)
	)

	if not _is_valid_vsync_mode(
		vsync_mode
	):
		vsync_mode = DisplayServer.VSYNC_ENABLED

	max_fps = maxi(
		0,
		int(
			config.get_value(
				SETTINGS_SECTION_VIDEO,
				"max_fps",
				max_fps
			)
		)
	)

	brightness = clampf(
		float(
			config.get_value(
				SETTINGS_SECTION_VIDEO,
				"brightness",
				brightness
			)
		),
		0.5,
		1.5
	)
	
	mouse_sensitivity = clampf(
		float(
			config.get_value(
				"input",
				"mouse_sensitivity",
				DEFAULT_MOUSE_SENSITIVITY
			)
		),
		MIN_MOUSE_SENSITIVITY,
		MAX_MOUSE_SENSITIVITY
	)

	is_horizontal_look_inverted = bool(
		config.get_value(
			"input",
			"invert_horizontal",
			false
		)
	)

	is_vertical_look_inverted = bool(
		config.get_value(
			"input",
			"invert_vertical",
			false
		)
	)
	
	last_selected_save_slot_index = int(
		config.get_value(
			SETTINGS_SECTION_PROFILE,
			"last_selected_save_slot_index",
			-1
		)
	)

	if (
		last_selected_save_slot_index < -1
		or last_selected_save_slot_index >= SaveManager.SLOT_COUNT
	):
		last_selected_save_slot_index = -1

	for bus_name: StringName in _bus_volume_db_by_name:
		var default_volume_db: float = (
			_bus_volume_db_by_name[bus_name]
		)

		var loaded_volume_db: float = clampf(
			float(
				config.get_value(
					SETTINGS_SECTION_AUDIO,
					String(bus_name),
					default_volume_db
				)
			),
			MIN_BUS_VOLUME_DB,
			MAX_BUS_VOLUME_DB
		)

		_bus_volume_db_by_name[bus_name] = loaded_volume_db

	_apply_all_settings()

	settings_loaded.emit()


func _set_runtime_defaults() -> void:
	is_fullscreen = (
		DisplayServer.window_get_mode()
		== DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	windowed_size = DisplayServer.window_get_size()

	vsync_mode = DisplayServer.window_get_vsync_mode()
	max_fps = Engine.max_fps
	brightness = DEFAULT_BRIGHTNESS
	
	mouse_sensitivity = DEFAULT_MOUSE_SENSITIVITY
	is_horizontal_look_inverted = false
	is_vertical_look_inverted = false
	
	last_selected_save_slot_index = -1

	_bus_volume_db_by_name.clear()

	for bus_index: int in AudioServer.get_bus_count():
		var bus_name: StringName = AudioServer.get_bus_name(
			bus_index
		)

		_bus_volume_db_by_name[bus_name] = (
			AudioServer.get_bus_volume_db(
				bus_index
			)
		)


func _apply_all_settings() -> void:
	_apply_window_mode()

	DisplayServer.window_set_vsync_mode(
		vsync_mode
	)

	Engine.max_fps = max_fps

	for bus_name: StringName in _bus_volume_db_by_name:
		var bus_index: int = AudioServer.get_bus_index(
			bus_name
		)

		if bus_index < 0:
			continue

		AudioServer.set_bus_volume_db(
			bus_index,
			_bus_volume_db_by_name[bus_name]
		)

	brightness_changed.emit(
		brightness
	)
	
	mouse_look_settings_changed.emit(
		mouse_sensitivity,
		is_horizontal_look_inverted,
		is_vertical_look_inverted
	)


func _apply_window_mode() -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		return

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
	)

	DisplayServer.window_set_size(
		windowed_size
	)


func _is_valid_vsync_mode(
	value: int
) -> bool:
	return (
		value == DisplayServer.VSYNC_DISABLED
		or value == DisplayServer.VSYNC_ENABLED
		or value == DisplayServer.VSYNC_ADAPTIVE
		or value == DisplayServer.VSYNC_MAILBOX
	)


func _ensure_settings_directory() -> void:
	var settings_directory: String = (
		ProjectSettings.globalize_path(
			"user://horseshoe"
		)
	)

	var make_directory_error: Error = (
		DirAccess.make_dir_recursive_absolute(
			settings_directory
		)
	)

	if (
		make_directory_error != OK
		and make_directory_error != ERR_ALREADY_EXISTS
	):
		push_error(
			"GameSettings: failed to create settings directory. Error: %d."
			% make_directory_error
		)
