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

var player: Player
var tile_map: TileMap
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
var spawn_point := Vector2(96, 480)
var checkpoint_position := Vector2(96, 480)
var elapsed_time := 0.0
var game_finished := false

func _ready() -> void:
	_ensure_input_actions()
	_build_background()
	_build_tilemap()
	_build_level()
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
	if player and not player.dead and player.global_position.y > 820:
		player.fall_out()
	if not game_finished:
		elapsed_time += delta
	_update_timer_ui()

func _build_background() -> void:
	var sky := ColorRect.new()
	sky.color = Color("#95d8ff")
	sky.size = Vector2(4096, 900)
	sky.position = Vector2(-256, -420)
	add_child(sky)
	for i in range(9):
		var cloud := ColorRect.new()
		cloud.color = Color(1, 1, 1, 0.65)
		cloud.position = Vector2(130 + i * 360, -260 + (i % 3) * 34)
		cloud.size = Vector2(110, 22)
		add_child(cloud)
	for i in range(7):
		var hill := Polygon2D.new()
		hill.color = Color("#79c66a")
		var x := -180 + i * 620
		hill.polygon = PackedVector2Array([Vector2(x, 462), Vector2(x + 310, 290 - (i % 2) * 30), Vector2(x + 680, 462)])
		add_child(hill)
	for i in range(9):
		_add_background_barn(Vector2(260 + i * 430, 408), i % 2 == 0)
	for i in range(20):
		var row := ColorRect.new()
		row.color = Color("#4f9a3f")
		row.position = Vector2(-150 + i * 190, 438)
		row.size = Vector2(100, 8)
		add_child(row)

func _add_background_barn(pos: Vector2, windmill: bool) -> void:
	var barn := ColorRect.new()
	barn.position = pos
	barn.size = Vector2(88, 54)
	barn.color = Color("#b84a3d")
	add_child(barn)
	var roof := Polygon2D.new()
	roof.color = Color("#7a362a")
	roof.polygon = PackedVector2Array([pos + Vector2(-8, 0), pos + Vector2(44, -34), pos + Vector2(96, 0)])
	add_child(roof)
	if windmill:
		var pole := ColorRect.new()
		pole.position = pos + Vector2(116, -34)
		pole.size = Vector2(8, 88)
		pole.color = Color("#8d6a45")
		add_child(pole)
		for blade in [Vector2(0, -22), Vector2(22, 0), Vector2(0, 22), Vector2(-22, 0)]:
			var arm := ColorRect.new()
			arm.position = pos + Vector2(120, 6)
			arm.size = Vector2(abs(blade.x) + 6, abs(blade.y) + 6)
			arm.color = Color("#f0dfb5")
			add_child(arm)

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
	# Clean route: warm-up, gap jumps, hazard climb, key path, enemy lane, boss arena.
	_add_ground(0, 18, 15)
	_add_ground(18, 18, 10)
	_add_ground(32, 18, 11)
	_add_ground(48, 18, 12)
	_add_ground(65, 18, 13)
	_add_ground(84, 18, 22)

	_add_platform(6, 15, 4, T_WOOD)
	_add_platform(16, 14, 4, T_WOOD)
	_add_platform(26, 13, 4, T_WOOD)
	_add_platform(37, 15, 5, T_WOOD)
	_add_platform(46, 12, 4, T_WOOD)
	_add_platform(55, 10, 4, T_WOOD)
	_add_platform(65, 13, 5, T_WOOD)
	_add_platform(75, 11, 4, T_WOOD)
	_add_platform(86, 14, 5, T_WOOD)

	_add_wall(43, 15, 3, T_FENCE)
	_add_wall(60, 15, 3, T_FENCE)
	_add_wall(83, 15, 3, T_FENCE)

	for x in [21, 22, 23, 52, 53, 54, 79, 80, 81]:
		_add_water_tile(x, 18)
	for x in [34, 35, 67, 68, 90, 91, 92]:
		_add_spike_tile(x, 17)
	for x in [30, 31, 61, 62, 88, 89]:
		tile_map.set_cell(0, Vector2i(x, 17), 0, T_MUD)

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
		var atlas_coords := tile_map.get_cell_atlas_coords(0, cell)
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
	player = Player.new()
	player.position = spawn_point
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	add_child(player)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.limit_left = -64
	camera.limit_top = -420
	camera.limit_right = 3500
	camera.limit_bottom = 820
	camera.zoom = Vector2(1.0, 1.0)
	player.add_child(camera)
	camera.make_current()

func _spawn_checkpoints() -> void:
	for pos in [Vector2(760, 520), Vector2(1640, 520), Vector2(2510, 320)]:
		var checkpoint := Checkpoint.new()
		checkpoint.position = pos
		checkpoint.activated.connect(_on_checkpoint_activated)
		add_child(checkpoint)

func _spawn_moving_platforms() -> void:
	_add_moving_platform(Vector2(1030, 445), Vector2(170, 0), 2.0)
	_add_moving_platform(Vector2(1770, 300), Vector2(0, 120), 2.4)
	_add_moving_platform(Vector2(2640, 405), Vector2(150, -70), 2.2)

func _add_moving_platform(pos: Vector2, offset: Vector2, travel: float) -> void:
	var platform := MovingPlatform.new()
	platform.position = pos
	platform.move_offset = offset
	platform.travel_time = travel
	add_child(platform)

func _spawn_shop() -> void:
	var shop := CropShop.new()
	shop.position = Vector2(1840, 520)
	shop.heal_requested.connect(_on_shop_heal_requested)
	add_child(shop)

func _spawn_collectibles() -> void:
	for pos in [Vector2(250, 430), Vector2(555, 395), Vector2(890, 360), Vector2(1235, 455), Vector2(1510, 300), Vector2(2110, 390), Vector2(2775, 455)]:
		_add_collectible("crop", pos, 25)
	for pos in [Vector2(420, 510), Vector2(760, 510), Vector2(1090, 510), Vector2(1710, 245), Vector2(2240, 510), Vector2(2420, 340), Vector2(2920, 510)]:
		_add_collectible("coin", pos, 10)
	_add_collectible("key", Vector2(2425, 305), 0)

func _add_collectible(kind: String, pos: Vector2, value: int) -> void:
	var item := Collectible.new()
	item.kind = kind
	item.value = value
	item.position = pos
	item.collected.connect(_on_collectible_collected)
	add_child(item)

func _spawn_enemies() -> void:
	_add_enemy("slime", Vector2(470, 520))
	_add_enemy("worm", Vector2(1180, 520))
	_add_enemy("crow", Vector2(1500, 285))
	_add_enemy("mushroom", Vector2(1980, 520))
	_add_enemy("crow", Vector2(2390, 320))
	_add_enemy("worm", Vector2(2860, 520))
	_add_enemy("boss", Vector2(3130, 500))

func _add_enemy(kind: String, pos: Vector2) -> void:
	var enemy := FarmEnemy.new()
	enemy.configure(kind, player)
	enemy.position = pos
	enemy.defeated.connect(_on_enemy_defeated.bind(kind))
	add_child(enemy)

func _spawn_gate() -> void:
	gate = Gate.new()
	gate.position = Vector2(3350, 510)
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
