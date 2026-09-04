extends Node
## ============================================================
##  GameBus —— 轻量事件总线（跨玩法复用）
## ============================================================
## 【为什么叫 GameBus】`EventBus` 名在部分 Godot 版本/工具链下会
##   被解析为"类"导致单例调用报错，故命名 GameBus 以规避。
##
## 【职责】解耦任意模块之间的通信：发事件的一方不需要知道
##   谁在听，监听的一方不需要知道谁发的。
##
## 【用法】
##   发事件：
##     GameBus.emit_event("player_died", { "x": 1.0 })
##   监听事件：
##     GameBus.on_event("player_died", _on_player_died)
##     func _on_player_died(payload: Dictionary) -> void: ...
##   取消监听：
##     GameBus.off_event("player_died", _on_player_died)
##
## 【注意】
##   - 事件名用字符串，建议集中定义常量避免拼写错误
##   - 本实现是同步调用；如需要跨帧/跨线程，可扩展为队列
## ============================================================


# 事件名 -> Array[Callable]
var _listeners: Dictionary = {}


# ============================================================
#  对外接口
# ============================================================

## 广播一个事件，携带任意负载
func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	var list: Array = _listeners.get(event_name, [])
	# 拷贝一份，避免回调中修改列表导致遍历出错
	for cb in list.duplicate():
		if cb.is_valid():
			cb.call(payload)


## 监听事件
func on_event(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callback)


## 取消监听
func off_event(event_name: String, callback: Callable) -> void:
	var list: Array = _listeners.get(event_name, [])
	list.erase(callback)


## 清空某事件的全部监听
func clear_event(event_name: String) -> void:
	_listeners.erase(event_name)


## 清空全部监听
func clear_all() -> void:
	_listeners.clear()
