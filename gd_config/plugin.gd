@tool
extends EditorPlugin
## ============================================================
##  gd_config/plugin.gd —— 插件入口
## ============================================================
## 【作用】在项目设置里启用本插件后，自动把 ConfigManager.gd
##   注册为全局单例（Autoload），无需手动去项目设置里添加。
##
## 【安装】把整个 addons/gd_config 目录复制到项目 addons/ 下，
##   在 项目设置 → 插件 里启用 "GD Config" 即可。
## ============================================================

const SINGLETON_NAME := "ConfigManager"
const SINGLETON_PATH := "res://addons/gd_config/ConfigManager.gd"

func _enter_tree() -> void:
	# 避免重复注册（如果项目里已手动添加过同名 autoload）
	if not Engine.has_singleton(SINGLETON_NAME):
		add_autoload_singleton(SINGLETON_NAME, SINGLETON_PATH)

func _exit_tree() -> void:
	if Engine.has_singleton(SINGLETON_NAME):
		remove_autoload_singleton(SINGLETON_NAME)
