# GD UI（通用 UI 骨架）

跨玩法复用的 UI 基础件：结算弹窗、HUD 控制器。

## 安装
1. 把 `addons/gd_ui` 整个目录复制到项目 `addons/` 下
2. 项目设置 → 插件 → 启用 **GD UI**
3. 全局类自动可用：`FinishPopup`、`HudMenu`

## FinishPopup（结算弹窗）
通用结算面板。场景里放一个 Control 挂本脚本，子节点约定：
```
FinishPopup (Control)
└─ Control
   ├─ Btn_Restart   (Button)
   ├─ Btn_GameOver  (Button)
   └─ Text_Finish   (Label)
```

```gdscript
finish_popup.set_ui_result(355)
finish_popup.show_popup()
finish_popup.request_restart.connect(restart_game)
```

## HudMenu（HUD 控制器）
顶部信息条 + 弹窗的管理器。节点引用在 Inspector 拖入，不依赖固定路径。

```gdscript
@onready var hud: HudMenu = $HUD
hud.set_score(100)
hud.set_countdown(58.3)
hud.set_pickups(7)
hud.show_finish(355)
```

### 与 GameFlow 联动（推荐）
同时启用 gd_state 插件后，一行接线：
```gdscript
hud.connect_to_flow(flow)
```
之后 HUD 自动响应开局/倒计时/结束信号。
