extends Node2D

@onready var tilemap = $Terrain

@export var brush_size: int = 1  # размер кисти в тайлах

# Размер одного тайла в пикселях
var tile_size = 512

func _ready():
	print("=== TILEMAP ЗЕМЛЯ ГОТОВА ===")
	print("Размер карты: ", tilemap.get_used_rect())
	print("Размер тайла: ", tile_size)

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		erase_at_position(mouse_pos)

func erase_at_position(world_pos: Vector2):
	# Получаем координаты тайла под мышкой
	var tile_coords = tilemap.local_to_map(tilemap.to_local(world_pos))
	
	# Очищаем тайлы в радиусе
	for x in range(-brush_size, brush_size + 1):
		for y in range(-brush_size, brush_size + 1):
			var erase_pos = tile_coords + Vector2i(x, y)
			
			# Проверяем, есть ли там тайл
			if tilemap.get_cell_source_id(erase_pos) != -1:
				# Удаляем тайл (стираем землю)
				tilemap.set_cell(erase_pos, -1)
				
				# Сообщаем GridManager
				var world_erase_pos = tilemap.to_global(tilemap.map_to_local(erase_pos))
				GridManager.erase_terrain(world_erase_pos.x, world_erase_pos.y)
