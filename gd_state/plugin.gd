@tool
extends EditorPlugin
## ============================================================
##  gd_state/plugin.gd —— 插件入口
## ============================================================
## gd_state 提供两个全局类（class_name），无需注册单例：
##   - StateMachine：通用状态机
##   - GameFlow：通用游戏流程控制器
## 插件只负责把脚本路径加入项目（class_name 自动注册全局类）   。
## ============================================================

func _enter_tree() -> void:
	# class_name 已声明于脚本内，Godot 扫描 addons 时会自动注册，
	# 这里无需额外操作。保留本文件是为了符合 Godot 插件约定。
	pass

func _exit_tree() -> void:
	pass
