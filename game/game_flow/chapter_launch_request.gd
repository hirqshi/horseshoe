class_name ChapterLaunchRequest
extends RefCounted

var chapter_definition: ChapterDefinition
var start_mode: int = ChapterStartMode.Id.START_FROM_BEGINNING


static func create(
	target_chapter_definition: ChapterDefinition,
	target_start_mode: int
) -> ChapterLaunchRequest:
	var result: ChapterLaunchRequest = ChapterLaunchRequest.new()

	result.chapter_definition = target_chapter_definition
	result.start_mode = target_start_mode

	return result


func is_valid() -> bool:
	if chapter_definition == null:
		return false

	if not chapter_definition.is_valid_definition():
		return false

	return (
		start_mode == ChapterStartMode.Id.START_FROM_BEGINNING
		or start_mode == ChapterStartMode.Id.RESUME_FROM_CHECKPOINT
		or start_mode == ChapterStartMode.Id.NEW_GAME_PLUS
	)
