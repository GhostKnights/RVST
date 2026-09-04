class_name GameFlow
extends Node
## ============================================================
##  GameFlow —— 通用游戏流程控制器（跨玩法复用）
## ============================================================
## 【职责】管理"开始/暂停/恢复/结束/重开"生命周期 + 可选倒计时，
##   所有变化通过信号通知外部。**不持有玩法数据**（分数、次数、
##   道具等由项目自己持有，或在 end 时通过 final_data 传出）。
##
## 【来源】从项目 GameManager 抽象而来，剥离玩法数据后的通用骨架。
##
## 【用法】
##   1. 挂一个 GameFlow 节点（场景或 Autoload 均可）
##   2. 连接信号：game_started / game_ended / countdown_changed ...
##   3. 开局：flow.start_game({ "countdown_enabled": true, "countdown_seconds": 99 })
##   4. 结束：flow.end_game({ "final_score": 100 })
##   5. 暂停/恢复/重开：pause_game() / resume_game() / start_game(...)
##
## 【注意】get_tree().paused = true 时本节点 _process 停跑，
##   倒计时自动冻结，符合"暂停即冻结"预期。
## ============================================================


# ============================================================
#  信号
# ============================================================
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended(final_data: Dictionary)
signal countdown_changed(remaining_sec: float)


# ============================================================
#  阶段枚举
# ============================================================
enum Phase { IDLE, RUNNING, PAUSED, ENDED }


# ============================================================
#  内部状态
# ============================================================
var phase: Phase = Phase.IDLE

# 倒计时（可选，通过 start_game 的 data 启用）
var countdown_enabled: bool = false
var countdown_total: float = 0.0
var countdown_remaining: float = 0.0


# ============================================================
#  生命周期
# ============================================================

## 开始/重开新游戏。data 可选键：
##   countdown_enabled: bool   是否启用倒计时
##   countdown_seconds: float  倒计时总秒数
func start_game(data: Dictionary = {}) -> void:
	phase = Phase.RUNNING
	get_tree().paused = false

	countdown_enabled = bool(data.get("countdown_enabled", false))
	countdown_total = float(data.get("countdown_seconds", 0.0))
	countdown_remaining = countdown_total

	emit_signal("game_started")


## 结束游戏（防重入）。final_data 用于把结算数据传出
##   （如 { "final_score": 100, "reason": "timeout" }）
func end_game(final_data: Dictionary = {}) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	get_tree().paused = true
	emit_signal("game_ended", final_data)


## 暂停
func pause_game() -> void:
	if phase != Phase.RUNNING:
		return
	phase = Phase.PAUSED
	get_tree().paused = true
	emit_signal("game_paused")


## 恢复
func resume_game() -> void:
	if phase != Phase.PAUSED:
		return
	phase = Phase.RUNNING
	get_tree().paused = false
	emit_signal("game_resumed")


## 快捷：是否在运行中（用于输入/逻辑开关）
func is_running() -> bool:
	return phase == Phase.RUNNING


# ============================================================
#  倒计时（每帧驱动）
# ============================================================
func _process(delta: float) -> void:
	if not countdown_enabled or phase != Phase.RUNNING:
		return

	countdown_remaining -= delta
	if countdown_remaining <= 0.0:
		countdown_remaining = 0.0
		emit_signal("countdown_changed", 0.0)
		end_game()
	else:
		emit_signal("countdown_changed", countdown_remaining)
