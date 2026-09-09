class_name ChapterDefinition
extends Resource

@export_group("Identity")
@export var chapter_id: StringName = &""
@export_range(0, 99, 1) var chapter_index: int = 0

@export_group("Presentation")
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var preview_texture: Texture2D

@export_group("Scene")
@export var world_scene: PackedScene

@export_group("Progression")
@export var completion_unlock_ability_ids: PackedStringArray = PackedStringArray()


func is_valid_definition() -> bool:
	if chapter_id.is_empty():
		return false

	if display_name.is_empty():
		return false

	if world_scene == null:
		return false

	return true
