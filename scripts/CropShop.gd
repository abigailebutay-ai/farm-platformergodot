extends Area2D
class_name CropShop

signal heal_requested(cost: int)

@export var heal_cost := 3

var label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		heal_requested.emit(heal_cost)

func _build() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(92, 80)
	collision.shape = shape
	add_child(collision)

	var stall := ColorRect.new()
	stall.position = Vector2(-46, -20)
	stall.size = Vector2(92, 58)
	stall.color = Color("#7b4a2e")
	add_child(stall)

	var awning := ColorRect.new()
	awning.position = Vector2(-50, -48)
	awning.size = Vector2(100, 28)
	awning.color = Color("#e76f51")
	add_child(awning)

	label = Label.new()
	label.position = Vector2(-62, -78)
	label.size = Vector2(124, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "SHOP: 3 coins = heal"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
