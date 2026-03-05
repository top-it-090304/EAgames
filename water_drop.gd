extends RigidBody2D

func _ready():
	# Создаем текстуру капли
	var drop_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	drop_image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(8, 8)
	
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist < 7:
				var alpha = 1.0 - dist / 8.0
				# ИСПРАВЛЕНО: чистый синий цвет
				drop_image.set_pixel(x, y, Color(0.0, 0.6, 1.0, alpha))
	
	var sprite = $Sprite 
	if sprite:
		sprite.texture = ImageTexture.create_from_image(drop_image)
	
	# Настройки физики
	freeze = true
	gravity_scale = 0.0

func is_water_drop():
	return true
