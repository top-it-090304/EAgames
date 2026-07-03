class_name Level extends Node2D

signal level_complete(success: bool, time: float, moves: int)
signal update_timer(seconds: int)
signal update_moves(count: int)

@export var grid_size: Vector2i = Vector2i(6, 8)
@export var cell_size: int = 100

@export var max_hints: int = 2 # Счётчик подсказок
var hints_remaining: int = 2
signal hints_updated(remaining: int)

@onready var grid_container: Node2D = $GridContainer

var pipes: Dictionary = {}
var start_pipe: Pipe = null
var end_pipes: Array[Pipe] = []

var elapsed_time: float = 0.0
var move_count: int = 0
var is_playing: bool = false
var is_completed: bool = false

func _ready() -> void:
	_scan_pipes()
	await reset_level()

func _process(delta: float) -> void:
	if is_playing and not is_completed:
		elapsed_time += delta
		if int(elapsed_time) != int(elapsed_time - delta):
			update_timer.emit(int(elapsed_time))

func _scan_pipes() -> void:
	pipes.clear()
	start_pipe = null
	end_pipes.clear()
	
	if grid_container == null:
		push_error("GridContainer не найден!")
		return
	
	for child in grid_container.get_children():
		if child is Pipe:
			var pipe: Pipe = child
			var pos = pipe.grid_position
			pipes[pos] = pipe
			
			if not pipe.pipe_rotated.is_connected(_on_pipe_rotated):
				pipe.pipe_rotated.connect(_on_pipe_rotated)
			
			# ✅ Новая логика сбора труб
			if pipe.is_start:
				start_pipe = pipe
			if pipe.is_end or pipe.is_mandatory:
				end_pipes.append(pipe)

func reset_level() -> void:
	# Сброс подсказок при новом старте
	hints_remaining = max_hints
	hints_updated.emit(hints_remaining)
	
	_unlock_all_pipes()
	
	var attempts = 0
	var max_attempts = 50
	
	while attempts < max_attempts:
		_randomize_pipes()
		if not await _check_connections(true):
			break
		attempts += 1
	
	if attempts >= max_attempts:
		push_warning("⚠️ Не удалось сгенерировать нерешённый уровень. Принудительный поворот.")
		_force_break_solution()
	
	for pipe in pipes.values():
		pipe.reset_fill()
	
	elapsed_time = 0.0
	move_count = 0
	is_completed = false
	is_playing = true
	update_moves.emit(0)
	
	await _check_connections(false)

func _lock_all_pipes() -> void:
	for pipe in pipes.values():
		if pipe.touch_area: pipe.touch_area.input_pickable = false

func _unlock_all_pipes() -> void:
	for pipe in pipes.values():
		if pipe.touch_area: pipe.touch_area.input_pickable = true

func _randomize_pipes() -> void:
	for pipe in pipes.values():
		# Не трогаем стартовые, конечные, обязательные и заблокированные
		if not pipe.is_locked and not pipe.is_start and not pipe.is_end and not pipe.is_mandatory:
			pipe.rotation_state = randi() % 4
			pipe.rotation_degrees = pipe.rotation_state * 90
			pipe._update_visuals()

func _force_break_solution() -> void:
	for pipe in pipes.values():
		if not pipe.is_locked and not pipe.is_start and not pipe.is_end and not pipe.is_mandatory:
			pipe.rotate_pipe()
			return

func _on_pipe_rotated(_pipe: Pipe) -> void:
	if is_completed: return
	move_count += 1
	update_moves.emit(move_count)
	await _check_connections(false)

func _check_connections(dry_run: bool = false) -> bool:
	if start_pipe == null or end_pipes.size() == 0:
		return false
	
	if not dry_run:
		for pipe in pipes.values(): pipe.reset_fill()
	
	var visited: Dictionary = {}
	var queue: Array = [start_pipe]
	visited[start_pipe.grid_position] = true
	if not dry_run: start_pipe.fill_with_water()
	
	var reached_end_count: int = 0
	var targets_reached: Dictionary = {}
	
	while queue.size() > 0:
		var current: Pipe = queue.pop_front()
		
		if current in end_pipes and not targets_reached.has(current):
			targets_reached[current] = true
			reached_end_count += 1
		
		for side in current.get_active_sides():
			var neighbor_pos = _get_neighbor_pos(current.grid_position, side)
			if not pipes.has(neighbor_pos) or visited.has(neighbor_pos): continue
			
			var neighbor: Pipe = pipes[neighbor_pos]
			var opposite = Pipe.get_opposite_side(side)
			
			if current.has_connection_to(side) and neighbor.has_connection_to(opposite):
				visited[neighbor_pos] = true
				if not dry_run: neighbor.fill_with_water()
				queue.append(neighbor)
	
	var all_pipes_closed: bool = _check_all_pipes_closed()
	var all_ends_reached: bool = (reached_end_count == end_pipes.size())
	var is_solved: bool = all_ends_reached and all_pipes_closed
	
	if not dry_run and is_solved and not is_completed:
		is_completed = true
		is_playing = false
		_lock_all_pipes()
		await get_tree().create_timer(1.0).timeout
		level_complete.emit(true, elapsed_time, move_count)
	
	return is_solved

func _check_all_pipes_closed() -> bool:
	var side_names = ["TOP", "RIGHT", "BOTTOM", "LEFT"]
	for pipe in pipes.values():
		for side in pipe.get_active_sides():
			var neighbor_pos = _get_neighbor_pos(pipe.grid_position, side)
			if not pipes.has(neighbor_pos):
				print("❌ Открытый конец у трубы на %s в сторону %s" % [pipe.grid_position, side_names[side]])
				return false
			
			var neighbor: Pipe = pipes[neighbor_pos]
			var opposite = Pipe.get_opposite_side(side)
			if not neighbor.has_connection_to(opposite):
				print("❌ Разрыв между %s и %s" % [pipe.grid_position, neighbor.grid_position])
				return false
	return true

func _get_neighbor_pos(pos: Vector2i, side: int) -> Vector2i:
	match side:
		Pipe.Side.TOP: return pos + Vector2i(0, -1)
		Pipe.Side.RIGHT: return pos + Vector2i(1, 0)
		Pipe.Side.BOTTOM: return pos + Vector2i(0, 1)
		Pipe.Side.LEFT: return pos + Vector2i(-1, 0)
	return pos

func get_cell_size() -> int: return cell_size

func show_hint() -> void:
	# Если подсказки кончились — ничего не делаем
	if hints_remaining <= 0:
		return
	hints_remaining -= 1
	hints_updated.emit(hints_remaining)  # Сообщаем игре, что подсказка использована
	PycoLog.log_event_by_type("hint_used", {"level": LevelManager.current_level + 1, "hints_remaining": hints_remaining})
	# Находим трубы с разорванными соединениями
	var problem_pipes: Array[Pipe] = []
	
	for pipe in pipes.values():
		var has_problem = false
		for side in pipe.get_active_sides():
			var neighbor_pos = _get_neighbor_pos(pipe.grid_position, side)
			
			# Нет соседа = разрыв
			if not pipes.has(neighbor_pos):
				has_problem = true
				break
			
			# Сосед есть, но не соединён = разрыв
			var neighbor: Pipe = pipes[neighbor_pos]
			var opposite = Pipe.get_opposite_side(side)
			if not neighbor.has_connection_to(opposite):
				has_problem = true
				break
		
		# Добавляем трубу в список проблемных (без дубликатов)
		if has_problem and pipe not in problem_pipes:
			problem_pipes.append(pipe)
	
	# Подсвечиваем, если есть проблемы
	if problem_pipes.size() > 0:
		_highlight_pipes(problem_pipes)

func _highlight_pipes(pipes_to_highlight: Array[Pipe]) -> void:
	# Сохраняем оригинальные цвета для восстановления
	var original_colors: Dictionary = {}
	
	for pipe in pipes_to_highlight:
		if not pipe.is_inside_tree(): continue
		if pipe.sprite:
			# Сохраняем текущие цвета
			original_colors[pipe] = {
				"sprite": pipe.sprite.modulate,
				"water": pipe.water_sprite.modulate if pipe.water_sprite else Color.WHITE,
				"water_visible": pipe.water_sprite.visible if pipe.water_sprite else false
			}
			#  Подсвечиваем ЯРКО-ЖЁЛТЫМ, независимо от воды
			pipe.sprite.modulate = Color(1.5, 1.5, 0.3)
			if pipe.water_sprite:
				pipe.water_sprite.modulate = Color(1.5, 1.5, 0.3)
				pipe.water_sprite.visible = true
	
	# Ждём 1 секунду
	await get_tree().create_timer(1.0).timeout
	
	# Возвращаем как было (только если трубы ещё в сцене)
	for pipe in pipes_to_highlight:
		if not pipe.is_inside_tree(): continue
		if pipe.sprite and original_colors.has(pipe):
			var orig = original_colors[pipe]
			pipe.sprite.modulate = orig["sprite"]
			if pipe.water_sprite:
				pipe.water_sprite.modulate = orig["water"]
				pipe.water_sprite.visible = orig["water_visible"]
