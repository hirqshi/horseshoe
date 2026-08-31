class_name RestZone
extends Area3D

signal player_entered(
	rest_zone: RestZone,
	body: Node3D
)

signal player_exited(
	rest_zone: RestZone,
	body: Node3D
)


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)


func _on_body_entered(
	body: Node3D
) -> void:
	player_entered.emit(
		self,
		body
	)


func _on_body_exited(
	body: Node3D
) -> void:
	player_exited.emit(
		self,
		body
	)
