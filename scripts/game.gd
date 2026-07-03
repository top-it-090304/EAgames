extends Node

@onready var ui: CanvasLayer = $UI
@onready var level_label: Label = $UI/TopBar/LevelLabel
@onready var timer_label: Label = $UI/TopBar/TimerLabel
@onready var moves_label: Label = $UI/TopBar/MovesLabel
@onready var complete_panel: ColorRect = $UI/CompletePanel
@onready var complete_time: Label = $UI/CompletePanel/TimeLabel
@onready var complete_moves: Label = $UI/CompletePanel/MovesLabel
@onready var stars_container: HBoxContainer = $UI/CompletePanel/Stars
@onready var pause_panel: ColorRect = $UI/PausePanel
@onready var pause_button: Button = $UI/TopBar/PauseButton
@onready var hint_button: Button = $UI/TopBar/HintButton
@onready var hint_label: Label = $UI/TopBar/HintButton/Label

var current_level_instance: Node2D = null
var is_paused: bool = false

# Максимальный реализованный уровень (должен совпадать с menu.gd!)
const MAX_IMPLEMENTED_LEVEL: int = 24

func _ready() -> void:
	complete_panel.visible = false
	pause_panel.visible = false
	
	if LevelManager.level_changed.is_connected(_on_level_changed):
		LevelManager.level_changed.disconnect(_on_level_changed)
	LevelManager.level_changed.connect(_on_level_changed)
	
	_connect_safe(pause_button, _on_pause_button_pressed)
	_connect_safe($UI/PausePanel/Buttons/ResumeButton, _on_resume_button_pressed)
	_connect_safe($UI/PausePanel/Buttons/RestartButton, _on_restart_button_pressed)
	_connect_safe($UI/PausePanel/Buttons/MenuButton, _on_menu_button_pressed)
	_connect_safe($UI/CompletePanel/Buttons/NextButton, _on_next_button_pressed)
	_load_level(LevelManager.current_level)
	


func _connect_safe(btn: Button, callback: Callable) -> void:
	if btn and not btn.pressed.is_connected(callback):
		btn.pressed.connect(callback)

func _load_level(level_num: int) -> void:
	# level_start логируем здесь — единый чокпойнт загрузки уровня (и из меню,
	# и авто-переход на следующий). Раньше был только в menu.gd → авто-переходы
	# не считались (level_start < level_complete).
	PycoLog.log_event_by_type("level_start", {"level": level_num + 1})
	MusicManager.start_music()
	if current_level_instance:
		current_level_instance.queue_free()
	
	var level_path = LevelManager.get_current_level_path()
	var level_scene = load(level_path)
	
	if level_scene == null:
		push_error("❌ Не удалось загрузить уровень: " + level_path)
		return
	
	current_level_instance = level_scene.instantiate()
	current_level_instance.name = "Level"
	
	if has_node("LevelContainer"):
		$LevelContainer.add_child(current_level_instance)
	else:
		add_child(current_level_instance)
		move_child(current_level_instance, 0)
	
	# Подключение к сигналу подсказок
	if current_level_instance and current_level_instance.has_signal("hints_updated"):
		if current_level_instance.hints_updated.is_connected(_on_hints_updated):
			current_level_instance.hints_updated.disconnect(_on_hints_updated)
		current_level_instance.hints_updated.connect(_on_hints_updated)
	
	if current_level_instance.has_signal("level_complete"):
		if current_level_instance.level_complete.is_connected(_on_level_complete):
			current_level_instance.level_complete.disconnect(_on_level_complete)
		current_level_instance.level_complete.connect(_on_level_complete)
	
	if current_level_instance.has_signal("update_timer"):
		if current_level_instance.update_timer.is_connected(_on_update_timer):
			current_level_instance.update_timer.disconnect(_on_update_timer)
		current_level_instance.update_timer.connect(_on_update_timer)
	
	if current_level_instance.has_signal("update_moves"):
		if current_level_instance.update_moves.is_connected(_on_update_moves):
			current_level_instance.update_moves.disconnect(_on_update_moves)
		current_level_instance.update_moves.connect(_on_update_moves)
	
	level_label.text = "УРОВЕНЬ %d" % (level_num + 1)
	complete_panel.visible = false
	_set_pause(false)
	# Инициализация текста подсказок
	if current_level_instance:
		_on_hints_updated(current_level_instance.hints_remaining)

func _on_hints_updated(remaining: int) -> void:
	# Обновляем текст на кнопке
	if hint_label:
		hint_label.text = "%d/%d" % [remaining, current_level_instance.max_hints]
	
	# Блокируем кнопку, если подсказки кончились
	if hint_button:
		hint_button.disabled = (remaining <= 0)
		hint_button.modulate = Color(1, 1, 1, 1.0 if remaining > 0 else 0.5)

func _set_pause(paused: bool) -> void:
	is_paused = paused
	get_tree().paused = paused
	pause_panel.visible = paused
	pause_button.disabled = paused

func _on_pause_button_pressed() -> void:
	SoundManager.play_button_click()
	if current_level_instance and current_level_instance.get("is_completed"):
		return
	_set_pause(true)

func _on_resume_button_pressed() -> void:
	SoundManager.play_button_click()
	_set_pause(false)

func _on_restart_button_pressed() -> void:
	SoundManager.play_button_click()
	if current_level_instance and current_level_instance.has_method("reset_level"):
		PycoLog.log_event_by_type("level_restart", {
			"level": LevelManager.current_level + 1,
			"moves": current_level_instance.move_count,
			"time": current_level_instance.elapsed_time
		})
		current_level_instance.reset_level()
	complete_panel.visible = false
	_set_pause(false)

func _on_menu_button_pressed() -> void:
	SoundManager.play_button_click()
	_set_pause(false)
	# Бросил уровень не пройдя — точка отвала
	if current_level_instance and not current_level_instance.is_completed:
		PycoLog.log_event_by_type("level_quit", {
			"level": LevelManager.current_level + 1,
			"moves": current_level_instance.move_count,
			"time": current_level_instance.elapsed_time
		})
	LevelManager.return_to_level_select = true
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_level_complete(success: bool, time: float, moves: int) -> void:
	if success:
		MusicManager.fade_out_music(0.5)  # 👈 ДОБАВЬ
		SoundManager.play_level_complete()
		# Сохраняем прогресс сразу
		LevelManager.save_level_progress(time, moves)

		var hints_used := 0
		if current_level_instance:
			hints_used = current_level_instance.max_hints - current_level_instance.hints_remaining
		PycoLog.log_event_by_type("level_complete", {
			"level": LevelManager.current_level + 1,
			"time": time,
			"moves": moves,
			"hints_used": hints_used
		})

		complete_panel.visible = true
		complete_time.text = "ВРЕМЯ: %.1f сек" % time
		complete_moves.text = "ХОДЫ: %d" % moves
		
		# Очищаем старые звёзды
		for child in stars_container.get_children():
			child.queue_free()
		
		# Создаём одну звезду
		var star = Sprite2D.new()
		star.texture = preload("res://assets/sprites/star_yellow.png")
		star.scale = Vector2(0, 0)  
		stars_container.add_child(star)
		
		var tween = create_tween()
		tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.4) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)

func _on_update_timer(seconds: int) -> void:
	var minutes = seconds / 60  
	var secs = seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, secs]

func _on_update_moves(count: int) -> void:
	moves_label.text = "ХОДЫ: %d" % count
	
func _on_hint_button_pressed() -> void:
	SoundManager.play_button_click()
	if current_level_instance and current_level_instance.has_method("show_hint"):
		current_level_instance.show_hint()
	
func _on_next_button_pressed() -> void:
	SoundManager.play_button_click()
	var next_level = LevelManager.current_level + 1
	
	#Если следующего уровня ещё нет — показываем попап ЧЕРЕЗ МЕНЮ
	if next_level >= MAX_IMPLEMENTED_LEVEL:
		# Сохраняем флаг, что нужно показать попап после возврата в меню
		LevelManager.return_to_level_select = true
		# Передаём номер "несуществующего" уровня, чтобы меню знало, что показать попап
		LevelManager.pending_popup_level = next_level  # ← добавь эту переменную в LevelManager!
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	LevelManager.advance_level()

func _on_level_changed(_level_num: int) -> void:
	_load_level(_level_num)
