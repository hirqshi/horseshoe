class_name AudioSettingsPanel
extends Control

@export var audio_rows: Array[AudioSettingRow] = []


func _ready() -> void:
	refresh()


func refresh() -> void:
	for audio_row: AudioSettingRow in audio_rows:
		if audio_row == null:
			continue

		audio_row.refresh()
