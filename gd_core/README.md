# GD Core（事件总线 + 日志）

跨玩法复用的基础通信与日志设施。

## 安装
1. 把 `addons/gd_core` 整个目录复制到项目 `addons/` 下
2. 项目设置 → 插件 → 启用 **GD Core**
3. 自动注册两个单例：`GameBus`、`GameLog`

> 命名说明：Godot 4 内置了原生类 `Logger`，重名会冲突；`EventBus` 名在部分环境下会被解析为"类"导致单例调用报错。因此统一命名为 `GameBus` / `GameLog`，规避一切重名问题。

## GameBus（事件总线）
解耦模块通信。

```gdscript
# 发
GameBus.emit_event("player_died", { "pos": Vector3(0, 0, 0) })
# 收
GameBus.on_event("player_died", _on_player_died)
func _on_player_died(payload: Dictionary) -> void: ...
```

## GameLog（日志）
统一分级日志。

```gdscript
GameLog.set_level(GameLog.Level.DEBUG)
GameLog.info("加载完成")
GameLog.warn("配置缺失，用默认值")
GameLog.error("初始化失败")
```

## 事件命名建议
事件名建议集中定义常量，避免散落字符串：

```gdscript
# events.gd
class_name GameEvents
const PLAYER_DIED := "player_died"
const SCORE_CHANGED := "score_changed"
```
