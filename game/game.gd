class_name Game
extends Node

@export var player: Player
@export var in_game_hud: InGameHud

func _ready() -> void:
	if player == null:
		push_error("Game requires Player.")
		return

	if in_game_hud == null:
		push_error("Game requires InGameHud.")
		return

	in_game_hud.set_player(player)

	player.look_delta_received.connect(
		in_game_hud.register_look_delta
	)

	player.dash_started.connect(
		in_game_hud._on_player_dash_started
	)

	player.slide_started.connect(
		in_game_hud._on_player_slide_started
	)
