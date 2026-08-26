class_name MovementAction
extends Node

func setup(_motor: MovementMotor) -> void:
	pass

func can_start(_context: MovementContext) -> bool:
	return false

func try_buffer(_context: MovementContext) -> bool:
	return false

func start(_context: MovementContext) -> void:
	pass

func physics_tick(_context: MovementContext) -> bool:
	return false

func finish(_context: MovementContext) -> void:
	pass

func blocks_locomotion_transition() -> bool:
	return false
