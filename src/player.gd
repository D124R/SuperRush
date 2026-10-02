extends CharacterBody2D
class_name SuperRushPlayer

signal run_started

const IDLE_TEXTURE: Texture2D = preload("res://assets/Sprite Pack 2/Sprite Pack 2/2 - Mr. Mochi/Idle (32 x 32).png")
const RUN_TEXTURE: Texture2D = preload("res://assets/Sprite Pack 2/Sprite Pack 2/2 - Mr. Mochi/Running (32 x 32).png")
const JUMP_TEXTURE: Texture2D = preload("res://assets/Sprite Pack 2/Sprite Pack 2/2 - Mr. Mochi/Jumping (32 x 32).png")
const HURT_TEXTURE: Texture2D = preload("res://assets/Sprite Pack 2/Sprite Pack 2/2 - Mr. Mochi/Hurt (32 x 32).png")

const RUN_SPEED: float = 285.0
const ACCELERATION: float = 1900.0
const FRICTION: float = 2300.0
const JUMP_SPEED: float = -480.0
const GRAVITY: float = 1200.0
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER_TIME: float = 0.12
const DASH_SPEED: float = 540.0
const DASH_DURATION: float = 0.14
const DASH_COOLDOWN: float = 0.65

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var facing: float = 1.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var run_has_started: bool = false
var hurt_timer: float = 0.0


func _physics_process(delta: float) -> void:
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = signf(direction)
		_start_run()

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		_start_run()
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_SPEED
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		if direction == 0.0:
			direction = facing
		facing = signf(direction)
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		_start_run()

	if dash_timer > 0.0:
		dash_timer = maxf(dash_timer - delta, 0.0)
	else:
		velocity.x = move_toward(velocity.x, direction * RUN_SPEED, (ACCELERATION if direction != 0.0 else FRICTION) * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta

	move_and_slide()
	_update_animation(direction)


func respawn(at_position: Vector2) -> void:
	global_position = at_position
	velocity = Vector2.ZERO
	dash_timer = 0.0


func play_hurt() -> void:
	hurt_timer = 0.3
	_set_sprite(HURT_TEXTURE, 1)


func _start_run() -> void:
	if run_has_started:
		return
	run_has_started = true
	run_started.emit()


func _update_animation(direction: float) -> void:
	sprite.flip_h = facing < 0.0
	if hurt_timer > 0.0:
		_set_sprite(HURT_TEXTURE, 1)
		return
	if not is_on_floor():
		_set_sprite(JUMP_TEXTURE, 1)
	elif absf(direction) > 0.0:
		_set_sprite(RUN_TEXTURE, 4)
		sprite.frame = int(Time.get_ticks_msec() / 110) % 4
	else:
		_set_sprite(IDLE_TEXTURE, 2)
		sprite.frame = int(Time.get_ticks_msec() / 420) % 2


func _set_sprite(texture: Texture2D, frames: int) -> void:
	if sprite.texture == texture:
		return
	sprite.texture = texture
	sprite.hframes = frames
	sprite.frame = 0
