class_name HudMenu
extends CanvasLayer
## ============================================================
##  HudMenu —— 通用 HUD 控制器（跨玩法复用）
## ============================================================
## 【职责】管理顶部信息条（分数/倒计时/次数）+ 结算弹窗的展示。
##   **不持有游戏数据**，只提供"被外部驱动的 set 接口"和
##   "桥接 GameFlow 信号的便捷方法"。
##
## 【用法】
##   1. 场景里放 CanvasLayer 挂本脚本，把节点引用拖入：
##        lbl_score     : Label  顶部分数
##        lbl_countdown : Label  顶部倒计时
##        lbl_pickups   : Label  顶部剩余次数
##        finish_popup  : FinishPopup 节点
##   2. 方案 A：手动驱动
##        hud.set_score(100)
##   3. 方案 B：连接 GameFlow（gd_state 插件）
##        hud.connect_to_flow(flow)
##   4. 结束：hud.show_finish(score)
## ============================================================


# ============================================================
#  节点引用（在 Inspector 拖入，避免硬编码节点路径）
# ============================================================
@export var lbl_score: Label
@export var lbl_countdown: Label
@export var lbl_pickups: Label
@export var finish_popup: FinishPopup


# ============================================================
#  对外接口：数值驱动
# ============================================================
func set_score(value: int) -> void:
	if lbl_score:
		lbl_score.text = "%d" % value


func set_countdown(sec: float) -> void:
	if lbl_countdown:
		# 向上取整显示，避免"显示 99 实际只剩 0.1 秒"
		lbl_countdown.text = "%d" % int(ceil(sec))


func set_pickups(value: int) -> void:
	if lbl_pickups:
		lbl_pickups.text = "%d" % value


# ============================================================
#  对外接口：结算弹窗
# ============================================================
func show_finish(score: int) -> void:
	if finish_popup:
		finish_popup.set_ui_result(score)
		finish_popup.show_popup()


func hide_finish() -> void:
	if finish_popup:
		finish_popup.hide_popup()


# ============================================================
#  便捷：一键连接 GameFlow（来自 gd_state 插件）
#  需要 gd_state 插件同时启用，否则类型不识别，可去掉类型标注用 Variant
# ============================================================
func connect_to_flow(flow: Variant) -> void:
	if flow == null:
		return
	# 监听生命周期信号
	flow.game_started.connect(_on_flow_started)
	flow.countdown_changed.connect(set_countdown)
	flow.game_ended.connect(_on_flow_ended)


func _on_flow_started() -> void:
	hide_finish()


func _on_flow_ended(final_data: Dictionary) -> void:
	var score: int = int(final_data.get("final_score", 0))
	show_finish(score)
