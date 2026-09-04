extends Node
## ============================================================
##  ConfigManager —— 通用配置查询引擎（跨项目共享）
## ============================================================
## 【注意】本脚本是 Autoload 单例，**不要声明 class_name**：
##   单例名与 class_name 同名时，GDScript 会把它解析成"类"，
##   导致 ConfigManager.lookup_xxx() 这类实例调用报错。
##
## 【定位】godot-common 共享框架的配置层。与任何玩法无关，
##   只负责：把 CSV/TXT 配置加载成表 → 提供 5 种通用查表模式。
##
## 【接入方式（二选一）】
##   方式 A：直接使用本单例
##     在 _ready 里配置要加载的表，然后调 load_all()。
##   方式 B：项目子类化（推荐，玩法越复杂越适合）
##     # 项目内 ProjectConfig.gd（无 class_name 的脚本用路径 extends）
##     class_name ProjectConfig
##     extends "res://addons/gd_config/ConfigManager.gd"
##     func _ready() -> void:
##         table_specs = {
##             "score": {"file": "PickUP.txt", "skip": 3},
##         }
##         kv_specs = {
##             "game_rules": "game_rules.txt",
##         }
##         super._ready()
##     # 业务薄封装：查表逻辑永远不重写
##     func get_score_by_area(area: float) -> int:
##         return int(lookup_range(get_table("score"), area, "max_area", "score", 0))
##     然后把 autoload 指向 ProjectConfig.gd 即可。
##
## 【通用查表模式】
##   lookup_exact        精确匹配
##   lookup_range        区间匹配（不依赖表顺序）
##   lookup_weighted     权重随机
##   lookup_multi        多条件匹配
##   lookup_interpolated 线性插值
##
## 【配置表文件格式】
##   普通表：首行/前 N 行表头 + 数据行，逗号分隔（.csv / .txt 均可）
##   KV 表：key,value 两列，一行一个参数
## ============================================================


# ============================================================
#  一、加载声明（子类在 _ready 里覆盖，再调 super._ready()）
# ============================================================
## 配置目录（相对 res://）
var config_dir: String = "res://Config/"

## 普通表声明：{ 表名: { "file": "xxx.txt", "skip": 表头行数 } }
var table_specs: Dictionary = {}

## KV 表声明：{ 表名: "xxx.txt" }
var kv_specs: Dictionary = {}


# ============================================================
#  二、存储（表名 -> 数据）
# ============================================================
var tables: Dictionary = {}      # 表名 -> Array[Dictionary]
var kv_tables: Dictionary = {}   # 表名 -> { key: value }


# ============================================================
#  三、生命周期
# ============================================================
func _ready() -> void:
	load_all()


## 按声明加载全部配置表（可在运行时手动调用以热更）
func load_all() -> void:
	tables.clear()
	kv_tables.clear()

	for tname in table_specs:
		var spec: Dictionary = table_specs[tname]
		var path: String = config_dir + str(spec.get("file", ""))
		var skip: int = int(spec.get("skip", 1))
		tables[tname] = _load_csv(path, skip)

	for tname in kv_specs:
		var path: String = config_dir + str(kv_specs[tname])
		kv_tables[tname] = _load_kv_csv(path)

	print("[ConfigManager] 已加载 %d 张普通表 / %d 张 KV 表" % [tables.size(), kv_tables.size()])


# ============================================================
#  四、访问接口
# ============================================================

## 获取普通表（查表时传入）
func get_table(name: String) -> Array:
	return tables.get(name, [])

## 获取 KV 表
func get_kv_table(name: String) -> Dictionary:
	return kv_tables.get(name, {})

## KV 表查值（键不存在返回默认值）
func get_kv(kv_name: String, key: String, default: Variant = null) -> Variant:
	return kv_tables.get(kv_name, {}).get(key, default)


# ============================================================
#  五、通用查询引擎（5 种模式，与业务无关）
# ============================================================

## 1. 精确匹配：找 key_col == key_val 的行，返回 return_col
func lookup_exact(table: Array, key_val: Variant, key_col: String, return_col: String, default: Variant = null) -> Variant:
	for row in table:
		if row.get(key_col) == key_val:
			return row.get(return_col, default)
	return default


## 2. 区间匹配：找 range_col >= input 的行中 range_col 最小的
##    input 超过所有区间时返回最大区间的值（不依赖表顺序）
func lookup_range(table: Array, input: float, range_col: String, return_col: String, default: Variant = null) -> Variant:
	if table.is_empty():
		return default

	var best_val: Variant = default
	var best_range: float = INF

	for row in table:
		var r: float = float(row.get(range_col, INF))
		if input <= r and r < best_range:
			best_range = r
			best_val = row.get(return_col, default)

	# 兜底：input 超过所有区间，返回最大区间的值
	if best_range == INF:
		var max_r: float = -INF
		for row in table:
			var r: float = float(row.get(range_col, -INF))
			if r > max_r:
				max_r = r
				best_val = row.get(return_col, default)

	return best_val


## 3. 权重随机：按 weight_col 权重随机抽一行，返回 return_col
func lookup_weighted(table: Array, weight_col: String, return_col: String) -> Variant:
	if table.is_empty():
		return null

	var total: float = 0.0
	for row in table:
		var w: float = float(row.get(weight_col, 0))
		if w > 0:
			total += w

	if total <= 0:
		push_warning("[ConfigManager] lookup_weighted: 所有权重均为 0 或负数")
		return null

	var roll: float = randf() * total
	var acc: float = 0.0
	for row in table:
		var w: float = float(row.get(weight_col, 0))
		if w <= 0:
			continue
		acc += w
		if roll <= acc:
			return row.get(return_col)

	# 浮点误差兜底
	for i in range(table.size() - 1, -1, -1):
		if float(table[i].get(weight_col, 0)) > 0:
			return table[i].get(return_col)
	return null


## 4. 多条件匹配：conditions = {列名: 期望值}，全部满足才返回
func lookup_multi(table: Array, conditions: Dictionary, return_col: String, default: Variant = null) -> Variant:
	for row in table:
		var matched: bool = true
		for key in conditions:
			if row.get(key) != conditions[key]:
				matched = false
				break
		if matched:
			return row.get(return_col, default)
	return default


## 5. 线性插值：input 落在 x_col 两点之间时对 y_col 插值
##    小于最小值返回首点，大于最大值返回末点
func lookup_interpolated(table: Array, input: float, x_col: String, y_col: String, default: float = 0.0) -> float:
	if table.is_empty():
		return default
	if table.size() == 1:
		return float(table[0].get(y_col, default))

	var sorted: Array = table.duplicate()
	sorted.sort_custom(func(a, b): return float(a.get(x_col, INF)) < float(b.get(x_col, INF)))

	var x_first: float = float(sorted[0].get(x_col, 0))
	var x_last: float = float(sorted[-1].get(x_col, 0))

	if input <= x_first:
		return float(sorted[0].get(y_col, default))
	if input >= x_last:
		return float(sorted[-1].get(y_col, default))

	for i in range(sorted.size() - 1):
		var x0: float = float(sorted[i].get(x_col, 0))
		var x1: float = float(sorted[i + 1].get(x_col, 0))
		if x0 <= input and input <= x1:
			var y0: float = float(sorted[i].get(y_col, default))
			var y1: float = float(sorted[i + 1].get(y_col, default))
			if x1 == x0:
				return y0
			var t: float = (input - x0) / (x1 - x0)
			return y0 + (y1 - y0) * t

	return default


# ============================================================
#  六、内部工具：CSV 加载 + 类型自动转换
# ============================================================

## 加载普通表并自动转换类型
func _load_csv(path: String, skip_header_lines: int = 1) -> Array:
	var raw: Array = _read_csv(path, skip_header_lines)
	for row in raw:
		for key in row:
			row[key] = _auto_convert(row[key])
	return raw


## 加载 KV 结构 CSV（key,value 两列）→ {key: 转换后值}
func _load_kv_csv(path: String, skip_header_lines: int = 1) -> Dictionary:
	var result: Dictionary = {}
	var rows: Array = _read_csv(path, skip_header_lines)
	for row in rows:
		var key: String = str(row.get("key", ""))
		if key == "":
			continue
		result[key] = _auto_convert(str(row.get("value", "")))
	return result


## 通用 CSV 读取器（.csv / .txt 均可）
## skip_header_lines：跳过的行数；第 skip_header_lines 行当作表头
func _read_csv(path: String, skip_header_lines: int = 1) -> Array:
	var result: Array = []

	if not FileAccess.file_exists(path):
		push_warning("[ConfigManager] 配置文件不存在（将返回空表）: %s" % path)
		return result

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[ConfigManager] 无法打开文件: %s" % path)
		return result

	var header: PackedStringArray = []
	var line_num: int = 0

	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.is_empty() or (line.size() == 1 and line[0] == ""):
			continue
		line_num += 1
		if line_num <= skip_header_lines:
			if line_num == skip_header_lines:
				header = line
				for idx in range(header.size()):
					header[idx] = header[idx].lstrip("\ufeff")
			continue
		var row: Dictionary = {}
		for i in range(header.size()):
			row[header[i]] = line[i] if i < line.size() else ""
		result.append(row)

	file.close()
	return result


## 字符串自动转数字
func _auto_convert(val: String) -> Variant:
	if val.is_valid_int():
		return int(val)
	if val.is_valid_float():
		return float(val)
	return val
