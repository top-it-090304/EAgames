extends Area2D

func _ready():
	# Простая анимация - меняем размер
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($ColorRect, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property($ColorRect, "scale", Vector2(1.0, 1.0), 0.5)

func _on_area_entered(area):
	if area.name == "Water":
		print("СВОМПИ СЧАСТЛИВ!")
		$ColorRect.color = Color(0, 1, 0)  # Ярко-зеленый
