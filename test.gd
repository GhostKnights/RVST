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
	gen.generate()
	$TerrainRenderer.grid_data  = gd
	$TerrainRenderer.build()
	
	var all_pass := true
	for s in range(20):
		gen.set_seed(s)
		gen.generate()          # 每次 generate 内部都会 is_reachable
		var ok = gen.is_reachable()
		print("seed ", s, " -> ", ok)
		if not ok:
			all_pass = false
	print("=== 20 种子全部可达: ", all_pass, " ===")
