extends Area2D

enum Direction { NORTH, SOUTH, WEST, EAST }

var open_sides = [Direction.NORTH, Direction.SOUTH]
var connected_pipes = []
var has_water = false

@onready var empty_sprite = $Emptypipe
@onready var full_sprite = $Fillpipe

func _ready():
	area_entered.connect(_on_area_entered)
	full_sprite.hide()
	
	## Даем воду через 1 секунду
	#await get_tree().create_timer(1.0).timeout
	#receive_water()

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
		print("Соединение установлено!")
		
		if has_water:
			print("Передаю воду соседу")
			area.receive_water()

func receive_water():
	if has_water:
		return
		
	print("Получил воду!")
	has_water = true
	full_sprite.show()
	empty_sprite.hide()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
		if rect.has_point(mouse_pos):
			rotation_degrees += 90
