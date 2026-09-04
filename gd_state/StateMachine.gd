class_name StateMachine
extends Node
## ============================================================
##  StateMachine —— 通用状态机（跨玩法复用）
## ============================================================
## 【职责】用"状态名 + 进出回调"驱动状态迁移，不关心具体玩法。
##   适用于：AI 行为、UI 流程、战斗阶段、场景流程等。
##
## 【用法】
##   1. 在场景里挂一个 StateMachine 节点（或 add_child）
##   2. 注册状态：
##        sm.register_state("idle", _on_idle_enter)
##      enter/exit 回调签名：func(state_name: String, payload: Variant) -> void
##   3. 切换状态：
##        sm.change_state("attacking", {target = 敌人})
##   4. 监听迁移：sm.state_changed.connect(...)
##      signal state_changed(from, to, payload)
##
## 【设计要点】
##   - 状态只是字符串，不绑定节点结构，任何玩法都能用
##   - 支持 enter 回调带 payload（跨状态传数据）
##   - 同一状态重复切换默认忽略（可配置 allow_reentry）
## ============================================================


# ============================================================
#  信号
# ============================================================
signal state_changed(from_state: String, to_state: String, payload: Variant)
signal state_entered(state_name: String, payload: Variant)


# ============================================================
#  配置
# ============================================================
## 初始状态（_ready 时自动进入）
@export var initial_state: String = ""
## 是否允许切换到当前所在的状态（默认 false 忽略重复切换）
@export var allow_reentry: bool = false


# ============================================================
#  内部状态
# ============================================================
var current_state: String = ""

# 状态名 -> { "enter": Callable, "exit": Callable }
var _states: Dictionary = {}


# ============================================================
#  生命周期
# ============================================================
func _ready() -> void:
	if initial_state != "" and _states.has(initial_state):
		change_state(initial_state)


# ============================================================
#  对外接口
# ============================================================

## 注册一个状态。
## on_enter / on_exit 可选，签名：func(state_name: String, payload: Variant) -> void
func register_state(state_name: String, on_enter: Callable = Callable(), on_exit: Callable = Callable()) -> void:
	_states[state_name] = {
		"enter": on_enter,
		"exit": on_exit,
	}


## 注销一个状态
func unregister_state(state_name: String) -> void:
	_states.erase(state_name)


## 切换到指定状态。payload 会传给新状态的 enter 回调，并随 state_changed 信号发出
func change_state(state_name: String, payload: Variant = null) -> bool:
	if not _states.has(state_name):
		push_warning("[StateMachine] 未注册的状态: %s" % state_name)
		return false
	if state_name == current_state and not allow_reentry:
		return false

	var from: String = current_state
	var to: String = state_name

	# 退出旧状态
	if from != "" and _states.has(from):
		var exit_cb: Callable = _states[from].exit
		if exit_cb.is_valid():
			exit_cb.call(from, payload)

	# 进入新状态
	current_state = to
	var enter_cb: Callable = _states[to].enter
	if enter_cb.is_valid():
		enter_cb.call(to, payload)

	state_changed.emit(from, to, payload)
	state_entered.emit(to, payload)
	return true


## 当前是否处于某状态
func is_in_state(state_name: String) -> bool:
	return current_state == state_name
