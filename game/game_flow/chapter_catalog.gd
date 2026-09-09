class_name ChapterCatalog
extends Resource

@export var chapters: Array[ChapterDefinition] = []


func get_chapter_by_id(
	chapter_id: StringName
) -> ChapterDefinition:
	if chapter_id.is_empty():
		return null

	for chapter_definition: ChapterDefinition in chapters:
		if chapter_definition == null:
			continue

		if chapter_definition.chapter_id == chapter_id:
			return chapter_definition

	return null


func get_first_chapter() -> ChapterDefinition:
	var first_chapter: ChapterDefinition = null

	for chapter_definition: ChapterDefinition in chapters:
		if chapter_definition == null:
			continue

		if not chapter_definition.is_valid_definition():
			continue

		if first_chapter == null:
			first_chapter = chapter_definition
			continue

		if chapter_definition.chapter_index < first_chapter.chapter_index:
			first_chapter = chapter_definition

	return first_chapter


func is_valid_catalog() -> bool:
	if chapters.is_empty():
		return false

	var used_ids: Dictionary[StringName, bool] = {}
	var used_indices: Dictionary[int, bool] = {}

	for chapter_definition: ChapterDefinition in chapters:
		if chapter_definition == null:
			return false

		if not chapter_definition.is_valid_definition():
			return false

		if used_ids.has(chapter_definition.chapter_id):
			return false

		if used_indices.has(chapter_definition.chapter_index):
			return false

		used_ids[chapter_definition.chapter_id] = true
		used_indices[chapter_definition.chapter_index] = true

	return true
