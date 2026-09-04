# GD Config（通用配置查询引擎）

跨项目复用的配置层：把 CSV/TXT 配置加载成表，提供 5 种通用查表模式，与任何玩法无关。

## 安装
1. 把 `addons/gd_config` 整个目录复制到项目 `addons/` 下
2. 项目设置 → 插件 → 启用 **GD Config**
3. 插件会自动注册 `ConfigManager` 单例（无需手动加 Autoload）

## 使用

### 方式 A：直接使用单例
在任意脚本里配置要加载的表：

```gdscript
# 主场景或启动脚本
func _ready() -> void:
	ConfigManager.config_dir = "res://Config/"
	ConfigManager.table_specs = {
		"score": {"file": "PickUP.txt", "skip": 3},
	}
	ConfigManager.kv_specs = {
		"game_rules": "game_rules.txt",
	}
	ConfigManager.load_all()
```

### 方式 B：子类化（推荐）
建一个 `ProjectConfig.gd extends ConfigManager`，把业务薄封装放里面。
> 注意：ConfigManager 是 Autoload 单例，脚本本身没有 class_name，
> 子类化要用脚本路径 extends。

```gdscript
class_name ProjectConfig
extends "res://addons/gd_config/ConfigManager.gd"

func _ready() -> void:
	table_specs = {
		"score": {"file": "PickUP.txt", "skip": 3},
	}
	kv_specs = {
		"game_rules": "game_rules.txt",
	}
	super._ready()

# 业务薄封装（查表逻辑永远不重写）
func get_score_by_area(area: float) -> int:
	return int(lookup_range(get_table("score"), area, "max_area", "score", 0))

func get_game_rule(key: String, default: Variant) -> Variant:
	return get_kv("game_rules", key, default)
```

然后把 Autoload 指向 `ProjectConfig.gd` 即可。

## 5 种查表模式
| 模式 | 方法 | 场景 |
|---|---|---|
| 精确 | `lookup_exact(table, val, key_col, ret_col)` | id → 名称 |
| 区间 | `lookup_range(table, input, range_col, ret_col)` | 面积 → 分数 |
| 权重 | `lookup_weighted(table, weight_col, ret_col)` | 掉落表 |
| 多条件 | `lookup_multi(table, {a:1,b:2}, ret_col)` | 兵种+等级 → 攻击 |
| 插值 | `lookup_interpolated(table, input, x_col, y_col)` | 等级 → 经验曲线 |

## 配置表格式
- 普通表：前 N 行表头 + 逗号分隔数据行（.csv / .txt 均可）
- KV 表：`key,value` 两列，一行一个参数
- 文件缺失时返回空表/默认值，不崩溃
