extends Control

const LIFE_COUNT: int = 5
const PIXEL_SIZE: float = 2.0
const HEART_ROWS: Array[String] = [
	"0110110",
	"1111111",
	"1111111",
	"0111110",
	"0011100",
	"0001000",
]
const HEART_COLORS: Array[Color] = [
	Color("#ff4b68"),
	Color("#625563"),
]

var current_lives: int = LIFE_COUNT


func set_lives(value: int) -> void:
	current_lives = clampi(value, 0, LIFE_COUNT)
	queue_redraw()


func _draw() -> void:
	var heart_width: float = HEART_ROWS[0].length() * PIXEL_SIZE
	for heart_index in range(LIFE_COUNT):
		var offset_x: float = heart_index * (heart_width + PIXEL_SIZE)
		var color: Color = HEART_COLORS[0] if heart_index < current_lives else HEART_COLORS[1]
		for row in range(HEART_ROWS.size()):
			for column in range(HEART_ROWS[row].length()):
				if HEART_ROWS[row][column] == "1":
					draw_rect(
						Rect2(
							Vector2(offset_x + column * PIXEL_SIZE, row * PIXEL_SIZE),
							Vector2(PIXEL_SIZE, PIXEL_SIZE)
						),
						color
					)
