class_name ZoneVisual
extends MeshInstance3D

@export_category("source")
@export var collision_shape: CollisionShape3D
@export var base_material: ShaderMaterial

@export_category("geometry detail")
@export_range(1, 32, 1) var box_subdivisions: int = 8
@export_range(3, 128, 1) var radial_segments: int = 32
@export_range(1, 64, 1) var vertical_subdivisions: int = 8

var _runtime_material: ShaderMaterial


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_rebuild_visual()


func _rebuild_visual() -> void:
	if collision_shape == null:
		push_error(
			"%s requires a CollisionShape3D."
			% name
		)
		return

	if collision_shape.shape == null:
		push_error(
			"%s CollisionShape3D has no Shape3D resource."
			% name
		)
		return

	if base_material == null:
		push_error(
			"%s requires a base ShaderMaterial."
			% name
		)
		return

	var generated_mesh: Mesh = _create_mesh_from_shape(
		collision_shape.shape
	)

	if generated_mesh == null:
		return

	mesh = generated_mesh

	transform = collision_shape.transform

	_create_runtime_material()


func _create_mesh_from_shape(
	shape: Shape3D
) -> Mesh:
	var box_shape: BoxShape3D = shape as BoxShape3D

	if box_shape != null:
		return _create_box_mesh(box_shape)

	var sphere_shape: SphereShape3D = shape as SphereShape3D

	if sphere_shape != null:
		return _create_sphere_mesh(sphere_shape)

	var cylinder_shape: CylinderShape3D = shape as CylinderShape3D

	if cylinder_shape != null:
		return _create_cylinder_mesh(cylinder_shape)

	var capsule_shape: CapsuleShape3D = shape as CapsuleShape3D

	if capsule_shape != null:
		return _create_capsule_mesh(capsule_shape)

	push_warning(
		(
			"%s does not support collision shape type: %s"
			% [
				name,
				shape.get_class(),
			]
		)
	)

	return null


func _create_box_mesh(
	shape: BoxShape3D
) -> BoxMesh:
	var box_mesh: BoxMesh = BoxMesh.new()

	box_mesh.size = shape.size
	box_mesh.subdivide_width = box_subdivisions
	box_mesh.subdivide_height = box_subdivisions
	box_mesh.subdivide_depth = box_subdivisions

	return box_mesh


func _create_sphere_mesh(
	shape: SphereShape3D
) -> SphereMesh:
	var sphere_mesh: SphereMesh = SphereMesh.new()

	sphere_mesh.radius = shape.radius
	sphere_mesh.height = shape.radius * 2.0
	sphere_mesh.radial_segments = radial_segments
	sphere_mesh.rings = vertical_subdivisions * 2

	return sphere_mesh


func _create_cylinder_mesh(
	shape: CylinderShape3D
) -> CylinderMesh:
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()

	cylinder_mesh.top_radius = shape.radius
	cylinder_mesh.bottom_radius = shape.radius
	cylinder_mesh.height = shape.height
	cylinder_mesh.radial_segments = radial_segments
	cylinder_mesh.rings = vertical_subdivisions

	return cylinder_mesh


func _create_capsule_mesh(
	shape: CapsuleShape3D
) -> CapsuleMesh:
	var capsule_mesh: CapsuleMesh = CapsuleMesh.new()

	capsule_mesh.radius = shape.radius
	capsule_mesh.height = shape.height
	capsule_mesh.radial_segments = radial_segments
	capsule_mesh.rings = vertical_subdivisions * 2

	return capsule_mesh


func _create_runtime_material() -> void:
	_runtime_material = base_material.duplicate() as ShaderMaterial

	if _runtime_material == null:
		push_error(
			"%s could not duplicate its ShaderMaterial."
			% name
		)
		return

	material_override = _runtime_material

	_apply_vertical_shader_bounds()


func _apply_vertical_shader_bounds() -> void:
	if _runtime_material == null:
		return

	if collision_shape == null:
		return

	if collision_shape.shape == null:
		return

	var shape_height: float = _get_shape_height(
		collision_shape.shape
	)

	_runtime_material.set_shader_parameter(
		"mesh_bottom_y",
		-shape_height * 0.5
	)

	_runtime_material.set_shader_parameter(
		"mesh_top_y",
		shape_height * 0.5
	)


func _get_shape_height(
	shape: Shape3D
) -> float:
	var box_shape: BoxShape3D = shape as BoxShape3D

	if box_shape != null:
		return box_shape.size.y

	var sphere_shape: SphereShape3D = shape as SphereShape3D

	if sphere_shape != null:
		return sphere_shape.radius * 2.0

	var cylinder_shape: CylinderShape3D = shape as CylinderShape3D

	if cylinder_shape != null:
		return cylinder_shape.height

	var capsule_shape: CapsuleShape3D = shape as CapsuleShape3D

	if capsule_shape != null:
		return capsule_shape.height

	return 1.0
