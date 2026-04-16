extends Area2D

enum Direction { NORTH, SOUTH, WEST, EAST }

var open_sides = [Direction.EAST, Direction.WEST, Direction.SOUTH]  # для прямой трубы
var connected_pipes = []
var has_water = false

@onready var empty_sprite = $Emptypipe
@onready var full_sprite = $Fillpipe

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	full_sprite.hide()
	
	# НЕ ДАЕМ ВОДУ ПРИ СТАРТЕ!
	# Вода появится ТОЛЬКО когда соединятся трубы

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
	return (my_side in open_sides) and (their_side in neighbor.open_sides)

func _on_area_entered(area):
	print("Вошла труба: ", area.name)
	
	if can_connect(area) and area not in connected_pipes:
		connected_pipes.append(area)
		print("Соединение установлено! connected_pipes: ", connected_pipes.size())
		
		# КЛЮЧЕВОЙ МОМЕНТ: даем воду ТОЛЬКО при соединении
		if not has_water and not area.has_water:
			# Если это первое соединение в системе - даем воду
			print("Первое соединение! Даю воду себе")
			receive_water()
		elif has_water and not area.has_water:
			print("У меня есть вода, передаю соседу")
			area.receive_water()
		elif area.has_water and not has_water:
			print("У соседа есть вода, беру себе")
			receive_water()

func _on_area_exited(area):
	if area in connected_pipes:
		connected_pipes.erase(area)
		print("Потерял соединение. connected_pipes: ", connected_pipes.size())
		
		# Если потеряли последнее соединение - убираем воду
		if connected_pipes.size() == 0 and has_water:
			print("Нет соединений, убираю воду")
			has_water = false
			full_sprite.hide()
			empty_sprite.show()

func receive_water():
	if has_water:
		return
	
	has_water = true
	full_sprite.show()
	empty_sprite.hide()
	print("💧 Вода появилась у ", name)
	
	for pipe in connected_pipes:
		if pipe.has_method("receive_water") and not pipe.has_water:
			print("  → Передаю воду ", pipe.name)
			pipe.receive_water()

func _recheck_connections():
	var old_pipes = connected_pipes.duplicate()
	connected_pipes.clear()
	
	for area in get_overlapping_areas():
		if can_connect(area):
			connected_pipes.append(area)
	
	print("Recheck: connected_pipes = ", connected_pipes.size())
	
	# Если были соединения, но теперь их нет - убираем воду
	if has_water and connected_pipes.size() == 0:
		print("Соединения разорваны, убираю воду")
		has_water = false
		full_sprite.hide()
		empty_sprite.show()
	elif has_water:
		for pipe in connected_pipes:
			if pipe.has_method("receive_water") and not pipe.has_water:
				pipe.receive_water()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
		if rect.has_point(mouse_pos):
			rotation_degrees += 90
			_recheck_connections()
