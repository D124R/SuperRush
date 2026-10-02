extends Control

const LIFE_COUNT: int = 5
const HEART_TEXTURE: Texture2D = preload("res://assets/Mini FX, Items & UI/Mini FX, Items & UI/Common Pick-ups/Heart_Spin (16 x 16).png")
const HEART_SIZE := Vector2(12.0, 12.0)
const HEART_GAP := 3.0

var current_lives: int = LIFE_COUNT


func set_lives(value: int) -> void:
	current_lives = clampi(value, 0, LIFE_COUNT)
	queue_redraw()


func _draw() -> void:
	for heart_index in range(LIFE_COUNT):
		var offset_x: float = heart_index * (HEART_SIZE.x + HEART_GAP)
		var tint := Color.WHITE if heart_index < current_lives else Color(0.24, 0.27, 0.32, 0.85)
		draw_texture_rect_region(
			HEART_TEXTURE,
			Rect2(Vector2(offset_x, 0), HEART_SIZE),
			Rect2(Vector2.ZERO, HEART_SIZE),
			tint
		)
