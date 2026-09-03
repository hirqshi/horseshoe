class_name PlayerInput
extends RefCounted

var move: Vector2 = Vector2.ZERO
var is_walk_pressed: bool = false
var is_walk_just_pressed: bool = false
var is_jump_pressed: bool = false
var is_jump_held: bool = false
var is_slide_pressed: bool = false
var is_slide_held: bool = false
var is_glide_pressed: bool = false
var is_glide_held: bool = false
var is_glide_released: bool = false

func update_from_input() -> void:
	move = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	is_walk_pressed = Input.is_action_pressed("walk")
	is_walk_just_pressed = Input.is_action_just_pressed("walk")
	is_jump_pressed = Input.is_action_just_pressed("jump")
	is_jump_held = Input.is_action_pressed("jump")
	is_slide_pressed = Input.is_action_just_pressed("slide")
	is_slide_held = Input.is_action_pressed("slide")
	is_glide_pressed = Input.is_action_just_pressed(
		&"glide"
	)

	is_glide_held = Input.is_action_pressed(
		&"glide"
	)

	is_glide_released = Input.is_action_just_released(
		&"glide"
	)
