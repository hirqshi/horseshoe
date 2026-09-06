class_name CornerFrameHud
extends HudElement

@export_category("references")
@export var frame_texture: Texture2D

@export var top_left: TextureRect
@export var top_right: TextureRect
@export var bottom_left: TextureRect
@export var bottom_right: TextureRect

@export_category("spread")
@export_range(
	0.0,
	3.0,
	0.01
) var spread_multiplier: float = 1.0

@export var top_left_spread_direction: Vector2 = Vector2(
	-1.0,
	-1.0
)

@export var top_right_spread_direction: Vector2 = Vector2(
	1.0,
	-1.0
)

@export var bottom_left_spread_direction: Vector2 = Vector2(
	-1.0,
	1.0
)

@export var bottom_right_spread_direction: Vector2 = Vector2(
	1.0,
	1.0
)

var _top_left_base_position: Vector2 = Vector2.ZERO
var _top_right_base_position: Vector2 = Vector2.ZERO
var _bottom_left_base_position: Vector2 = Vector2.ZERO
var _bottom_right_base_position: Vector2 = Vector2.ZERO

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

	if top_left == null:
		push_error(
			"%s requires TopLeft."
			% name
		)
		set_process(false)
		return

	if top_right == null:
		push_error(
			"%s requires TopRight."
			% name
		)
		set_process(false)
		return

	if bottom_left == null:
		push_error(
			"%s requires BottomLeft."
			% name
		)
		set_process(false)
		return

	if bottom_right == null:
		push_error(
			"%s requires BottomRight."
			% name
		)
		set_process(false)
		return

	_apply_corner_atlases()

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
	_top_left_base_position = top_left.position
	_top_right_base_position = top_right.position
	_bottom_left_base_position = bottom_left.position
	_bottom_right_base_position = bottom_right.position

	_is_initialized = true

	_apply_spread()


func _apply_corner_atlases() -> void:
	var texture_size: Vector2 = frame_texture.get_size()

	var half_width_px: float = floorf(
		texture_size.x
		* 0.5
	)

	var half_height_px: float = floorf(
		texture_size.y
		* 0.5
	)

	if half_width_px <= 0.0:
		push_error(
			"%s FrameTexture width is invalid."
			% name
		)
		return

	if half_height_px <= 0.0:
		push_error(
			"%s FrameTexture height is invalid."
			% name
		)
		return

	top_left.texture = _create_atlas_texture(
		Rect2(
			0.0,
			0.0,
			half_width_px,
			half_height_px
		)
	)

	top_right.texture = _create_atlas_texture(
		Rect2(
			half_width_px,
			0.0,
			half_width_px,
			half_height_px
		)
	)

	bottom_left.texture = _create_atlas_texture(
		Rect2(
			0.0,
			half_height_px,
			half_width_px,
			half_height_px
		)
	)

	bottom_right.texture = _create_atlas_texture(
		Rect2(
			half_width_px,
			half_height_px,
			half_width_px,
			half_height_px
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

	top_left.position = (
		_top_left_base_position
		+ top_left_spread_direction.normalized()
		* final_spread_px
	)

	top_right.position = (
		_top_right_base_position
		+ top_right_spread_direction.normalized()
		* final_spread_px
	)

	bottom_left.position = (
		_bottom_left_base_position
		+ bottom_left_spread_direction.normalized()
		* final_spread_px
	)

	bottom_right.position = (
		_bottom_right_base_position
		+ bottom_right_spread_direction.normalized()
		* final_spread_px
	)
