# GD State（通用状态机 + 游戏流程控制器）

跨玩法复用的流程骨架，把"状态迁移"和"游戏生命周期"做成与具体玩法无关的通用模块。

## 安装
1. 把 `addons/gd_state` 整个目录复制到项目 `addons/` 下
2. 项目设置 → 插件 → 启用 **GD State**
3. 两个全局类自动可用：`StateMachine`、`GameFlow`

## StateMachine（状态机）
适合 AI 行为、UI 流程、战斗阶段、场景流程。

```gdscript
var sm := StateMachine.new()
add_child(sm)

sm.register_state("idle", _on_idle)
sm.register_state("attacking", _on_attack, _on_attack_exit)
sm.change_state("attacking", { target = enemy })  # payload 传给回调

func _on_idle(state_name: String, payload: Variant) -> void:
	print("进入 idle")
```

## GameFlow（游戏流程控制器）
从项目 GameManager 抽象而来，剥离了玩法数据，只保留生命周期骨架。

```gdscript
@onready var flow: GameFlow = $GameFlow
flow.game_started.connect(...)
flow.game_ended.connect(func(data): print("结束", data))

# 开局（带倒计时）
flow.start_game({ "countdown_enabled": true, "countdown_seconds": 99 })
# 结束（带结算数据）
flow.end_game({ "final_score": 100 })
```

## 与玩法数据的关系
GameFlow 不持有分数/次数等数据——那是各玩法的私有状态。
项目在自己的脚本里管理数据，结束/开局时通过 `final_data` 或 `data` 传递即可。
