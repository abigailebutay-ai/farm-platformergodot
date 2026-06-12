extends TileMapLayer

const TILE := 32
const T_GRASS := Vector2i(0, 0)
const T_DIRT := Vector2i(1, 0)
const T_WOOD := Vector2i(2, 0)
const T_FENCE := Vector2i(3, 0)
const T_MUD := Vector2i(4, 0)
const T_SPIKE := Vector2i(5, 0)
const T_WATER := Vector2i(6, 0)

func _ready() -> void:
	_build_runtime_physics()

func _build_runtime_physics() -> void:
	for cell in get_used_cells():
		var atlas_coords := get_cell_atlas_coords(cell)
		if atlas_coords in [T_GRASS, T_DIRT, T_WOOD, T_FENCE, T_MUD]:
			_add_solid_tile(cell)
		elif atlas_coords == T_SPIKE:
			_add_hazard(Vector2(cell.x * TILE + 16, cell.y * TILE + 16), Vector2(30, 26), Color("#dfe8ef"), 1)
		elif atlas_coords == T_WATER:
			_add_hazard(Vector2(cell.x * TILE + 16, cell.y * TILE + 18), Vector2(32, 24), Color("#4db5db"), 1)

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

