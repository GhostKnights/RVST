extends Node
## ============================================================
##  GameLog —— 轻量分级日志（跨玩法复用）
## ============================================================
## 【为什么叫 GameLog】Godot 4 内置了原生类 Logger，重名会冲突，
##   所以本模块命名为 GameLog。用法完全一样。
##
## 【职责】统一日志输出格式 + 分级过滤 + 可选写文件。
##
## 【用法】
##   GameLog.info("加载完成，耗时 %d ms" % cost)
##   GameLog.warn("配置缺失，使用默认值")
##   GameLog.error("初始化失败", error_code)
##   GameLog.debug("每帧数值：%s" % val)
##
## 【配置】
##   GameLog.set_level(GameLog.Level.DEBUG)   # 显示调试级及以上
##   GameLog.set_log_file("user://log.txt")   # 同时写入文件
## ============================================================


enum Level { DEBUG, INFO, WARN, ERROR }


var _level: int = Level.INFO
var _log_file: FileAccess = null


# ============================================================
#  对外接口
# ============================================================

func set_level(level: int) -> void:
	_level = clampi(level, Level.DEBUG, Level.ERROR)


func set_log_file(path: String) -> void:
	if _log_file:
		_log_file.close()
	if path != "":
		_log_file = FileAccess.open(path, FileAccess.WRITE)


func debug(msg: String) -> void:
	_log(Level.DEBUG, "DBG", msg)


func info(msg: String) -> void:
	_log(Level.INFO, "INF", msg)


func warn(msg: String) -> void:
	_log(Level.WARN, "WRN", msg)


func error(msg: String) -> void:
	_log(Level.ERROR, "ERR", msg)


# ============================================================
#  内部
# ============================================================
func _log(level: int, tag: String, msg: String) -> void:
	if level < _level:
		return
	var line := "[%s] %s" % [tag, msg]
	match level:
		Level.WARN:
			push_warning(line)
		Level.ERROR:
			push_error(line)
		_:
			print(line)
	if _log_file:
		_log_file.store_line(line)
