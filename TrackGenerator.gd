class_name TrackGenerator
extends RefCounted

var grid_data: GridData
var current_row: int

func generate() -> void:
	current_row = 6                    # 起点中心行
	for col in range(0, 20):
		grid_data.set_terrain(Vector2i(col, current_row-1),"flat")
		grid_data.set_terrain(Vector2i(col, current_row),"flat")	    
		grid_data.set_terrain(Vector2i(col, current_row+1),"flat")
		
		if col < 19:                   # 最后一列不用再决定下一列
			current_row = clampi((current_row + randi_range(-1,1)),1,10)
		
