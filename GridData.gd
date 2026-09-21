class_name GridData
extends RefCounted

var grid_board: Dictionary[Vector2i, String] = {}
var cell_size: float = 1.0
var SEG_GAP = 2

## 通道格子的恒定顶面高度（方案 B：通道与所在段主地形同高）
## key = 格子坐标，value = 该通道所属段主地形的顶面高度（highland 段 = 1，water 段 = 0）
var channel_height: Dictionary[Vector2i, float] = {}

## 地形高度剖面：入口高度（前进方向的前边缘）→ 出口高度（后边缘）
## 平台：entry == exit；坡：沿前进方向渐变（uphill 升、downhill 降）
const TERRAIN_PROFILE := {
	"flat":     {"entry": 0.0, "exit": 0.0},
	"water":    {"entry": 0.0, "exit": 0.0},
	"highland": {"entry": 1.0, "exit": 1.0},
	"uphill":   {"entry": 0.0, "exit": 1.0},
	"downhill": {"entry": 1.0, "exit": 0.0},
}

## 格子内任意"前进进度"的高度（0=刚进入，1=快离开）
## 通道格子：恒等于段主地形顶面高度（跳过剖面插值，保证衔接连续）
## 坡上会随进度平滑升降；平台保持常量
func height_at(cell: Vector2i, progress: float) -> float:
	if channel_height.has(cell):
		return channel_height[cell]
	var p: Dictionary = TERRAIN_PROFILE[get_terrain(cell)]
	return lerpf(p["entry"], p["exit"], clampf(progress, 0.0, 1.0))

## 记录某格为通道，并固定其顶面高度 = 段主地形顶面高度
func set_channel_height(cell: Vector2i, h: float) -> void:
	channel_height[cell] = h

## 生成新赛道前清空通道记录（避免残留上一局）
func clear_channel_heights() -> void:
	channel_height.clear()

## 格子中心站立高度（坡取剖面中点）——兼容旧调用
func get_terrain_height(cell: Vector2i) -> float:
	return height_at(cell, 0.5)

func cell_to_world(cell: Vector2i) -> Vector3:
	var col = cell.x
	var row = cell.y
	var segment = col / 20
	var local_x = col % 20
	var world_x = (19 - local_x) if segment % 2 == 1 else local_x
	var world_y = row + segment * (5 + SEG_GAP)
	var world_position: Vector3 = Vector3((world_x+0.5)*cell_size,0,(world_y+0.5)*cell_size)
	return world_position

func world_to_cell(world_p: Vector3) -> Vector2i:
	var grid_position: Vector2i = Vector2i(floori(world_p.x/cell_size),floori(world_p.z/cell_size))
	return grid_position

func set_terrain(cell: Vector2i,terrain: String) ->void:
	grid_board[cell] = terrain

func get_terrain(cell: Vector2i,default: String = "flat") -> String:
	return grid_board.get(cell, default)

func erase_terrain(cell: Vector2i) -> void:
	grid_board.erase(cell)
