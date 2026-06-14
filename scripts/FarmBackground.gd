extends Node2D

func _ready() -> void:
	var texture: Texture2D = load("res://assets/backgrounds/farm_background.png")
	var image_size := texture.get_size()
	var background_scale := 720.0 / image_size.y
	var displayed_width := image_size.x * background_scale
	for i in range(3):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(displayed_width * 0.5 + i * displayed_width, 360)
		sprite.scale = Vector2.ONE * background_scale
		add_child(sprite)
