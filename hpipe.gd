extends Area2D

enum Direction { NORTH, SOUTH, WEST, EAST }

# 👇 ЭТОТ ПАРАМЕТР БУДЕШЬ МЕНЯТЬ В ИНСПЕКТОРЕ ДЛЯ КАЖДОЙ ТРУБЫ
var open_sides = [Direction.EAST, Direction.WEST]

var connected_pipes = []

@onready var empty_sprite = $Emptypipe
@onready var full_sprite = $Fillpipe

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	full_sprite.hide()

func _on_area_entered(area):
	if area not in connected_pipes:
		connected_pipes.append(area)
		_update_water()

func _on_area_exited(area):
	if area in connected_pipes:
		connected_pipes.erase(area)
		_update_water()

func _update_water():
	if connected_pipes.size() > 0:
		full_sprite.show()
		empty_sprite.hide()
	else:
		full_sprite.hide()
		empty_sprite.show()

func rotate_pipe():
	rotation_degrees += 90
	
	var new_sides = []
	for side in open_sides:
		match side:
			Direction.NORTH:
				new_sides.append(Direction.EAST)
			Direction.EAST:
				new_sides.append(Direction.SOUTH)
			Direction.SOUTH:
				new_sides.append(Direction.WEST)
			Direction.WEST:
				new_sides.append(Direction.NORTH)
	open_sides = new_sides
	_update_water()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
		if rect.has_point(mouse_pos):
			rotate_pipe()
