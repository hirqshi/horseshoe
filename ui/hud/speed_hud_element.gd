class_name SpeedHudElement
extends HudElement

@export_category("references")
@export var speed_label: Label

@export_category("display")
@export var use_total_speed_in_air: bool = true
@export var label_prefix: String = "Speed: "
@export var unit_suffix: String = ""
@export_range(0, 3, 1) var decimal_places: int = 2
@export var is_zero_padded: bool = false
@export_range(0.0, 1000.0, 0.1) var display_speed_cap_mps: float = 999.0

var _player: Player

func _ready() -> void:
	super()

	if speed_label == null:
		push_error("SpeedHudElement requires SpeedLabel.")
		set_process(false)
		return

	_update_label(0.0)

func _process(delta: float) -> void:
	super(delta)

	if _player == null:
		return

	var speed_mps: float = _get_display_speed_mps()
	_update_label(speed_mps)

func set_player(player: Player) -> void:
	_player = player

func _get_display_speed_mps() -> float:
	if _player == null:
		return 0.0

	var horizontal_speed_mps: float = Vector2(
		_player.velocity.x,
		_player.velocity.z
	).length()

	if not use_total_speed_in_air:
		return horizontal_speed_mps

	if _player.is_on_floor():
		return horizontal_speed_mps

	return _player.velocity.length()

func _update_label(speed_mps: float) -> void:
	var clamped_speed_mps: float = clampf(
		speed_mps,
		0.0,
		display_speed_cap_mps
	)

	var speed_text: String = _format_speed(
		clamped_speed_mps
	)

	var suffix_text: String = ""

	if not unit_suffix.is_empty():
		suffix_text = " " + unit_suffix

	speed_label.text = (
		label_prefix
		+ speed_text
		+ suffix_text
	)

func _format_speed(speed_mps: float) -> String:
	var format_string: String = "%%.%df" % decimal_places

	if is_zero_padded:
		var rounded_speed: int = roundi(speed_mps)
		return "%03d" % rounded_speed

	return format_string % speed_mps
