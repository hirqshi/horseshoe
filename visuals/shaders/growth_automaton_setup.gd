extends Control

# Growth automaton - two-pass architecture:
# 1. Buffer pass: ping-ponged SubViewports run growth_automaton_buffer.gdshader,
#    each reading the OTHER's frozen texture as previous_frame (same constraint
#    as the Rorschach feedback shader - can't read a viewport while writing it).
# 2. Image pass: a single opaque ColorRect on top reads whichever buffer was
#    just rendered and applies the final mod() colorize step.
#
# Scene tree required:
# Control (this script, Full Rect)
# +-- ContainerA (SubViewportContainer, Full Rect, stretch: true, visible: true - keep visible!)
#     +-- ViewportA (SubViewport)
#         +-- RectA (ColorRect, Full Rect, growth_automaton_buffer.gdshader, material instance #1)
# +-- ContainerB (SubViewportContainer, Full Rect, stretch: true, visible: true - keep visible!)
#     +-- ViewportB (SubViewport)
#         +-- RectB (ColorRect, Full Rect, growth_automaton_buffer.gdshader, material instance #2)
# +-- ImagePassRect (ColorRect, Full Rect, growth_automaton_image.gdshader)
#     -- must be LAST child so it draws on top, hiding ContainerA/B visually
#
# IMPORTANT: do NOT toggle ContainerA/B .visible - that stops their rendering
# entirely (Godot quirk) and breaks the buffer computation. Only toggle
# render_target_update_mode. ImagePassRect being opaque on top hides them from view.

@onready var container_a: SubViewportContainer = $ContainerA
@onready var container_b: SubViewportContainer = $ContainerB
@onready var viewport_a: SubViewport = $ContainerA/ViewportA
@onready var viewport_b: SubViewport = $ContainerB/ViewportB
@onready var rect_a: ColorRect = $ContainerA/ViewportA/RectA
@onready var rect_b: ColorRect = $ContainerB/ViewportB/RectB
@onready var image_pass_rect: ColorRect = $ImagePassRect

var material_a: ShaderMaterial
var material_b: ShaderMaterial
var image_material: ShaderMaterial
var use_a := true

func _ready() -> void:
	material_a = rect_a.material as ShaderMaterial
	material_b = rect_b.material as ShaderMaterial
	image_material = image_pass_rect.material as ShaderMaterial

	if material_a == null or material_b == null or image_material == null:
		push_error("Missing ShaderMaterial on RectA/RectB/ImagePassRect")
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
		image_material.set_shader_parameter("buffer_texture", viewport_a.get_texture())
	else:
		material_b.set_shader_parameter("previous_frame", viewport_a.get_texture())
		viewport_b.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
		image_material.set_shader_parameter("buffer_texture", viewport_b.get_texture())

	use_a = !use_a
