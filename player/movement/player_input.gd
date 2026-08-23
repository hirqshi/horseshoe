class_name PlayerInput
extends RefCounted

var move: Vector2
var is_walk_pressed: bool
var is_jump_pressed: bool
var is_jump_held: bool
var is_slide_pressed: bool
var is_dash_pressed: bool

static func read() -> PlayerInput:
	var player_input: PlayerInput = PlayerInput.new()

	player_input.move = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	player_input.is_walk_pressed = Input.is_action_pressed("walk")
	player_input.is_jump_pressed = Input.is_action_just_pressed("jump")
	player_input.is_jump_held = Input.is_action_pressed("jump")
	player_input.is_slide_pressed = Input.is_action_just_pressed("slide")
	player_input.is_dash_pressed = Input.is_action_just_pressed("dash")

	return player_input
