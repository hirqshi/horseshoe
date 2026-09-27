extends Control

# GPU-instanced port of the 4000-point flow-field plotter.
#
# Optimization: the original shader recomputes all 4000 point positions for
# EVERY pixel (resolution.x * resolution.y * 4000 evaluations per frame -
# roughly 8 billion for a 1080p screen). Since each point's position depends
# only on its index and TIME (never on pixel position), we compute all 4000
# positions ONCE per frame on the CPU and let the GPU rasterize them as real
# instanced quads with additive blending. This cuts the cost by 4-5 orders
# of magnitude.
#
# Scene tree required:
# Control (this script, Full Rect)
# +-- BufferContainer (SubViewportContainer, Full Rect, stretch: true, visible: true)
#     +-- BufferViewport (SubViewport)  -- set use_hdr_2d = true in inspector!
#         +-- Points (MultiMeshInstance2D)
#             multimesh: new MultiMesh, transform_format = TRANSFORM_2D, use_colors = false
#             mesh: QuadMesh, size ~ (1,1) (script scales via instance transform)
#             material: ShaderMaterial with point_sprite.gdshader
# +-- ImagePassRect (ColorRect, Full Rect, hsv_density_colorize.gdshader)
#     -- must be LAST child so it draws on top, hiding BufferContainer visually

const POINT_COUNT := 4000
const POINT_PIXEL_SIZE := 3.0  # diameter in pixels, tune to taste

@onready var buffer_viewport: SubViewport = $BufferContainer/BufferViewport
@onready var points: MultiMeshInstance2D = $BufferContainer/BufferViewport/Points
@onready var image_pass_rect: ColorRect = $ImagePassRect

var multimesh: MultiMesh
var image_material: ShaderMaterial

func _ready() -> void:
	buffer_viewport.use_hdr_2d = true
	buffer_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	buffer_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	multimesh = points.multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = POINT_COUNT

	image_material = image_pass_rect.material as ShaderMaterial
	if image_material == null:
		push_error("ImagePassRect missing ShaderMaterial")
		return
	image_material.set_shader_parameter("buffer_texture", buffer_viewport.get_texture())

func _process(_delta: float) -> void:
	var resolution: Vector2 = buffer_viewport.size
	var aspect: float = resolution.x / resolution.y
	var t: float = Time.get_ticks_msec() / 1000.0 * 0.5

	for i in range(POINT_COUNT):
		var fi: float = float(i)
		var x: float = fi * 1.1
		var y: float = fi * 0.008

		var k: float = (15.0 + sin(x * 0.2 + 12.0 * t)) * cos(x * 0.1)
		var e: float = y * 0.3 - 10.0
		var d: float = Vector2(k, e).length() + sin(y * 0.16 + 3.0 * t)
		var q: float = 8.0 * sin(1.4 * k) + sin(y * 0.07) * k * (18.0 + 5.0 * sin(y - 4.0 * d))
		var c: float = d * d / 90.0 - t

		var p := Vector2(
			(q + 90.0 * cos(c) + 200.0) / 400.0,
			(q * sin(c) + d * 60.0 - 320.0) / 400.0
		)

		# invert the original fragment-side transform: dist = distance(uv*0.7+0.5, p)
		# where uv.x was aspect-corrected: uv.x = base_uv.x * aspect, uv.y = base_uv.y
		var uv_target: Vector2 = (p - Vector2(0.5, 0.5)) / 0.7
		var base_uv := Vector2(uv_target.x / aspect, uv_target.y)
		var screen_pos := Vector2(
			(base_uv.x + 1.0) * 0.5 * resolution.x,
			(base_uv.y + 1.0) * 0.5 * resolution.y
		)

		var transform := Transform2D(0.0, screen_pos).scaled(Vector2(POINT_PIXEL_SIZE, POINT_PIXEL_SIZE))
		multimesh.set_instance_transform_2d(i, transform)
