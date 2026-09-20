extends "res://addons/gd_config/ConfigManager.gd"

var cost_override: Dictionary = {}	#键: "role:terrain", 值： 临时代价
func _ready() -> void:
	table_specs = {
		"cost": {"file": "cost_table.csv", "skip": 2},
	}
	super._ready()
	
func get_cost(role: String, terrain: String) -> float:
	var key := role + ":" + terrain
	if cost_override.has(key):
		return cost_override[key]	#有覆盖用覆盖
	return float(lookup_multi(get_table("cost"), {"role": role, "terrain": terrain}, "cost", 1.0))

func is_solid(role: String, terrain: String) -> bool:
	var solid_val: Variant = lookup_multi(get_table("cost"), {"role": role, "terrain": terrain}, "solid", 0)
	return int(solid_val) != 0
	
func set_cost_override(role: String, terrain: String, value: float) -> void:
	cost_override[role + ":" + terrain] = value

func clear_cost_override(role: String, terrain: String) -> void:
	cost_override.erase(role + ":" + terrain)
