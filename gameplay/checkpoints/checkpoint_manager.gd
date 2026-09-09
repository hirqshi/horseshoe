@tool
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

var _checkpoint_by_id: Dictionary[StringName, Checkpoint] = {}
var _id_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	if Engine.is_editor_hint():
		_id_rng.randomize()
		call_deferred(
			"_connect_checkpoints"
		)
		return

	_connect_checkpoints()


func setup(
	target_player: Player
) -> void:
	if target_player == null:
		push_error(
			"CheckpointManager requires a Player."
		)
		return

	player = target_player


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


func get_checkpoint_by_id(
	checkpoint_id: StringName
) -> Checkpoint:
	if checkpoint_id.is_empty():
		return null

	return _checkpoint_by_id.get(
		checkpoint_id
	) as Checkpoint


func restore_active_checkpoint(
	checkpoint_id: StringName
) -> bool:
	var checkpoint: Checkpoint = get_checkpoint_by_id(
		checkpoint_id
	)

	if checkpoint == null:
		push_warning(
			"CheckpointManager could not restore checkpoint '%s'."
			% checkpoint_id
		)
		return false

	_set_active_checkpoint(
		checkpoint,
		false
	)

	return true


func _connect_checkpoints() -> void:
	if checkpoints_root == null:
		push_error(
			"CheckpointManager requires a Checkpoints root."
		)
		return

	_checkpoint_by_id.clear()

	for checkpoint_node: Node in checkpoints_root.get_children():
		var checkpoint: Checkpoint = (
			checkpoint_node as Checkpoint
		)

		if checkpoint == null:
			continue

		_register_checkpoint_id(
			checkpoint
		)

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


func _register_checkpoint_id(
	checkpoint: Checkpoint
) -> void:
	if checkpoint == null:
		return

	var was_generated: bool = false
	var was_regenerated_after_duplicate: bool = false

	if checkpoint.checkpoint_id.is_empty():
		if not Engine.is_editor_hint():
			push_error(
				(
					"Checkpoint '%s' has no generated checkpoint_id. "
					+ "Open and save this chapter scene in the editor."
				)
				% checkpoint.name
			)
			return

		checkpoint.checkpoint_id = _generate_unique_checkpoint_id()
		was_generated = true

	var existing_checkpoint: Checkpoint = (
		_checkpoint_by_id.get(
			checkpoint.checkpoint_id
		) as Checkpoint
	)

	if existing_checkpoint != null:
		if not Engine.is_editor_hint():
			push_error(
				"Checkpoint '%s' and '%s' share checkpoint_id '%s'."
				% [
					existing_checkpoint.name,
					checkpoint.name,
					checkpoint.checkpoint_id,
				]
			)
			return

		checkpoint.checkpoint_id = _generate_unique_checkpoint_id()
		was_regenerated_after_duplicate = true

	_checkpoint_by_id[checkpoint.checkpoint_id] = checkpoint

	if was_generated:
		print(
			"checkpoint id created: %s -> %s"
			% [
				checkpoint.name,
				checkpoint.checkpoint_id,
			]
		)

	if was_regenerated_after_duplicate:
		print(
			"checkpoint duplicate id replaced: %s -> %s"
			% [
				checkpoint.name,
				checkpoint.checkpoint_id,
			]
		)


func _generate_unique_checkpoint_id() -> StringName:
	var generated_id: StringName = &""

	while generated_id.is_empty() or _checkpoint_by_id.has(generated_id):
		generated_id = StringName(
			"checkpoint_%08x_%08x_%08x_%08x"
			% [
				_id_rng.randi(),
				_id_rng.randi(),
				_id_rng.randi(),
				_id_rng.randi(),
			]
		)

	return generated_id


func _set_active_checkpoint(
	new_checkpoint: Checkpoint,
	should_emit_changed: bool = true
) -> void:
	if new_checkpoint == active_checkpoint:
		return

	var previous_checkpoint: Checkpoint = (
		active_checkpoint
	)

	if previous_checkpoint != null:
		previous_checkpoint.set_active(
			false
		)

	active_checkpoint = new_checkpoint
	active_checkpoint.set_active(
		true
	)

	if should_emit_changed:
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
