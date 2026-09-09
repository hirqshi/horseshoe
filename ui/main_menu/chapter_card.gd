class_name ChapterCard
extends Control

signal chapter_requested(
	chapter_definition: ChapterDefinition
)

@export_group("Chapter")
@export var chapter_definition: ChapterDefinition

@export_group("References")
@export var preview_texture_rect: TextureRect
@export var title_label: Label
@export var status_label: Label
@export var lock_overlay: Control
@export var select_button: Button


func _ready() -> void:
	if select_button == null:
		push_error(
			"ChapterCard requires a SelectButton."
		)
		return

	select_button.pressed.connect(
		_on_select_button_pressed
	)


func refresh() -> void:
	if chapter_definition == null:
		visible = false

		push_error(
			"ChapterCard '%s' has no ChapterDefinition."
			% name
		)
		return

	if not chapter_definition.is_valid_definition():
		visible = false

		push_error(
			"ChapterCard '%s' has an invalid ChapterDefinition."
			% name
		)
		return

	visible = true

	var is_available: bool = SaveManager.is_chapter_available(
		chapter_definition
	)

	if preview_texture_rect != null:
		preview_texture_rect.texture = (
			chapter_definition.preview_texture
		)

	if title_label != null:
		title_label.text = chapter_definition.display_name

	if status_label != null:
		status_label.text = (
			"AVAILABLE"
			if is_available
			else "LOCKED"
		)

	if lock_overlay != null:
		lock_overlay.visible = not is_available

	if select_button != null:
		select_button.disabled = not is_available


func _on_select_button_pressed() -> void:
	if chapter_definition == null:
		return

	if not SaveManager.is_chapter_available(
		chapter_definition
	):
		return

	chapter_requested.emit(
		chapter_definition
	)
