class_name IntroSplash
extends Control

@export_category("references")
@export var animation_player: AnimationPlayer
@export var logo_animation_name: StringName = &"logo_intro"

@export_category("skip")
@export var can_be_skipped: bool = true
@export var skip_action: StringName = &"ui_accept"

var _has_finished: bool = false


func _ready() -> void:
	if animation_player == null:
		push_error(
			"IntroSplash requires an AnimationPlayer."
		)
		return

	if not animation_player.has_animation(
		logo_animation_name
	):
		push_error(
			"IntroSplash: AnimationPlayer has no animation '%s'."
			% logo_animation_name
		)
		return

	animation_player.animation_finished.connect(
		_on_animation_finished
	)

	animation_player.play(
		logo_animation_name
	)


func _unhandled_input(
	event: InputEvent
) -> void:
	if not can_be_skipped:
		return

	if _has_finished:
		return

	if not event.is_action_pressed(
		skip_action
	):
		return

	get_viewport().set_input_as_handled()

	_finish_splash()


func _on_animation_finished(
	finished_animation_name: StringName
) -> void:
	if finished_animation_name != logo_animation_name:
		return

	_finish_splash()


func _finish_splash() -> void:
	if _has_finished:
		return

	_has_finished = true

	if animation_player != null:
		animation_player.stop()

	SceneManager.go_to_main_menu_from_boot()
