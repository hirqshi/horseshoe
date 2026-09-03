class_name PickupAudio
extends Node

@export_category("audio players")
@export var pickup_player: AudioStreamPlayer3D
@export var hum_player: AudioStreamPlayer3D

@export_category("pickup sound")
@export_range(0.1, 3.0, 0.01) var pickup_pitch_min: float = 0.97
@export_range(0.1, 3.0, 0.01) var pickup_pitch_max: float = 1.03

var _definition: PickupDefinition


func _ready() -> void:
	if pickup_player != null:
		pickup_player.bus = &"WorldSfx"
		pickup_player.max_polyphony = 1

	if hum_player != null:
		hum_player.bus = &"Ambience"
		hum_player.max_polyphony = 1


func configure(
	definition: PickupDefinition
) -> void:
	_definition = definition

	if _definition == null:
		return

	if hum_player == null:
		return

	hum_player.stream = _definition.hum_stream

	if hum_player.stream == null:
		return

	if not hum_player.playing:
		hum_player.play()


func play_collected() -> void:
	if hum_player != null:
		hum_player.stop()

	if pickup_player == null:
		return

	if _definition == null:
		return

	if _definition.pickup_streams.is_empty():
		return

	var stream_index: int = randi_range(
		0,
		_definition.pickup_streams.size() - 1
	)

	var selected_stream: AudioStream = (
		_definition.pickup_streams[stream_index]
	)

	pickup_player.stream = selected_stream
	pickup_player.pitch_scale = randf_range(
		pickup_pitch_min,
		pickup_pitch_max
	)
	pickup_player.play()


func restart_hum() -> void:
	if hum_player == null:
		return

	if hum_player.stream == null:
		return

	if hum_player.playing:
		return

	hum_player.play()
