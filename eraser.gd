extends Node2D

@export var brush_size: int = 15

var sprite_node: Sprite2D
var ground_image: Image
var ground_texture: ImageTexture
var water_manager: Node

func _ready():
	await get_tree().process_frame
	_initialize()

func _initialize():
	if get_parent().has_node("top_layer"):
		sprite_node = get_parent().get_node("top_layer")
	else:
		print("ОШИБКА: Не найден top_layer!")
		return
	
	if get_parent().has_node("water_manager"):
		water_manager = get_parent().get_node("water_manager")
	
	if sprite_node.texture == null:
		print("ОШИБКА: У top_layer нет текстуры!")
		return
	
	var original_texture = sprite_node.texture
	ground_image = original_texture.get_image()
	ground_image.convert(Image.FORMAT_RGBA8)
	
	ground_texture = ImageTexture.create_from_image(ground_image)
	sprite_node.texture = ground_texture
	
	print("=== СТИРАНИЕ ЗАПУЩЕНО ===")

func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		erase_at_position(mouse_pos)

func erase_at_position(global_pos: Vector2):
	if ground_image == null or sprite_node == null:
		return
	
	var local_pos = sprite_node.to_local(global_pos)
	var tex_size = ground_image.get_size()
	
	var texture_x = local_pos.x + tex_size.x / 2
	var texture_y = local_pos.y + tex_size.y / 2
	
	if texture_x < 0 or texture_x >= tex_size.x or texture_y < 0 or texture_y >= tex_size.y:
		return
	
	var center = Vector2i(texture_x, texture_y)
	var radius = brush_size
	var changed = false
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				var draw_pos = center + Vector2i(x, y)
				
				if draw_pos.x >= 0 and draw_pos.x < tex_size.x and draw_pos.y >= 0 and draw_pos.y < tex_size.y:
					ground_image.set_pixel(draw_pos.x, draw_pos.y, Color(0, 0, 0, 0))
					changed = true
	
	if changed:
		ground_texture.update(ground_image)
		if water_manager and water_manager.has_method("on_terrain_erased"):
			water_manager.on_terrain_erased(global_pos, radius)

func erase_area(center_global: Vector2, radius: int):
	if ground_image == null or sprite_node == null:
		return
	
	var local_pos = sprite_node.to_local(center_global)
	var tex_size = ground_image.get_size()
	
	var texture_x = local_pos.x + tex_size.x / 2
	var texture_y = local_pos.y + tex_size.y / 2
	
	var center = Vector2i(texture_x, texture_y)
	var changed = false
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				var draw_pos = center + Vector2i(x, y)
				
				if draw_pos.x >= 0 and draw_pos.x < tex_size.x and draw_pos.y >= 0 and draw_pos.y < tex_size.y:
					ground_image.set_pixel(draw_pos.x, draw_pos.y, Color(0, 0, 0, 0))
					changed = true
	
	if changed:
		ground_texture.update(ground_image)
		if water_manager and water_manager.has_method("on_terrain_erased"):
			water_manager.on_terrain_erased(center_global, radius)
