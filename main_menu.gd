extends Node2D

# Переменные для анимации фона
@onready var background = $Background
@onready var start_button = $MenuContainer/StartButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var quit_button = $MenuContainer/QuitButton

var time_passed = 0.0

#func _process(delta):


func _on_start_button_pressed() -> void:
	if not get_tree():
		print("Ошибка: дерево сцены не доступно")
		return
	
	await animate_button_press(start_button)
	
	get_tree().change_scene_to_file("res://lvl_1.tscn")

func _on_options_button_pressed() -> void:
	# ИСПРАВЛЕНО: добавляем await
	await animate_button_press(options_button)
	print("Настройки пока не реализованы")

func _on_quit_button_pressed() -> void:
	await animate_button_press(quit_button)
	get_tree().quit()

func animate_button_press(button: Button):
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.9, 0.05)
	tween.tween_property(button, "scale", original_scale, 0.1)
	
	await tween.finished
