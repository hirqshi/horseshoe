class_name ReverseStaminaHud
extends HudElement

@export_category("references")
@export var progress_bar: TextureProgressBar
@export var percent_label: Label

@export_category("bar smoothing")
@export_range(
	0.1,
	100.0,
	0.1,
	"suffix:1/s"
) var bar_follow_speed: float = 16.0

@export_category("percent display")
@export var percent_prefix: String = ""
@export var percent_suffix: String = "%"

@export_range(
	0,
	2,
	1
) var percent_decimal_places: int = 0

@export_category("color gradient")
@export var stamina_gradient: Gradient

var _reverse_stamina: ReverseStamina

var _target_normalized_value: float = 1.0
var _displayed_normalized_value: float = 1.0


func _ready() -> void:
	super._ready()

	if progress_bar == null:
		push_error(
			"ReverseStaminaHud requires ProgressBar."
		)
		set_process(false)
		return

	if percent_label == null:
		push_error(
			"ReverseStaminaHud requires PercentLabel."
		)
		set_process(false)
		return

	if stamina_gradient == null:
		push_error(
			"ReverseStaminaHud requires StaminaGradient."
		)
		set_process(false)
		return

	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 100.0

	_update_percent_label()

	_apply_stamina_color(
		_displayed_normalized_value
	)


func _process(
	delta: float
) -> void:
	super._process(delta)

	if progress_bar == null:
		return

	var follow_weight: float = (
		1.0
		- exp(
			-bar_follow_speed
			* delta
		)
	)

	_displayed_normalized_value = lerpf(
		_displayed_normalized_value,
		_target_normalized_value,
		follow_weight
	)

	progress_bar.value = (
		_displayed_normalized_value
		* progress_bar.max_value
	)

	_update_percent_label()

	_apply_stamina_color(
		_displayed_normalized_value
	)


func set_reverse_stamina(
	reverse_stamina: ReverseStamina
) -> void:
	if _reverse_stamina != null:
		if _reverse_stamina.value_changed.is_connected(
			_on_reverse_stamina_value_changed
		):
			_reverse_stamina.value_changed.disconnect(
				_on_reverse_stamina_value_changed
			)

	_reverse_stamina = reverse_stamina

	if _reverse_stamina == null:
		push_error(
			"ReverseStaminaHud requires ReverseStamina."
		)
		return

	_target_normalized_value = (
		_reverse_stamina.get_normalized_value()
	)

	_displayed_normalized_value = (
		_target_normalized_value
	)

	_reverse_stamina.value_changed.connect(
		_on_reverse_stamina_value_changed
	)

	_update_percent_label()

	_apply_stamina_color(
		_displayed_normalized_value
	)


func _on_reverse_stamina_value_changed(
	_current_value: float,
	_max_value: float,
	normalized_value: float
) -> void:
	_target_normalized_value = clampf(
		normalized_value,
		0.0,
		1.0
	)


func _update_percent_label() -> void:
	if percent_label == null:
		return

	var percent_value: float = (
		clampf(
			_displayed_normalized_value,
			0.0,
			1.0
		)
		* 100.0
	)

	var formatted_percent: String = ""

	if percent_decimal_places <= 0:
		formatted_percent = str(
			roundi(
				percent_value
			)
		)
	else:
		var format_string: String = (
			"%%.%df"
			% percent_decimal_places
		)

		formatted_percent = (
			format_string
			% percent_value
		)

	percent_label.text = (
		percent_prefix
		+ formatted_percent
		+ percent_suffix
	)


func _apply_stamina_color(
	normalized_value: float
) -> void:
	if progress_bar == null:
		return

	if stamina_gradient == null:
		return

	var stamina_color: Color = stamina_gradient.sample(
		clampf(
			normalized_value,
			0.0,
			1.0
		)
	)

	progress_bar.modulate = stamina_color
	percent_label.modulate = stamina_color
