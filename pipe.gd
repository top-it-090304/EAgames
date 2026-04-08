extends Area2D

enum Direction { NORTH, SOUTH, WEST, EAST }

# Стороны трубы (меняешь для каждого типа)
var open_sides = [Direction.NORTH, Direction.SOUTH]

# Список соединенных труб
var connected_pipes = []

var has_water = false

@onready var empty_sprite = $EmptySprite
@onready var full_sprite = $FullSprite

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	full_sprite.hide()

# Определяем сторону, где находится сосед
func get_side_to(neighbor: Area2D) -> int:
	var diff = neighbor.global_position - global_position
	
	if abs(diff.x) > abs(diff.y):
		return Direction.EAST if diff.x > 0 else Direction.WEST
	else:
		return Direction.SOUTH if diff.y > 0 else Direction.NORTH

# Противоположная сторона
func get_opposite(side: int) -> int:
	match side:
		Direction.NORTH: return Direction.SOUTH
		Direction.SOUTH: return Direction.NORTH
		Direction.WEST: return Direction.EAST
		Direction.EAST: return Direction.WEST
	return side

# Проверка: можно ли соединиться?
func can_connect(neighbor: Area2D) -> bool:
	var my_side = get_side_to(neighbor)
	var their_side = get_opposite(my_side)
	
	return (my_side in open_sides) and (their_side in neighbor.open_sides)

func _on_area_entered(area):
	if can_connect(area) and area not in connected_pipes:
		connected_pipes.append(area)
		
		# Если у меня есть вода, даю воду соседу
		if has_water:
			area.receive_water()

func _on_area_exited(area):
	if area in connected_pipes:
		connected_pipes.erase(area)
		
		# Если у меня была вода, сбрасываю себя
		if has_water:
			_reset_water()

# Получить воду (от источника или соседа)
func receive_water():
	if has_water:
		return
		
	has_water = true
	full_sprite.show()
	empty_sprite.hide()
	
	# Передаю воду всем соединенным трубам
	for pipe in connected_pipes:
		if pipe.has_method("receive_water"):
			pipe.receive_water()

# Сбросить воду (при разрыве соединения)
func _reset_water():
	if not has_water:
		return
		
	has_water = false
	full_sprite.hide()
	empty_sprite.show()

# Поворот трубы
func rotate_pipe():
	rotation_degrees += 90
	
	# Поворачиваем открытые стороны
	var rotated = []
	for side in open_sides:
		match side:
			Direction.NORTH: rotated.append(Direction.EAST)
			Direction.EAST: rotated.append(Direction.SOUTH)
			Direction.SOUTH: rotated.append(Direction.WEST)
			Direction.WEST: rotated.append(Direction.NORTH)
	open_sides = rotated
	
	# Перепроверяем все соединения
	_recheck_connections()

# Перепроверить соединения после поворота
func _recheck_connections():
	var old_pipes = connected_pipes.duplicate()
	connected_pipes.clear()
	
	# Находим всех, кто рядом и может соединиться
	for area in get_overlapping_areas():
		if can_connect(area):
			connected_pipes.append(area)
	
	# Если вода была, но соединения изменились
	if has_water:
		# Если нет соединений → сбрасываем воду
		if connected_pipes.is_empty():
			_reset_water()
		# Если появились новые соединения → даем им воду
		else:
			for pipe in connected_pipes:
				if pipe.has_method("receive_water") and not pipe.has_water:
					pipe.receive_water()

# Обработка клика
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
		if rect.has_point(mouse_pos):
			rotate_pipe()
