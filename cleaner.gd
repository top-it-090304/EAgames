extends Node2D

@onready var top_layer = $top_layer
@onready var background = $background

func _ready():
	print("Игра инициализирована")
	
	# Отключаем старый canvas если есть
	if has_node("SubViewportContainer/SubViewport/canvas"):
		$SubViewportContainer/SubViewport/canvas.visible = false
	
	# Создаем eraser
	if not has_node("eraser"):
		var eraser = preload("res://eraser.gd").new()
		eraser.brush_size = 15
		add_child(eraser)
		eraser.name = "eraser"
	
	# Создаем water_manager
	if not has_node("water_manager"):
		var water_manager = preload("res://water_manager.gd").new()
		add_child(water_manager)
		water_manager.name = "water_manager"
