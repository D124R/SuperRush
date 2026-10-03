extends CharacterBody2D

signal run_started
signal lives_changed(value: int)
signal damaged
signal game_over
signal special_powers_changed(wall_climb_seconds: int, fire_seconds: int)

const SPEED := 230.0
const JUMP_FORCE := -420.0
const DASH_SPEED := 520.0
const DASH_DURATION := 0.14
const MAX_LIVES := 5
const INVULNERABILITY_DURATION := 1.2
const SPECIAL_POWER_DURATION := 15.0
const WALL_CLIMB_SPEED := 150.0
const FIREBALL_COOLDOWN := 0.45
const FIREBALL_SCENE: PackedScene = preload("res://preafbs/fireball.tscn")

@onready var animation: AnimatedSprite2D = $anim

var is_jumping := false
var facing_direction := 1.0
var dash_time_left := 0.0
var has_started_run := false
var lives: int = MAX_LIVES
var spawn_position: Vector2
var invulnerability_time_left := 0.0
var hurt_animation_time_left := 0.0
var wall_climb_time_left := 0.0
var fire_power_time_left := 0.0
var fireball_cooldown_time_left := 0.0
var displayed_wall_seconds := 0
var displayed_fire_seconds := 0

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	if not InputMap.has_action("cast_fire"):
		InputMap.add_action("cast_fire")
	var fire_key := InputEventKey.new()
	fire_key.physical_keycode = KEY_F
	if not InputMap.action_has_event("cast_fire", fire_key):
		InputMap.action_add_event("cast_fire", fire_key)
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
	var dash_key := InputEventKey.new()
	dash_key.physical_keycode = KEY_SHIFT
	if not InputMap.action_has_event("dash", dash_key):
		InputMap.action_add_event("dash", dash_key)

func _physics_process(delta: float) -> void:
	_update_special_power_timers(delta)
	if hurt_animation_time_left > 0.0:
		hurt_animation_time_left = maxf(hurt_animation_time_left - delta, 0.0)
	fireball_cooldown_time_left = maxf(fireball_cooldown_time_left - delta, 0.0)

	if invulnerability_time_left > 0.0:
		invulnerability_time_left = maxf(invulnerability_time_left - delta, 0.0)
		visible = int(invulnerability_time_left * 12.0) % 2 == 0
		if invulnerability_time_left == 0.0:
			visible = true

	var direction := Input.get_axis("ui_left", "ui_right")
	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	var dash_pressed := Input.is_action_just_pressed("dash")

	if not has_started_run and (direction != 0.0 or jump_pressed or dash_pressed):
		has_started_run = true
		run_started.emit()

	if direction != 0.0:
		facing_direction = sign(direction)
		animation.scale.x = facing_direction

	if dash_pressed:
		dash_time_left = DASH_DURATION
		velocity = Vector2(facing_direction * DASH_SPEED, 0.0)

	if Input.is_action_just_pressed("cast_fire"):
		_shoot_fireball()

	if dash_time_left > 0.0:
		dash_time_left = maxf(dash_time_left - delta, 0.0)
		move_and_slide()
		return

	var climb_input := Input.get_axis("ui_up", "ui_down")
	var wall_ahead := direction != 0.0 and test_move(global_transform, Vector2(direction * 2.0, 0.0))
	var is_climbing := wall_climb_time_left > 0.0 and wall_ahead and climb_input != 0.0
	if is_climbing:
		velocity.x = direction * SPEED
		velocity.y = climb_input * WALL_CLIMB_SPEED
		animation.play("jump")
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta

		if jump_pressed and is_on_floor():
			velocity.y = JUMP_FORCE
			is_jumping = true
		elif is_on_floor():
			is_jumping = false

		if direction:
			velocity.x = direction * SPEED

			if hurt_animation_time_left > 0.0:
				animation.play("hurt")
			elif !is_jumping:
				animation.play("run")
		elif is_jumping:
			animation.play("hurt" if hurt_animation_time_left > 0.0 else "jump")
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			animation.play("hurt" if hurt_animation_time_left > 0.0 else "idle")

	move_and_slide()


func grant_special_power(power_type: int) -> void:
	match power_type:
		0:
			wall_climb_time_left = SPECIAL_POWER_DURATION
		1:
			fire_power_time_left = SPECIAL_POWER_DURATION
		_:
			push_warning("Tipo de coracao especial desconhecido: %d" % power_type)
			return
	_emit_special_powers_changed()


func _update_special_power_timers(delta: float) -> void:
	wall_climb_time_left = maxf(wall_climb_time_left - delta, 0.0)
	fire_power_time_left = maxf(fire_power_time_left - delta, 0.0)
	var wall_seconds := ceili(wall_climb_time_left)
	var fire_seconds := ceili(fire_power_time_left)
	if wall_seconds != displayed_wall_seconds or fire_seconds != displayed_fire_seconds:
		_emit_special_powers_changed()


func _emit_special_powers_changed() -> void:
	displayed_wall_seconds = ceili(wall_climb_time_left)
	displayed_fire_seconds = ceili(fire_power_time_left)
	special_powers_changed.emit(displayed_wall_seconds, displayed_fire_seconds)


func _shoot_fireball() -> void:
	if fire_power_time_left <= 0.0 or fireball_cooldown_time_left > 0.0:
		return
	fireball_cooldown_time_left = FIREBALL_COOLDOWN
	var fireball := FIREBALL_SCENE.instantiate() as Area2D
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + Vector2(facing_direction * 18.0, 94.0)
	fireball.call("set_direction", facing_direction)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies") or invulnerability_time_left > 0.0 or lives <= 0:
		return

	lives -= 1
	lives_changed.emit(lives)
	damaged.emit()
	hurt_animation_time_left = 0.28
	animation.play("hurt")
	if lives == 0:
		game_over.emit()
		set_physics_process(false)
		return

	global_position = spawn_position
	velocity = Vector2.ZERO
	dash_time_left = 0.0
	invulnerability_time_left = INVULNERABILITY_DURATION
	visible = true
