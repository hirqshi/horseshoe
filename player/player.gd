class_name Player
extends CharacterBody3D

signal look_delta_received(mouse_delta: Vector2)

signal dash_started()
signal slide_started()

@export var look_controller: PlayerLookController

@onready var movement_motor: MovementMotor = (
	get_node_or_null("MovementMotor") as MovementMotor
)
@onready var fall_tracker: FallTracker = (
	get_node_or_null("FallTracker") as FallTracker
)

func _ready() -> void:
	if fall_tracker == null:
		push_error("Player requires FallTracker.")
		return

	fall_tracker.fall_damage_requested.connect(
		_on_fall_damage_requested
	)

	fall_tracker.fatal_fall_detected.connect(
		_on_fatal_fall_detected
	)
	if movement_motor == null:
		push_error("Player requires a MovementMotor child node.")

	if look_controller == null:
		push_error("Player requires PlayerLookController.")
		return

	look_controller.look_delta_received.connect(
		_on_look_delta_received
	)
	if movement_motor == null:
		return
		
	if fall_tracker == null:
		push_error("Player requires FallTracker.")
		return
		
	movement_motor.dash_started.connect(
		_on_dash_started
	)

	movement_motor.slide_started.connect(
		_on_slide_started
	)

func get_fall_tracker() -> FallTracker:
	return fall_tracker

func _on_fall_damage_requested(
	damage: float,
	fall_distance_m: float,
	impact_speed_mps: float
) -> void:
	print(
		"Fall damage: %.1f | distance: %.2f m | impact: %.2f m/s"
		% [
			damage,
			fall_distance_m,
			impact_speed_mps,
		]
	)

func _on_fatal_fall_detected(
	fall_distance_m: float,
	impact_speed_mps: float
) -> void:
	print(
		"Fatal fall | distance: %.2f m | impact: %.2f m/s"
		% [
			fall_distance_m,
			impact_speed_mps,
		]
	)

func _on_look_delta_received(
	mouse_delta: Vector2
) -> void:
	look_delta_received.emit(mouse_delta)

func _on_dash_started() -> void:
	dash_started.emit()

func _on_slide_started() -> void:
	slide_started.emit()
