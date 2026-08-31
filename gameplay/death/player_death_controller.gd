class_name PlayerDeathController
extends Node

@export_group("Death Overlay")
@export var death_overlay: DeathOverlay

@export_group("Timing")
@export_range(0.0, 3.0, 0.01) var blackout_hold_duration: float = 0.12
@export_range(0.0, 5.0, 0.01) var reveal_duration: float = 0.55

var is_dying: bool = false

var _player: Player
var _world: World
var _previous_player_process_mode: Node.ProcessMode = (
	Node.PROCESS_MODE_INHERIT
)


func setup(
	player: Player,
	world: World
) -> void:
	if _player != null:
		push_warning(
			"PlayerDeathController.setup() was called more than once."
		)
		return

	if player == null:
		push_error(
			"PlayerDeathController requires a Player."
		)
		return

	if world == null:
		push_error(
			"PlayerDeathController requires a World."
		)
		return

	if death_overlay == null:
		push_error(
			"PlayerDeathController requires a DeathOverlay."
		)
		return

	_player = player
	_world = world

	_player.fatal_fall_detected.connect(
		_on_player_fatal_fall_detected
	)
	
	_player.reverse_stamina_depleted.connect(
		_on_player_reverse_stamina_depleted
	)
	
	_player.instant_death_requested.connect(
		_on_player_instant_death_requested
	)


func request_death() -> void:
	if is_dying:
		return

	if _player == null:
		push_error(
			"PlayerDeathController has not been set up."
		)
		return

	if _world == null:
		push_error(
			"PlayerDeathController has no World."
		)
		return

	if death_overlay == null:
		push_error(
			"PlayerDeathController has no DeathOverlay."
		)
		return

	is_dying = true

	_previous_player_process_mode = _player.process_mode
	_player.process_mode = Node.PROCESS_MODE_DISABLED

	_player.velocity = Vector3.ZERO

	death_overlay.cover_immediately()

	await get_tree().process_frame

	if !is_instance_valid(_player):
		return

	var respawn_transform: Transform3D = (
		_world.get_respawn_transform()
	)

	_player.global_transform = respawn_transform
	_player.velocity = Vector3.ZERO

	_player.reset_after_respawn()

	_world.reset_player_zone_state()

	await get_tree().physics_frame

	if !is_instance_valid(_player):
		return

	_player.velocity = Vector3.ZERO

	if blackout_hold_duration > 0.0:
		await get_tree().create_timer(
			blackout_hold_duration
		).timeout

	if !is_instance_valid(_player):
		return

	_player.process_mode = _previous_player_process_mode
	_player.velocity = Vector3.ZERO

	if death_overlay != null:
		await death_overlay.reveal(
			reveal_duration
		)

	is_dying = false


func _on_player_fatal_fall_detected(
	_fall_distance_m: float,
	_impact_speed_mps: float
) -> void:
	request_death()

func _on_player_reverse_stamina_depleted() -> void:
	request_death()

func _on_player_instant_death_requested() -> void:
	request_death()
