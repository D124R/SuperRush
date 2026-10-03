extends Area2D

@export_enum("Escalar paredes", "Poder de fogo", "Super pulo") var power_type: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var symbol: Label = $Symbol

var collected_once := false
var start_y := 0.0


func _ready() -> void:
	add_to_group("special_hearts")
	start_y = position.y
	match power_type:
		0:
			sprite.modulate = Color("#70f4ff")
			symbol.text = "^"
		1:
			sprite.modulate = Color("#ffae55")
			symbol.text = "F"
		2:
			sprite.modulate = Color("#ff78c8")
			symbol.text = "J"


func _process(_delta: float) -> void:
	sprite.frame = int(Time.get_ticks_msec() / 150) % 4
	position.y = start_y + sin(Time.get_ticks_msec() / 240.0) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if collected_once or not body.is_in_group("player"):
		return
	if not body.has_method("grant_special_power"):
		return

	collected_once = true
	body.call("grant_special_power", power_type)
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()
