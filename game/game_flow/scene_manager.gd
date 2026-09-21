extends Node

signal chapter_launch_requested(
	launch_request: ChapterLaunchRequest
)

signal chapter_scene_loaded(
	chapter_definition: ChapterDefinition,
	start_mode: int
)

signal main_menu_requested()

signal scene_transition_started()
signal scene_transition_finished()

const CHAPTER_CATALOG_PATH: String = (
	"res://data/chapters/catalog/default_chapter_catalog.tres"
)

const MAIN_MENU_SCENE_PATH: String = (
	"res://ui/main_menu/main_menu.tscn"
)

const SCREEN_TRANSITION_SCENE: PackedScene = preload(
	"res://game/game_flow/screen_transition.tscn"
)

const GAME_SCENE_PATH: String = (
	"res://game/game.tscn"
)

const TRANSITION_COVER_DURATION_S: float = 0.42
const TRANSITION_REVEAL_DURATION_S: float = 0.48

var _chapter_catalog: ChapterCatalog = null
var _pending_chapter_launch_request: ChapterLaunchRequest = null
var _active_chapter_definition: ChapterDefinition = null

var _screen_transition: ScreenTransition = null
var _is_scene_transition_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_screen_transition = (
		SCREEN_TRANSITION_SCENE.instantiate()
		as ScreenTransition
	)

	if _screen_transition == null:
		push_error(
			"SceneManager failed to instantiate ScreenTransition."
		)
		return

	add_child(
		_screen_transition
	)


func start_chapter_from_beginning(
	chapter_definition: ChapterDefinition
) -> bool:
	return _request_chapter_launch(
		chapter_definition,
		ChapterStartMode.Id.START_FROM_BEGINNING
	)


func start_new_game_plus_chapter(
	chapter_definition: ChapterDefinition
) -> bool:
	if not SaveManager.has_active_profile():
		push_error(
			"SceneManager: cannot start NG+ chapter without an active profile."
		)
		return false

	if not SaveManager.active_profile.is_new_game_plus_unlocked:
		push_error(
			"SceneManager: NG+ is not unlocked for the active profile."
		)
		return false

	return _request_chapter_launch(
		chapter_definition,
		ChapterStartMode.Id.NEW_GAME_PLUS
	)


func continue_active_profile() -> bool:
	if not SaveManager.has_active_profile():
		push_error(
			"SceneManager: cannot continue without an active profile."
		)
		return false

	var chapter_id: StringName = (
		SaveManager.active_profile.last_checkpoint_chapter_id
	)

	if chapter_id.is_empty():
		var first_chapter: ChapterDefinition = _get_first_chapter()

		if first_chapter == null:
			return false

		return start_chapter_from_beginning(
			first_chapter
		)

	var chapter_definition: ChapterDefinition = (
		_get_chapter_by_id(
			chapter_id
		)
	)

	if chapter_definition == null:
		push_error(
			"SceneManager: saved chapter '%s' is missing from ChapterCatalog."
			% chapter_id
		)
		return false

	return _request_chapter_launch(
		chapter_definition,
		ChapterStartMode.Id.RESUME_FROM_CHECKPOINT
	)


func restart_current_chapter() -> bool:
	if _active_chapter_definition == null:
		push_error(
			"SceneManager: cannot restart because no active chapter is registered."
		)
		return false

	return _request_chapter_launch(
		_active_chapter_definition,
		ChapterStartMode.Id.START_FROM_BEGINNING
	)


func return_to_main_menu() -> bool:
	if _is_scene_transition_active:
		push_warning(
			"SceneManager: a scene transition is already active."
		)
		return false

	if _screen_transition == null:
		push_error(
			"SceneManager: ScreenTransition is missing."
		)
		return false

	_transition_to_main_menu()

	return true


func consume_chapter_launch_request() -> ChapterLaunchRequest:
	var result: ChapterLaunchRequest = (
		_pending_chapter_launch_request
	)

	_pending_chapter_launch_request = null

	return result


func register_active_chapter(
	chapter_definition: ChapterDefinition
) -> void:
	if chapter_definition == null:
		push_error(
			"SceneManager: cannot register a null active chapter."
		)
		return

	_active_chapter_definition = chapter_definition


func get_active_chapter_definition() -> ChapterDefinition:
	return _active_chapter_definition


func get_chapter_catalog() -> ChapterCatalog:
	return _get_chapter_catalog()


func _request_chapter_launch(
	chapter_definition: ChapterDefinition,
	start_mode: int
) -> bool:
	if _is_scene_transition_active:
		push_warning(
			"SceneManager: a scene transition is already active."
		)
		return false

	if not _validate_chapter_launch(
		chapter_definition,
		start_mode
	):
		return false

	var launch_request: ChapterLaunchRequest = (
		ChapterLaunchRequest.create(
			chapter_definition,
			start_mode
		)
	)

	_pending_chapter_launch_request = launch_request

	chapter_launch_requested.emit(
		launch_request
	)

	_transition_to_chapter(
		launch_request
	)

	return true


func _transition_to_chapter(
	launch_request: ChapterLaunchRequest
) -> void:
	if launch_request == null:
		return

	if not launch_request.is_valid():
		push_error(
			"SceneManager: attempted to transition with an invalid launch request."
		)
		return

	if _screen_transition == null:
		push_error(
			"SceneManager: ScreenTransition is missing."
		)
		return

	_is_scene_transition_active = true
	scene_transition_started.emit()

	await _screen_transition.cover(
		TRANSITION_COVER_DURATION_S
	)

	if SaveManager.has_active_profile():
		SaveManager.save_active_profile()

	var change_error: Error = get_tree().change_scene_to_file(
		GAME_SCENE_PATH
	)

	if change_error != OK:
		push_error(
			"SceneManager: failed to load chapter '%s'. Error: %d."
			% [
				launch_request.chapter_definition.chapter_id,
				change_error,
			]
		)

		_pending_chapter_launch_request = null

		await _screen_transition.reveal(
			TRANSITION_REVEAL_DURATION_S
		)

		_is_scene_transition_active = false
		scene_transition_finished.emit()

		return

	await get_tree().process_frame

	if UiAudio != null:
		UiAudio.play_game_start()

	chapter_scene_loaded.emit(
		launch_request.chapter_definition,
		launch_request.start_mode
	)

	await _screen_transition.reveal(
		TRANSITION_REVEAL_DURATION_S
	)

	_is_scene_transition_active = false
	scene_transition_finished.emit()


func _transition_to_main_menu() -> void:
	_is_scene_transition_active = true
	scene_transition_started.emit()

	await _screen_transition.cover(
		TRANSITION_COVER_DURATION_S
	)

	if SaveManager.has_active_profile():
		SaveManager.save_active_profile()

	_pending_chapter_launch_request = null
	_active_chapter_definition = null

	var change_error: Error = get_tree().change_scene_to_file(
		MAIN_MENU_SCENE_PATH
	)

	if change_error != OK:
		push_error(
			"SceneManager: failed to load main menu scene '%s'. Error: %d."
			% [
				MAIN_MENU_SCENE_PATH,
				change_error,
			]
		)

		await _screen_transition.reveal(
			TRANSITION_REVEAL_DURATION_S
		)

		_is_scene_transition_active = false
		scene_transition_finished.emit()

		return

	await get_tree().process_frame

	main_menu_requested.emit()

	await _screen_transition.reveal(
		TRANSITION_REVEAL_DURATION_S
	)

	_is_scene_transition_active = false
	scene_transition_finished.emit()


func _validate_chapter_launch(
	chapter_definition: ChapterDefinition,
	start_mode: int
) -> bool:
	if chapter_definition == null:
		push_error(
			"SceneManager: chapter definition is null."
		)
		return false

	if not chapter_definition.is_valid_definition():
		push_error(
			"SceneManager: chapter definition '%s' is invalid."
			% chapter_definition.resource_path
		)
		return false

	if (
		start_mode != ChapterStartMode.Id.START_FROM_BEGINNING
		and start_mode != ChapterStartMode.Id.RESUME_FROM_CHECKPOINT
		and start_mode != ChapterStartMode.Id.NEW_GAME_PLUS
	):
		push_error(
			"SceneManager: invalid chapter start mode %d."
			% start_mode
		)
		return false

	if not SaveManager.has_active_profile():
		push_error(
			"SceneManager: cannot launch a chapter without an active profile."
		)
		return false

	if (
		start_mode != ChapterStartMode.Id.NEW_GAME_PLUS
		and not SaveManager.is_chapter_available(
			chapter_definition
		)
	):
		push_error(
			"SceneManager: chapter '%s' is not unlocked."
			% chapter_definition.chapter_id
		)
		return false

	return true


func _get_chapter_by_id(
	chapter_id: StringName
) -> ChapterDefinition:
	var chapter_catalog: ChapterCatalog = _get_chapter_catalog()

	if chapter_catalog == null:
		return null

	return chapter_catalog.get_chapter_by_id(
		chapter_id
	)


func _get_first_chapter() -> ChapterDefinition:
	var chapter_catalog: ChapterCatalog = _get_chapter_catalog()

	if chapter_catalog == null:
		return null

	return chapter_catalog.get_first_chapter()


func _get_chapter_catalog() -> ChapterCatalog:
	if _chapter_catalog != null:
		return _chapter_catalog

	var loaded_resource: Resource = ResourceLoader.load(
		CHAPTER_CATALOG_PATH
	)

	_chapter_catalog = loaded_resource as ChapterCatalog

	if _chapter_catalog == null:
		push_error(
			"SceneManager: failed to load ChapterCatalog at '%s'."
			% CHAPTER_CATALOG_PATH
		)
		return null

	if not _chapter_catalog.is_valid_catalog():
		push_error(
			"SceneManager: ChapterCatalog '%s' is invalid."
			% CHAPTER_CATALOG_PATH
		)
		return null

	return _chapter_catalog
