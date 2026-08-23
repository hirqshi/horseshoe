class_name Player
extends CharacterBody3D

@onready var movement_motor: MovementMotor = (
	get_node_or_null("MovementMotor") as MovementMotor
)

func _ready() -> void:
	if movement_motor == null:
		push_error("Player requires a MovementMotor child node.")
