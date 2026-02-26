extends Node2D

@onready var top_layer = $top_layer # Слой, который мы стираем
@onready var viewport = $SubViewportContainer/SubViewport

func _ready():
	# Ждем один кадр, чтобы Viewport успел создаться
	await get_tree().process_frame 
	
	if top_layer.material:
		var tex = viewport.get_texture()
		# Передаем текстуру маски в шейдер
		top_layer.material.set_shader_parameter("mask_texture", tex)
	else:
		print("ОШИБКА: Забудь накинуть ShaderMaterial на спрайт top_layer!")
