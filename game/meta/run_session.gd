class_name RunSession
extends RefCounted

var is_active: bool = false
var current_chapter_id: StringName = &""

var chapter_elapsed_time_s: float = 0.0
var checkpoint_elapsed_time_s: float = 0.0

var chapter_deaths: int = 0
var deaths_since_checkpoint: int = 0

func start_chapter(chapter_id: StringName) -> void:
	is_active = true
	current_chapter_id = chapter_id
	chapter_elapsed_time_s = 0.0
	checkpoint_elapsed_time_s = 0.0
	chapter_deaths = 0
	deaths_since_checkpoint = 0

func reset_checkpoint_timer() -> void:
	checkpoint_elapsed_time_s = 0.0
	deaths_since_checkpoint = 0

func clear() -> void:
	is_active = false
	current_chapter_id = &""
	chapter_elapsed_time_s = 0.0
	checkpoint_elapsed_time_s = 0.0
	chapter_deaths = 0
	deaths_since_checkpoint = 0
