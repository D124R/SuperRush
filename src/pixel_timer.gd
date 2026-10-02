extends Label

var display_text: String = "00:00.00"


func _ready() -> void:
	text = display_text


func set_time(value: String) -> void:
	if display_text == value:
		return
	display_text = value
	text = value
