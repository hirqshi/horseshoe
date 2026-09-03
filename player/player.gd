class_name Player
extends CharacterBody3D

signal look_delta_received(mouse_delta: Vector2)

signal dash_started()
signal slide_started()

signal fatal_fall_detected(
	fall_distance_m: float,
	impact_speed_mps: float
)
signal reverse_stamina_depleted()
signal instant_death_requested()

@export var look_controller: PlayerLookController

@onready var movement_motor: MovementMotor = (
	get_node_or_null("MovementMotor") as MovementMotor
)

@onready var fall_tracker: FallTracker = (
	get_node_or_null("FallTracker") as FallTracker
)

@onready var reverse_stamina: ReverseStamina = (
	get_node_or_null("ReverseStamina") as ReverseStamina
)


func _ready() -> void:
	if movement_motor == null:
		push_error(
			"Player requires a MovementMotor child node."
		)
		return

	if fall_tracker == null:
		push_error(
			"Player requires a FallTracker child node."
		)
		return

	if reverse_stamina == null:
		push_error(
			"Player requires a ReverseStamina child node."
		)
		return

	if look_controller == null:
		push_error(
			"Player requires a PlayerLookController."
		)
		return

	fall_tracker.fall_damage_requested.connect(
		_on_fall_damage_requested
	)

	fall_tracker.fatal_fall_detected.connect(
		_on_fatal_fall_detected
	)
	
	reverse_stamina.depleted.connect(
		_on_reverse_stamina_depleted
	)
	
	look_controller.look_delta_received.connect(
		_on_look_delta_received
	)

	movement_motor.dash_started.connect(
		_on_dash_started
	)

	movement_motor.slide_started.connect(
		_on_slide_started
	)

func reset_after_respawn() -> void:
	if movement_motor != null:
		movement_motor.reset_after_respawn()

		movement_motor.clear_speed_boost()

		var glide_state: GlideState = (
			movement_motor.get_glide_state()
		)

		if glide_state != null:
			glide_state.restore_all_charges()

	if reverse_stamina != null:
		reverse_stamina.restore_full()

func request_instant_death() -> void:
	instant_death_requested.emit()

func get_fall_tracker() -> FallTracker:
	return fall_tracker


func get_reverse_stamina() -> ReverseStamina:
	return reverse_stamina

func get_movement_motor() -> MovementMotor:
	return movement_motor

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
	fatal_fall_detected.emit(
		fall_distance_m,
		impact_speed_mps
	)


func _on_look_delta_received(
	mouse_delta: Vector2
) -> void:
	look_delta_received.emit(mouse_delta)


func _on_dash_started() -> void:
	dash_started.emit()


func _on_slide_started() -> void:
	slide_started.emit()

func _on_reverse_stamina_depleted() -> void:
	reverse_stamina_depleted.emit()
