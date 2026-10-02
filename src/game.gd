extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const STAGE_NAMES: Array[String] = ["GRAMADO", "FLORESTA", "TROPICOS"]
const STAGE_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/Seasonal Tilesets/Seasonal Tilesets/1 - Grassland/Background parts/_Complete_static_BG_(288 x 208).png"),
	preload("res://assets/Seasonal Tilesets/Seasonal Tilesets/2 - Autumn Forest/Background parts/_Complete_static_BG_(288 x 208).png"),
	preload("res://assets/Seasonal Tilesets/Seasonal Tilesets/3 - Tropics/Background parts/_Complete_static_BG_(288 x 208).png"),
]
const COIN_TEXTURE: Texture2D = preload("res://assets/Mini FX, Items & UI/Mini FX, Items & UI/Common Pick-ups/Coin (16 x 16).png")
const RECORD_PATH: String = "user://super_rush_records.cfg"
const RECORD_KEY: String = "full_course"
const MAX_LIVES: int = 5
const DAMAGE_COOLDOWN: float = 1.0

@onready var level: Node2D = $Level

var player: SuperRushPlayer
var background: TextureRect
var timer_label: Label
var stats_label: Label
var status_label: Label
var best_label: Label
var stage_label: Label
var life_meter: Control
var game_over_overlay: ColorRect
var game_over_label: Label
var retry_button: Button
var damage_flash: ColorRect
var elapsed_time: float = 0.0
var best_time: float = 0.0
var death_count: int = 0
var coin_count: int = 0
var lives: int = MAX_LIVES
var stage_index: int = 0
var stage_finish_x: float = 2940.0
var damage_cooldown: float = 0.0
var checkpoint_position: Vector2 = Vector2(48.0, 208.0)
var timer_running: bool = false
var run_finished: bool = false
var game_over: bool = false
var stage_transition_pending: bool = false
var animated_coins: Array[Sprite2D] = []
var dirt_color := Color("#a85b42")
var grass_color := Color("#57c86c")
var grass_trim_color := Color("#318c55")
var spike_color := Color("#e65858")
var finish_flag_color := Color("#ff6b6b")


func _ready() -> void:
	_setup_input()
	_load_record()
	_create_background()
	_build_stage(stage_index)
	_spawn_player()
	_create_hud()


func _process(delta: float) -> void:
	if damage_cooldown > 0.0:
		damage_cooldown = maxf(damage_cooldown - delta, 0.0)
		player.sprite.visible = int(damage_cooldown * 12.0) % 2 == 0
		damage_flash.color.a = 0.26 if int(damage_cooldown * 12.0) % 2 == 0 else 0.0
		if damage_cooldown == 0.0:
			player.sprite.visible = true
			damage_flash.color.a = 0.0

	if timer_running and not run_finished:
		elapsed_time += delta
		timer_label.text = "TEMPO  %s" % _format_time(elapsed_time)

	var coin_frame: int = int(Time.get_ticks_msec() / 150) % 4
	for coin_sprite in animated_coins:
		if is_instance_valid(coin_sprite):
			coin_sprite.frame = coin_frame

	if player != null and player.global_position.y > 310.0 and not game_over:
		_respawn_player()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_action("dash", [KEY_SHIFT, KEY_X])


func _add_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key_code in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key_code
		if not InputMap.action_has_event(action_name, key_event):
			InputMap.action_add_event(action_name, key_event)


func _load_record() -> void:
	var config := ConfigFile.new()
	if config.load(RECORD_PATH) == OK:
		best_time = float(config.get_value("records", RECORD_KEY, 0.0))


func _save_record() -> void:
	var config := ConfigFile.new()
	var load_error: Error = config.load(RECORD_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Nao foi possivel carregar o arquivo de recordes: %s" % error_string(load_error))
		return
	config.set_value("records", RECORD_KEY, best_time)
	var save_error: Error = config.save(RECORD_PATH)
	if save_error != OK:
		push_warning("Nao foi possivel salvar o recorde: %s" % error_string(save_error))


func _create_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)

	background = TextureRect.new()
	background.texture = STAGE_BACKGROUNDS[0]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_layer.add_child(background)


func _build_stage(index: int) -> void:
	background.texture = STAGE_BACKGROUNDS[index]
	var ground_segments: Array[Vector3]
	var shortcut_platforms: Array[Vector3]
	var spike_rows: Array[Vector3]
	var coin_positions: Array[Vector2]
	var checkpoint_at := Vector2(1450.0, 190.0)

	match index:
		0:
			stage_finish_x = 2940.0
			dirt_color = Color("#a85b42")
			grass_color = Color("#57c86c")
			grass_trim_color = Color("#318c55")
			spike_color = Color("#e65858")
			finish_flag_color = Color("#ff6b6b")
			ground_segments = [
				Vector3(0, 500, 220), Vector3(560, 310, 220), Vector3(930, 270, 220),
				Vector3(1260, 300, 220), Vector3(1620, 310, 220), Vector3(1990, 270, 220),
				Vector3(2320, 700, 220),
			]
			shortcut_platforms = [
				Vector3(485, 68, 178), Vector3(810, 72, 166), Vector3(1110, 72, 178),
				Vector3(1485, 82, 162), Vector3(1875, 72, 174), Vector3(2215, 72, 164),
			]
			spike_rows = [
				Vector3(260, 42, 220), Vector3(680, 42, 220), Vector3(1000, 42, 220),
				Vector3(1320, 42, 220), Vector3(1720, 42, 220), Vector3(2105, 48, 220),
				Vector3(2490, 48, 220), Vector3(2740, 42, 220),
			]
			coin_positions = [
				Vector2(150, 190), Vector2(190, 174), Vector2(230, 190),
				Vector2(390, 150), Vector2(430, 150), Vector2(520, 145),
				Vector2(620, 190), Vector2(720, 150), Vector2(850, 138),
				Vector2(960, 190), Vector2(1080, 150), Vector2(1160, 145),
				Vector2(1360, 190), Vector2(1440, 140), Vector2(1530, 135),
				Vector2(1650, 190), Vector2(1810, 190), Vector2(1910, 145),
				Vector2(2050, 190), Vector2(2170, 135), Vector2(2260, 140),
				Vector2(2400, 190), Vector2(2590, 190), Vector2(2810, 190),
			]
		1:
			stage_finish_x = 2650.0
			checkpoint_at = Vector2(1370.0, 190.0)
			dirt_color = Color("#79533f")
			grass_color = Color("#d98945")
			grass_trim_color = Color("#a85439")
			spike_color = Color("#ef714c")
			finish_flag_color = Color("#ffd166")
			ground_segments = [
				Vector3(0, 460, 220), Vector3(510, 260, 220), Vector3(860, 300, 220),
				Vector3(1250, 300, 220), Vector3(1630, 300, 220), Vector3(2020, 680, 220),
			]
			shortcut_platforms = [
				Vector3(425, 70, 170), Vector3(750, 72, 160), Vector3(1090, 70, 166),
				Vector3(1450, 74, 160), Vector3(1825, 70, 165), Vector3(2220, 72, 165),
			]
			spike_rows = [
				Vector3(190, 38, 220), Vector3(605, 38, 220), Vector3(965, 42, 220),
				Vector3(1320, 38, 220), Vector3(1705, 44, 220), Vector3(2140, 44, 220),
				Vector3(2450, 42, 220),
			]
			coin_positions = [
				Vector2(135, 178), Vector2(300, 185), Vector2(450, 135),
				Vector2(570, 185), Vector2(700, 135), Vector2(820, 145),
				Vector2(990, 185), Vector2(1060, 138), Vector2(1200, 185),
				Vector2(1410, 135), Vector2(1540, 185), Vector2(1790, 140),
				Vector2(1940, 185), Vector2(2100, 185), Vector2(2200, 140),
				Vector2(2360, 185), Vector2(2560, 185),
			]
		2:
			stage_finish_x = 3260.0
			checkpoint_at = Vector2(1700.0, 190.0)
			dirt_color = Color("#765a47")
			grass_color = Color("#43c9b4")
			grass_trim_color = Color("#238c94")
			spike_color = Color("#fa5d73")
			finish_flag_color = Color("#ffe078")
			ground_segments = [
				Vector3(0, 420, 220), Vector3(500, 310, 210), Vector3(900, 250, 220),
				Vector3(1260, 320, 210), Vector3(1650, 300, 220), Vector3(2040, 300, 210),
				Vector3(2430, 900, 220),
			]
			shortcut_platforms = [
				Vector3(410, 74, 170), Vector3(775, 76, 162), Vector3(1110, 72, 168),
				Vector3(1480, 76, 160), Vector3(1860, 72, 166), Vector3(2240, 76, 160),
				Vector3(2700, 72, 168), Vector3(3000, 72, 165),
			]
			spike_rows = [
				Vector3(220, 44, 220), Vector3(620, 42, 210), Vector3(1020, 46, 220),
				Vector3(1380, 42, 210), Vector3(1760, 46, 220), Vector3(2160, 42, 210),
				Vector3(2530, 48, 220), Vector3(2890, 44, 220), Vector3(3150, 40, 220),
			]
			coin_positions = [
				Vector2(130, 185), Vector2(340, 145), Vector2(460, 140),
				Vector2(575, 175), Vector2(735, 135), Vector2(860, 185),
				Vector2(990, 140), Vector2(1170, 185), Vector2(1350, 140),
				Vector2(1510, 135), Vector2(1740, 185), Vector2(1900, 140),
				Vector2(2110, 175), Vector2(2300, 140), Vector2(2490, 185),
				Vector2(2670, 140), Vector2(2820, 185), Vector2(3000, 140),
				Vector2(3200, 185),
			]

	for segment in ground_segments:
		_add_platform(segment.x, segment.y, segment.z)
	for platform in shortcut_platforms:
		_add_platform(platform.x, platform.y, platform.z)
	for spikes in spike_rows:
		_add_spikes(spikes.x, spikes.y, spikes.z)
	for coin_position in coin_positions:
		_add_coin(coin_position)
	_add_checkpoint(checkpoint_at)
	_add_finish()


func _add_platform(start: float, width: float, top: float) -> void:
	var platform := StaticBody2D.new()
	platform.position = Vector2(start + width * 0.5, top + 9.0)
	level.add_child(platform)

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 18.0)
	collision.shape = rectangle
	platform.add_child(collision)

	var dirt := Polygon2D.new()
	dirt.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -9), Vector2(width * 0.5, -9),
		Vector2(width * 0.5, 9), Vector2(-width * 0.5, 9),
	])
	dirt.color = dirt_color
	platform.add_child(dirt)

	var grass := Polygon2D.new()
	grass.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -9), Vector2(width * 0.5, -9),
		Vector2(width * 0.5, -4), Vector2(-width * 0.5, -4),
	])
	grass.color = grass_color
	platform.add_child(grass)

	var trim := Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -4), Vector2(width * 0.5, -4),
		Vector2(width * 0.5, -2), Vector2(-width * 0.5, -2),
	])
	trim.color = grass_trim_color
	platform.add_child(trim)


func _add_spikes(start: float, width: float, top: float) -> void:
	var spikes := Area2D.new()
	spikes.position = Vector2(start, top - 12.0)
	spikes.body_entered.connect(_on_hazard_entered)
	level.add_child(spikes)

	var collision := CollisionShape2D.new()
	collision.position = Vector2(width * 0.5, 6.0)
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 12.0)
	collision.shape = rectangle
	spikes.add_child(collision)

	var spike_art := Polygon2D.new()
	var spike_width: float = 12.0
	var x: float = 0.0
	while x < width:
		var spike_tip := Polygon2D.new()
		spike_tip.polygon = PackedVector2Array([
			Vector2(0.0, 12.0),
			Vector2(minf(spike_width * 0.5, width - x), 0.0),
			Vector2(minf(spike_width, width - x), 12.0),
		])
		spike_tip.position.x = x
		spike_tip.color = spike_color
		spikes.add_child(spike_tip)
		x += spike_width


func _add_coin(at_position: Vector2) -> void:
	var coin := Area2D.new()
	coin.position = at_position
	coin.body_entered.connect(_on_coin_body_entered.bind(coin))
	level.add_child(coin)

	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	collision.shape = circle
	coin.add_child(collision)

	var coin_sprite := Sprite2D.new()
	coin_sprite.texture = COIN_TEXTURE
	coin_sprite.hframes = 4
	coin.add_child(coin_sprite)
	animated_coins.append(coin_sprite)


func _add_checkpoint(at_position: Vector2) -> void:
	var checkpoint := Area2D.new()
	checkpoint.position = at_position
	checkpoint.body_entered.connect(_on_checkpoint_entered.bind(at_position))
	level.add_child(checkpoint)

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 70.0)
	collision.shape = rectangle
	checkpoint.add_child(collision)

	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-2, -33), Vector2(2, -33), Vector2(2, 33), Vector2(-2, 33),
	])
	post.color = Color("#594b6b")
	checkpoint.add_child(post)

	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(2, -32), Vector2(20, -26), Vector2(2, -19),
	])
	flag.color = Color("#ffd166")
	checkpoint.add_child(flag)


func _add_finish() -> void:
	var finish := Area2D.new()
	finish.position = Vector2(stage_finish_x, 184.0)
	finish.body_entered.connect(_on_finish_entered)
	level.add_child(finish)

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(28.0, 76.0)
	collision.shape = rectangle
	finish.add_child(collision)

	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-2, -36), Vector2(2, -36), Vector2(2, 36), Vector2(-2, 36),
	])
	post.color = Color("#594b6b")
	finish.add_child(post)

	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(2, -35), Vector2(23, -28), Vector2(2, -21),
	])
	flag.color = finish_flag_color
	finish.add_child(flag)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as SuperRushPlayer
	player.position = checkpoint_position
	player.run_started.connect(_on_run_started)
	level.add_child(player)
	player.camera.limit_left = 0
	player.camera.limit_top = -80
	player.camera.limit_right = roundi(stage_finish_x + 240.0)
	player.camera.limit_bottom = 320
	player.camera.offset = Vector2(0.0, -24.0)
	player.camera.make_current()


func _create_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var panel := ColorRect.new()
	panel.position = Vector2(8, 8)
	panel.size = Vector2(168, 66)
	panel.color = Color(0.08, 0.13, 0.18, 0.86)
	hud.add_child(panel)

	timer_label = _add_label(hud, Vector2(16, 12), Vector2(156, 15), "TEMPO  00:00.00", 8)
	best_label = _add_label(hud, Vector2(16, 29), Vector2(156, 12), "RECORDE  --:--.--", 8)
	var coin_icon := Sprite2D.new()
	coin_icon.texture = COIN_TEXTURE
	coin_icon.hframes = 4
	coin_icon.frame = 0
	coin_icon.position = Vector2(23, 51)
	hud.add_child(coin_icon)
	animated_coins.append(coin_icon)
	stats_label = _add_label(hud, Vector2(34, 45), Vector2(136, 12), "MOEDAS  000  QUEDAS  0", 8)

	var life_panel := ColorRect.new()
	life_panel.anchor_left = 1.0
	life_panel.anchor_right = 1.0
	life_panel.offset_left = -154.0
	life_panel.offset_top = 8.0
	life_panel.offset_right = -8.0
	life_panel.offset_bottom = 42.0
	life_panel.color = Color(0.08, 0.13, 0.18, 0.86)
	hud.add_child(life_panel)
	_add_label(
		life_panel,
		Vector2(8, 9),
		Vector2(48, 16),
		"VIDAS",
		8
	)
	var life_meter_script: Script = load("res://src/life_meter.gd")
	life_meter = Control.new()
	life_meter.position = Vector2(60, 12)
	life_meter.custom_minimum_size = Vector2(78, 12)
	life_meter.set_script(life_meter_script)
	life_panel.add_child(life_meter)
	life_meter.call("set_lives", lives)

	status_label = _add_label(hud, Vector2(216, 12), Vector2(254, 18), "A/D ou setas: correr", 11)
	_add_label(hud, Vector2(216, 29), Vector2(254, 18), "Espaco: pular    Shift/X: dash    R: reiniciar", 9)
	stage_label = _add_label(hud, Vector2(216, 48), Vector2(254, 16), _stage_heading(), 9)

	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.0, 0.04, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_flash)

	game_over_overlay = ColorRect.new()
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.color = Color(0.42, 0.01, 0.04, 0.8)
	game_over_overlay.visible = false
	hud.add_child(game_over_overlay)

	var game_over_panel := PanelContainer.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_panel.position = Vector2(-110, -42)
	game_over_panel.size = Vector2(220, 84)
	game_over_overlay.add_child(game_over_panel)

	var game_over_content := VBoxContainer.new()
	game_over_content.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(game_over_content)

	game_over_label = Label.new()
	game_over_label.text = "FIM DE JOGO"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_content.add_child(game_over_label)

	retry_button = Button.new()
	retry_button.text = "TENTAR DE NOVO"
	retry_button.pressed.connect(_on_retry_pressed)
	game_over_content.add_child(retry_button)

	_update_hud()


func _add_label(parent: Node, at_position: Vector2, label_size: Vector2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.position = at_position
	label.size = label_size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff4d6"))
	parent.add_child(label)
	return label


func _on_run_started() -> void:
	timer_running = true
	status_label.text = "Correndo: %s!" % STAGE_NAMES[stage_index]


func _on_hazard_entered(body: Node2D) -> void:
	if body == player and not run_finished and not game_over:
		_respawn_player()


func _on_coin_body_entered(body: Node2D, coin: Area2D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	coin_count += 1
	coin.queue_free()
	_update_hud()


func _on_checkpoint_entered(body: Node2D, at_position: Vector2) -> void:
	if body != player:
		return
	checkpoint_position = at_position + Vector2(0, 18)
	status_label.text = "Checkpoint ativado!"


func _on_finish_entered(body: Node2D) -> void:
	if body != player or run_finished or game_over or stage_transition_pending:
		return
	if stage_index < STAGE_NAMES.size() - 1:
		stage_transition_pending = true
		player.set_physics_process(false)
		status_label.text = "FASE CONCLUIDA! Preparando %s..." % STAGE_NAMES[stage_index + 1]
		_advance_to_next_stage()
		return

	run_finished = true
	timer_running = false
	player.set_physics_process(false)
	status_label.text = "VOCE VENCEU! Tempo: %s" % _format_time(elapsed_time)
	game_over_label.text = "VOCE VENCEU!"
	retry_button.text = "JOGAR DE NOVO"
	game_over_overlay.color = Color(0.05, 0.25, 0.12, 0.84)
	game_over_overlay.visible = true
	if best_time <= 0.0 or elapsed_time < best_time:
		best_time = elapsed_time
		_save_record()
	_update_hud()


func _advance_to_next_stage() -> void:
	var resume_timer := timer_running
	timer_running = false
	await get_tree().create_timer(0.8).timeout
	if game_over:
		return

	stage_index += 1
	run_finished = false
	stage_transition_pending = false
	checkpoint_position = Vector2(48.0, 208.0)
	animated_coins.clear()
	for stage_node in level.get_children():
		level.remove_child(stage_node)
		stage_node.queue_free()
	player = null

	_build_stage(stage_index)
	_spawn_player()
	stage_label.text = _stage_heading()
	timer_running = resume_timer
	if resume_timer:
		status_label.text = "Correndo: %s!" % STAGE_NAMES[stage_index]
	else:
		status_label.text = "FASE %d - %s" % [stage_index + 1, STAGE_NAMES[stage_index]]
	_update_hud()


func _stage_heading() -> String:
	return "FASE %d/%d - %s" % [stage_index + 1, STAGE_NAMES.size(), STAGE_NAMES[stage_index]]


func _respawn_player() -> void:
	if run_finished or game_over or damage_cooldown > 0.0:
		return
	death_count += 1
	lives = maxi(lives - 1, 0)
	player.respawn(checkpoint_position)
	player.play_hurt()
	damage_cooldown = DAMAGE_COOLDOWN
	player.sprite.visible = true
	if is_instance_valid(damage_flash):
		damage_flash.color.a = 0.26
	_update_hud()
	if lives == 0:
		game_over = true
		timer_running = false
		player.set_physics_process(false)
		damage_flash.color.a = 0.0
		status_label.text = "Sem vidas! R para reiniciar."
		game_over_overlay.visible = true
		return
	status_label.text = "De volta ao checkpoint! Tente outra rota."


func _update_hud() -> void:
	if stats_label != null:
		stats_label.text = "MOEDAS  %03d  QUEDAS  %d" % [coin_count, death_count]
	if life_meter != null:
		life_meter.call("set_lives", lives)
	if best_label != null:
		best_label.text = "RECORDE  %s" % (_format_time(best_time) if best_time > 0.0 else "--:--.--")


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _format_time(seconds: float) -> String:
	var centiseconds: int = int(fmod(seconds, 1.0) * 100.0)
	var total_seconds: int = int(seconds)
	var minutes: int = total_seconds / 60
	var remaining_seconds: int = total_seconds % 60
	return "%02d:%02d.%02d" % [minutes, remaining_seconds, centiseconds]
