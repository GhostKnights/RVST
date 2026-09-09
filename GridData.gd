class_name GridData
extends RefCounted

var grid_board: Dictionary[Vector2i, String] = {}
var cell_size: float = 1.0


func cell_to_world(cell: Vector2i) -> Vector3:
	var world_position: Vector3 = Vector3((cell.x+0.5)*cell_size,0,(cell.y+0.5)*cell_size)
	return world_position
	
func world_to_cell(world_p: Vector3) -> Vector2i:
	var grid_position: Vector2i = Vector2i(floori(world_p.x/cell_size),floori(world_p.z/cell_size))
	return grid_position 
	
func set_terrain(cell: Vector2i,terrain: String) ->void:
	grid_board[cell] = terrain
	
func get_terrain(cell: Vector2i,default: String = "flat") -> String:
	return grid_board.get(cell, default)
	
