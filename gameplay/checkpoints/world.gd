class_name World
extends Node3D

@export var checkpoint_manager: CheckpointManager
@export var rest_zones_root: Node3D
@export var death_zones_root: Node3D

var _player: Player
var _active_rest_zone_count: int = 0
var _are_zones_connected: bool = false


func setup(
	player: Player
) -> void:
	if player == null:
		push_error(
			"World requires a Player."
		)
		return

	_player = player

	if checkpoint_manager == null:
		push_error(
			"World requires a CheckpointManager."
		)
		return

	checkpoint_manager.setup(_player)

	_connect_zones()

	_update_rest_zone_state()


func get_respawn_transform() -> Transform3D:
	if checkpoint_manager == null:
		push_error(
			"World cannot provide a respawn transform: CheckpointManager is missing."
		)

		return Transform3D.IDENTITY

	return checkpoint_manager.get_respawn_transform()


func reset_player_zone_state() -> void:
	_active_rest_zone_count = 0

	_update_rest_zone_state()


func _connect_zones() -> void:
	if _are_zones_connected:
		return

	_connect_rest_zones()
	_connect_death_zones()

	_are_zones_connected = true


func _connect_rest_zones() -> void:
	if rest_zones_root == null:
		return

	for zone_node: Node in rest_zones_root.get_children():
		var rest_zone: RestZone = zone_node as RestZone

		if rest_zone == null:
			continue

		rest_zone.player_entered.connect(
			_on_rest_zone_player_entered
		)

		rest_zone.player_exited.connect(
			_on_rest_zone_player_exited
		)


func _connect_death_zones() -> void:
	if death_zones_root == null:
		return

	for zone_node: Node in death_zones_root.get_children():
		var death_zone: DeathZone = zone_node as DeathZone

		if death_zone == null:
			continue

		death_zone.player_entered.connect(
			_on_death_zone_player_entered
		)


func _on_rest_zone_player_entered(
	_rest_zone: RestZone,
	body: Node3D
) -> void:
	if body != _player:
		return

	_active_rest_zone_count += 1

	_update_rest_zone_state()


func _on_rest_zone_player_exited(
	_rest_zone: RestZone,
	body: Node3D
) -> void:
	if body != _player:
		return

	_active_rest_zone_count = maxi(
		0,
		_active_rest_zone_count - 1
	)

	_update_rest_zone_state()


func _on_death_zone_player_entered(
	_death_zone: DeathZone,
	body: Node3D
) -> void:
	if body != _player:
		return

	_player.request_instant_death()


func _update_rest_zone_state() -> void:
	if _player == null:
		return

	var reverse_stamina: ReverseStamina = (
		_player.get_reverse_stamina()
	)

	if reverse_stamina == null:
		push_error(
			"World could not get ReverseStamina from Player."
		)
		return

	reverse_stamina.set_resting(
		_active_rest_zone_count > 0
	)
