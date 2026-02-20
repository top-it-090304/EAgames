extends TileMapLayer

@onready var water = get_node("../Water")

func _input(event):
	print("Событие: ", event)  # Проверяем, видит ли Godot касания
	
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.pressed):
		print("Касание обнаружено!")  # Проверяем, заходит ли в условие
		
		var touch_pos = event.position
		var cell_pos = local_to_map(to_local(touch_pos))
		
		print("Позиция клетки: ", cell_pos)  # Смотрим координаты
		print("ID клетки: ", get_cell_source_id(cell_pos))  # Что там лежит
		
		if get_cell_source_id(cell_pos) != -1:
			print("Удаляем землю!")  # Подтверждение удаления
			erase_cell(cell_pos)
			check_water_path()

func check_water_path():
	# Получаем позицию воды в клетках
	var water_pos = water.position
	var water_cell = local_to_map(to_local(water_pos))
	
	# Смотрим клетку под водой
	var below_cell = Vector2i(water_cell.x, water_cell.y + 1)
	
	# Если под водой пусто - вода может течь
	if get_cell_source_id(below_cell) == -1:
		water.can_move = true
		print("Вода может течь!")
