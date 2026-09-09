extends "res://addons/gd_config/ConfigManager.gd"

func _ready() -> void:
	table_specs = {
		"cost": {"file": "cost_table.csv", "skip": 2},
	}
	super._ready()
	
func get_cost(role: String, terrain: String) -> float:
	return float(lookup_multi(get_table("cost"), {"role": role, "terrain": terrain}, "cost", 1.0))

func is_solid(role: String, terrain: String) -> bool:
	var solid_val: Variant = lookup_multi(get_table("cost"), {"role": role, "terrain": terrain}, "solid", 0)
	return int(solid_val) != 0
