extends Area2D

signal collected

var is_collected := false


func _ready() -> void:
	add_to_group("coins")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or is_collected:
		return

	is_collected = true
	collected.emit()
	monitoring = false
	$colision.set_deferred("disabled", true)
	$anim.play("collect")


func _on_anim_animation_finished() -> void:
	if is_collected:
		queue_free()
