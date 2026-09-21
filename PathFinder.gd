class_name PathFinder
extends RefCounted
var grid_data: GridData
var role: String

var astar = AStarGrid2D.new()

func _init(grid_dt: GridData, role_dt: String) -> void:
	grid_data = grid_dt
	role = role_dt
	
func setup() -> void:
	astar.region = Rect2i(0,0,60,12)	#赛道尺寸
	astar.cell_size = Vector2(1.0,1.0)	#格子尺寸
	astar.diagonal_mode =AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	
	
	
# 第一步：region 内所有格子默认禁行（空气不能走）
	for y in range(12):
		for x in range(60):
			astar.set_point_solid(Vector2i(x, y), true)

	# 第二步：只开放赛道格子，按角色灌权重/禁行
	for cell in grid_data.grid_board:
		var terrain := grid_data.get_terrain(cell)
		if ConfigManager.is_solid(role, terrain):
			astar.set_point_solid(cell, true)      # 禁行（保持）
		else:
			astar.set_point_solid(cell, false)     # 开放
			astar.set_point_weight_scale(cell, ConfigManager.get_cost(role, terrain))
			

	
func find_path(from_cell: Vector2i, to_cell: Vector2i) ->Array[Vector2i]:
	return astar.get_id_path(from_cell, to_cell)



	

	
