extends Node3D

func _ready() -> void:
	print("=== 代价查询（期望: 1.0 / 100.0 / 100.0 / 1.0 / 0.6 / 0.8）===")
	print("turtle-water     = ", ConfigManager.get_cost("turtle", "water"))
	print("rabbit-water     = ", ConfigManager.get_cost("rabbit", "water"))
	print("turtle-highland  = ", ConfigManager.get_cost("turtle", "highland"))
	print("rabbit-highland  = ", ConfigManager.get_cost("rabbit", "highland"))
	print("turtle-downhill  = ", ConfigManager.get_cost("turtle", "downhill"))
	print("rabbit-downhill  = ", ConfigManager.get_cost("rabbit", "downhill"))
	print("=== 禁行查询（期望: false / true / true）===")
	print("turtle-water solid    = ", ConfigManager.is_solid("turtle", "water"))
	print("rabbit-water solid    = ", ConfigManager.is_solid("rabbit", "water"))
	print("turtle-highland solid = ", ConfigManager.is_solid("turtle", "highland"))
	
	var gd = GridData.new()
	var gen = TrackGenerator.new()
	gen.grid_data = gd
	gen.set_seed(123)
	if gen.generate_valid(["turtle", "rabbit"]):
		gen.generate()
		$TerrainRenderer.grid_data  = gd
		$TerrainRenderer.build()
	
	var pf_turtle = PathFinder.new(gd, "turtle")
	pf_turtle.setup()
	print("[debug] board 格子数 = ", gd.grid_board.size())
	print("[debug] 起点 solid = ", pf_turtle.astar.is_point_solid(Vector2i(0, 6)))
	print("[debug] 终点 solid = ", pf_turtle.astar.is_point_solid(Vector2i(19, gen.center_rows[19])))
	var path_turtle = pf_turtle.find_path(Vector2i(0, 6), Vector2i(19, gen.center_rows[19]))
	print("乌龟路径格数: ", path_turtle.size())
	print("乌龟路径格子: ", path_turtle)
	
	# 打印路径地形序列（验证用）
	var terrains_turtle: Array[String] = []
	for cell in path_turtle:
		terrains_turtle.append(gd.get_terrain(cell))
	print("乌龟路径地形: ", terrains_turtle)
	
	var pf_rabbit = PathFinder.new(gd, "rabbit")
	pf_rabbit.setup()
	var path_rabbit = pf_rabbit.find_path(Vector2i(0, 6), Vector2i(19, gen.center_rows[19]))
	print("兔子路径格数: ", path_rabbit.size())
	print("兔子路径格子: ", path_rabbit)
	
	# 打印路径地形序列（验证用）
	var terrains_rabbit: Array[String] = []
	for cell in path_rabbit:
		terrains_rabbit.append(gd.get_terrain(cell))
	print("兔子路径地形: ", terrains_rabbit)
	
	print("result is ", gen.generate_valid(["turtle", "rabbit"]))
	
	#测试路径连通性
	#var all_pass := true
	#for s in range(20):
		#gen.set_seed(s)
		#gen.generate()          # 每次 generate 内部都会 is_reachable
		#var ok = gen.is_reachable()
		#print("seed ", s, " -> ", ok)
		#if not ok:
			#all_pass = false
	#print("=== 20 种子全部可达: ", all_pass, " ===")
