extends Area2D
class_name Gate

signal reached_gate

var unlocked := false
var label: Label
var door: ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build()
	set_unlocked(false)

func set_unlocked(value: bool) -> void:
	unlocked = value
	if door:
		door.color = Color("#69c36d") if unlocked else Color("#81522d")
	if label:
		label.text = "OPEN" if unlocked else "LOCKED"

func _on_body_entered(body: Node) -> void:
	if unlocked and body is Player:
		reached_gate.emit()

func _build() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(70, 96)
	collision.shape = shape
	add_child(collision)

	door = ColorRect.new()
	door.position = Vector2(-35, -48)
	door.size = Vector2(70, 96)
	add_child(door)

	var roof := Polygon2D.new()
	roof.color = Color("#b64136")
	roof.polygon = PackedVector2Array([Vector2(-46, -48), Vector2(0, -82), Vector2(46, -48)])
	add_child(roof)

	label = Label.new()
	label.position = Vector2(-31, -6)
	label.size = Vector2(62, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
