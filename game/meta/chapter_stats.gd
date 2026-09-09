class_name ChapterStats
extends RefCounted

var is_completed: bool = false
var completion_count: int = 0
var total_play_time_s: float = 0.0
var total_deaths: int = 0
var best_completion_time_s: float = -1.0
var best_completion_deaths: int = -1

func register_completion(completion_time_s: float, completion_deaths: int) -> void:
	is_completed = true
	completion_count += 1

	if best_completion_time_s < 0.0 or completion_time_s < best_completion_time_s:
		best_completion_time_s = completion_time_s

	if best_completion_deaths < 0 or completion_deaths < best_completion_deaths:
		best_completion_deaths = completion_deaths

func to_dictionary() -> Dictionary[String, Variant]:
	return {
		"is_completed": is_completed,
		"completion_count": completion_count,
		"total_play_time_s": total_play_time_s,
		"total_deaths": total_deaths,
		"best_completion_time_s": best_completion_time_s,
		"best_completion_deaths": best_completion_deaths,
	}

static func from_dictionary(data: Dictionary[String, Variant]) -> ChapterStats:
	var result: ChapterStats = ChapterStats.new()

	result.is_completed = bool(data.get("is_completed", false))
	result.completion_count = int(data.get("completion_count", 0))
	result.total_play_time_s = float(data.get("total_play_time_s", 0.0))
	result.total_deaths = int(data.get("total_deaths", 0))
	result.best_completion_time_s = float(data.get("best_completion_time_s", -1.0))
	result.best_completion_deaths = int(data.get("best_completion_deaths", -1))

	return result
