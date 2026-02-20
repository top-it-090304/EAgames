extends Area2D

var velocity = Vector2(0, 0)
var water_gravity = 200
var can_move = false
var ducks_collected = 0

@onready var ray = $RayCast2D
@onready var visual = $ColorRect
@onready var ground = get_node("../Ground")  # Добавляем ссылку на землю

func _ready():
	# Настраиваем внешний вид
	visual.color = Color(0.2, 0.6, 1, 0.8)
	
	# Создаем мерцание воды
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_blink)
	add_child(timer)
	timer.start()

func _physics_process(delta):
	if not can_move:
		return
	
	# Проверяем, есть ли земля ПРЯМО ПОД водой (для остановки)
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.name == "Ground":
			velocity.y = 0
			can_move = false
			print("Вода остановилась - земля под водой")
			return
	
	# НОВАЯ ПРОВЕРКА: проверяем, есть ли земля ВПЕРЕДИ по пути движения
	var next_position = position + Vector2(0, velocity.y * delta * 2)  # позиция в следующем кадре
	var next_cell = ground.local_to_map(ground.to_local(next_position))
	
	# Если в следующей клетке есть земля - останавливаемся
	if ground.get_cell_source_id(next_cell) != -1:
		velocity.y = 0
		can_move = false
		print("Вода остановилась - земля впереди в клетке ", next_cell)
		return
	
	# Падаем вниз
	velocity.y += water_gravity * delta  # ИСПРАВЛЕНО: water_gravity вместо gravity
	position += velocity * delta

func _blink():
	# Эффект мерцания воды
	visual.color.a = 0.6 + randf() * 0.3

func _on_area_entered(area):
	if area.name.begins_with("Duck"):
		ducks_collected += 1
		print("Уточка собрана! Всего: ", ducks_collected)
		area.queue_free()
	
	if area.name == "Swampy":
		print("ПОБЕДА! Уровень пройден! Уточек: ", ducks_collected)
		# Здесь можно перейти на следующий уровень
		# get_tree().change_scene_to_file("res://level2.tscn")
