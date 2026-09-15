class_name TerrainRenderer
extends Node3D
var grid_data: GridData


## 地形 → 视觉映射（表驱动余地：加地形 = 加一条字典项）
## height 与 GridData.TERRAIN_PROFILE 对齐：坡取最高点 1（entry/exit 为 0↔1）
## 注意：0 高度格子（flat/water）在 _create_tile 里会被垫 0.05 薄底座，避免 BoxMesh 退化成不可见
const TERRAIN_VISUAL := {
	"water":    {"color": Color(0.42, 0.71, 0.91), "height": 0, "mesh": "box"},
	"flat":     {"color": Color(0.42, 0.68, 0.31), "height": 0, "mesh": "box"},
	"highland": {"color": Color(0.64, 0.45, 0.24), "height": 1, "mesh": "box"},
	"downhill": {"color": Color(0.91, 0.62, 0.35), "height": 1, "mesh": "prism","left_to_right": true},
	"uphill":	{"color":Color(1,1,0), "height":1,"mesh": "prism","left_to_right": false}
}

## 0 高度格子的最小渲染厚度（视觉薄片，逻辑高度仍为 0，不影响寻路/移动）
const BASE_THICKNESS := 0.05

## 入口：遍历所有格子，逐个生成方块
func build() -> void:
	if grid_data == null:
		return
	for cell in grid_data.grid_board:
		_create_tile(cell, grid_data.grid_board[cell])

func _create_tile(cell: Vector2i, terrain: String) -> void:
	var visual: Dictionary = TERRAIN_VISUAL.get(terrain, TERRAIN_VISUAL["flat"])
	var is_channel: bool = grid_data.channel_height.has(cell)

	# 通道格子：永远渲染成"顶面 = 记录高度"的平台（与段主地形同高，保证视觉连续）
	# 非通道 0 高度格子：垫 BASE_THICKNESS 薄底座
	var height: float = visual["height"]
	if is_channel:
		height = grid_data.channel_height[cell]
	elif height <= 0.0:
		height = BASE_THICKNESS

	var mi := MeshInstance3D.new()
	if is_channel or visual["mesh"] == "box":
		var box := BoxMesh.new()
		box.size = Vector3(1.0, height, 1.0)
		mi.mesh = box
	else:
		var prism := PrismMesh.new()
		prism.size = Vector3(1.0, height, 1.0)
		prism.left_to_right = visual.get("left_to_right", true)
		mi.mesh = prism
		mi.rotation.y = deg_to_rad(180)  # ← 旋转写在 mi（节点）上
	mi.material_override = _make_material(visual["color"])
	# 底座贴地：用网格包围盒自动对齐（Box/Prism 通用，不用手算高度）
	var pos: Vector3 = grid_data.cell_to_world(cell)
	pos.y = -mi.mesh.get_aabb().position.y
	mi.position = pos
	add_child(mi)

func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
