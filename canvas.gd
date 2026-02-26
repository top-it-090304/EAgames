extends Node2D

@export var brush_texture: Texture2D
var drawing = false

func _input(event):
	# Проверяем нажатие/касание
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
	
	# Для мобильных устройств (движение пальца)
	if event is InputEventScreenDrag:
		_draw_brush(event.position)
			
	# Если мышь движется и кнопка зажата
	if event is InputEventMouseMotion and drawing:
		_draw_brush(event.position)

func _draw_brush(pos):
	var brush = Sprite2D.new()
	brush.texture = brush_texture
	# Важно: берем локальную позицию мыши относительно canvas
	brush.position = get_local_mouse_position() 
	add_child(brush) # Теперь без ошибок, добавляем прямо в себя
