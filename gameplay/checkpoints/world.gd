class_name World
extends Node3D

@export var checkpoint_manager: CheckpointManager


func setup(
	player: CharacterBody3D
) -> void:
	if checkpoint_manager == null:
		push_error(
			"World requires a CheckpointManager."
		)

		return

	checkpoint_manager.setup(player)


func get_respawn_transform() -> Transform3D:
	if checkpoint_manager == null:
		push_error(
			"World cannot provide a respawn transform: CheckpointManager is missing."
		)

		return Transform3D.IDENTITY

	return checkpoint_manager.get_respawn_transform()
