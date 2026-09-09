extends Node

signal active_profile_changed(profile: SaveProfile)
signal save_slot_changed(slot_index: int)
signal profile_saved(slot_index: int)
signal checkpoint_committed(chapter_id: StringName, checkpoint_id: StringName)
signal death_registered(total_deaths: int, chapter_deaths: int, checkpoint_deaths: int)
signal ability_unlocked(ability_id: StringName)
signal chapter_completed(chapter_id: StringName)
signal chapter_time_changed(chapter_time_s: float)
signal checkpoint_time_changed(checkpoint_time_s: float)

const SLOT_COUNT: int = 3
const SAVES_DIRECTORY: String = "user://horseshoe/saves"
const SAVE_FILE_FORMAT: String = "slot_%d.json"
const AUTO_SAVE_INTERVAL_S: float = 20.0

var active_profile: SaveProfile = null
var run_session: RunSession = RunSession.new()

var _is_profile_dirty: bool = false
var _auto_save_elapsed_s: float = 0.0

func has_active_profile() -> bool:
	return active_profile != null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_saves_directory()

func _process(delta: float) -> void:
	if active_profile == null:
		return

	if not run_session.is_active:
		return

	if get_tree().paused:
		return

	active_profile.total_play_time_s += delta
	run_session.chapter_elapsed_time_s += delta
	run_session.checkpoint_elapsed_time_s += delta

	var current_chapter_stats: ChapterStats = active_profile.get_or_create_chapter_stats(
		run_session.current_chapter_id
	)
	current_chapter_stats.total_play_time_s += delta

	_is_profile_dirty = true
	_auto_save_elapsed_s += delta

	chapter_time_changed.emit(run_session.chapter_elapsed_time_s)
	checkpoint_time_changed.emit(run_session.checkpoint_elapsed_time_s)

	if _auto_save_elapsed_s >= AUTO_SAVE_INTERVAL_S:
		save_active_profile()

func has_save(slot_index: int) -> bool:
	if not _is_valid_slot_index(slot_index):
		return false

	return FileAccess.file_exists(_get_save_path(slot_index))

func load_or_create_profile(
	slot_index: int
) -> bool:
	if not _is_valid_slot_index(
		slot_index
	):
		push_error(
			"SaveManager: invalid slot index %d."
			% slot_index
		)
		return false

	var loaded_profile: SaveProfile = _load_profile_from_disk(
		slot_index
	)

	var was_created: bool = false

	if loaded_profile == null:
		loaded_profile = SaveProfile.create_new(
			slot_index
		)

		was_created = true

	active_profile = loaded_profile

	run_session.clear()

	_auto_save_elapsed_s = 0.0
	_is_profile_dirty = false

	if was_created:
		save_active_profile()

	active_profile_changed.emit(
		active_profile
	)

	save_slot_changed.emit(
		slot_index
	)

	return true

func start_new_profile(slot_index: int) -> bool:
	if not _is_valid_slot_index(slot_index):
		push_error("SaveManager: invalid slot index %d." % slot_index)
		return false

	active_profile = SaveProfile.create_new(slot_index)
	run_session.clear()
	_auto_save_elapsed_s = 0.0
	_is_profile_dirty = true

	save_active_profile()

	active_profile_changed.emit(active_profile)
	save_slot_changed.emit(slot_index)

	return true

func delete_profile(slot_index: int) -> bool:
	if not _is_valid_slot_index(slot_index):
		push_error("SaveManager: invalid slot index %d." % slot_index)
		return false

	var save_path: String = _get_save_path(slot_index)

	if not FileAccess.file_exists(save_path):
		return true

	var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	if remove_error != OK:
		push_error(
			"SaveManager: could not delete save slot %d. Error: %d." % [
				slot_index,
				remove_error,
			]
		)
		return false

	if active_profile != null and active_profile.slot_index == slot_index:
		active_profile = null
		run_session.clear()
		_is_profile_dirty = false

	return true

func get_active_slot_index() -> int:
	if active_profile == null:
		return -1

	return active_profile.slot_index

func get_slot_summary(slot_index: int) -> Dictionary[String, Variant]:
	if not _is_valid_slot_index(slot_index):
		return {}

	var profile: SaveProfile = _load_profile_from_disk(slot_index)

	if profile == null:
		return {
			"has_save": false,
			"slot_index": slot_index,
			"total_play_time_s": 0.0,
			"total_deaths": 0,
			"highest_unlocked_chapter_index": 0,
		}

	return {
		"has_save": true,
		"slot_index": profile.slot_index,
		"total_play_time_s": profile.total_play_time_s,
		"total_deaths": profile.total_deaths,
		"highest_unlocked_chapter_index": profile.highest_unlocked_chapter_index,
	}

func start_chapter(
	chapter_id: StringName,
	resume_from_saved_checkpoint: bool = false
) -> void:
	if active_profile == null:
		push_error(
			"SaveManager: cannot start chapter without an active profile."
		)
		return

	if chapter_id.is_empty():
		push_error(
			"SaveManager: cannot start a chapter with an empty chapter_id."
		)
		return

	run_session.start_chapter(
		chapter_id
	)

	if (
		resume_from_saved_checkpoint
		and active_profile.last_checkpoint_chapter_id == chapter_id
		and not active_profile.last_checkpoint_id.is_empty()
	):
		run_session.chapter_elapsed_time_s = (
			active_profile.last_checkpoint_chapter_elapsed_time_s
		)

		run_session.chapter_deaths = (
			active_profile.last_checkpoint_chapter_deaths
		)

		run_session.checkpoint_elapsed_time_s = 0.0
		run_session.deaths_since_checkpoint = 0
		active_profile.deaths_since_checkpoint = 0
	else:
		active_profile.deaths_since_checkpoint = 0

	_is_profile_dirty = true

func leave_current_chapter() -> void:
	save_active_profile()
	run_session.clear()

func commit_checkpoint(checkpoint_id: StringName) -> void:
	if active_profile == null:
		push_error(
			"SaveManager: cannot commit a checkpoint without an active profile."
		)
		return

	if not run_session.is_active:
		push_error(
			"SaveManager: cannot commit a checkpoint without an active chapter."
		)
		return

	if checkpoint_id.is_empty():
		push_error(
			"SaveManager: cannot commit an empty checkpoint id."
		)
		return

	active_profile.last_checkpoint_chapter_id = (
		run_session.current_chapter_id
	)
	active_profile.last_checkpoint_id = checkpoint_id
	active_profile.deaths_since_checkpoint = 0
	
	active_profile.last_checkpoint_chapter_elapsed_time_s = (
		run_session.chapter_elapsed_time_s
	)

	active_profile.last_checkpoint_chapter_deaths = (
		run_session.chapter_deaths
	)
	
	run_session.reset_checkpoint_timer()

	_is_profile_dirty = true
	save_active_profile()

	checkpoint_committed.emit(
		run_session.current_chapter_id,
		checkpoint_id
	)

func register_death() -> void:
	if active_profile == null:
		push_error("SaveManager: cannot register death without an active profile.")
		return

	active_profile.total_deaths += 1
	active_profile.deaths_since_checkpoint += 1

	if run_session.is_active:
		run_session.chapter_deaths += 1
		run_session.deaths_since_checkpoint += 1

		var current_chapter_stats: ChapterStats = active_profile.get_or_create_chapter_stats(
			run_session.current_chapter_id
		)
		current_chapter_stats.total_deaths += 1

	_is_profile_dirty = true
	save_active_profile()

	death_registered.emit(
		active_profile.total_deaths,
		run_session.chapter_deaths,
		active_profile.deaths_since_checkpoint
	)

func complete_current_chapter(chapter_index: int) -> void:
	if active_profile == null:
		push_error("SaveManager: cannot complete chapter without an active profile.")
		return

	if not run_session.is_active:
		push_error("SaveManager: cannot complete a chapter without an active session.")
		return

	var completed_chapter_id: StringName = run_session.current_chapter_id
	var stats: ChapterStats = active_profile.get_or_create_chapter_stats(completed_chapter_id)

	stats.register_completion(
		run_session.chapter_elapsed_time_s,
		run_session.chapter_deaths
	)

	active_profile.mark_chapter_completed(completed_chapter_id)
	active_profile.highest_unlocked_chapter_index = max(
		active_profile.highest_unlocked_chapter_index,
		chapter_index + 1
	)

	_is_profile_dirty = true
	save_active_profile()
	chapter_completed.emit(completed_chapter_id)

	run_session.clear()

func unlock_ability(ability_id: StringName) -> bool:
	if active_profile == null:
		push_error("SaveManager: cannot unlock ability without an active profile.")
		return false

	var was_unlocked: bool = active_profile.unlock_ability(ability_id)

	if not was_unlocked:
		return false

	_is_profile_dirty = true
	save_active_profile()
	ability_unlocked.emit(ability_id)

	return true

func has_ability(ability_id: StringName) -> bool:
	if active_profile == null:
		return false

	return active_profile.has_ability(ability_id)

func is_chapter_available(
	chapter_definition: ChapterDefinition
) -> bool:
	if active_profile == null:
		return false

	if chapter_definition == null:
		return false

	return (
		chapter_definition.chapter_index
		<= active_profile.highest_unlocked_chapter_index
	)

func save_active_profile() -> bool:
	if active_profile == null:
		return false

	_ensure_saves_directory()

	var save_path: String = _get_save_path(active_profile.slot_index)
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)

	if file == null:
		push_error(
			"SaveManager: failed to open '%s'. Error: %d." % [
				save_path,
				FileAccess.get_open_error(),
			]
		)
		return false

	var serialized_profile: Dictionary[String, Variant] = active_profile.to_dictionary()
	var json_text: String = JSON.stringify(serialized_profile, "\t")

	file.store_string(json_text)
	file.flush()
	file.close()

	_is_profile_dirty = false
	_auto_save_elapsed_s = 0.0
	profile_saved.emit(active_profile.slot_index)

	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _is_profile_dirty:
		save_active_profile()

func _load_profile_from_disk(slot_index: int) -> SaveProfile:
	var save_path: String = _get_save_path(slot_index)

	if not FileAccess.file_exists(save_path):
		return null

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)

	if file == null:
		push_error(
			"SaveManager: failed to read '%s'. Error: %d." % [
				save_path,
				FileAccess.get_open_error(),
			]
		)
		return null

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(json_text)

	if parse_error != OK:
		push_error(
			"SaveManager: invalid JSON in '%s' at line %d: %s." % [
				save_path,
				json.get_error_line(),
				json.get_error_message(),
			]
		)
		return null

	if not json.data is Dictionary:
		push_error("SaveManager: root data in '%s' is not a dictionary." % save_path)
		return null

	var raw_data: Dictionary = json.data as Dictionary
	var typed_data: Dictionary[String, Variant] = {}

	for key: Variant in raw_data:
		typed_data[String(key)] = raw_data[key]

	var loaded_profile: SaveProfile = SaveProfile.from_dictionary(typed_data)

	if loaded_profile.slot_index != slot_index:
		push_error(
			"SaveManager: slot mismatch in '%s'. Expected %d, got %d." % [
				save_path,
				slot_index,
				loaded_profile.slot_index,
			]
		)
		return null

	if loaded_profile.save_version > SaveProfile.CURRENT_SAVE_VERSION:
		push_error(
			"SaveManager: slot %d uses a newer save version (%d)." % [
				slot_index,
				loaded_profile.save_version,
			]
		)
		return null

	_migrate_profile_if_needed(loaded_profile)
	return loaded_profile

func _migrate_profile_if_needed(profile: SaveProfile) -> void:
	if profile.save_version == SaveProfile.CURRENT_SAVE_VERSION:
		return

	profile.save_version = SaveProfile.CURRENT_SAVE_VERSION

func _ensure_saves_directory() -> void:
	var absolute_directory: String = ProjectSettings.globalize_path(SAVES_DIRECTORY)
	var make_directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)

	if make_directory_error != OK and make_directory_error != ERR_ALREADY_EXISTS:
		push_error(
			"SaveManager: failed to create saves directory. Error: %d." % (
				make_directory_error
			)
		)

func _get_save_path(slot_index: int) -> String:
	return SAVES_DIRECTORY.path_join(SAVE_FILE_FORMAT % slot_index)

func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT

func get_saved_checkpoint_id_for_chapter(
	chapter_id: StringName
) -> StringName:
	if active_profile == null:
		return &""

	if active_profile.last_checkpoint_chapter_id != chapter_id:
		return &""

	return active_profile.last_checkpoint_id


func has_saved_checkpoint_for_chapter(
	chapter_id: StringName
) -> bool:
	return not get_saved_checkpoint_id_for_chapter(
		chapter_id
	).is_empty()
