extends Area2D
class_name Collectible

signal collected(kind: String, value: int)

@export var kind := "crop"
@export var value := 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_add_visual()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		collected.emit(kind, value)
		queue_free()

func _add_visual() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	add_child(collision)

	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 5.0)
	frames.set_animation_loop("idle", true)

	var colors := {
		"crop": [Color("#ffd34d"), Color("#f28f35")],
		"coin": [Color("#fff27a"), Color("#f7bd25")],
		"key": [Color("#ffe96e"), Color("#fb8c3a")]
	}
	for color in colors.get(kind, colors["crop"]):
		frames.add_frame("idle", _make_texture(color))
	sprite.sprite_frames = frames
	sprite.play("idle")
	add_child(sprite)

func _make_texture(color: Color) -> Texture2D:
	var img := Image.create(34, 34, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == "coin":
		_draw_coin(img, color)
	elif kind == "key":
		_draw_key(img, color)
	else:
		_draw_crop(img, color)
	return ImageTexture.create_from_image(img)

func _draw_coin(img: Image, color: Color) -> void:
	for y in range(34):
		for x in range(34):
			var p := Vector2(x - 17, y - 17)
			if p.length() < 12:
				img.set_pixel(x, y, Color("#b26b16"))
			if p.length() < 10:
				img.set_pixel(x, y, color)
			if p.length() < 7:
				img.set_pixel(x, y, color.lightened(0.2))
	_draw_line(img, Vector2i(17, 9), Vector2i(17, 25), Color("#9a5b10"))
	_draw_line(img, Vector2i(13, 13), Vector2i(21, 13), Color("#9a5b10"))
	_draw_line(img, Vector2i(13, 21), Vector2i(21, 21), Color("#9a5b10"))

func _draw_key(img: Image, color: Color) -> void:
	for y in range(34):
		for x in range(34):
			var p := Vector2(x - 11, y - 16)
			if p.length() < 8:
				img.set_pixel(x, y, Color("#9a5b10"))
			if p.length() < 6:
				img.set_pixel(x, y, color)
			if p.length() < 3:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_fill_rect(img, Rect2i(17, 14, 14, 5), color)
	_fill_rect(img, Rect2i(25, 19, 3, 6), color.darkened(0.1))
	_fill_rect(img, Rect2i(30, 19, 3, 4), color.darkened(0.2))

func _draw_crop(img: Image, color: Color) -> void:
	_draw_line(img, Vector2i(16, 8), Vector2i(10, 2), Color("#2f8f3b"))
	_draw_line(img, Vector2i(17, 8), Vector2i(17, 1), Color("#65c957"))
	_draw_line(img, Vector2i(18, 8), Vector2i(24, 2), Color("#2f8f3b"))
	for y in range(8, 31):
		for x in range(7, 27):
			var width: float = 10.0 - float(y - 8) * 0.34
			if abs(float(x - 17)) < width:
				img.set_pixel(x, y, Color("#8a4a12"))
			if abs(float(x - 17)) < width - 1.5:
				img.set_pixel(x, y, color)
	_draw_line(img, Vector2i(12, 15), Vector2i(22, 14), Color("#ffb05a"))
	_draw_line(img, Vector2i(13, 22), Vector2i(20, 21), Color("#ffb05a"))

func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, color)

func _draw_line(img: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var points: int = maxi(abs(end.x - start.x), abs(end.y - start.y))
	for i in range(points + 1):
		var t: float = float(i) / maxf(1.0, float(points))
		var pos := Vector2i(roundi(lerpf(float(start.x), float(end.x), t)), roundi(lerpf(float(start.y), float(end.y), t)))
		if pos.x >= 0 and pos.y >= 0 and pos.x < img.get_width() and pos.y < img.get_height():
			img.set_pixel(pos.x, pos.y, color)
