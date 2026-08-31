class_name DeathZone
extends Area3D

signal player_entered(
	death_zone: DeathZone,
	body: Node3D
)


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)


func _on_body_entered(
	body: Node3D
) -> void:
	player_entered.emit(
		self,
		body
	)
