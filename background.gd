extends ParallaxBackground

var speed = 25

func _process(delta: float) -> void:
	scroll_offset.y += speed * delta
