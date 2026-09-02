class_name CheckpointAudio
extends Node

@export_category("audio players")
@export var activation_player: AudioStreamPlayer3D
@export var hum_player: AudioStreamPlayer3D

@export_category("activation")
@export var activation_streams: Array[AudioStream] = []
@export_range(0.1, 3.0, 0.01) var activation_pitch_min: float = 0.98
@export_range(0.1, 3.0, 0.01) var activation_pitch_max: float = 1.02

var _checkpoint: Checkpoint


func _ready() -> void:
	_checkpoint = get_parent() as Checkpoint

	if _checkpoint == null:
		push_error(
			"CheckpointAudio must be a child of Checkpoint."
		)
		set_process(false)
		return

	_checkpoint.active_changed.connect(
		_on_checkpoint_active_changed
	)

	_setup_hum()


func _setup_hum() -> void:
	if hum_player == null:
		push_warning(
			"CheckpointAudio has no HumPlayer."
		)
		return

	hum_player.bus = &"Ambience"
	hum_player.max_polyphony = 1

	if hum_player.stream == null:
		push_warning(
			"CheckpointAudio HumPlayer has no stream."
		)
		return

	if not hum_player.playing:
		hum_player.play()


func _on_checkpoint_active_changed(
	is_active: bool
) -> void:
	if not is_active:
		return

	_play_activation()


func _play_activation() -> void:
	if activation_player == null:
		return

	if activation_streams.is_empty():
		push_warning(
			"CheckpointAudio has no activation streams."
		)
		return

	var stream_index: int = randi_range(
		0,
		activation_streams.size() - 1
	)

	var selected_stream: AudioStream = (
		activation_streams[stream_index]
	)

	activation_player.bus = &"WorldSfx"
	activation_player.max_polyphony = 2
	activation_player.stream = selected_stream
	activation_player.pitch_scale = randf_range(
		activation_pitch_min,
		activation_pitch_max
	)
	activation_player.play()
