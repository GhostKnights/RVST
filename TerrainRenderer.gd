class_name TerrainRenderer
extends Node3D
var grid_data: GridData


## 地形 → 视觉映射（表驱动余地：加地形 = 加一条字典项）
const TERRAIN_VISUAL := {
	"water":    {"color": Color(0.42, 0.71, 0.91), "height": 0.2, "mesh": "box"},
	"flat":     {"color": Color(0.42, 0.68, 0.31), "height": 0.2, "mesh": "box"},
	"highland": {"color": Color(0.64, 0.45, 0.24), "height": 1.2, "mesh": "box"},
	"downhill": {"color": Color(0.91, 0.62, 0.35), "height": 1.2, "mesh": "prism","left_to_right": true},
	"uphill":	{"color":Color(1,1,0), "height":0.2,"mesh": "prism","left_to_right": false}
}

## 入口：遍历所有格子，逐个生成方块
func build() -> void:
	if grid_data == null:
		return
	for cell in grid_data.grid_board:
		_create_tile(cell, grid_data.grid_board[cell])

func _create_tile(cell: Vector2i, terrain: String) -> void:
	var visual: Dictionary = TERRAIN_VISUAL.get(terrain, TERRAIN_VISUAL["flat"])
	var mi := MeshInstance3D.new()
	mi.mesh = _make_mesh(visual)
	mi.material_override = _make_material(visual["color"])
	if visual["mesh"] == "prism":
		mi.rotation.y = deg_to_rad(180)  # ← 旋转写在 mi（节点）上
	# 底座贴地：用网格包围盒自动对齐（Box/Prism 通用，不用手算高度）
	var pos: Vector3 = grid_data.cell_to_world(cell)
	pos.y = -mi.mesh.get_aabb().position.y
	mi.position = pos
	add_child(mi)

func _make_mesh(visual: Dictionary) -> Mesh:
	var height: float = visual["height"]
	if visual["mesh"] == "prism":
		var prism := PrismMesh.new()
		prism.size = Vector3(1.0, height, 1.0)
		prism.left_to_right = visual.get("left_to_right", true)   # 从映射里读，不再写死
		return prism
	var box := BoxMesh.new()
	box.size = Vector3(1.0, height, 1.0)
	return box

func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
