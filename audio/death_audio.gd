class_name DeathAudio
extends Node

@export_category("audio player")
@export var death_player: AudioStreamPlayer

@export_category("death")
@export var death_streams: Array[AudioStream] = []
@export_range(0.1, 3.0, 0.01) var death_pitch_min: float = 0.98
@export_range(0.1, 3.0, 0.01) var death_pitch_max: float = 1.02


func _ready() -> void:
	if death_player == null:
		push_error(
			"DeathAudio requires DeathPlayer."
		)
		set_process(false)
		return

	death_player.bus = &"Ui"
	death_player.max_polyphony = 1


func play_death() -> void:
	if death_player == null:
		return

	if death_streams.is_empty():
		push_warning(
			"DeathAudio has no death streams."
		)
		return

	var stream_index: int = randi_range(
		0,
		death_streams.size() - 1
	)

	var selected_stream: AudioStream = (
		death_streams[stream_index]
	)

	death_player.stream = selected_stream
	death_player.pitch_scale = randf_range(
		death_pitch_min,
		death_pitch_max
	)
	death_player.play()
