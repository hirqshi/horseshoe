class_name ChargeFrameHud
extends HudElement

@export_category("charge icons")
@export var charge_icons: Array[ChargeIcon] = []

var _available_charges: int = 0
var _is_move_available: bool = false
var _is_initialized: bool = false


func _ready() -> void:
	super._ready()

	if charge_icons.is_empty():
		push_error(
			"%s requires at least one ChargeIcon."
			% name
		)
		set_process(false)
		return

	for charge_icon: ChargeIcon in charge_icons:
		if charge_icon == null:
			push_error(
				"%s has an empty ChargeIcon reference."
				% name
			)
			set_process(false)
			return

	_apply_state(
		false
	)


func set_charge_state(
	available_charges: int,
	is_move_available: bool
) -> void:
	var clamped_charges: int = clampi(
		available_charges,
		0,
		charge_icons.size()
	)

	var previous_charges: int = _available_charges

	_available_charges = clamped_charges
	_is_move_available = is_move_available

	var should_pulse: bool = _is_initialized

	_apply_state(
		should_pulse,
		previous_charges
	)

	_is_initialized = true


func _apply_state(
	should_pulse: bool,
	previous_charges: int = 0
) -> void:
	for index: int in charge_icons.size():
		var charge_icon: ChargeIcon = charge_icons[index]

		var had_charge: bool = index < previous_charges
		var has_charge: bool = index < _available_charges

		var charge_was_spent: bool = (
			had_charge
			and not has_charge
		)

		var charge_was_restored: bool = (
			not had_charge
			and has_charge
		)

		var icon_should_pulse: bool = (
			should_pulse
			and (
				charge_was_spent
				or charge_was_restored
			)
		)

		charge_icon.set_charge_state(
			has_charge,
			_is_move_available,
			icon_should_pulse
		)
