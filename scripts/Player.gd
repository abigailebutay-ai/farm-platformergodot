extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal died

const SPEED := 190.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1150.0

@export var max_health := 5
@export var max_jumps := 2

var health := 5
var facing := 1
var jumps_left := 2
var attacking := false
var hurt_timer := 0.0
var invincible_timer := 0.0
var dead := false

var sprite: AnimatedSprite2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var attack_flash: ColorRect

func _ready() -> void:
	health = max_health
	jumps_left = max_jumps
	_build_body()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if dead:
		return

	hurt_timer = max(0.0, hurt_timer - delta)
	invincible_timer = max(0.0, invincible_timer - delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jumps_left = max_jumps

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	if direction != 0:
		facing = sign(direction)
		sprite.flip_h = facing < 0
		_update_attack_area()

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	if Input.is_action_just_pressed("attack"):
		_attack()

	move_and_slide()
	if is_on_floor() and velocity.y >= 0.0:
		jumps_left = max_jumps
	_update_animation(direction)

func take_damage(amount: int, knockback: Vector2) -> void:
	if dead or invincible_timer > 0.0:
		return
	health -= amount
	velocity = knockback
	hurt_timer = 0.35
	invincible_timer = 0.85
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()

func heal_full() -> void:
	health = max_health
	dead = false
	modulate.a = 1.0
	health_changed.emit(health, max_health)

func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)

func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	dead = false
	attacking = false
	invincible_timer = 1.0
	jumps_left = max_jumps
	heal_full()
	sprite.play("idle")

func fall_out() -> void:
	if dead:
		return
	health = 0
	health_changed.emit(health, max_health)
	_die()

func _attack() -> void:
	if attacking or dead:
		return
	attacking = true
	sprite.play("attack")
	_update_attack_area()
	attack_shape.disabled = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	for area in attack_area.get_overlapping_areas():
		var enemy := area.get_parent()
		if enemy and enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(2, Vector2(320 * facing, -180))
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(2, Vector2(320 * facing, -180))
	await get_tree().create_timer(0.18).timeout
	attack_shape.disabled = true
	await get_tree().create_timer(0.1).timeout
	attacking = false

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	died.emit()

func _update_animation(direction: float) -> void:
	if dead:
		return
	modulate.a = 0.55 if invincible_timer > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	if attacking:
		return
	if hurt_timer > 0:
		sprite.play("hurt")
	elif not is_on_floor() and velocity.y < 0:
		sprite.play("jump")
	elif not is_on_floor():
		sprite.play("fall")
	elif direction != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

func _build_body() -> void:
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 13
	shape.height = 42
	collision.shape = shape
	add_child(collision)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _make_frames()
	sprite.position = Vector2(0, -28)
	sprite.scale = Vector2(0.42, 0.42)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.play("idle")

	attack_area = Area2D.new()
	add_child(attack_area)
	attack_shape = CollisionShape2D.new()
	var attack_rect := RectangleShape2D.new()
	attack_rect.size = Vector2(108, 64)
	attack_shape.shape = attack_rect
	attack_shape.disabled = true
	attack_area.add_child(attack_shape)

	attack_flash = ColorRect.new()
	attack_flash.color = Color(1.0, 0.15, 0.05, 0.25)
	attack_flash.size = Vector2(108, 64)
	attack_flash.position = Vector2(-54, -32)
	attack_flash.visible = false
	attack_area.add_child(attack_flash)
	_update_attack_area()

func _update_attack_area() -> void:
	if not attack_area:
		return
	attack_area.position = Vector2(58 * facing, -10)

func _make_frames() -> SpriteFrames:
	var asset_frames := _make_asset_frames()
	if asset_frames:
		return asset_frames

	var frames := SpriteFrames.new()
	var anims := {
		"idle": 4,
		"run": 8,
		"jump": 1,
		"fall": 1,
		"attack": 8,
		"hurt": 4,
		"death": 4
	}
	for anim in anims:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, anims[anim])
		frames.set_animation_loop(anim, anim not in ["attack", "death"])

	for i in range(2):
		frames.add_frame("idle", _make_texture(Color("#f2b46d"), i, "idle"))
		frames.add_frame("run", _make_texture(Color("#f2b46d"), i, "run"))
		frames.add_frame("attack", _make_texture(Color("#f2b46d"), i, "attack"))
	for anim in ["jump", "fall", "hurt", "death"]:
		frames.add_frame(anim, _make_texture(Color("#ffffff") if anim == "hurt" else Color("#f2b46d"), 0, anim))
	return frames

func _make_asset_frames() -> SpriteFrames:
	if not ResourceLoader.exists("res://assets/characters/player/idle_0.png"):
		return null

	var frames := SpriteFrames.new()
	_add_asset_animation(frames, "idle", "idle", 3, 5.0, true)
	_add_asset_animation(frames, "run", "run", 6, 10.0, true)
	_add_asset_animation(frames, "jump", "jump", 3, 8.0, false)
	_add_asset_animation(frames, "fall", "fall", 3, 8.0, false)
	_add_asset_animation(frames, "attack", "attack", 5, 12.0, false)
	_add_asset_animation(frames, "hurt", "fall", 1, 6.0, false)
	_add_asset_animation(frames, "death", "idle", 1, 4.0, false)
	return frames

func _add_asset_animation(frames: SpriteFrames, animation: String, prefix: String, count: int, speed: float, looping: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, looping)
	for i in range(count):
		var path := "res://assets/characters/player/%s_%d.png" % [prefix, i]
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			frames.add_frame(animation, texture)

func _make_texture(skin: Color, phase: int, anim: String) -> Texture2D:
	var img := Image.create(32, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var wobble := phase if anim in ["idle", "run", "attack"] else 0
	var step := 2 if phase == 1 and anim == "run" else 0
	var ink := Color("#24201f")
	var shirt := Color("#3f82cf")
	var shirt_shadow := Color("#24578f")
	var straw := Color("#d9ad45")
	var hat_green := Color("#6fb24b")
	var pants := Color("#5d4532")

	# Rough black outline first, then colored pixel chunks inside it.
	_fill_rect(img, Rect2i(11, 1 + wobble, 10, 6), ink)
	_fill_rect(img, Rect2i(7, 6 + wobble, 18, 5), ink)
	_fill_rect(img, Rect2i(10, 9 + wobble, 11, 10), ink)
	_fill_rect(img, Rect2i(8, 18, 16, 15), ink)
	_fill_rect(img, Rect2i(6, 19, 5, 12), ink)
	_fill_rect(img, Rect2i(22, 19, 5, 12), ink)
	_fill_rect(img, Rect2i(8 - step, 30, 6, 6), ink)
	_fill_rect(img, Rect2i(18 + step, 30, 6, 6), ink)

	_fill_rect(img, Rect2i(12, 2 + wobble, 8, 4), hat_green)
	_fill_rect(img, Rect2i(8, 7 + wobble, 16, 3), straw)
	_fill_rect(img, Rect2i(11, 10 + wobble, 9, 8), skin)
	_fill_rect(img, Rect2i(9, 19, 14, 12), shirt)
	_fill_rect(img, Rect2i(17, 20, 5, 10), shirt_shadow)
	_fill_rect(img, Rect2i(7, 20, 3, 10), skin)
	_fill_rect(img, Rect2i(23, 20, 3, 10), skin)
	_fill_rect(img, Rect2i(9 - step, 31, 4, 5), pants)
	_fill_rect(img, Rect2i(19 + step, 31, 4, 5), pants)

	# Sketchy pixel-art marks, like a quick Pixilart draft with visible hand-drawn texture.
	_set_pixel_safe(img, Vector2i(13, 12 + wobble), ink)
	_set_pixel_safe(img, Vector2i(18, 12 + wobble), ink)
	_draw_line_pixels(img, Vector2i(12, 17 + wobble), Vector2i(18, 17 + wobble), Color("#a85f44"))
	_draw_line_pixels(img, Vector2i(10, 22), Vector2i(21, 26), Color("#8fb9e8"))
	_draw_line_pixels(img, Vector2i(11, 27), Vector2i(19, 23), Color("#1f4778"))
	_set_pixel_safe(img, Vector2i(7, 8 + wobble), Color("#fff0a8"))
	_set_pixel_safe(img, Vector2i(23, 8 + wobble), Color("#9f742d"))

	if anim == "attack":
		_draw_line_pixels(img, Vector2i(22, 21 + phase * 2), Vector2i(31, 8 + phase), ink)
		_draw_line_pixels(img, Vector2i(23, 21 + phase * 2), Vector2i(31, 9 + phase), Color("#dfe9f2"))
		_draw_line_pixels(img, Vector2i(24, 21 + phase * 2), Vector2i(31, 10 + phase), Color("#8fa8bd"))
		_fill_rect(img, Rect2i(21, 20 + phase * 2, 4, 3), Color("#8f5d35"))
		_set_pixel_safe(img, Vector2i(30, 8 + phase), Color("#ffffff"))
	if anim == "hurt":
		_draw_line_pixels(img, Vector2i(10, 11), Vector2i(20, 18), Color("#e35a5a"))
	if anim == "death":
		_draw_line_pixels(img, Vector2i(7, 29), Vector2i(25, 34), Color("#24201f"))
	return ImageTexture.create_from_image(img)

func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, color)

func _set_pixel_safe(img: Image, pos: Vector2i, color: Color) -> void:
	if pos.x >= 0 and pos.y >= 0 and pos.x < img.get_width() and pos.y < img.get_height():
		img.set_pixel(pos.x, pos.y, color)

func _draw_line_pixels(img: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var points: int = maxi(abs(end.x - start.x), abs(end.y - start.y))
	for i in range(points + 1):
		var t: float = float(i) / maxf(1.0, float(points))
		var pos: Vector2i = Vector2i(
			roundi(lerpf(float(start.x), float(end.x), t)),
			roundi(lerpf(float(start.y), float(end.y), t))
		)
		_set_pixel_safe(img, pos, color)
