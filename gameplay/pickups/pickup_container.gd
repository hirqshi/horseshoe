class_name PickupContainer
extends Node3D


func reset_pickups() -> void:
	for child: Node in get_children():
		var pickup: Pickup = child as Pickup

		if pickup == null:
			continue

		pickup.reset_for_respawn()
