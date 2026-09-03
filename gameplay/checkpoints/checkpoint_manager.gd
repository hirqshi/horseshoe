class_name CheckpointManager
extends Node

signal checkpoint_changed(
	previous_checkpoint: Checkpoint,
	current_checkpoint: Checkpoint
)

signal player_entered_checkpoint_zone(
	checkpoint: Checkpoint
)

signal player_exited_checkpoint_zone(
	checkpoint: Checkpoint
)

@export var checkpoints_root: Node3D
@export var initial_spawn_anchor: Marker3D

var active_checkpoint: Checkpoint
var player: Player


func setup(
	target_player: Player
) -> void:
	if target_player == null:
		push_error(
			"CheckpointManager requires a Player."
		)
		return

	player = target_player


func _ready() -> void:
	_connect_checkpoints()


func get_respawn_transform() -> Transform3D:
	if active_checkpoint != null:
		return active_checkpoint.get_spawn_transform()

	if initial_spawn_anchor == null:
		push_error(
			"CheckpointManager has no active checkpoint "
			+ "and no InitialSpawn."
		)

		return Transform3D.IDENTITY

	var initial_transform: Transform3D = (
		initial_spawn_anchor.global_transform
	)

	return Transform3D(
		initial_transform.basis.orthonormalized(),
		initial_transform.origin
	)


func _connect_checkpoints() -> void:
	if checkpoints_root == null:
		push_error(
			"CheckpointManager requires a Checkpoints root."
		)

		return

	for checkpoint_node: Node in checkpoints_root.get_children():
		var checkpoint: Checkpoint = (
			checkpoint_node as Checkpoint
		)

		if checkpoint == null:
			continue

		if not checkpoint.body_reached.is_connected(
			_on_checkpoint_body_reached
		):
			checkpoint.body_reached.connect(
				_on_checkpoint_body_reached
			)

		if not checkpoint.body_presence_changed.is_connected(
			_on_checkpoint_presence_changed
		):
			checkpoint.body_presence_changed.connect(
				_on_checkpoint_presence_changed
			)


func _set_active_checkpoint(
	new_checkpoint: Checkpoint
) -> void:
	if new_checkpoint == active_checkpoint:
		return

	var previous_checkpoint: Checkpoint = (
		active_checkpoint
	)

	if previous_checkpoint != null:
		previous_checkpoint.set_active(false)

	active_checkpoint = new_checkpoint
	active_checkpoint.set_active(true)

	checkpoint_changed.emit(
		previous_checkpoint,
		active_checkpoint
	)


func _on_checkpoint_body_reached(
	checkpoint: Checkpoint,
	body: Node3D
) -> void:
	if body != player:
		return

	_set_active_checkpoint(
		checkpoint
	)


func _on_checkpoint_presence_changed(
	checkpoint: Checkpoint,
	body: Node3D,
	is_inside: bool
) -> void:
	if body != player:
		return

	if is_inside:
		player_entered_checkpoint_zone.emit(
			checkpoint
		)

		return

	player_exited_checkpoint_zone.emit(
		checkpoint
	)
