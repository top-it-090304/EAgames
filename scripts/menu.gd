extends Control

@onready var main_panel: Panel = $MainPanel
@onready var level_select_panel: Panel = $LevelSelectPanel
@onready var levels_container: GridContainer = $LevelSelectPanel/Scroll/Levels
@onready var total_stars_label: Label = $LevelSelectPanel/TotalStarsLabel
@onready var development_popup: Control = $LevelSelectPanel/DevelopmentPopup  

var level_button_scene = preload("res://scenes/level_button.tscn")

# Максимальный реализованный уровень (0-индексация: 20 = уровень 21)
# Меняем это число, когда добавляем новые сцены уровней
const MAX_IMPLEMENTED_LEVEL: int = 24  # Уровни 0-22 (1-23) реализованы

func _ready() -> void:
	if LevelManager.level_changed.is_connected(_on_level_changed):
		LevelManager.level_changed.disconnect(_on_level_changed)
	LevelManager.level_changed.connect(_on_level_changed)
	
	if LevelManager.progress_reset.is_connected(_on_progress_reset):
		LevelManager.progress_reset.disconnect(_on_progress_reset)
	LevelManager.progress_reset.connect(_on_progress_reset)
	
	_setup_main_panel()
	_create_level_buttons()
	_update_total_stars()
	
	if LevelManager.return_to_level_select:
		LevelManager.return_to_level_select = false
		main_panel.visible = false
		level_select_panel.visible = true
		level_select_panel.modulate.a = 1.0
		level_select_panel.position.y = 0
	else:
		_show_main_panel()
	
	_setup_development_popup()
	
	# Настройка скролла только для телефона
	var scroll: ScrollContainer = $LevelSelectPanel/Scroll
	if scroll:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Убеждаемся, что сетка не блокирует свайпы
	if levels_container:
		levels_container.mouse_filter = Control.MOUSE_FILTER_PASS
		


func _setup_development_popup() -> void:
	if development_popup:
		development_popup.visible = false
		# Авто-подключение кнопки закрытия, если она есть внутри попапа
		if development_popup.has_node("CloseButton"):
			var close_btn: Button = development_popup.get_node("CloseButton")
			if not close_btn.pressed.is_connected(_on_close_popup):
				close_btn.pressed.connect(_on_close_popup)

func _on_close_popup() -> void:
	if development_popup:
		development_popup.visible = false

func _setup_main_panel() -> void:
	if has_node("MainPanel/Title"):
		var title = $MainPanel/Title
		title.modulate.a = 0.0
		title.position.y -= 30
		
		var tween = create_tween()
		tween.tween_property(title, "modulate:a", 1.0, 0.5)
		tween.parallel().tween_property(title, "position:y", title.position.y + 30, 0.5).set_ease(Tween.EASE_OUT)

func _create_level_buttons() -> void:
	for child in levels_container.get_children():
		child.queue_free()
	
	for i in LevelManager.levels.size():
		var btn = level_button_scene.instantiate()
		btn.level_num = i
		# Блокировка: если уровень не разблокирован ИЛИ ещё не реализован
		btn.is_locked = not LevelManager.is_level_unlocked(i) or i >= MAX_IMPLEMENTED_LEVEL
		btn.stars = LevelManager.get_stars(i)
		btn.level_selected.connect(_on_level_selected)
		levels_container.add_child(btn)

func _update_total_stars() -> void:
	if total_stars_label:
		total_stars_label.text = "Звёзды: %d / %d" % [LevelManager.get_total_stars(), LevelManager.levels.size()]

func _show_main_panel() -> void:
	# Скрываем панель уровней без анимации
	level_select_panel.visible = false
	level_select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_select_panel.modulate.a = 0.0
	
	# Показываем главную панель
	main_panel.visible = true
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main_panel.modulate.a = 1.0
	main_panel.position.y = 0
	
	# Анимация только для главной панели
	var tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.3).from(0.0) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_panel, "position:y", 0, 0.3).from(-30) \
		.set_ease(Tween.EASE_OUT)

func _show_level_select() -> void:
	#Сначала гарантированно скрываем главную панель БЕЗ анимации
	main_panel.visible = false
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.modulate.a = 0.0  # Сбрасываем прозрачность
	
	#Показываем панель уровней
	level_select_panel.visible = true
	level_select_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	level_select_panel.modulate.a = 1.0
	level_select_panel.position.y = 0
	
	#Анимация только для панели уровней (плавное появление)
	var tween = create_tween()
	tween.tween_property(level_select_panel, "modulate:a", 1.0, 0.3).from(0.0) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(level_select_panel, "position:y", 0, 0.3).from(20) \
		.set_ease(Tween.EASE_OUT)
		
func _on_play_button_pressed() -> void:
	SoundManager.play_button_click()
	main_panel.hide()
	level_select_panel.show()
	_show_level_select()

func _on_back_button_pressed() -> void:
	SoundManager.play_button_click()
	level_select_panel.hide()
	main_panel.show()
	_show_main_panel()

func _on_level_selected(level_num: int) -> void:
	# 1. Уровень ещё не создан → показываем попап
	if level_num >= MAX_IMPLEMENTED_LEVEL:
		PycoLog.log_event_by_type("dev_popup", {"requested_level": level_num + 1})
		_show_development_popup()
		return
	
	# 2. Уровень создан, но ещё не открыт → ничего не делаем (кнопка затемнена)
	if not LevelManager.is_level_unlocked(level_num):
		return  # Просто игнорируем клик
	
	# 3. Всё ок → запускаем (level_start логируется в game.gd _load_level)
	SoundManager.play_button_click()
	LevelManager.go_to_level(level_num)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _show_development_popup() -> void:
	SoundManager.play_button_click()
	if development_popup:
		development_popup.visible = true
		# Блокируем клики по меню, пока открыт попап
		level_select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_level_changed(_level_num: int) -> void:
	_create_level_buttons()
	_update_total_stars()

func _on_reset_button_pressed() -> void:
	SoundManager.play_button_click()
	PycoLog.log_event_by_type("progress_reset", {})
	LevelManager.reset_progress()

func _on_progress_reset() -> void:
	_create_level_buttons()
	_update_total_stars()

func _on_exit_button_pressed() -> void:
	SoundManager.play_button_click()
	await PycoLog.log_stop_playing()
	get_tree().quit()

func _on_button_pressed() -> void:
	SoundManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_tutorial_pressed() -> void:
	SoundManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


func _on_close_button_pressed() -> void:
	pass # Replace with function body.
