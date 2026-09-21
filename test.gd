extends Node3D
enum Stage { SELECTING, RACING, FINISHED }
var stage :Stage = Stage.SELECTING
var player_role := ""	#玩家选的角色（乌龟/兔子），结算要用
var turtle_racer: Racer
var rabbit_racer: Racer
# 随机事件（M4 魔改 A）暂不启用：会稀释"选角决定胜负"的因果，后续想做运气元素再启用
#var event_timer := 0.0	#累积计时
var select_timer := 10.0	#倒计时选择计时
#var active_event := {}	#进行中的事件（空=无）
#const EVENT_INTERVAL := 2.0 #每隔几秒掷一次骰子
#const EVENT_CHANCE := 0.35 	#触发概率

func _ready() -> void:
	# 连按钮信号
	$CanvasLayer/UI/CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button_Turtle.pressed.connect(_on_turtle_pressed)
	$CanvasLayer/UI/CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button_Rabbit.pressed.connect(_on_rabbit_pressed)
	


func _process(delta: float) -> void:
	if stage == Stage.SELECTING:
		if select_timer >= 0.0:
			select_timer -= delta
			$CanvasLayer/UI/TimeLeft.text = str(int(select_timer))
		else:
			stage = Stage.RACING
			$CanvasLayer/UI/TimeLeft.visible = false
			var num = randi() % 2
			if num == 0:
				$CanvasLayer/UI/CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button_Turtle.pressed.emit()
			else:	
				$CanvasLayer/UI/CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button_Rabbit.pressed.emit()
	# --- 随机事件骰子（M4 魔改 A）暂不启用 ---
	#if stage == Stage.RACING and active_event.is_empty():
		#event_timer += delta
		#if event_timer >= EVENT_INTERVAL and randf() < EVENT_CHANCE:
			#_trigger_event()
			#event_timer = 0.0
			
	if stage == Stage.RACING and turtle_racer.finished and rabbit_racer.finished:
		_settle()
		
	# --- 随机事件倒计时（M4 魔改 A）暂不启用 ---
	#if not active_event.is_empty():
		#active_event["remain"] -= delta
		#if active_event["remain"] <= 0.0:
			#ConfigManager.clear_cost_override(active_event["role"], active_event["terrain"])
			#active_event = {}

# 随机事件触发（M4 魔改 A）暂不启用
#func _trigger_event() -> void:
	#var role := "turtle" if randi() % 2 == 0 else "rabbit"
	#var racer: Racer = turtle_racer if role == "turtle" else rabbit_racer
	#
	## 事件地形只从该角色路径上实际存在的地形里选 → 保证事件一定影响比赛
	#var candidates: Array[String] = []
	#for cell in racer.path:
		#var t: String = racer.grid_data.get_terrain(cell)
		#if not candidates.has(t):
			#candidates.append(t)
	#if candidates.is_empty():
		#return
	#var terrain: String = candidates.pick_random()
	#
	#var factor := 0.5 if randi() % 2  == 0 else 2.0	#顺风减半 / 逆风加倍
	#ConfigManager.set_cost_override(role, terrain, ConfigManager.get_cost(role, terrain) * factor)
	#active_event = {"role":role, "terrain": terrain, "remain": 8.0}
	#print(("顺风" if factor < 1.0 else "逆风"), "！", role, "在", terrain, "上", "加速" if factor < 1.0 else "减速")
	#print("当前 need: turtle=", turtle_racer.need, " rabbit=", rabbit_racer.need)

func _settle() -> void:
	stage = Stage.FINISHED
	var msg :String = ""

	if absf(turtle_racer.finish_time - rabbit_racer.finish_time) < 0.001:
			msg = "平局！"
	elif turtle_racer.finish_time < rabbit_racer.finish_time:
		msg = "乌龟获胜！用时 %s 秒" % snapped(turtle_racer.finish_time, 0.01)
	else:
		msg = "兔子获胜！用时 %s 秒" % snapped(rabbit_racer.finish_time, 0.01)
		
	# 玩家所选角色是否赢了（player_role 正好用上）
	if msg != "平局！":
		var winner := "turtle" if turtle_racer.finish_time < rabbit_racer.finish_time else "rabbit"
		msg += "\n你选的角色" + ("获胜！" if winner == player_role else "惜败。")

	$CanvasLayer/UI/ResultLabel.text = msg
	$CanvasLayer/UI/ResultLabel.visible = true

func _on_turtle_pressed() -> void:
	_start_race("turtle")

func _on_rabbit_pressed() -> void:
	_start_race("rabbit")
	
func _start_race(role: String) -> void:
	player_role = role
	$CanvasLayer/UI/CenterContainer.visible = false           # 隐藏选角 UI
	$CanvasLayer/UI/TimeLeft.visible = false		#隐藏倒计时
	stage = Stage.RACING
	
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
	gen.set_seed(1982101)   #测试刺激的1982101
	if gen.generate_valid(["turtle", "rabbit"]):
		$TerrainRenderer.grid_data  = gd
		$TerrainRenderer.build()
	_build_legend()
	
	var pf_turtle = PathFinder.new(gd, "turtle")
	pf_turtle.setup()
	print("[debug] board 格子数 = ", gd.grid_board.size())
	print("[debug] 起点 solid = ", pf_turtle.astar.is_point_solid(Vector2i(0, 6)))
	print("[debug] 终点 solid = ", pf_turtle.astar.is_point_solid(Vector2i(59, gen.center_rows[59])))
	var path_turtle = pf_turtle.find_path(Vector2i(0, 6), Vector2i(59, gen.center_rows[59]))
	print("乌龟路径格数: ", path_turtle.size())
	print("乌龟路径格子: ", path_turtle)
	
	# 打印路径地形序列（验证用）
	var terrains_turtle: Array[String] = []
	for cell in path_turtle:
		terrains_turtle.append(gd.get_terrain(cell))
	print("乌龟路径地形: ", terrains_turtle)
	
	var pf_rabbit = PathFinder.new(gd, "rabbit")
	pf_rabbit.setup()
	var path_rabbit = pf_rabbit.find_path(Vector2i(0, 6), Vector2i(59, gen.center_rows[59]))
	print("兔子路径格数: ", path_rabbit.size())
	print("兔子路径格子: ", path_rabbit)
	
	# 打印路径地形序列（验证用）
	var terrains_rabbit: Array[String] = []
	for cell in path_rabbit:
		terrains_rabbit.append(gd.get_terrain(cell))
	print("兔子路径地形: ", terrains_rabbit)
	

	var vis := PathRenderer.new()
	add_child(vis)
	vis.grid_data = gd
	vis.draw_path(path_turtle, Color(0.2, 0.4, 1.0))   # 蓝
	vis.draw_path(path_rabbit, Color(1.0, 0.3, 0.3))   # 红
	
	print_path_summary("rabbit", path_rabbit, gd)
	print_path_summary("turtle", path_turtle, gd)
	
	# 比如：乌龟走兔子路径的代价
	var cross_cost_turtle := 0.0
	for cell in path_rabbit:
		cross_cost_turtle += ConfigManager.get_cost("turtle", gd.get_terrain(cell))
	print("乌龟走兔子路: ", snapped(cross_cost_turtle, 0.01))
	
	# 比如：兔子走乌龟路径的代价
	var cross_cost_rabbit := 0.0
	for cell in path_turtle:
		cross_cost_rabbit += ConfigManager.get_cost("rabbit", gd.get_terrain(cell))
	print("兔子走乌龟路: ", snapped(cross_cost_rabbit, 0.01))
	
	#生成兔子和乌龟角色racer移动
	rabbit_racer = Racer.new(gd, "rabbit", path_rabbit)
	add_child(rabbit_racer)
	turtle_racer = Racer.new(gd, "turtle", path_turtle)
	add_child(turtle_racer)
	


func _build_legend() -> void:
	var box := $CanvasLayer/UI/LegendPanel/LegendBox
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

	for terrain in ["flat", "water", "highland", "downhill", "uphill", "channel"]:
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)

		# ① 色块（查 TERRAIN_VISUAL，表驱动）
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(16, 16)
		swatch.color = TerrainRenderer.TERRAIN_VISUAL[terrain]["color"]
		entry.add_child(swatch)

		# ② 文字：名称 + 高度（TERRAIN_PROFILE）+ 龟/兔代价（ConfigManager）
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		if terrain == "channel":
			label.text = "通道(桥/坑)·可通行"
		else:
			var prof: Dictionary = GridData.TERRAIN_PROFILE[terrain]
			var h: String
			if prof["entry"] == prof["exit"]:
				h = "高%d" % int(prof["entry"])
			else:
				h = "高%d→%d" % [int(prof["entry"]), int(prof["exit"])]
			var cost_t: float = ConfigManager.get_cost("turtle", terrain)
			var cost_r: float = ConfigManager.get_cost("rabbit", terrain)
			var t_txt := "禁" if ConfigManager.is_solid("turtle", terrain) else ("%.1f" % cost_t)
			var r_txt := "禁" if ConfigManager.is_solid("rabbit", terrain) else ("%.1f" % cost_r)
			label.text = "%s %s 龟%s 兔%s" % [terrain, h, t_txt, r_txt]
		entry.add_child(label)
		box.add_child(entry)
	$CanvasLayer/UI/LegendPanel.visible = true

func print_path_summary(role: String, path: Array[Vector2i], gd: GridData) -> void:
	var total := 0.0
	for cell in path:
		total += ConfigManager.get_cost(role, gd.get_terrain(cell))
	print(role, " | 格数: ", path.size(), " | 总代价: ", snapped(total, 0.01))
	
	
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
