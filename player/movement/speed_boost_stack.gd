class_name SpeedBoostStack
extends RefCounted

var multiplier: float = 1.0
var remaining_s: float = 0.0


func _init(
	initial_multiplier: float,
	initial_remaining_s: float
) -> void:
	multiplier = maxf(
		initial_multiplier,
		1.0
	)

	remaining_s = maxf(
		initial_remaining_s,
		0.0
	)
