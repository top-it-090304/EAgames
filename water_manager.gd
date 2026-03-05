extends Node2D

# Ссылки на узлы
@onready var top_layer = $"../top_layer"
@onready var water_exit = $"../water_exit"

# Настройки воды
@export var water_flow_speed: float = 90.0
@export var max_drops: int = 300

# Вода
var water_drops = []  # Все капли

# Карта проходимости (где стерта земля)
var passable_map = []
var map_width = 0
var map_height = 0
var cell_size = 2

# Позиция лужи
var pool_position = Vector2(400, 150)
var pool_radius = 70
var water_flow_active = false

func _ready():
	await get_tree().process_frame
	
	# Создаем карту проходимости
	_create_passable_map()
	
	# Центрируем лужу по экрану
	pool_position.x = get_viewport().size.x / 2
	
	# Создаем предварительно стертую область
	_create_initial_pool()
	
	# Заполняем лужу водой
	_fill_pool_with_water()
	
	print("=== ВОДА ГОТОВА ===")
	print("Позиция лужи: ", pool_position)

func _create_passable_map():
	if top_layer and top_layer.texture:
		var tex_size = top_layer.texture.get_size()
		map_width = int(ceil(tex_size.x / float(cell_size))) + 1
		map_height = int(ceil(tex_size.y / float(cell_size))) + 1
		
		passable_map.resize(map_width)
		for x in range(map_width):
			passable_map[x] = []
			passable_map[x].resize(map_height)
			for y in range(map_height):
				passable_map[x][y] = false

func _create_initial_pool():
	var eraser = $"../eraser"
	if eraser and eraser.has_method("erase_area"):
		# Стираем круг для воды
		eraser.erase_area(pool_position, 70)
		
		# Обновляем карту проходимости для этого круга
		_update_passable_area(pool_position, 90)

func _update_passable_area(global_pos: Vector2, radius: int):
	if not top_layer or not top_layer.texture:
		return
		
	var local_pos = top_layer.to_local(global_pos)
	var tex_size = top_layer.texture.get_size()
	
	var texture_x = local_pos.x + tex_size.x / 2
	var texture_y = local_pos.y + tex_size.y / 2
	
	var cell_x = int(texture_x / cell_size)
	var cell_y = int(texture_y / cell_size)
	var cell_radius = int(radius / cell_size) + 2
	
	for x in range(-cell_radius, cell_radius + 1):
		for y in range(-cell_radius, cell_radius + 1):
			var check_x = cell_x + x
			var check_y = cell_y + y
			
			if check_x >= 0 and check_x < map_width and check_y >= 0 and check_y < map_height:
				if x*x + y*y <= cell_radius*cell_radius:
					passable_map[check_x][check_y] = true

func _fill_pool_with_water():
	for i in range(350):
		var angle = randf() * 2 * PI
		var distance = randf() * pool_radius * 0.9
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var drop_pos = pool_position + offset
		
		var drop = _create_water_drop(drop_pos)
		drop.scale = Vector2(0.7 + randf() * 0.8, 0.7 + randf() * 0.8)
		
		water_drops.append({
			"node": drop,
			"in_pool": true,
			"last_pos": drop_pos  # Запоминаем последнюю позицию
		})

func _create_water_drop(pos: Vector2) -> RigidBody2D:
	var drop_scene = preload("res://water_drop.tscn")
	var drop = drop_scene.instantiate()
	drop.position = pos
	drop.gravity_scale = 0.0
	drop.freeze = true
	
	add_child(drop)
	return drop

func _check_erasing_under_water(global_pos: Vector2):
	if water_flow_active:
		return
		
	var pool_bottom = pool_position.y + pool_radius
	if global_pos.y > pool_bottom - 50 and abs(global_pos.x - pool_position.x) < pool_radius + 50:
		_activate_water_flow()

func _activate_water_flow():
	water_flow_active = true
	print("Вода начала течь!")
	
	await get_tree().create_timer(0.1).timeout
	
	for drop_data in water_drops:
		if drop_data.in_pool:
			var drop = drop_data.node
			if is_instance_valid(drop):
				drop_data.in_pool = false
				drop.freeze = false
				drop.gravity_scale = 0.8
				drop.linear_velocity = Vector2(randf_range(-5, 5), 30)  # Еще меньше горизонтальная скорость

func _physics_process(delta):
	if not water_flow_active:
		return
	
	var drops_to_remove = []
	
	for drop_data in water_drops:
		var drop = drop_data.node
		if not is_instance_valid(drop):
			drops_to_remove.append(drop_data)
			continue
		
		var current_pos = drop.global_position
		
		# Проверяем, находится ли капля в проходимой области 
		if not _is_position_passable(current_pos):
			# Если капля вышла за пределы стертой области - останавливаем
			drop.linear_velocity = Vector2.ZERO
			# Возвращаем на последнюю проходимую позицию
			if drop_data.has("last_good_pos"):
				drop.global_position = drop_data.last_good_pos
			continue
		else:
			# Запоминаем последнюю проходимую позицию
			drop_data["last_good_pos"] = current_pos
		
		# Проверяем, можно ли двигаться вниз
		var next_pos_down = current_pos + Vector2(0, 10)
		
		if _is_position_passable(next_pos_down):
			# Можно падать вниз
			drop.linear_velocity = Vector2(0, water_flow_speed)
		else:
			# Проверяем другие направления ТОЛЬКО если они проходимы
			var moved = false
			var directions = [
				{"pos": Vector2(8, 4), "vel": Vector2(water_flow_speed * 0.5, water_flow_speed * 0.5)},
				{"pos": Vector2(-8, 4), "vel": Vector2(-water_flow_speed * 0.5, water_flow_speed * 0.5)},
				{"pos": Vector2(10, 0), "vel": Vector2(water_flow_speed * 0.6, 0)},
				{"pos": Vector2(-10, 0), "vel": Vector2(-water_flow_speed * 0.6, 0)},
				{"pos": Vector2(0, -5), "vel": Vector2(0, -water_flow_speed * 0.3)}  # Вверх (для выхода из тупика)
			]
			
			for dir in directions:
				if _is_position_passable(current_pos + dir.pos):
					drop.linear_velocity = dir.vel
					moved = true
					break
			
			if not moved:
				# Если нет проходимого пути - останавливаемся
				drop.linear_velocity = Vector2.ZERO
		
		# Проверка выхода
		if water_exit and water_exit.overlaps_body(drop):
			drops_to_remove.append(drop_data)
	
	for drop_data in drops_to_remove:
		water_drops.erase(drop_data)
		if is_instance_valid(drop_data.node):
			drop_data.node.queue_free()
			print("Капля достигла цели!")

func _is_position_passable(pos: Vector2) -> bool:
	if not top_layer or not top_layer.texture:
		return false
		
	var local_pos = top_layer.to_local(pos)
	var tex_size = top_layer.texture.get_size()
	
	# Проверяем границы текстуры
	if abs(local_pos.x) > tex_size.x / 2 or abs(local_pos.y) > tex_size.y / 2:
		return false
	
	var texture_x = local_pos.x + tex_size.x / 2
	var texture_y = local_pos.y + tex_size.y / 2
	
	# Проверяем несколько точек вокруг для более точной проверки
	var points_to_check = [
		Vector2(0, 0),
		Vector2(3, 3), Vector2(-3, 3), Vector2(3, -3), Vector2(-3, -3),
		Vector2(0, 4), Vector2(4, 0), Vector2(-4, 0), Vector2(0, -4)
	]
	
	var passable_count = 0
	var total_checks = 0
	
	for offset in points_to_check:
		var check_x = texture_x + offset.x
		var check_y = texture_y + offset.y
		
		if check_x < 0 or check_x >= tex_size.x or check_y < 0 or check_y >= tex_size.y:
			continue
			
		total_checks += 1
		var cell_x = int(check_x / cell_size)
		var cell_y = int(check_y / cell_size)
		
		if cell_x >= 0 and cell_x < map_width and cell_y >= 0 and cell_y < map_height:
			if passable_map[cell_x][cell_y]:
				passable_count += 1
	
	# Если больше половины проверенных точек проходимы - считаем позицию проходимой
	if total_checks > 0:
		return float(passable_count) / total_checks > 0.5
	
	return false

func on_terrain_erased(global_pos: Vector2, radius: int):
	# Обновляем карту проходимости
	_update_passable_area(global_pos, radius)
	# Проверяем, стирается ли под водой
	_check_erasing_under_water(global_pos)
