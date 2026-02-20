extends Node2D

# Переменные для анимации фона
@onready var background = $Background
@onready var title_label = $MenuContainer/TitleLabel
@onready var start_button = $MenuContainer/StartButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var quit_button = $MenuContainer/QuitButton

var time_passed = 0.0

func _process(delta):
	# Простая анимация для фона (мерцание звёзд/ламп)
	time_passed += delta
	
	# Если есть спрайт с материалом, можно менять яркость
	if background and background.material:
		var intensity = 0.8 + 0.2 * sin(time_passed * 2.0)
		background.material.set_shader_parameter("intensity", intensity)
		print("Интенсивность: ", intensity)

func _on_start_button_pressed() -> void:
	# Проверяем, что дерево существует
	if not get_tree():
		print("Ошибка: дерево сцены не доступно")
		return
	
	# ИСПРАВЛЕНО: добавляем await перед вызовом анимации
	await animate_button_press(start_button)
	
	# Переходим
	get_tree().change_scene_to_file("res://lvl_1.tscn")

func _on_options_button_pressed() -> void:
	# ИСПРАВЛЕНО: добавляем await
	await animate_button_press(options_button)
	print("Настройки пока не реализованы")
	# pass можно убрать

func _on_quit_button_pressed() -> void:
	# ИСПРАВЛЕНО: добавляем await
	await animate_button_press(quit_button)
	get_tree().quit()

# Анимация нажатия кнопки (БЕЗ ИЗМЕНЕНИЙ)
func animate_button_press(button: Button):
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.9, 0.05)
	tween.tween_property(button, "scale", original_scale, 0.1)
	
	# ИСПРАВЛЕНО: ждём завершения анимации
	await tween.finished
