class_name SaveProfile
extends RefCounted

const CURRENT_SAVE_VERSION: int = 1

var save_version: int = CURRENT_SAVE_VERSION
var slot_index: int = -1

var total_play_time_s: float = 0.0
var total_deaths: int = 0

var highest_unlocked_chapter_index: int = 0
var completed_chapter_ids: PackedStringArray = PackedStringArray()
var unlocked_ability_ids: PackedStringArray = PackedStringArray()
var is_new_game_plus_unlocked: bool = false

var last_checkpoint_chapter_id: StringName = &""
var last_checkpoint_id: StringName = &""
var deaths_since_checkpoint: int = 0

var last_checkpoint_chapter_elapsed_time_s: float = 0.0
var last_checkpoint_chapter_deaths: int = 0

var chapter_stats_by_id: Dictionary[StringName, ChapterStats] = {}

func has_completed_chapter(chapter_id: StringName) -> bool:
	return completed_chapter_ids.has(String(chapter_id))

func mark_chapter_completed(chapter_id: StringName) -> void:
	var chapter_id_text: String = String(chapter_id)

	if not completed_chapter_ids.has(chapter_id_text):
		completed_chapter_ids.append(chapter_id_text)

func has_ability(ability_id: StringName) -> bool:
	return unlocked_ability_ids.has(String(ability_id))

func unlock_ability(ability_id: StringName) -> bool:
	var ability_id_text: String = String(ability_id)

	if unlocked_ability_ids.has(ability_id_text):
		return false

	unlocked_ability_ids.append(ability_id_text)
	return true

func get_or_create_chapter_stats(chapter_id: StringName) -> ChapterStats:
	var existing_stats: ChapterStats = chapter_stats_by_id.get(chapter_id) as ChapterStats

	if existing_stats != null:
		return existing_stats

	var new_stats: ChapterStats = ChapterStats.new()
	chapter_stats_by_id[chapter_id] = new_stats
	return new_stats

func to_dictionary() -> Dictionary[String, Variant]:
	var serialized_chapter_stats: Dictionary[String, Variant] = {}

	for chapter_id: StringName in chapter_stats_by_id:
		var stats: ChapterStats = chapter_stats_by_id[chapter_id]
		serialized_chapter_stats[String(chapter_id)] = stats.to_dictionary()

	return {
		"save_version": save_version,
		"slot_index": slot_index,
		"total_play_time_s": total_play_time_s,
		"total_deaths": total_deaths,
		"highest_unlocked_chapter_index": highest_unlocked_chapter_index,
		"completed_chapter_ids": Array(completed_chapter_ids),
		"unlocked_ability_ids": Array(unlocked_ability_ids),
		"is_new_game_plus_unlocked": is_new_game_plus_unlocked,
		"last_checkpoint_chapter_id": String(last_checkpoint_chapter_id),
		"last_checkpoint_id": String(last_checkpoint_id),
		"deaths_since_checkpoint": deaths_since_checkpoint,
		"chapter_stats_by_id": serialized_chapter_stats,
		"last_checkpoint_chapter_elapsed_time_s": (
		last_checkpoint_chapter_elapsed_time_s
		),
		"last_checkpoint_chapter_deaths": (
			last_checkpoint_chapter_deaths
		),
	}

static func create_new(slot: int) -> SaveProfile:
	var result: SaveProfile = SaveProfile.new()
	result.slot_index = slot
	return result

static func from_dictionary(data: Dictionary[String, Variant]) -> SaveProfile:
	var result: SaveProfile = SaveProfile.new()

	result.save_version = int(data.get("save_version", 0))
	result.slot_index = int(data.get("slot_index", -1))
	result.total_play_time_s = float(data.get("total_play_time_s", 0.0))
	result.total_deaths = int(data.get("total_deaths", 0))
	result.highest_unlocked_chapter_index = int(data.get("highest_unlocked_chapter_index", 0))
	result.is_new_game_plus_unlocked = bool(data.get("is_new_game_plus_unlocked", false))
	result.last_checkpoint_chapter_id = StringName(
		String(data.get("last_checkpoint_chapter_id", ""))
	)
	result.last_checkpoint_id = StringName(String(data.get("last_checkpoint_id", "")))
	result.deaths_since_checkpoint = int(data.get("deaths_since_checkpoint", 0))
	result.last_checkpoint_chapter_elapsed_time_s = float(
		data.get(
			"last_checkpoint_chapter_elapsed_time_s",
			0.0
		)
	)

	result.last_checkpoint_chapter_deaths = int(
		data.get(
			"last_checkpoint_chapter_deaths",
			0
		)
	)
	var loaded_completed_ids: Array = data.get("completed_chapter_ids", []) as Array
	for chapter_id_value: Variant in loaded_completed_ids:
		result.completed_chapter_ids.append(String(chapter_id_value))

	var loaded_ability_ids: Array = data.get("unlocked_ability_ids", []) as Array
	for ability_id_value: Variant in loaded_ability_ids:
		result.unlocked_ability_ids.append(String(ability_id_value))

	var loaded_chapter_stats: Dictionary = data.get("chapter_stats_by_id", {}) as Dictionary
	for chapter_id_value: Variant in loaded_chapter_stats:
		var chapter_id: StringName = StringName(String(chapter_id_value))
		var raw_stats: Dictionary = loaded_chapter_stats[chapter_id_value] as Dictionary

		if raw_stats.is_empty():
			continue

		var typed_stats: Dictionary[String, Variant] = {}
		for key: Variant in raw_stats:
			typed_stats[String(key)] = raw_stats[key]

		result.chapter_stats_by_id[chapter_id] = ChapterStats.from_dictionary(typed_stats)

	return result
