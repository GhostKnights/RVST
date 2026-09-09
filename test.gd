extends Node3D

func _ready() -> void:
	print("=== 代价查询（期望: 1.0 / 100.0 / 100.0 / 1.0 / 0.6 / 2.0）===")
	print("turtle-water     = ", ConfigManager.get_cost("turtle", "water"))
	print("rabbit-water     = ", ConfigManager.get_cost("rabbit", "water"))
	print("turtle-highland  = ", ConfigManager.get_cost("turtle", "highland"))
	print("rabbit-highland  = ", ConfigManager.get_cost("rabbit", "highland"))
	print("turtle-downhill  = ", ConfigManager.get_cost("turtle", "downhill"))
	print("rabbit-downhill  = ", ConfigManager.get_cost("rabbit", "downhill"))
	print("=== 禁行查询（期望: false / true / true）===")
	print("turtle-water solid    = ", ConfigManager.is_solid("turtle", "water"))
	print("rabbit-water solid    = ", ConfigManager.is_solid("rabbit", "water"))
	print("turtle-highland solid = ", ConfigManager.is_solid("turtle", "highland"))
