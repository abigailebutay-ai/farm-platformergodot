extends Area2D
class_name Hazard

@export var damage := 1
@export var launch := Vector2(0, -320)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(size: Vector2, color: Color) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)

	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.25, -size.y * 0.5),
		Vector2(0, size.y * 0.5),
		Vector2(size.x * 0.25, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5)
	])
	add_child(poly)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage, launch)
