extends Area2D

const SPEED := 420.0
const LIFETIME := 1.4

var direction := 1.0
var time_left := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_direction(value: float) -> void:
	direction = signf(value)
	scale.x = direction


func _physics_process(delta: float) -> void:
	global_position.x += direction * SPEED * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var flame := PackedVector2Array([
		Vector2(-9, -4), Vector2(-5, -7), Vector2(-2, -5),
		Vector2(1, -9), Vector2(7, -4), Vector2(9, 0),
		Vector2(5, 6), Vector2(0, 7), Vector2(-6, 4),
	])
	var core := PackedVector2Array([
		Vector2(-5, -2), Vector2(-1, -4), Vector2(3, -3),
		Vector2(5, 0), Vector2(2, 3), Vector2(-3, 3),
	])
	draw_colored_polygon(flame, Color("#f04b35"))
	draw_colored_polygon(core, Color("#ffe36e"))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var enemy_animation := body.get_node_or_null("anim") as AnimationPlayer
		if enemy_animation != null:
			enemy_animation.play("hurt")
	queue_free()
