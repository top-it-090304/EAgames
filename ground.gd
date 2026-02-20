extends TileMapLayer

@onready var water = get_node("../Water")

func _input(event):
	# ДЛЯ ПК: используем InputEventMouseButton
	if event is InputEventMouseButton and event.pressed:
		print("Клик мыши! Кнопка: ", event.button_index)
		
		# Левая кнопка мыши (обычно 1)
		if event.button_index == MOUSE_BUTTON_LEFT:
			var touch_pos = event.position
			var cell_pos = local_to_map(to_local(touch_pos))
			
			print("Позиция клетки: ", cell_pos)
			print("ID клетки: ", get_cell_source_id(cell_pos))
			
			if get_cell_source_id(cell_pos) != -1:
				print("Удаляем землю!")
				erase_cell(cell_pos)
				check_water_path()

# Оставляем функцию для воды без изменений
func check_water_path():
	var water_pos = water.position
	var water_cell = local_to_map(to_local(water_pos))
	var below_cell = Vector2i(water_cell.x, water_cell.y + 1)
	
	if get_cell_source_id(below_cell) == -1:
		water.can_move = true
		print("Вода может течь!")
