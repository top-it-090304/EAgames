extends Area2D

var water_drops = []  # Капли в этой луже
var max_drops = 50
var pool_radius = 70

func _ready():
	# Создаем визуальный эффект лужи
	_create_pool_visual()
	
	# Создаем коллизию для лужи
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = pool_radius
	collision.shape = circle
	add_child(collision)

func _create_pool_visual():
	# Создаем поверхность воды
	var pool_surface = Sprite2D.new()
	var pool_image = Image.create(pool_radius * 2, pool_radius * 2, false, Image.FORMAT_RGBA8)
	pool_image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(pool_radius, pool_radius)
	
	for x in range(pool_radius * 2):
		for y in range(pool_radius * 2):
			var dist = Vector2(x, y).distance_to(center)
			if dist < pool_radius:
				# Прозрачная вода с рябью
				var alpha = 0.2 * (1.0 - dist / pool_radius)
				var ripple = sin(x * 0.3) * sin(y * 0.3) * 0.1
				pool_image.set_pixel(x, y, Color(0.2, 0.4, 0.8, alpha + ripple))
	
	pool_surface.texture = ImageTexture.create_from_image(pool_image)
	pool_surface.position = Vector2(pool_radius, pool_radius)
	add_child(pool_surface)

func add_drop(drop):
	if water_drops.size() < max_drops:
		water_drops.append(drop)
		# Позиционируем каплю внутри лужи
		var angle = randf() * 2 * PI
		var distance = randf() * pool_radius * 0.7
		drop.position = Vector2(cos(angle), sin(angle)) * distance
		drop.is_active = false

func remove_drop(drop):
	water_drops.erase(drop)

func activate_drops():
	# Активируем капли постепенно (не все сразу)
	var drops_to_activate = min(5, water_drops.size())
	for i in range(drops_to_activate):
		if water_drops.size() > 0:
			var drop = water_drops[0]
			drop.activate()
			water_drops.remove_at(0)
