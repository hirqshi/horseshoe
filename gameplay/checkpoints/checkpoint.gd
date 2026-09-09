@tool
class_name Checkpoint
extends Area3D

signal body_reached(
	checkpoint: Checkpoint,
	body: Node3D
)

signal body_presence_changed(
	checkpoint: Checkpoint,
	body: Node3D,
	is_inside: bool
)

signal active_changed(
	is_active: bool
)

@export_group("Save")
@export_storage var checkpoint_id: StringName = &""

@export_group("References")
@export var spawn_anchor: Marker3D
@export var visual: CheckpointVisual

var is_active: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)

	if spawn_anchor == null:
		push_warning(
			"%s has no SpawnAnchor assigned."
			% name
		)

	if visual != null:
		visual.set_active(
			is_active
		)

func set_active(
	value: bool
) -> void:
	if is_active == value:
		return

	is_active = value

	if visual != null:
		visual.set_active(
			is_active
		)

	active_changed.emit(
		is_active
	)


func get_spawn_transform() -> Transform3D:
	if spawn_anchor == null:
		push_error(
			"%s cannot provide a spawn transform: "
			+ "SpawnAnchor is missing."
			% name
		)

		return global_transform

	var anchor_transform: Transform3D = (
		spawn_anchor.global_transform
	)

	return Transform3D(
		anchor_transform.basis.orthonormalized(),
		anchor_transform.origin
	)


func _on_body_entered(
	body: Node3D
) -> void:
	body_reached.emit(
		self,
		body
	)

	body_presence_changed.emit(
		self,
		body,
		true
	)


func _on_body_exited(
	body: Node3D
) -> void:
	body_presence_changed.emit(
		self,
		body,
		false
	)
