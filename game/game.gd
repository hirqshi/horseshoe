class_name Game
extends Node

@export_group("Development")
@export var allow_direct_scene_start: bool = false
@export_range(0, 2, 1) var development_slot_index: int = 0
@export var development_chapter_definition: ChapterDefinition

@export_group("Scenes")
@export var player_scene: PackedScene

@export_group("References")
@export var world_container: Node3D
@export var in_game_hud: InGameHud
@export var player_death_controller: PlayerDeathController
@export var pause_menu: PauseMenu

var player: Player = null
var world: World = null
var chapter_definition: ChapterDefinition = null


func _ready() -> void:
	if not _validate_persistent_references():
		return

	if not _ensure_active_profile():
		return

	var launch_request: ChapterLaunchRequest = (
		_get_launch_request()
	)

	if launch_request == null:
		return

	chapter_definition = launch_request.chapter_definition

	if not _instantiate_gameplay_nodes():
		return

	_setup_gameplay_nodes()

	SceneManager.register_active_chapter(
		chapter_definition
	)

	_start_chapter(
		launch_request
	)


func _exit_tree() -> void:
	if SaveManager.has_active_profile():
		SaveManager.leave_current_chapter()


func _validate_persistent_references() -> bool:
	if world_container == null:
		push_error(
			"Game requires a WorldContainer."
		)
		return false

	if player_scene == null:
		push_error(
			"Game requires a Player scene."
		)
		return false

	if in_game_hud == null:
		push_error(
			"Game requires an InGameHud."
		)
		return false

	if player_death_controller == null:
		push_error(
			"Game requires a PlayerDeathController."
		)
		return false
		
	if pause_menu == null:
		push_error(
			"Game requires a PauseMenu."
		)
		return false
		
	return true


func _ensure_active_profile() -> bool:
	if SaveManager.has_active_profile():
		return true

	if not allow_direct_scene_start:
		push_error(
			"Game requires an active save profile. "
			+ "Open this scene through MainMenu or SceneManager."
		)
		return false

	var was_loaded: bool = SaveManager.load_or_create_profile(
		development_slot_index
	)

	if not was_loaded:
		push_error(
			"Game could not create or load development save slot %d."
			% development_slot_index
		)
		return false

	return true


func _get_launch_request() -> ChapterLaunchRequest:
	var pending_launch_request: ChapterLaunchRequest = (
		SceneManager.consume_chapter_launch_request()
	)

	if pending_launch_request != null:
		if pending_launch_request.is_valid():
			return pending_launch_request

		push_error(
			"Game received an invalid ChapterLaunchRequest."
		)
		return null

	if not allow_direct_scene_start:
		push_error(
			"Game was opened without a ChapterLaunchRequest."
		)
		return null

	if development_chapter_definition == null:
		push_error(
			"Game direct launch requires a Development Chapter Definition."
		)
		return null

	if not development_chapter_definition.is_valid_definition():
		push_error(
			"Game direct launch received an invalid Development Chapter Definition."
		)
		return null

	return ChapterLaunchRequest.create(
		development_chapter_definition,
		ChapterStartMode.Id.RESUME_FROM_CHECKPOINT
	)


func _instantiate_gameplay_nodes() -> bool:
	player = player_scene.instantiate() as Player

	if player == null:
		push_error(
			"Game failed to instantiate Player."
		)
		return false

	world = chapter_definition.world_scene.instantiate() as World

	if world == null:
		push_error(
			"Game failed to instantiate World for chapter '%s'."
			% chapter_definition.chapter_id
		)
		return false

	world_container.add_child(
		player
	)

	world_container.add_child(
		world
	)

	return true


func _setup_gameplay_nodes() -> void:
	world.setup(
		player
	)

	player_death_controller.setup(
		player,
		world
	)
	
	pause_menu.setup(
		player
	)
	
	in_game_hud.set_player(
		player
	)

	player.look_delta_received.connect(
		in_game_hud.register_look_delta
	)

	player.dash_started.connect(
		in_game_hud._on_player_dash_started
	)

	player.slide_started.connect(
		in_game_hud._on_player_slide_started
	)

	world.checkpoint_activated.connect(
		_on_world_checkpoint_activated
	)


func _start_chapter(
	launch_request: ChapterLaunchRequest
) -> void:
	var should_resume_from_checkpoint: bool = (
		launch_request.start_mode
		== ChapterStartMode.Id.RESUME_FROM_CHECKPOINT
	)

	SaveManager.start_chapter(
		chapter_definition.chapter_id,
		should_resume_from_checkpoint
	)

	if should_resume_from_checkpoint:
		var checkpoint_id: StringName = (
			SaveManager.get_saved_checkpoint_id_for_chapter(
				chapter_definition.chapter_id
			)
		)

		if not checkpoint_id.is_empty():
			var was_restored: bool = world.restore_checkpoint(
				checkpoint_id
			)

			if not was_restored:
				push_warning(
					(
						"Game could not restore checkpoint '%s' "
						+ "for chapter '%s'."
					)
					% [
						checkpoint_id,
						chapter_definition.chapter_id,
					]
				)

				SaveManager.start_chapter(
					chapter_definition.chapter_id,
					false
				)

	_place_player_at_world_respawn()


func _place_player_at_world_respawn() -> void:
	if player == null:
		return

	if world == null:
		return

	var spawn_transform: Transform3D = (
		world.get_respawn_transform()
	)

	player.global_transform = spawn_transform
	player.velocity = Vector3.ZERO

	player.reset_after_respawn()


func _on_world_checkpoint_activated(
	checkpoint: Checkpoint
) -> void:
	if checkpoint == null:
		return

	if checkpoint.checkpoint_id.is_empty():
		push_error(
			"Game cannot save checkpoint '%s': checkpoint_id is empty."
			% checkpoint.name
		)
		return

	SaveManager.commit_checkpoint(
		checkpoint.checkpoint_id
	)
