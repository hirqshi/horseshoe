extends Control

# True ping-pong feedback buffer via two SubViewportContainers.
# Godot 4's RenderingDevice forbids reading a SubViewport's texture while
# rendering into that same SubViewport - so we alternate between two of them,
# one rendering (visible) while the other is frozen (hidden, providing the
# previous_frame texture).
#
# Scene tree required:
# Control (this script, Full Rect)
# +-- ContainerA (SubViewportContainer, Full Rect, stretch: true)
#     +-- ViewportA (SubViewport)
#         +-- RectA (ColorRect, Full Rect, ShaderMaterial instance #1)
# +-- ContainerB (SubViewportContainer, Full Rect, stretch: true)
#     +-- ViewportB (SubViewport)
#         +-- RectB (ColorRect, Full Rect, ShaderMaterial instance #2, SAME shader resource, different material)
#
# IMPORTANT: RectA and RectB must use separate ShaderMaterial resources
# ("Make Unique" on the material), otherwise the previous_frame uniform
# binding will collide between the two.

@onready var container_a: SubViewportContainer = $ContainerA
@onready var container_b: SubViewportContainer = $ContainerB
@onready var viewport_a: SubViewport = $ContainerA/ViewportA
@onready var viewport_b: SubViewport = $ContainerB/ViewportB
@onready var rect_a: ColorRect = $ContainerA/ViewportA/RectA
@onready var rect_b: ColorRect = $ContainerB/ViewportB/RectB

var material_a: ShaderMaterial
var material_b: ShaderMaterial
var use_a := true

func _ready() -> void:
	material_a = rect_a.material as ShaderMaterial
	material_b = rect_b.material as ShaderMaterial

	if material_a == null or material_b == null:
		push_error("RectA/RectB missing ShaderMaterial")
		return

	viewport_a.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	viewport_b.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER

	viewport_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport_b.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _process(_delta: float) -> void:
	if use_a:
		material_a.set_shader_parameter("previous_frame", viewport_b.get_texture())
		viewport_a.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
		container_a.visible = true
		container_b.visible = false
	else:
		material_b.set_shader_parameter("previous_frame", viewport_a.get_texture())
		viewport_b.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
		container_b.visible = true
		container_a.visible = false

	use_a = !use_a
