class_name Pickup
extends Area3D

signal collected(
	pickup: Pickup,
	player: Player,
	definition: PickupDefinition
)

@export_category("definition")
@export var definition: PickupDefinition

@export_category("references")
@export var collision_shape: CollisionShape3D
@export var visual: PickupVisual
@export var pickup_audio: PickupAudio

@export_category("collection")
@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:s"
) var collection_audio_tail_s: float = 1.5

var _is_collected: bool = false


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)

	if definition == null:
		push_error(
			"%s requires PickupDefinition."
			% name
		)
		set_process(false)
		return

	if collision_shape == null:
		push_error(
			"%s requires CollisionShape3D."
			% name
		)
		set_process(false)
		return

	if visual != null:
		visual.apply_definition(definition)

	if pickup_audio != null:
		pickup_audio.configure(definition)


func _on_body_entered(
	body: Node3D
) -> void:
	if _is_collected:
		return

	var player: Player = body as Player

	if player == null:
		return

	var movement_motor: MovementMotor = (
		player.get_movement_motor()
	)

	if movement_motor == null:
		push_error(
			"%s could not find Player/MovementMotor."
			% name
		)
		return

	_collect(
		player,
		movement_motor
	)


func _collect(
	player: Player,
	movement_motor: MovementMotor
) -> void:
	if _is_collected:
		return

	_is_collected = true

	_apply_effect(movement_motor)

	set_deferred(
		"monitoring",
		false
	)

	set_deferred(
		"monitorable",
		false
	)

	collision_shape.set_deferred(
		"disabled",
		true
	)

	if visual != null:
		visual.hide_after_collect()

	if pickup_audio != null:
		pickup_audio.play_collected()

	collected.emit(
		self,
		player,
		definition
	)


func reset_for_respawn() -> void:
	if not _is_collected:
		return

	_is_collected = false

	set_deferred(
		"monitoring",
		true
	)

	set_deferred(
		"monitorable",
		true
	)

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			false
		)

	if visual != null:
		visual.show_after_respawn()

	if pickup_audio != null:
		pickup_audio.restart_hum()


func _apply_effect(
	movement_motor: MovementMotor
) -> void:
	match definition.effect_type:
		PickupDefinition.EffectType.DASH_CHARGES:
			movement_motor.restore_dash_charges(
				definition.charge_amount
			)

		PickupDefinition.EffectType.WALL_JUMP_CHARGES:
			movement_motor.restore_wall_jump_charges(
				definition.charge_amount
			)

		PickupDefinition.EffectType.SPEED_BOOST:
			movement_motor.apply_speed_boost(
				definition.speed_multiplier,
				definition.speed_boost_duration_s
			)

		PickupDefinition.EffectType.FORWARD_IMPULSE:
			movement_motor.apply_forward_impulse(
				definition.impulse_minimum_speed_mps
			)

		PickupDefinition.EffectType.REPULSION:
			movement_motor.apply_repulsion(
				definition.impulse_minimum_speed_mps
			)
