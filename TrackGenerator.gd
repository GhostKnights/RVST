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

## 地形高度统一在 GridData.TERRAIN_PROFILE（入口/出口高度）：
## 中心行能否错位 = 前后地形高度连续（A 的出口 == B 的入口），
## 平台间（flat/water 等高）与"坡接平台"均满足，正对链接仅发生在高度跳变时。

var grid_data: GridData
var current_row: int

## 记录每一列的中心行（蜿蜒路径的骨架）
var center_rows: Array[int] = []

## 记录每一格是否到达
var check_reachable: Dictionary[Vector2i,bool] = {} 

var seed_value: int = 0

func set_seed(s: int) -> void:
	seed_value = s

func generate() -> void:
	seed(seed_value)   # ← generate 开头先播种子
	grid_data.grid_board.clear()   # ← 每次生成先清空
	grid_data.clear_channel_heights()   # ← 通道高度记录同步清空
	center_rows.clear()            # ← 同上
	
	
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
	current_row = 6
	var channel_terrain := ""          # 当前段的通道地形（"" = 无通道）
	var channel_offset := -2           # 通道带起点行偏移（通道 = offset, offset+1）

	for col in range(0, 20):
		center_rows.append(current_row)
		var main_t := terrains[col]

		# ① 段变化检测：换段时决定本段通道
		if col == 0 or terrains[col - 1] != main_t:
			if main_t == "water":
				channel_terrain = "highland" if randi() % 2 == 0 else "flat"
				channel_offset = randi_range(-2, 1)
			elif main_t == "highland":
				channel_terrain = "water" if randi() % 2 == 0 else "flat"
				channel_offset = randi_range(-2, 1)
			else:
				channel_terrain = ""                 # flat/下坡/上坡：整列同地形

		# ② 段内：通道位置逐列微调（±1，保证连续）
		if channel_terrain != "":
			channel_offset = clampi(channel_offset + randi_range(-1, 1), -2, 1)

		# ③ 铺 5 行：通道行铺通道地形，其余铺主地形
		# 方案 B：通道格子记录"恒定顶面高度 = 段主地形顶面高度"（highland 段 = 1，water 段 = 0）
		# → 角色在通道上高度与主地形一致，进出通道不再跳变
		for d in range(-2, 3):
			var t := main_t
			if channel_terrain != "" and (d == channel_offset or d == channel_offset + 1):
				t = channel_terrain
				grid_data.set_channel_height(
					Vector2i(col, current_row + d),
					GridData.TERRAIN_PROFILE[main_t]["entry"]
				)
			grid_data.set_terrain(Vector2i(col, current_row + d), t)

		# ④ 中心行蜿蜒（范围改为 2..9，保证 ±2 不越界）
		# 错位条件：前后地形高度连续（前一列出口 == 后一列入口），否则正对链接
		if col < 19:
			var prev_exit: float = GridData.TERRAIN_PROFILE[terrains[col]]["exit"]
			var next_entry: float = GridData.TERRAIN_PROFILE[terrains[col + 1]]["entry"]
			if prev_exit == next_entry:
				current_row = clampi(current_row + randi_range(-1, 1), 2, 9)
	
				
func is_reachable() -> bool:
	check_reachable.clear()
	current_row = 6 
	flood_fill(0, current_row)			
	return check_reachable.has(Vector2i(19,center_rows[19]))
	
func is_reachable_for(role: String) -> bool:
	check_reachable.clear()
	current_row = 6 
	flood_fill(0, current_row, role)			
	return check_reachable.has(Vector2i(19,center_rows[19]))
	
func generate_valid(roles: Array[String]) -> bool:
	for attempt in range(100):               # 最多试 100 个种子
		generate()
		var all_ok := true
		for role in roles:
			if not is_reachable_for(role):
				all_ok = false
				break
		if all_ok:
			print("有效种子: ", seed_value)   # ← 方便复现/分享
			return true
		seed_value += 1                      # 换种子重试
	return false
	
	
func flood_fill(col :int, row : int, role : String = "Normal") -> void:
	if not(col < 0 or col >= 20 or row < 0 or row >= 12):
		if grid_data.grid_board.has(Vector2i(col, row-1)) and not check_reachable.has(Vector2i(col, row-1)) and not ConfigManager.is_solid(role, grid_data.get_terrain(Vector2i(col, row-1))):
			check_reachable.set(Vector2i(col,row-1),true)
			flood_fill(col, row-1, role)
		if grid_data.grid_board.has(Vector2i(col, row+1)) and not check_reachable.has(Vector2i(col, row+1)) and not ConfigManager.is_solid(role, grid_data.get_terrain(Vector2i(col, row+1))):
			check_reachable.set(Vector2i(col,row+1),true)
			flood_fill(col, row+1, role)
		if grid_data.grid_board.has(Vector2i(col-1, row)) and not check_reachable.has(Vector2i(col-1, row)) and not ConfigManager.is_solid(role, grid_data.get_terrain(Vector2i(col-1, row))):
			check_reachable.set(Vector2i(col-1,row),true)
			flood_fill(col-1, row, role)
		if grid_data.grid_board.has(Vector2i(col+1, row)) and not check_reachable.has(Vector2i(col+1, row)) and not ConfigManager.is_solid(role, grid_data.get_terrain(Vector2i(col+1, row))):
			check_reachable.set(Vector2i(col+1,row),true)
			flood_fill(col+1, row, role)
