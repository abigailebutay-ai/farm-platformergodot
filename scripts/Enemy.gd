extends CharacterBody2D
class_name FarmEnemy

signal defeated(points: int)

@export var enemy_type := "slime"
@export var max_health := 2
@export var speed := 60.0
@export var contact_damage := 1
@export var points := 100

const GRAVITY := 980.0

var health := 2
var direction := -1.0
var start_position := Vector2.ZERO
var player: Player
var sprite: AnimatedSprite2D
var contact_area: Area2D
var health_bar: ColorRect
var damage_cooldown := 0.0
var hurt_time := 0.0
var dead := false

func _ready() -> void:
	start_position = global_position
	health = max_health
	add_to_group("enemies")
	_build_body()
	_update_health_bar()

func configure(kind: String, target: Player) -> void:
	enemy_type = kind
	player = target
	match enemy_type:
		"worm":
			max_health = 2
			speed = 45
			points = 90
		"crow":
			max_health = 2
			speed = 85
			points = 120
		"mushroom":
			max_health = 3
			speed = 55
			points = 150
		"boss":
			max_health = 12
			speed = 75
			contact_damage = 2
			points = 1000
		_:
			max_health = 2
			speed = 60
			points = 100
	health = max_health

func _physics_process(delta: float) -> void:
	if dead:
		return
	damage_cooldown = max(0.0, damage_cooldown - delta)
	hurt_time = max(0.0, hurt_time - delta)

	if enemy_type == "crow":
		_fly(delta)
	else:
		_walk(delta)

	if player and damage_cooldown <= 0.0:
		_damage_player_if_touching()

	_update_animation()

func take_damage(amount: int, knockback: Vector2) -> void:
	if dead:
		return
	health -= amount
	velocity = knockback
	hurt_time = 0.28
	_update_health_bar()
	modulate = Color("#ffb0b0")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.18)
	if health <= 0:
		_die()

func _walk(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var chase := player and enemy_type in ["mushroom", "boss"] and global_position.distance_to(player.global_position) < (280 if enemy_type == "boss" else 190)
	if chase:
		direction = sign(player.global_position.x - global_position.x)
	elif abs(global_position.x - start_position.x) > (220 if enemy_type == "boss" else 120):
		direction *= -1

	velocity.x = direction * speed
	move_and_slide()
	if is_on_wall():
		direction *= -1

func _fly(delta: float) -> void:
	var chase := player and global_position.distance_to(player.global_position) < 210
	if chase:
		direction = sign(player.global_position.x - global_position.x)
	elif abs(global_position.x - start_position.x) > 170:
		direction *= -1
	velocity.x = direction * speed
	velocity.y = sin(Time.get_ticks_msec() / 220.0) * 35
	move_and_slide()

func _die() -> void:
	dead = true
	defeated.emit(points)
	if sprite:
		sprite.play("death")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.tween_callback(queue_free)

func _update_animation() -> void:
	if not sprite:
		return
	sprite.flip_h = direction > 0
	if hurt_time > 0:
		sprite.play("hurt")
	elif enemy_type == "crow":
		sprite.play("fly")
	elif enemy_type == "boss":
		sprite.play("stomp")
	else:
		sprite.play("walk")

func _build_body() -> void:
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 16 if enemy_type != "boss" else 34
	shape.height = 36 if enemy_type != "boss" else 76
	collision.shape = shape
	add_child(collision)

	contact_area = Area2D.new()
	add_child(contact_area)
	var contact_shape := CollisionShape2D.new()
	var contact_rect := RectangleShape2D.new()
	contact_rect.size = Vector2(48, 42) if enemy_type != "boss" else Vector2(96, 92)
	contact_shape.shape = contact_rect
	contact_area.add_child(contact_shape)
	contact_area.body_entered.connect(_on_contact_body_entered)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _make_frames()
	sprite.scale = Vector2(0.62, 0.62) if enemy_type == "boss" else Vector2(0.52, 0.52)
	sprite.position.y = -18 if enemy_type == "boss" else -8
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_build_health_bar()
	_update_animation()

func _build_health_bar() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(-24, -46) if enemy_type != "boss" else Vector2(-48, -84)
	bg.size = Vector2(48, 6) if enemy_type != "boss" else Vector2(96, 8)
	bg.color = Color("#241a1a")
	add_child(bg)

	health_bar = ColorRect.new()
	health_bar.position = bg.position + Vector2(1, 1)
	health_bar.size = bg.size - Vector2(2, 2)
	health_bar.color = Color("#e84d4d") if enemy_type != "boss" else Color("#b84cff")
	add_child(health_bar)

func _update_health_bar() -> void:
	if not health_bar:
		return
	var max_width: float = 46.0 if enemy_type != "boss" else 94.0
	var ratio: float = clamp(float(max(0, health)) / float(max_health), 0.0, 1.0)
	health_bar.size.x = max_width * ratio

func _on_contact_body_entered(body: Node) -> void:
	if body is Player:
		_damage_player(body)

func _damage_player_if_touching() -> void:
	if not contact_area:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player:
			_damage_player(body)
			return

func _damage_player(target: Player) -> void:
	if dead or damage_cooldown > 0.0:
		return
	var knockback_dir := 1.0
	if target.global_position.x < global_position.x:
		knockback_dir = -1.0
	target.take_damage(contact_damage, Vector2(260 * knockback_dir, -260))
	damage_cooldown = 0.9

func _make_frames() -> SpriteFrames:
	var asset_frames := _make_asset_frames()
	if asset_frames:
		return asset_frames

	var frames := SpriteFrames.new()
	for anim in ["walk", "fly", "stomp", "hurt", "death"]:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 7.0)
		frames.set_animation_loop(anim, anim != "death")

	var base := Color("#78d45b")
	match enemy_type:
		"worm":
			base = Color("#d8875c")
		"crow":
			base = Color("#4e5a71")
		"mushroom":
			base = Color("#cc5e5e")
		"boss":
			base = Color("#8c4e9f")

	for i in range(2):
		var tex := _make_texture(base.lightened(i * 0.08), i)
		frames.add_frame("walk", tex)
		frames.add_frame("fly", tex)
		frames.add_frame("stomp", tex)
	frames.add_frame("hurt", _make_texture(Color("#ffffff"), 0))
	frames.add_frame("death", _make_texture(base.darkened(0.45), 0))
	return frames

func _make_asset_frames() -> SpriteFrames:
	var folder := _asset_folder()
	if folder == "" or not ResourceLoader.exists("res://assets/characters/%s/walk_0.png" % folder):
		return null

	var frames := SpriteFrames.new()
	_add_enemy_asset_animation(frames, "walk", folder, "walk", 4, 7.0, true)
	_add_enemy_asset_animation(frames, "fly", folder, "walk", 4, 8.0, true)
	_add_enemy_asset_animation(frames, "stomp", folder, "walk", 4, 7.0, true)
	_add_enemy_asset_animation(frames, "hurt", folder, "hurt", 2, 6.0, false)
	_add_enemy_asset_animation(frames, "death", folder, "death", 3, 5.0, false)
	return frames

func _asset_folder() -> String:
	match enemy_type:
		"worm":
			return "worm"
		"crow":
			return "crow"
		"boss":
			return "boss"
		_:
			return "beetle"

func _add_enemy_asset_animation(frames: SpriteFrames, animation: String, folder: String, prefix: String, count: int, speed: float, looping: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, looping)
	for i in range(count):
		var path := "res://assets/characters/%s/%s_%d.png" % [folder, prefix, i]
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			frames.add_frame(animation, texture)

func _make_texture(color: Color, phase: int) -> Texture2D:
	var w := 42 if enemy_type != "boss" else 54
	var h := 38 if enemy_type != "boss" else 60
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		for x in range(w):
			var nx := (x - w * 0.5) / (w * 0.5)
			var ny := (y - h * 0.55) / (h * 0.45)
			var body := nx * nx + ny * ny < 1.0
			if enemy_type == "crow":
				body = abs(ny) < 0.35 and abs(nx) < 0.75 or (phase == 0 and y < h * 0.5 and abs(nx) < 1.0) or (phase == 1 and y > h * 0.45 and abs(nx) < 1.0)
			elif enemy_type == "worm":
				body = abs(ny) < 0.45 and abs(nx) < 0.95
			if body:
				img.set_pixel(x, y, color)
			if body and y < h * 0.5 and x > w * 0.45 and x < w * 0.55:
				img.set_pixel(x, y, color.lightened(0.25))
	return ImageTexture.create_from_image(img)
