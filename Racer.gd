class_name Racer
extends Node3D

var role: String
var grid_data: GridData
var path: Array[Vector2i]
var base_time := 0.5        # 每格基础耗时（秒）
var base_y_offset := 0.35   # 方块中心高出地形顶面的距离（半高 0.3 + 余量）

# 移动状态（格子间插值）
var prev_cell := Vector2i.ZERO   # 当前段的起点格
var curr_cell := Vector2i.ZERO   # 当前段的目标格（正在进入的格）
var next_index := 1              # path 中下一个要进入的格子索引
var t := 0.0                     # 0..1：从 prev 中心到 curr 中心的进度
var need := 1.0                  # 当前段总耗时（秒）= base_time * cost(curr_cell)

# 比赛状态（M3 结算用）
var elapsed := 0.0               # 总用时（逻辑时间，精确可复算）
var finish_time := -1.0          # 到达时间（-1 = 未到达）
var finished := false

func _init(grid_dt: GridData, role_dt: String, path_dt: Array[Vector2i]) -> void:
	grid_data = grid_dt
	role = role_dt
	path = path_dt

func _ready() -> void:
	# 方块外观
	var racer_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	racer_mesh.mesh = box
	add_child(racer_mesh)
	var mat := StandardMaterial3D.new()
	if role == "turtle":
		mat.albedo_color = Color(0.1, 0.3, 0.6)    # 蓝 = 乌龟
	elif role == "rabbit":
		mat.albedo_color = Color(0.9, 0.1, 0.1)    # 红 = 兔子
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	racer_mesh.material_override = mat

	# 起点：站在 path[0] 的入口高度
	position = grid_data.cell_to_world(path[0])
	position.y = grid_data.height_at(path[0], 0.0) + base_y_offset
	prev_cell = path[0]
	_start_next_segment()

## 进入下一个格子：按该格代价算出耗时 need
func _start_next_segment() -> void:
	if next_index >= path.size():
		finished = true
		finish_time = elapsed
		return
	curr_cell = path[next_index]
	next_index += 1
	var terrain := grid_data.get_terrain(curr_cell)
	need = base_time * ConfigManager.get_cost(role, terrain)
	t = 0.0

func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta

	# ---- 逻辑层：按代价推进（速度放逻辑层） ----
	t += delta / need
	if t >= 1.0:
		prev_cell = curr_cell
		_start_next_segment()
		if finished:
			# 到达终点：停在终点格子中心
			position = grid_data.cell_to_world(curr_cell)
			position.y = grid_data.height_at(curr_cell, 0.5) + base_y_offset
			return

	# ---- 表现层：位置与高度插值（动画放表现层） ----
	var from: Vector3 = grid_data.cell_to_world(prev_cell)
	var to: Vector3 = grid_data.cell_to_world(curr_cell)
	position.x = lerpf(from.x, to.x, t)
	position.z = lerpf(from.z, to.z, t)
	# 高度：角色从 prev 中心走到 curr 中心
	# 前半段在 prev 格后半剖面（中点→出口），后半段在 curr 格前半剖面（入口→中点）
	# 边界处 prev 出口 == curr 入口（TERRAIN_PROFILE 保证）→ 坡面连续无跳变
	if t < 0.5:
		position.y = grid_data.height_at(prev_cell, 0.5 + t) + base_y_offset
	else:
		position.y = grid_data.height_at(curr_cell, t - 0.5) + base_y_offset
