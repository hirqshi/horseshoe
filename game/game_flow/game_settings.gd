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

const SETTINGS_SECTION_INPUT: String = "input"
const SETTINGS_SECTION_INPUT_BINDINGS: String = "input_bindings"

const REBINDABLE_ACTION_IDS: PackedStringArray = [
	"move_forward",
	"move_back",
	"move_left",
	"move_right",
	"walk",
	"jump",
	"slide",
	"dash",
	"grapple",
	"glide",
	"interact",
	"pause",
	"toggle_hud",
]

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

var _default_input_events_by_action: Dictionary[StringName, InputEventList] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_capture_default_input_bindings()
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
		
	for action_id_text: String in REBINDABLE_ACTION_IDS:
		var action_id: StringName = StringName(
			action_id_text
		)

		if not InputMap.has_action(
			action_id
		):
			continue

		var serialized_events: Array = []

		for input_event: InputEvent in get_action_bindings(
			action_id
		):
			serialized_events.append(
				_serialize_input_event(
					input_event
				)
			)

		config.set_value(
			SETTINGS_SECTION_INPUT_BINDINGS,
			String(action_id),
			JSON.stringify(
				serialized_events
			)
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
	
	_load_input_bindings(
		config
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


func get_rebindable_action_ids() -> PackedStringArray:
	return REBINDABLE_ACTION_IDS


func get_action_bindings(
	action_id: StringName
) -> Array[InputEvent]:
	var result: Array[InputEvent] = []

	if not InputMap.has_action(
		action_id
	):
		push_error(
			"GameSettings: Input Map has no action '%s'."
			% action_id
		)
		return result

	var input_events: Array[InputEvent] = (
		InputMap.action_get_events(
			action_id
		)
	)

	for input_event: InputEvent in input_events:
		if not _is_supported_rebind_event(
			input_event
		):
			continue

		var copied_event: InputEvent = (
			input_event.duplicate(
				true
			) as InputEvent
		)

		if copied_event != null:
			result.append(
				copied_event
			)

	return result


func get_default_action_bindings(
	action_id: StringName
) -> Array[InputEvent]:
	var default_event_list: InputEventList = (
		_default_input_events_by_action.get(
			action_id
		) as InputEventList
	)

	if default_event_list == null:
		return []

	return default_event_list.get_events_copy()


func get_action_bind_slot_count(
	action_id: StringName
) -> int:
	var current_events: Array[InputEvent] = get_action_bindings(
		action_id
	)

	var default_events: Array[InputEvent] = (
		get_default_action_bindings(
			action_id
		)
	)

	return maxi(
		1,
		maxi(
			current_events.size(),
			default_events.size()
		)
	)


func get_action_binding_display_name(
	action_id: StringName,
	slot_index: int
) -> String:
	var input_events: Array[InputEvent] = get_action_bindings(
		action_id
	)

	if slot_index < 0 or slot_index >= input_events.size():
		return "UNBOUND"

	return _get_input_event_display_name(
		input_events[slot_index]
	)


func rebind_action_slot(
	action_id: StringName,
	slot_index: int,
	new_input_event: InputEvent
) -> bool:
	if not InputMap.has_action(
		action_id
	):
		push_error(
			"GameSettings: Input Map has no action '%s'."
			% action_id
		)
		return false

	if slot_index < 0:
		push_error(
			"GameSettings: invalid bind slot index %d."
			% slot_index
		)
		return false

	if not _is_supported_rebind_event(
		new_input_event
	):
		push_error(
			"GameSettings: unsupported input event for '%s'."
			% action_id
		)
		return false

	var input_events: Array[InputEvent] = get_action_bindings(
		action_id
	)

	while input_events.size() <= slot_index:
		input_events.append(
			InputEventKey.new()
		)

	input_events[slot_index] = (
		new_input_event.duplicate(
			true
		) as InputEvent
	)

	_apply_action_bindings(
		action_id,
		input_events
	)

	save_settings()

	return true


func clear_action_bind_slot(
	action_id: StringName,
	slot_index: int
) -> bool:
	if not InputMap.has_action(
		action_id
	):
		push_error(
			"GameSettings: Input Map has no action '%s'."
			% action_id
		)
		return false

	var input_events: Array[InputEvent] = get_action_bindings(
		action_id
	)

	if slot_index < 0 or slot_index >= input_events.size():
		return false

	input_events.remove_at(
		slot_index
	)

	_apply_action_bindings(
		action_id,
		input_events
	)

	save_settings()

	return true


func reset_input_bindings_to_defaults() -> void:
	for action_id_text: String in REBINDABLE_ACTION_IDS:
		var action_id: StringName = StringName(
			action_id_text
		)

		if not InputMap.has_action(
			action_id
		):
			continue

		_apply_action_bindings(
			action_id,
			get_default_action_bindings(
				action_id
			)
		)

	save_settings()


func _capture_default_input_bindings() -> void:
	_default_input_events_by_action.clear()

	for action_id_text: String in REBINDABLE_ACTION_IDS:
		var action_id: StringName = StringName(
			action_id_text
		)

		if not InputMap.has_action(
			action_id
		):
			push_warning(
				"GameSettings: Input Map action '%s' is missing."
				% action_id
			)
			continue

		var default_event_list: InputEventList = (
			InputEventList.new()
		)

		default_event_list.set_events(
			get_action_bindings(
				action_id
			)
		)

		_default_input_events_by_action[action_id] = (
			default_event_list
		)


func _apply_action_bindings(
	action_id: StringName,
	input_events: Array[InputEvent]
) -> void:
	InputMap.action_erase_events(
		action_id
	)

	for input_event: InputEvent in input_events:
		if not _is_supported_rebind_event(
			input_event
		):
			continue

		InputMap.action_add_event(
			action_id,
			input_event
		)


func _load_input_bindings(
	config: ConfigFile
) -> void:
	for action_id_text: String in REBINDABLE_ACTION_IDS:
		var action_id: StringName = StringName(
			action_id_text
		)

		if not InputMap.has_action(
			action_id
		):
			continue

		var serialized_bindings: String = String(
			config.get_value(
				SETTINGS_SECTION_INPUT_BINDINGS,
				String(action_id),
				""
			)
		)

		if serialized_bindings.is_empty():
			continue

		var json: JSON = JSON.new()

		if json.parse(serialized_bindings) != OK:
			push_warning(
				"GameSettings: invalid bindings for action '%s'."
				% action_id
			)
			continue

		if not json.data is Array:
			push_warning(
				"GameSettings: bindings for '%s' are not an array."
				% action_id
			)
			continue

		var raw_events: Array = json.data as Array
		var parsed_events: Array[InputEvent] = []

		for raw_event: Variant in raw_events:
			if not raw_event is Dictionary:
				continue

			var event_data: Dictionary = raw_event as Dictionary
			var input_event: InputEvent = (
				_deserialize_input_event(
					event_data
				)
			)

			if input_event == null:
				continue

			parsed_events.append(
				input_event
			)

		_apply_action_bindings(
			action_id,
			parsed_events
		)


func _serialize_input_event(
	input_event: InputEvent
) -> Dictionary[String, Variant]:
	if input_event is InputEventKey:
		var key_event: InputEventKey = (
			input_event as InputEventKey
		)

		return {
			"type": "key",
			"physical_keycode": key_event.physical_keycode,
			"keycode": key_event.keycode,
			"shift_pressed": key_event.shift_pressed,
			"alt_pressed": key_event.alt_pressed,
			"ctrl_pressed": key_event.ctrl_pressed,
			"meta_pressed": key_event.meta_pressed,
		}

	if input_event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			input_event as InputEventMouseButton
		)

		return {
			"type": "mouse_button",
			"button_index": mouse_event.button_index,
		}

	return {}


func _deserialize_input_event(
	event_data: Dictionary
) -> InputEvent:
	var event_type: String = String(
		event_data.get(
			"type",
			""
		)
	)

	if event_type == "key":
		var key_event: InputEventKey = InputEventKey.new()

		key_event.physical_keycode = int(
			event_data.get(
				"physical_keycode",
				0
			)
		)

		key_event.keycode = int(
			event_data.get(
				"keycode",
				0
			)
		)

		key_event.shift_pressed = bool(
			event_data.get(
				"shift_pressed",
				false
			)
		)

		key_event.alt_pressed = bool(
			event_data.get(
				"alt_pressed",
				false
			)
		)

		key_event.ctrl_pressed = bool(
			event_data.get(
				"ctrl_pressed",
				false
			)
		)

		key_event.meta_pressed = bool(
			event_data.get(
				"meta_pressed",
				false
			)
		)

		return key_event

	if event_type == "mouse_button":
		var mouse_event: InputEventMouseButton = (
			InputEventMouseButton.new()
		)

		mouse_event.button_index = int(
			event_data.get(
				"button_index",
				0
			)
		)

		return mouse_event

	return null


func _is_supported_rebind_event(
	input_event: InputEvent
) -> bool:
	if input_event is InputEventKey:
		return true

	if input_event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			input_event as InputEventMouseButton
		)

		return (
			mouse_event.button_index
			== MOUSE_BUTTON_LEFT
			or mouse_event.button_index
			== MOUSE_BUTTON_RIGHT
			or mouse_event.button_index
			== MOUSE_BUTTON_MIDDLE
			or mouse_event.button_index
			== MOUSE_BUTTON_XBUTTON1
			or mouse_event.button_index
			== MOUSE_BUTTON_XBUTTON2
		)

	return false


func _get_input_event_display_name(
	input_event: InputEvent
) -> String:
	if input_event is InputEventKey:
		var key_event: InputEventKey = (
			input_event as InputEventKey
		)

		var keycode: Key = (
			key_event.physical_keycode
			if key_event.physical_keycode != Key.KEY_NONE
			else key_event.keycode
		)

		return OS.get_keycode_string(
			keycode
		).to_upper()

	if input_event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			input_event as InputEventMouseButton
		)

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			return "LMB"

		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			return "RMB"

		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			return "MMB"

		if mouse_event.button_index == MOUSE_BUTTON_XBUTTON1:
			return "MOUSE 4"

		if mouse_event.button_index == MOUSE_BUTTON_XBUTTON2:
			return "MOUSE 5"

	return "UNBOUND"


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
