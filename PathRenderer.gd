class_name PathRenderer
extends Node3D
var grid_data: GridData

# 建议独立类 PathRenderer.gd（extends Node3D），与现有类结构一致
func draw_path(path: Array[Vector2i], color: Color) -> void:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	mi.mesh = im
	add_child(mi)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mi.material_override = mat

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for cell in path:
		var wp: Vector3 = grid_data.cell_to_world(cell)
		im.surface_add_vertex(wp + Vector3(0, 0.5, 0))   # 抬高 0.5，避免线埋进地里
	im.surface_end()
