extends Area2D

enum Direction { NORTH, SOUTH, WEST, EAST }

var open_sides = [Direction.EAST, Direction.SOUTH]
var connected_pipes = []
var has_water = false

@onready var empty_sprite = $Emptypipe
@onready var full_sprite = $Fillpipe

func _ready():
	area_entered.connect(_on_area_entered)
	full_sprite.hide()
	
	# Даем воду через 1 секунду, НО только если есть соединения
	#await get_tree().create_timer(1.0).timeout
	#_try_start_water()
	receive_water()

func _try_start_water():
	# Сначала проверяем все текущие соединения
	_recheck_connections()
	
	# Если есть хотя бы одно валидное соединение - даем воду
	if connected_pipes.size() > 0:
		print("Есть соединения, даю воду")
		receive_water()
	else:
		print("Нет соединений, вода не дана")

func get_side_to(neighbor):
	var diff = neighbor.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		return Direction.EAST if diff.x > 0 else Direction.WEST
	else:
		return Direction.SOUTH if diff.y > 0 else Direction.NORTH

func get_opposite(side):
	match side:
		Direction.NORTH: return Direction.SOUTH
		Direction.SOUTH: return Direction.NORTH
		Direction.WEST: return Direction.EAST
		Direction.EAST: return Direction.WEST
	return side

func can_connect(neighbor):
	var my_side = get_side_to(neighbor)
	var their_side = get_opposite(my_side)
	
	var my_side_open = my_side in open_sides
	var their_side_open = their_side in neighbor.open_sides
	
	# Отладка
	print("   my_side=", my_side, " (", _side_to_string(my_side), ")")
	print("   their_side=", their_side, " (", _side_to_string(their_side), ")")
	print("   my_side in open_sides? ", my_side_open)
	print("   their_side in neighbor.open_sides? ", their_side_open)
	
	return my_side_open and their_side_open

func _side_to_string(side):
	match side:
		Direction.NORTH: return "NORTH"
		Direction.SOUTH: return "SOUTH"
		Direction.WEST: return "WEST"
		Direction.EAST: return "EAST"
	return "?"

func _on_area_entered(area):
	print("Вошла труба: ", area.name)
	
	if can_connect(area) and area not in connected_pipes:
		connected_pipes.append(area)
		print("Соединение установлено! Теперь connected_pipes: ", connected_pipes.size())
		
		if has_water:
			print("У меня есть вода, передаю соседу")
			area.receive_water()
		elif area.has_water:  # ← ЭТО НОВОЕ! Проверяем, есть ли вода у соседа
			print("У соседа есть вода, беру себе")
			receive_water()

func _on_area_exited(area):
	if area in connected_pipes:
		connected_pipes.erase(area)
		print("Потерял соединение. connected_pipes: ", connected_pipes.size())

func receive_water():
	if has_water:
		return
	
	has_water = true
	full_sprite.show()
	empty_sprite.hide()
	print("💧 Вода появилась у ", name)
	
	# Передаем воду всем соединенным трубам
	for pipe in connected_pipes:
		if pipe.has_method("receive_water") and not pipe.has_water:
			print("  → Передаю воду ", pipe.name)
			pipe.receive_water()

func _recheck_connections():
	connected_pipes.clear()
	for area in get_overlapping_areas():
		if can_connect(area):
			connected_pipes.append(area)
	print("Recheck: connected_pipes = ", connected_pipes.size())

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
		if rect.has_point(mouse_pos):
			rotation_degrees += 90
			# После поворота перепроверяем соединения
			_recheck_connections()
