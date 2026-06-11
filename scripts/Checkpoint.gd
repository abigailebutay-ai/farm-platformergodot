extends Area2D
class_name Checkpoint

signal activated(position: Vector2)

var active := false
var flag: ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		active = true
		flag.color = Color("#56d46f")
		activated.emit(global_position)

func _build() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 70)
	collision.shape = shape
	add_child(collision)

	var pole := ColorRect.new()
	pole.position = Vector2(-3, -45)
	pole.size = Vector2(6, 70)
	pole.color = Color("#7a4b2f")
	add_child(pole)

	flag = ColorRect.new()
	flag.position = Vector2(3, -42)
	flag.size = Vector2(34, 22)
	flag.color = Color("#d45b45")
	add_child(flag)

	var base := ColorRect.new()
	base.position = Vector2(-15, 22)
	base.size = Vector2(30, 8)
	base.color = Color("#6c4b33")
	add_child(base)
