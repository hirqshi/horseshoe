class_name CameraController
extends Node3D

@export var mouse_sensitivity: float = 0.0025
@export_range(1.0, 89.0, 1.0) var max_pitch_deg: float = 85.0
@export var body_path: NodePath

var _body: CharacterBody3D

func _ready() -> void:
	_body = get_node_or_null(body_path) as CharacterBody3D
	if _body == null:
		push_error("CameraController could not find player body: %s." % body_path)
		set_process_input(false)
		return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)

func _rotate_camera(mouse_delta: Vector2) -> void:
	_body.rotate_y(-mouse_delta.x * mouse_sensitivity)

	rotation.x = clampf(
		rotation.x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(-max_pitch_deg),
		deg_to_rad(max_pitch_deg)
	)
