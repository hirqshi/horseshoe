class_name MenuPreviewFloat
extends Node3D

@export_group("Float")
@export_range(0.0, 5.0, 0.01) var float_amplitude_m: float = 0.06
@export_range(0.0, 10.0, 0.01) var float_speed: float = 1.0
@export_range(0.0, 1.0, 0.01) var float_phase_offset: float = 0.0

@export_group("Rotation")
@export var rotation_speed_deg_s: Vector3 = Vector3(
	0.0,
	8.0,
	0.0
)

var _base_position: Vector3 = Vector3.ZERO
var _base_rotation: Vector3 = Vector3.ZERO
var _time_s: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_base_position = position
	_base_rotation = rotation


func _process(
	delta: float
) -> void:
	_time_s += delta

	var float_offset_y: float = sin(
		(
			_time_s
			+ float_phase_offset
		)
		* float_speed
	) * float_amplitude_m

	position = (
		_base_position
		+ Vector3(
			0.0,
			float_offset_y,
			0.0
		)
	)

	rotation = (
		_base_rotation
		+ Vector3(
			deg_to_rad(
				rotation_speed_deg_s.x
			) * _time_s,
			deg_to_rad(
				rotation_speed_deg_s.y
			) * _time_s,
			deg_to_rad(
				rotation_speed_deg_s.z
			) * _time_s
		)
	)
