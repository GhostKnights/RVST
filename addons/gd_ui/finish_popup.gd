class_name FinishPopup
extends Control
## ============================================================
##  FinishPopup —— 通用结算弹窗（跨玩法复用）
## ============================================================
## 【职责】
##   - 显示结算文字（分数/结果）
##   - 两个按钮只发信号，不处理任何游戏数据
##   - 可见性由外部（HudMenu 或业务脚本）管理
##
## 【用法】
##   1. 在场景里放一个 Control，挂本脚本，子节点命名为：
##        Control/Btn_Restart（重新开始按钮）
##        Control/Btn_GameOver（结束按钮）
##        Control/Text_Finish（结果文字 Label）
##   2. 监听信号：popup.request_restart / request_quit
##   3. 结束游戏时：popup.set_ui_result(score); popup.show_popup()
## ============================================================


# ============================================================
#  信号（只发信号，不处理游戏数据）
# ============================================================
signal request_restart()
signal request_quit()


# ============================================================
#  节点引用
# ============================================================
@onready var btn_restart: Button = $Control/Btn_Restart
@onready var btn_quit: Button = $Control/Btn_GameOver
@onready var text_finish: Label = $Control/Text_Finish


# ============================================================
#  生命周期
# ============================================================
func _ready():
	# 关键：游戏结束时全局暂停，弹窗按钮仍可交互
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	btn_restart.pressed.connect(_on_btn_restart)
	btn_quit.pressed.connect(_on_btn_quit)


# ============================================================
#  对外接口
# ============================================================

## 外部调用：填入结算结果文字
func set_ui_result(score: int) -> void:
	text_finish.text = "%d" % score


## 通用版：也可填入任意字符串结果（如 "通关" / "失败"）
func set_result_text(text: String) -> void:
	text_finish.text = text


## 显示弹窗
func show_popup() -> void:
	visible = true


## 隐藏弹窗
func hide_popup() -> void:
	visible = false


# ============================================================
#  按钮回调（只发信号）
# ============================================================
func _on_btn_restart():
	request_restart.emit()


func _on_btn_quit():
	request_quit.emit()
