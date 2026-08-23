class_name ActionController
extends Node

var _motor: MovementMotor
var _actions: Array[MovementAction] = []
var _active_action: MovementAction

func _ready() -> void:
	_motor = get_parent() as MovementMotor

	if _motor == null:
		push_error("ActionController must be a child of MovementMotor.")
		set_process(false)
		return

	for child: Node in get_children():
		var action: MovementAction = child as MovementAction

		if action == null:
			continue

		_actions.append(action)
		action.setup(_motor)

func apply(context: MovementContext) -> void:
	if _active_action != null:
		var is_still_active: bool = _active_action.physics_tick(context)

		if not is_still_active:
			_active_action.finish(context)
			_active_action = null

		return

	for action: MovementAction in _actions:
		if not action.can_start(context):
			continue

		_active_action = action
		_active_action.start(context)

		var is_still_active: bool = _active_action.physics_tick(context)
		if not is_still_active:
			_active_action.finish(context)
			_active_action = null

		return

func has_active_action() -> bool:
	return _active_action != null

func blocks_locomotion_transition() -> bool:
	return (
		_active_action != null
		and _active_action.blocks_locomotion_transition()
	)
