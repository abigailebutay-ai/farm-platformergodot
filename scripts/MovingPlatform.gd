extends AnimatableBody2D
class_name MovingPlatform

@export var move_offset := Vector2(160, 0)
@export var travel_time := 2.0

var start_position := Vector2.ZERO
var direction := 1.0

func _ready() -> void:
	start_position = global_position
	sync_to_physics = true
	_build()

func _physics_process(delta: float) -> void:
	var target := start_position + move_offset * direction
	global_position = global_position.move_toward(target, move_offset.length() / travel_time * delta)
	if global_position.distance_to(target) < 2.0:
		direction *= -1.0

func _build() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(128, 22)
	collision.shape = shape
	add_child(collision)

	var visual := ColorRect.new()
	visual.position = Vector2(-64, -11)
	visual.size = Vector2(128, 22)
	visual.color = Color("#b67842")
	add_child(visual)

	var trim := ColorRect.new()
	trim.position = Vector2(-64, -11)
	trim.size = Vector2(128, 5)
	trim.color = Color("#d09a5f")
	add_child(trim)
