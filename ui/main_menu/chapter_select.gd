class_name ChapterSelect
extends Control

signal back_requested()

@export var chapter_cards: Array[ChapterCard] = []
@export var back_button: Button


func _ready() -> void:
	for chapter_card: ChapterCard in chapter_cards:
		if chapter_card == null:
			continue

		chapter_card.chapter_requested.connect(
			_on_chapter_requested
		)

	if back_button != null:
		back_button.pressed.connect(
			_on_back_button_pressed
		)


func refresh() -> void:
	for chapter_card: ChapterCard in chapter_cards:
		if chapter_card == null:
			continue

		chapter_card.refresh()


func _on_chapter_requested(
	chapter_definition: ChapterDefinition
) -> void:
	SceneManager.start_chapter_from_beginning(
		chapter_definition
	)


func _on_back_button_pressed() -> void:
	back_requested.emit()
