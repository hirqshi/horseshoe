class_name LocomotionState
extends Node

func enter(_context: MovementContext) -> void:
	pass

func exit(_context: MovementContext) -> void:
	pass

func can_enter(_context: MovementContext) -> bool:
	return false

func can_continue(_context: MovementContext) -> bool:
	return true

func physics_tick(_context: MovementContext) -> StringName:
	return &""
