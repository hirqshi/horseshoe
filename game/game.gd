class_name Game
extends Node

@export var player: Player
@export var in_game_hud: InGameHud
@export var world: World
@export var player_death_controller: PlayerDeathController


func _ready() -> void:
	if player == null:
		push_error(
			"Game requires a Player."
		)
		return

	if world == null:
		push_error(
			"Game requires a World."
		)
		return

	if in_game_hud == null:
		push_error(
			"Game requires an InGameHud."
		)
		return

	if player_death_controller == null:
		push_error(
			"Game requires a PlayerDeathController."
		)
		return

	world.setup(player)

	player_death_controller.setup(
		player,
		world
	)

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
