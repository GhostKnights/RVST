# godot-common —— 跨项目共享框架（Godot 4）

面向"多个玩法不同、技术栈相同"的系列项目。把与玩法无关的通用功能做成
**独立插件包**，每个项目通过 **Git subtree**（或直接复制）引入，
一处维护处处复用。

## 为什么这样组织

- **玩法层**（各项目私有）：具体玩法逻辑留在各自项目，互不干扰
- **框架层**（本仓库的插件包）：通用功能，一次开发多项目复用
- **引擎层**（Godot 4.7）：官方能力，不自造轮子

玩法不同 ≠ 技术栈不同。配置、状态机、UI 骨架、事件总线这些"皮"不依赖"肉"，
值得抽出来共享。

## 目录结构

```
godot-common/            <- git 仓库根（每个子目录就是一个 Godot 插件包）
├── README.md
├── gd_config/           # 通用配置查询引擎（5 种查表 + KV 配置）→ 注册 ConfigManager 单例
├── gd_state/            # 通用状态机 StateMachine + 游戏流程控制器 GameFlow
├── gd_ui/               # 通用 UI 骨架：结算弹窗 FinishPopup、HUD 控制器 HudMenu
└── gd_core/             # 基础设施：事件总线 GameBus、日志 GameLog
```

> 插件包放在仓库根（而不是 `addons/` 子目录下），是为了让 subtree 能直接
> 铺到项目的 `addons/` 目录，符合 Godot "插件必须在 res://addons/<插件名>/" 的约定。

## 接入方式

### 方式一：Git subtree（推荐）
共享仓库直接合并进项目 `addons/` 目录，成为项目代码的一部分，无 `.gitmodules`。

```bash
# 首次引入：把共享插件铺到项目 addons/ 下
git subtree add --prefix addons <godot-common 仓库地址> main --squash

# 之后同步共享层更新到本项目
git subtree pull --prefix addons <godot-common 仓库地址> main --squash

# 在本项目里改了共享代码后，回推到共享仓库
git subtree push --prefix addons <godot-common 仓库地址> main
```

> 分支名以共享仓库实际分支为准（本仓库为 `main`；旧仓库可能是 `master`）。

引入后项目里会出现 `addons/gd_config/`、`addons/gd_state/` 等插件目录，
在项目设置 → 插件 里启用即可。

> 注意：subtree 会把共享代码历史并入项目历史（历史体积变大）；
> 如果"共享层更新"和"本地改过共享代码"同时发生，pull 可能需要解决冲突。
> 单人开发控制好节奏（先 pull 再改，或改完先 push）通常不会遇到。

### 方式二：直接复制（免 git，最快起跑）
把需要的插件目录（如 `gd_config/`）复制到项目 `addons/` 下。
更新时手动再复制。

> 缺点：没有自动同步，共享层修了 bug 需要手动分发到每个项目。

## 启用插件

复制 / subtree 引入后，在项目设置 → 插件 里启用需要的插件：
- **GD Config** → 自动注册 `ConfigManager` 单例
- **GD State** → 提供全局类 `StateMachine` / `GameFlow`
- **GD UI** → 提供全局类 `FinishPopup` / `HudMenu`
- **GD Core** → 自动注册 `GameBus` / `GameLog` 单例

## 各模块使用

| 模块 | 一句话 | 详见 |
|---|---|---|
| gd_config | 配置表加载 + 5 种查表模式 | `gd_config/README.md` |
| gd_state | 状态机 + 游戏流程生命周期 | `gd_state/README.md` |
| gd_ui | 结算弹窗 + HUD 骨架 | `gd_ui/README.md` |
| gd_core | 事件总线 + 日志 | `gd_core/README.md` |

## 提炼原则（怎么决定新功能进不进共享层）

写新玩法时先在自己的项目里做出来、跑通、验证，然后问三条判据：

1. **下一个项目也会用它吗？** —— 只有一次用途的不抽
2. **它不依赖具体玩法的数据吗？** —— 依赖数据就做成"配置驱动"再抽
3. **接口稳定了吗？** —— 跑通一个项目后再抽，避免早期反复改接口

三条全满足 → 挪进本仓库做成插件包，顺手写 README + 示例。

## 版本策略

- 共享层升级注意向后兼容（不删既有接口，用新增方式扩展）
- 破坏性改动升主版本号，并在 README 标注迁移说明
- 各项目通过 subtree 锁定的快照按需手动 pull，避免被共享层更新带崩
