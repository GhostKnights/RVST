class_name TrackGenerator
extends RefCounted

## 地形转移表：当前地形 -> 下一个地形的合法选择池（"根据上下文生成"）
## 规则：过渡地形（downhill/uphill）不能延续；平台地形（highland/flat/water）可延续
const TERRAIN_TRANSITIONS = {
	"highland": ["highland", "downhill"],
	"downhill": ["flat", "water"],
	"flat": ["flat", "water", "uphill"],
	"water": ["water", "flat", "uphill"],
	"uphill": ["highland"],
}

## 地形高度分组（决定中心行能否错位）：
## 前后地形高度差为 0 -> 允许蜿蜒错位；高度差不为 0 -> 正对链接
const TERRAIN_HEIGHT = {
	"flat": 0,
	"water": 0,
	"uphill": 1,
	"downhill": 1,
	"highland": 2,
}

var grid_data: GridData
var current_row: int

## 记录每一列的中心行（蜿蜒路径的骨架）
var center_rows: Array[int] = []

## 记录每一格是否到达
var check_reachable: Dictionary[Vector2i,bool] = {} 

func generate() -> void:
	# ---- 第一步：先生成整条赛道的地形序列（每列一个地形）----
	# 地形由转移表 + 段长决定；起点从 flat 开始（第一段必是 flat = 起点安全区）
	var terrains: Array[String] = []
	var column := 0
	var terrain := "flat"
	while column < 20:
		# 过渡地形只铺 1 格，平台地形铺 2~4 格
		var seg_len: int
		if terrain == "downhill" or terrain == "uphill":
			seg_len = 1
		else:
			seg_len = randi_range(2, 4)
		for i in range(seg_len):
			if column >= 20:
				break
			terrains.append(terrain)
			column += 1
		# 段尾按转移表选下一个地形（上下文生成的核心）
		var pool: Array = TERRAIN_TRANSITIONS[terrain]
		terrain = pool[randi() % pool.size()]

	# ---- 第二步：逐列铺格，中心行按"前后地形高度差"决定是否错位 ----
	current_row = 6                     # 起点中心行（地图 12 行中央）
	for col in range(0, 20):
		center_rows.append(current_row)
		# 固定 3 格宽：中心行加减 1
		for d in range(-1, 2):
			grid_data.set_terrain(Vector2i(col, current_row + d), terrains[col])
		# 决定下一列中心行：
		# 前后地形高度差为 0（等高）-> 允许蜿蜒错位（加减 1）
		# 高度差不等于 0（高低过渡）-> 正对链接（不偏移）
		if col < 19:
			if TERRAIN_HEIGHT[terrains[col]] == TERRAIN_HEIGHT[terrains[col + 1]]:
				current_row = clampi(current_row + randi_range(-1, 1), 1, 10)
	
	print(is_reachable())
				
func is_reachable() -> bool:
	check_reachable.clear()
	current_row = 6 
	flood_fill(0, current_row)			
	return check_reachable.has(Vector2i(19,center_rows[19]))
	
func flood_fill(col :int, row : int) -> void:
	if not(col < 0 or col >= 20 or row < 0 or row >= 12):
		if grid_data.grid_board.has(Vector2i(col, row-1)) and not check_reachable.has(Vector2i(col, row-1)):
			check_reachable.set(Vector2i(col,row-1),true)
			flood_fill(col, row-1)
		if grid_data.grid_board.has(Vector2i(col, row+1)) and not check_reachable.has(Vector2i(col, row+1)):
			check_reachable.set(Vector2i(col,row+1),true)
			flood_fill(col, row+1)
		if grid_data.grid_board.has(Vector2i(col-1, row)) and not check_reachable.has(Vector2i(col-1, row)):
			check_reachable.set(Vector2i(col-1,row),true)
			flood_fill(col-1, row)
		if grid_data.grid_board.has(Vector2i(col+1, row)) and not check_reachable.has(Vector2i(col+1, row)):
			check_reachable.set(Vector2i(col+1,row),true)
			flood_fill(col+1, row)
