extends Node2D

const TILE := 32
const T_GRASS := Vector2i(0, 0)
const T_DIRT := Vector2i(1, 0)
const T_WOOD := Vector2i(2, 0)
const T_FENCE := Vector2i(3, 0)
const T_MUD := Vector2i(4, 0)
const T_SPIKE := Vector2i(5, 0)
const T_WATER := Vector2i(6, 0)
const T_FLOWER := Vector2i(7, 0)

const PLAYER_SCENE := preload("res://scenes/characters/Player.tscn")
const BEETLE_SCENE := preload("res://scenes/enemies/Beetle.tscn")
const WORM_SCENE := preload("res://scenes/enemies/Worm.tscn")
const CROW_SCENE := preload("res://scenes/enemies/Crow.tscn")
const MUSHROOM_SCENE := preload("res://scenes/enemies/MushroomBeetle.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/PestKing.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/objects/Checkpoint.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/objects/MovingPlatform.tscn")
const SHOP_SCENE := preload("res://scenes/objects/CropShop.tscn")
const GATE_SCENE := preload("res://scenes/objects/Gate.tscn")

var player: Player
var tile_map: Node
var score := 0
var crops := 0
var coins := 0
var has_key := false
var boss_defeated := false
var gate: Gate
var ui_score: Label
var ui_hearts: Label
var ui_key: Label
var ui_timer: Label
var player_health_bar: ColorRect
var message: Label
var spawn_point := Vector2(96, 350)
var checkpoint_position := Vector2(96, 350)
var elapsed_time := 0.0
var game_finished := false

func _ready() -> void:
	_ensure_input_actions()
	_spawn_player()
	_spawn_checkpoints()
	_spawn_moving_platforms()
	_spawn_shop()
	_spawn_collectibles()
	_spawn_enemies()
	_spawn_gate()
	_build_ui()

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_add_key_action("attack", [KEY_J])
	_add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	_add_key_action("restart", [KEY_R])

func _add_key_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var already_added := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.keycode == key:
				already_added = true
		if not already_added:
			var event := InputEventKey.new()
			event.keycode = key
			InputMap.action_add_event(action, event)

func _add_mouse_action(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventMouseButton and existing.button_index == button:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if player and not player.dead and player.global_position.y > 900:
		player.fall_out()
	if not game_finished:
		elapsed_time += delta
	_update_timer_ui()

func _build_background() -> void:
	var texture: Texture2D = load("res://assets/backgrounds/farm_background.png")
	var background := Node2D.new()
	background.z_index = -100
	add_child(background)
	var target_size := Vector2(1280, 720)
	var image_size := texture.get_size()
	for i in range(4):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(640 + i * 1280, 360)
		sprite.scale = Vector2(target_size.x / image_size.x, target_size.y / image_size.y)
		background.add_child(sprite)

func _build_tilemap() -> void:
	tile_map = TileMap.new()
	tile_map.tile_set = _make_tileset()
	add_child(tile_map)

func _make_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture_region_size = Vector2i(TILE, TILE)
	source.texture = _make_tile_atlas()
	var id := tileset.add_source(source)
	for x in range(8):
		source.create_tile(Vector2i(x, 0))
	return tileset

func _make_tile_atlas() -> Texture2D:
	var img := Image.create(TILE * 8, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint_tile(img, 0, Color("#58b957"), Color("#3f8f3e"))
	_paint_tile(img, 1, Color("#96613b"), Color("#6f4329"))
	_paint_tile(img, 2, Color("#b67842"), Color("#7a4b2f"))
	_paint_tile(img, 3, Color("#875b35"), Color("#5d3c24"))
	_paint_tile(img, 4, Color("#6f5941"), Color("#4b3b2b"))
	_paint_tile(img, 5, Color("#dfe8ef"), Color("#9da8b1"))
	_paint_tile(img, 6, Color("#4db5db"), Color("#2475a4"))
	_paint_tile(img, 7, Color("#f7d85b"), Color("#5abf63"))
	return ImageTexture.create_from_image(img)

func _paint_tile(img: Image, tile_x: int, top: Color, bottom: Color) -> void:
	var ox := tile_x * TILE
	for y in range(TILE):
		for x in range(TILE):
			var t := float(y) / float(TILE - 1)
			img.set_pixel(ox + x, y, top.lerp(bottom, t))
	if tile_x == 0:
		for x in range(TILE):
			img.set_pixel(ox + x, 0, Color("#b5df55"))
			img.set_pixel(ox + x, 1, Color("#77bd35"))
		for x in range(3, TILE, 7):
			img.set_pixel(ox + x, 3, Color("#d5ec77"))
	if tile_x == 1:
		for p in [Vector2i(5, 8), Vector2i(18, 5), Vector2i(27, 14), Vector2i(10, 24), Vector2i(23, 27)]:
			img.set_pixel(ox + p.x, p.y, Color("#c28a55"))
			if p.x + 1 < TILE:
				img.set_pixel(ox + p.x + 1, p.y, Color("#5e3826"))
	if tile_x == 2:
		for y in [7, 15, 23]:
			for x in range(TILE):
				img.set_pixel(ox + x, y, Color("#6d432b"))
		for x in [4, 18, 29]:
			img.set_pixel(ox + x, 5, Color("#e1ad6d"))
	if tile_x == 3:
		for x in [7, 23]:
			for y in range(TILE):
				img.set_pixel(ox + x, y, Color("#d6a05d"))
		for x in range(TILE):
			img.set_pixel(ox + x, 10, Color("#d6a05d"))
	if tile_x == 5:
		img.fill_rect(Rect2i(ox, 0, TILE, TILE), Color(0, 0, 0, 0))
		for i in range(4):
			var cx := ox + i * 8 + 4
			for y in range(TILE):
				for x in range(cx - y / 3, cx + y / 3 + 1):
					if x >= ox and x < ox + TILE:
						img.set_pixel(x, TILE - y - 1, Color("#dfe8ef").lerp(Color("#87919a"), float(y) / TILE))

func _build_level() -> void:
	# TileMap version of the reference: layered cliffs, bridge gaps, tunnels, and boss yard.
	_add_ground(0, 13, 16)
	_add_ground(0, 18, 14)
	_add_ground(0, 24, 27)
	_add_ground(31, 16, 30)
	_add_ground(36, 10, 13)
	_add_ground(39, 22, 26)
	_add_ground(65, 19, 14)
	_add_ground(76, 16, 34)
	_add_ground(78, 24, 32)

	_add_platform(17, 15, 4, T_WOOD)
	_add_platform(23, 18, 5, T_WOOD)
	_add_platform(29, 13, 4, T_WOOD)
	_add_platform(54, 20, 5, T_WOOD)
	_add_platform(66, 15, 6, T_WOOD)
	_add_platform(84, 21, 5, T_WOOD)

	_add_wall(8, 17, 4, T_FENCE)
	_add_wall(43, 15, 6, T_FENCE)
	_add_wall(64, 21, 4, T_FENCE)
	_add_wall(82, 23, 5, T_FENCE)
	_add_wall(100, 23, 6, T_FENCE)

	for x in [7, 8, 9]:
		_add_spike_tile(x, 23)
	for x in [69, 70, 71]:
		_add_spike_tile(x, 18)
	for x in [91, 92, 93, 94]:
		_add_spike_tile(x, 15)
	for x in [26, 27, 28]:
		_add_water_tile(x, 24)
	for x in [61, 62, 63]:
		_add_water_tile(x, 22)
	for x in [50, 51, 73, 74, 104, 105]:
		tile_map.set_cell(0, Vector2i(x, 21), 0, T_MUD)

	_add_tile_collisions()

func _add_platform(tile_x: int, tile_y: int, length: int, tile: Vector2i) -> void:
	for x in range(tile_x, tile_x + length):
		tile_map.set_cell(0, Vector2i(x, tile_y), 0, tile)

func _add_ground(tile_x: int, tile_y: int, length: int) -> void:
	for x in range(tile_x, tile_x + length):
		tile_map.set_cell(0, Vector2i(x, tile_y), 0, T_GRASS)
		tile_map.set_cell(0, Vector2i(x, tile_y + 1), 0, T_DIRT)
		tile_map.set_cell(0, Vector2i(x, tile_y + 2), 0, T_DIRT)

func _add_wall(tile_x: int, bottom_y: int, height: int, tile: Vector2i) -> void:
	for y in range(bottom_y - height + 1, bottom_y + 1):
		tile_map.set_cell(0, Vector2i(tile_x, y), 0, tile)

func _add_water_tile(tile_x: int, tile_y: int) -> void:
	tile_map.set_cell(0, Vector2i(tile_x, tile_y), 0, T_WATER)
	_add_hazard(Vector2(tile_x * TILE + 16, tile_y * TILE + 18), Vector2(32, 24), Color("#4db5db"), 1)

func _add_spike_tile(tile_x: int, tile_y: int) -> void:
	tile_map.set_cell(0, Vector2i(tile_x, tile_y), 0, T_SPIKE)
	_add_hazard(Vector2(tile_x * TILE + 16, tile_y * TILE + 16), Vector2(30, 26), Color("#dfe8ef"), 1)

func _add_tile_collisions() -> void:
	var solid_tiles := [T_GRASS, T_DIRT, T_WOOD, T_FENCE, T_MUD]
	for cell in tile_map.get_used_cells(0):
		var atlas_coords: Vector2i = tile_map.get_cell_atlas_coords(0, cell)
		if atlas_coords in solid_tiles:
			_add_solid_tile(cell)

func _add_solid_tile(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_hazard(pos: Vector2, size: Vector2, color: Color, damage: int) -> void:
	var hazard := Hazard.new()
	hazard.position = pos
	hazard.damage = damage
	hazard.setup(size, color)
	add_child(hazard)

func _spawn_player() -> void:
	player = get_node_or_null("player") as Player
	if not player:
		player = PLAYER_SCENE.instantiate()
		player.name = "player"
		player.position = spawn_point
		add_child(player)
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.limit_left = -64
	camera.limit_top = -420
	camera.limit_right = 3600
	camera.limit_bottom = 900
	camera.zoom = Vector2(1.0, 1.0)
	player.add_child(camera)
	camera.make_current()

func _spawn_checkpoints() -> void:
	for pos in [Vector2(720, 710), Vector2(1660, 640), Vector2(2540, 450)]:
		var checkpoint: Checkpoint = CHECKPOINT_SCENE.instantiate()
		checkpoint.position = pos
		checkpoint.activated.connect(_on_checkpoint_activated)
		add_child(checkpoint)

func _spawn_moving_platforms() -> void:
	_add_moving_platform(Vector2(565, 490), Vector2(200, 0), 2.0)
	_add_moving_platform(Vector2(930, 430), Vector2(0, 135), 2.4)
	_add_moving_platform(Vector2(2110, 500), Vector2(180, -70), 2.2)

func _add_moving_platform(pos: Vector2, offset: Vector2, travel: float) -> void:
	var platform: MovingPlatform = MOVING_PLATFORM_SCENE.instantiate()
	platform.position = pos
	platform.move_offset = offset
	platform.travel_time = travel
	add_child(platform)

func _spawn_shop() -> void:
	var shop: CropShop = SHOP_SCENE.instantiate()
	shop.position = Vector2(1710, 465)
	shop.heal_requested.connect(_on_shop_heal_requested)
	add_child(shop)

func _spawn_collectibles() -> void:
	for pos in [Vector2(250, 350), Vector2(530, 650), Vector2(940, 380), Vector2(1260, 275), Vector2(1730, 430), Vector2(2300, 515), Vector2(2860, 420)]:
		_add_collectible("crop", pos, 25)
	for pos in [Vector2(410, 510), Vector2(790, 680), Vector2(1090, 455), Vector2(1450, 260), Vector2(2040, 580), Vector2(2480, 430), Vector2(3150, 430)]:
		_add_collectible("coin", pos, 10)
	_add_collectible("key", Vector2(1440, 245), 0)

func _add_collectible(kind: String, pos: Vector2, value: int) -> void:
	var item := Collectible.new()
	item.kind = kind
	item.value = value
	item.position = pos
	item.collected.connect(_on_collectible_collected)
	add_child(item)

func _spawn_enemies() -> void:
	_add_enemy("slime", Vector2(380, 520))
	_add_enemy("worm", Vector2(1040, 700))
	_add_enemy("crow", Vector2(1240, 270))
	_add_enemy("mushroom", Vector2(1810, 650))
	_add_enemy("crow", Vector2(2230, 500))
	_add_enemy("worm", Vector2(2760, 450))
	_add_enemy("boss", Vector2(3060, 420))

func _add_enemy(kind: String, pos: Vector2) -> void:
	var packed_scene: PackedScene = BEETLE_SCENE
	match kind:
		"worm":
			packed_scene = WORM_SCENE
		"crow":
			packed_scene = CROW_SCENE
		"mushroom":
			packed_scene = MUSHROOM_SCENE
		"boss":
			packed_scene = BOSS_SCENE
	var enemy: FarmEnemy = packed_scene.instantiate()
	enemy.configure(kind, player)
	enemy.position = pos
	enemy.defeated.connect(_on_enemy_defeated.bind(kind))
	add_child(enemy)

func _spawn_gate() -> void:
	gate = GATE_SCENE.instantiate()
	gate.position = Vector2(3370, 420)
	gate.reached_gate.connect(_on_gate_reached)
	add_child(gate)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.08, 0.05, 0.55)
	panel.position = Vector2(12, 12)
	panel.size = Vector2(360, 112)
	layer.add_child(panel)
	ui_hearts = _ui_label(Vector2(24, 20), 20)
	ui_score = _ui_label(Vector2(24, 50), 17)
	ui_key = _ui_label(Vector2(24, 78), 17)
	ui_timer = _ui_label(Vector2(260, 20), 17)
	layer.add_child(ui_hearts)
	layer.add_child(ui_score)
	layer.add_child(ui_key)
	layer.add_child(ui_timer)
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(106, 25)
	bar_bg.size = Vector2(130, 12)
	bar_bg.color = Color("#2a1d1d")
	layer.add_child(bar_bg)
	player_health_bar = ColorRect.new()
	player_health_bar.position = bar_bg.position + Vector2(2, 2)
	player_health_bar.size = Vector2(126, 8)
	player_health_bar.color = Color("#e84d4d")
	layer.add_child(player_health_bar)
	message = _ui_label(Vector2(0, 250), 44)
	message.size = Vector2(1280, 120)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.visible = false
	layer.add_child(message)
	_update_ui()

func _ui_label(pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = Vector2(420, 34)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _on_player_health_changed(current: int, maximum: int) -> void:
	if ui_hearts:
		ui_hearts.text = "HP: %d/%d" % [max(0, current), maximum]
	if player_health_bar:
		var ratio: float = clamp(float(max(0, current)) / float(maximum), 0.0, 1.0)
		player_health_bar.size.x = 126.0 * ratio

func _on_player_died() -> void:
	if not player:
		return
	_show_message("CHECKPOINT!\nRespawning...")
	await get_tree().create_timer(0.9).timeout
	message.visible = false
	player.respawn_at(checkpoint_position)

func _on_collectible_collected(kind: String, value: int) -> void:
	if kind == "key":
		has_key = true
	else:
		score += value
		if kind == "crop":
			crops += 1
		else:
			coins += 1
	_update_ui()
	_check_gate()

func _on_enemy_defeated(points_value: int, kind: String) -> void:
	score += points_value
	if kind == "boss":
		boss_defeated = true
		_show_message("BOSS DEFEATED!\nThe barn gate is open.")
		await get_tree().create_timer(1.6).timeout
		message.visible = false
	_update_ui()
	_check_gate()

func _check_gate() -> void:
	gate.set_unlocked(has_key and boss_defeated)
	if ui_key:
		ui_key.text = "Crops: %d   Coins: %d   Key: %s" % [crops, coins, "YES" if has_key else "NO"]

func _on_gate_reached() -> void:
	game_finished = true
	_show_message("LEVEL COMPLETE!\nHarvest saved. Score: %d  Time: %s" % [score, _format_time(elapsed_time)])
	player.dead = true

func _update_ui() -> void:
	ui_score.text = "Score: %d" % score
	if ui_key:
		ui_key.text = "Crops: %d   Coins: %d   Key: %s" % [crops, coins, "YES" if has_key else "NO"]
	if player:
		_on_player_health_changed(player.health, player.max_health)

func _show_message(text: String) -> void:
	message.text = text
	message.visible = true

func _on_checkpoint_activated(pos: Vector2) -> void:
	checkpoint_position = pos + Vector2(0, -36)
	_show_message("CHECKPOINT SAVED")
	await get_tree().create_timer(0.9).timeout
	if not game_finished:
		message.visible = false

func _on_shop_heal_requested(cost: int) -> void:
	if not player or player.health >= player.max_health:
		return
	if coins >= cost:
		coins -= cost
		player.heal(2)
		_update_ui()
		_show_message("BOUGHT HEAL")
		await get_tree().create_timer(0.8).timeout
		message.visible = false
	else:
		_show_message("NEED %d COINS" % cost)
		await get_tree().create_timer(0.8).timeout
		message.visible = false

func _update_timer_ui() -> void:
	if ui_timer:
		ui_timer.text = "Time: " + _format_time(elapsed_time)

func _format_time(time_value: float) -> String:
	var total: int = int(time_value)
	var minutes: int = floori(float(total) / 60.0)
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]
