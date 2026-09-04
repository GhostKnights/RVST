@tool
extends EditorPlugin
## ============================================================
##  gd_ui/plugin.gd —— 插件入口
## ============================================================
## gd_ui 提供全局类：FinishPopup、HudMenu（class_name 自动注册）。
## 节点引用用 @export 在场景里拖入，不依赖固定节点路径。
## ============================================================

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
