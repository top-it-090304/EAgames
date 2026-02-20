extends Area2D

var velocity = Vector2(0, 0)
var water_gravity = 200
var can_move = false
var ducks_collected = 0

@onready var ray = $RayCast2D
@onready var visual = $ColorRect

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
	
	# Проверяем, есть ли земля под водой
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.name == "Ground":
			velocity.y = 0
			can_move = false
			print("Вода остановилась")
			return
	
	# Падаем вниз
	velocity.y += gravity * delta
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
