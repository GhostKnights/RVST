@tool
extends EditorPlugin
## ============================================================
##  gd_core/plugin.gd —— 插件入口
## ============================================================
## 启用后自动注册两个全局单例：
##   GameBus —— 事件总线（Godot 内置 Logger 类名被占用 → GameLog；
##              EventBus 名会被解析为类 → GameBus，命名同风格规避）
##   GameLog —— 分级日志
## ============================================================

const EVENTBUS_NAME := "GameBus"
const EVENTBUS_PATH := "res://addons/gd_core/GameBus.gd"
const LOGGER_NAME := "GameLog"
const LOGGER_PATH := "res://addons/gd_core/GameLog.gd"

func _enter_tree() -> void:
	if not Engine.has_singleton(EVENTBUS_NAME):
		add_autoload_singleton(EVENTBUS_NAME, EVENTBUS_PATH)
	if not Engine.has_singleton(LOGGER_NAME):
		add_autoload_singleton(LOGGER_NAME, LOGGER_PATH)

func _exit_tree() -> void:
	if Engine.has_singleton(EVENTBUS_NAME):
		remove_autoload_singleton(EVENTBUS_NAME)
	if Engine.has_singleton(LOGGER_NAME):
		remove_autoload_singleton(LOGGER_NAME)
