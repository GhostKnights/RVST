class_name LookupDemo
extends Node
## ============================================================
##  gd_config 示例：5 种查表模式 + KV 配置演示
## ============================================================
## 【跑法】把本目录的 lookup_demo.tscn 设为临时主场景运行，
##   或挂到任意场景根节点，看控制台输出。
## ============================================================

func _ready() -> void:
	print("========== GD Config 查表演示 ==========")

	# 配置要加载的表（示例：沿用项目 PickUp 的分数表结构）
	ConfigManager.config_dir = "res://Config/"
	ConfigManager.table_specs = {
		"score":  { "file": "PickUP.txt", "skip": 3 },
		"levels": { "file": "levels.txt", "skip": 1 },
	}
	ConfigManager.kv_specs = {
		"game_rules": "game_rules.txt",
	}
	ConfigManager.load_all()

	var score_table: Array = ConfigManager.get_table("score")

	# 1. 区间查表：面积 -> 分数（输入超过所有档位时返回最高档）
	var area := 1.5
	var score: int = ConfigManager.lookup_range(score_table, area, "max_area", "score", 0)
	print("[区间] 面积 %.1f -> 分数 %d" % [area, score])

	# 2. 精确查表：id -> 名称
	var name: String = ConfigManager.lookup_exact(score_table, 2, "id", "说明", "未知")
	print("[精确] id=2 -> %s" % name)

	# 3. 权重随机：按 weight 随机（演示多次）
	var weights := ConfigManager.get_table("levels")
	var picks := {}
	for i in 20:
		var k: String = str(ConfigManager.lookup_weighted(weights, "weight", "name"))
		picks[k] = picks.get(k, 0) + 1
	print("[权重] 20 次掉落分布: ", picks)

	# 4. 多条件匹配
	var atk: int = ConfigManager.lookup_multi(weights, {"tier": 2, "rare": 1}, "atk", 0)
	print("[多条件] tier=2 & rare=1 -> atk=%d" % atk)

	# 5. 线性插值：等级 -> 经验
	var exp: float = ConfigManager.lookup_interpolated(weights, 2.5, "level", "exp", 0.0)
	print("[插值] level=2.5 -> exp=%.1f" % exp)

	# KV 配置
	print("[KV] initial_pickups = %s" % ConfigManager.get_kv("game_rules", "initial_pickups", "N/A"))

	print("========== 演示结束 ==========")
