extends Node

# Размер ячейки в пикселях (должен совпадать с размером тайла!)
var cell_size = 64  # !!! ВАЖНО: теперь размер тайла
# Размер карты в ячейках
var map_width = 100
var map_height = 100

var terrain = []  # true - есть земля, false - стерто

func _ready():
	terrain.resize(map_width)
	for x in range(map_width):
		terrain[x] = []
		terrain[x].resize(map_height)
		for y in range(map_height):
			terrain[x][y] = true

func erase_terrain(world_x, world_y):
	var cell = world_to_cell(world_x, world_y)
	if is_valid_cell(cell):
		if terrain[cell.x][cell.y] == true:
			terrain[cell.x][cell.y] = false
			return true
	return false

func world_to_cell(world_x, world_y):
	return Vector2i(
		int(floor(world_x / cell_size)),
		int(floor(world_y / cell_size))
	)

func is_valid_cell(cell):
	return cell.x >= 0 and cell.x < map_width and cell.y >= 0 and cell.y < map_height
