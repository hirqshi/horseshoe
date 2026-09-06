class_name SplitFrameHud
extends HudElement

@export_category("references")
@export var frame_texture: Texture2D
@export var left_half: TextureRect
@export var right_half: TextureRect

@export_category("spread")
@export_range(
	0.0,
	3.0,
	0.01
) var spread_multiplier: float = 0.45

@export var left_spread_direction: Vector2 = Vector2(
	-1.0,
	0.0
)

@export var right_spread_direction: Vector2 = Vector2(
	1.0,
	0.0
)

var _left_base_position: Vector2 = Vector2.ZERO
var _right_base_position: Vector2 = Vector2.ZERO

var _current_spread_px: float = 0.0
var _is_initialized: bool = false


func _ready() -> void:
	super._ready()

	if frame_texture == null:
		push_error(
			"%s requires FrameTexture."
			% name
		)
		set_process(false)
		return

	if left_half == null:
		push_error(
			"%s requires LeftHalf."
			% name
		)
		set_process(false)
		return

	if right_half == null:
		push_error(
			"%s requires RightHalf."
			% name
		)
		set_process(false)
		return

	_apply_split_atlases()

	call_deferred(
		"_cache_base_positions"
	)


func set_spread_px(
	value: float
) -> void:
	_current_spread_px = maxf(
		value,
		0.0
	)

	_apply_spread()


func _cache_base_positions() -> void:
	_left_base_position = left_half.position
	_right_base_position = right_half.position

	_is_initialized = true

	_apply_spread()


func _apply_split_atlases() -> void:
	var texture_size: Vector2 = frame_texture.get_size()

	var half_width_px: float = floorf(
		texture_size.x
		* 0.5
	)

	if half_width_px <= 0.0:
		push_error(
			"%s FrameTexture width is invalid."
			% name
		)
		return

	if texture_size.y <= 0.0:
		push_error(
			"%s FrameTexture height is invalid."
			% name
		)
		return

	left_half.texture = _create_atlas_texture(
		Rect2(
			0.0,
			0.0,
			half_width_px,
			texture_size.y
		)
	)

	right_half.texture = _create_atlas_texture(
		Rect2(
			half_width_px,
			0.0,
			half_width_px,
			texture_size.y
		)
	)


func _create_atlas_texture(
	region: Rect2
) -> AtlasTexture:
	var atlas_texture: AtlasTexture = AtlasTexture.new()

	atlas_texture.atlas = frame_texture
	atlas_texture.region = region

	return atlas_texture


func _apply_spread() -> void:
	if not _is_initialized:
		return

	var final_spread_px: float = (
		_current_spread_px
		* spread_multiplier
	)

	left_half.position = (
		_left_base_position
		+ left_spread_direction.normalized()
		* final_spread_px
	)

	right_half.position = (
		_right_base_position
		+ right_spread_direction.normalized()
		* final_spread_px
	)
