extends Node2D

const COIN_TEXTURE: Texture2D = preload("res://assets/Mini FX, Items & UI/Mini FX, Items & UI/Common Pick-ups/Coin (16 x 16).png")
const DAMAGE_FLASH_DURATION := 0.22

@onready var player: CharacterBody2D = $player
@onready var camera := $camera as Camera2D

var elapsed_time := 0.0
var timer_running := false
var timer_display: Label
var life_meter: Control
var coin_label: Label
var special_power_label: Label
var coin_count: int = 0
var game_over_overlay: ColorRect
var pause_menu: Control
var mobile_controls: Control
var hud_root: MarginContainer
var is_touch: bool = false
var damage_flash: ColorRect
var damage_flash_time_left := 0.0


func _ready() -> void:
	player.connect("run_started", _start_timer)
	player.connect("lives_changed", _on_lives_changed)
	player.connect("damaged", _on_player_damaged)
	player.connect("game_over", _on_game_over)
	player.connect("special_powers_changed", _on_special_powers_changed)
	for coin in get_tree().get_nodes_in_group("coins"):
		coin.connect("collected", _on_coin_collected)
	is_touch = _detect_touch()
	_create_hud()
	_configure_player_camera()
	_on_special_powers_changed(0, 0)


func _process(delta: float) -> void:
	if damage_flash_time_left > 0.0:
		damage_flash_time_left = maxf(damage_flash_time_left - delta, 0.0)
		damage_flash.color = Color(
			1.0,
			0.08,
			0.12,
			0.38 * damage_flash_time_left / DAMAGE_FLASH_DURATION
		)
		damage_flash.visible = damage_flash_time_left > 0.0

	if get_tree().paused:
		return

	if not timer_running:
		return

	elapsed_time += delta
	var total_seconds := int(elapsed_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	var centiseconds := int(fposmod(elapsed_time, 1.0) * 100.0)
	timer_display.call("set_time", "%02d:%02d.%02d" % [minutes, seconds, centiseconds])


func _start_timer() -> void:
	timer_running = true


func _configure_player_camera() -> void:
	camera.enabled = false
	var player_camera := player.get_node("camera") as Camera2D
	player_camera.enabled = true
	player_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player_camera.position_smoothing_enabled = true
	player_camera.position_smoothing_speed = 8.0
	player_camera.limit_left = -1000
	player_camera.limit_top = -1000
	player_camera.limit_right = 10000
	player_camera.limit_bottom = 10000
	player_camera.make_current()
	player_camera.reset_smoothing()


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.08, 0.12, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.visible = false
	canvas.add_child(damage_flash)

	# Layout com containers: os paineis nao ficam mais presos a posicoes fixas.
	# Se a tela for estreita demais, _fit_hud() reduz a escala do HUD inteiro.
	hud_root = MarginContainer.new()
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		hud_root.add_theme_constant_override("margin_" + side, 8)
	canvas.add_child(hud_root)

	var top_row := HBoxContainer.new()
	top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 8)
	hud_root.add_child(top_row)

	# Coluna esquerda: tempo + moedas, e logo abaixo os poderes
	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_column.add_theme_constant_override("separation", 6)
	top_row.add_child(left_column)

	var stats_row := HBoxContainer.new()
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_theme_constant_override("separation", 8)
	left_column.add_child(stats_row)

	var timer_panel := _create_hud_panel(
		stats_row,
		Vector2.ZERO,
		Vector2(158, 50),
		Color("#ffd34e")
	)
	_create_hud_label(
		timer_panel,
		Vector2(9, 4),
		Vector2(138, 12),
		"TEMPO",
		8,
		Color("#ffd34e")
	)

	var pixel_timer_script: Script = load("res://src/pixel_timer.gd")
	timer_display = Label.new()
	timer_display.position = Vector2(9, 17)
	timer_display.size = Vector2(138, 25)
	timer_display.set_script(pixel_timer_script)
	timer_display.add_theme_font_size_override("font_size", 16)
	timer_panel.add_child(timer_display)

	var coin_panel := _create_hud_panel(
		stats_row,
		Vector2.ZERO,
		Vector2(126, 50),
		Color("#ffad45")
	)
	_create_hud_label(
		coin_panel,
		Vector2(9, 4),
		Vector2(108, 12),
		"MOEDAS",
		8,
		Color("#ffad45")
	)

	var coin_icon := TextureRect.new()
	var coin_icon_texture := AtlasTexture.new()
	coin_icon_texture.atlas = COIN_TEXTURE
	coin_icon_texture.region = Rect2(Vector2.ZERO, Vector2(16, 16))
	coin_icon.texture = coin_icon_texture
	coin_icon.position = Vector2(9, 24)
	coin_icon.custom_minimum_size = Vector2(20, 20)
	coin_icon.size = Vector2(20, 20)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_panel.add_child(coin_icon)

	coin_label = _create_hud_label(
		coin_panel,
		Vector2(34, 24),
		Vector2(82, 20),
		"x 000",
		14
	)

	var power_panel := _create_hud_panel(
		left_column,
		Vector2.ZERO,
		Vector2(292, 24),
		Color("#58d8d0")
	)
	special_power_label = _create_hud_label(
		power_panel,
		Vector2(8, 2),
		Vector2(274, 18),
		_power_hint(),
		8
	)

	# Coluna direita: vidas e botao de pausa
	var right_column := VBoxContainer.new()
	right_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_column.add_theme_constant_override("separation", 6)
	top_row.add_child(right_column)

	var life_meter_script: Script = load("res://src/life_meter.gd")
	var life_panel := _create_hud_panel(
		right_column,
		Vector2.ZERO,
		Vector2(202, 52),
		Color("#f15b66")
	)

	_create_hud_label(
		life_panel,
		Vector2(10, 3),
		Vector2(180, 12),
		"VIDAS",
		8,
		Color("#ff777e")
	)

	life_meter = Control.new()
	life_meter.position = Vector2(10, 20)
	life_meter.custom_minimum_size = Vector2(164, 30)
	life_meter.size = Vector2(164, 30)
	life_meter.set_script(life_meter_script)
	life_panel.add_child(life_meter)
	life_meter.call("set_lives", player.get("lives"))

	var pause_button := Button.new()
	pause_button.text = "II"
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause_button.custom_minimum_size = Vector2(48, 48) if is_touch else Vector2(34, 34)
	pause_button.add_theme_font_size_override("font_size", 16 if is_touch else 12)
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(_toggle_pause)
	pause_button.visible = is_touch
	right_column.add_child(pause_button)

	game_over_overlay = ColorRect.new()
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.color = Color(0.02, 0.04, 0.08, 0.8)
	game_over_overlay.visible = false
	canvas.add_child(game_over_overlay)

	var game_over_panel := PanelContainer.new()
	game_over_panel.custom_minimum_size = Vector2(220, 78)
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_panel.position = Vector2(-110, -39)
	game_over_panel.size = Vector2(220, 78)
	game_over_overlay.add_child(game_over_panel)

	var game_over_content := VBoxContainer.new()
	game_over_content.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(game_over_content)

	var game_over_label := Label.new()
	game_over_label.text = "FIM DE JOGO"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_content.add_child(game_over_label)

	var retry_button := Button.new()
	retry_button.text = "TENTAR DE NOVO"
	if is_touch:
		retry_button.custom_minimum_size = Vector2(0, 44) # alvo de toque confortavel
	retry_button.pressed.connect(_on_retry_pressed)
	game_over_content.add_child(retry_button)

	var pause_menu_script: Script = load("res://src/pause_menu.gd")
	pause_menu = Control.new()
	pause_menu.set_script(pause_menu_script)
	pause_menu.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.connect("pause_requested", _toggle_pause)
	pause_menu.connect("continue_requested", _resume_game)
	pause_menu.connect("restart_requested", _restart_from_pause)
	pause_menu.connect("exit_requested", _exit_to_title)
	canvas.add_child(pause_menu)

	var mobile_controls_script: Script = load("res://src/mobile_controls.gd")
	mobile_controls = Control.new()
	mobile_controls.set_script(mobile_controls_script)
	canvas.add_child(mobile_controls)

	get_viewport().size_changed.connect(_fit_hud)
	_fit_hud.call_deferred()


# Se a tela for mais estreita que o HUD, reduz a escala dele para tudo caber
func _fit_hud() -> void:
	if hud_root == null:
		return
	var view := get_viewport_rect().size
	hud_root.scale = Vector2.ONE
	var needed := hud_root.get_combined_minimum_size()
	var fit := minf(1.0, view.x / maxf(needed.x, 1.0))
	hud_root.scale = Vector2(fit, fit)
	hud_root.position = Vector2.ZERO
	hud_root.size = view / fit


func _detect_touch() -> bool:
	if OS.has_feature("web"):
		if OS.has_feature("web_android") or OS.has_feature("web_ios"):
			return true
		var coarse = JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches", true)
		return coarse == true
	return DisplayServer.is_touchscreen_available()


func _power_hint() -> String:
	return "CIMA + LADO: ESCALAR  |  FOGO" if is_touch else "CIMA + LADO: ESCALAR  |  F: FOGO"


func _toggle_pause() -> void:
	if game_over_overlay.visible:
		return
	if get_tree().paused:
		_resume_game()
		return
	pause_menu.visible = true
	mobile_controls.visible = false
	get_tree().paused = true
	get_node("/root/MusicManager").call("pause_music")
	pause_menu.call("focus_default")


func _resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	mobile_controls.call("set_touch_controls_enabled", is_touch)
	get_node("/root/MusicManager").call("resume_music")


func _restart_from_pause() -> void:
	get_tree().paused = false
	get_node("/root/MusicManager").call("resume_music")
	get_tree().reload_current_scene()


func _exit_to_title() -> void:
	get_tree().paused = false
	get_node("/root/MusicManager").call("resume_music")
	get_tree().change_scene_to_file("res://preafbs/title_screen.tscn")


func _create_hud_panel(
	parent: Node,
	at_position: Vector2,
	panel_size: Vector2,
	accent: Color
) -> Panel:
	var panel := Panel.new()
	panel.position = at_position
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111a2b")
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _create_hud_label(
	parent: Node,
	at_position: Vector2,
	label_size: Vector2,
	value: String,
	font_size: int = 8,
	font_color: Color = Color("#fff4d6")
) -> Label:
	var label := Label.new()
	label.position = at_position
	label.size = label_size
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color("#111a2b"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label


func _on_lives_changed(value: int) -> void:
	life_meter.call("set_lives", value)


func _on_player_damaged() -> void:
	damage_flash_time_left = DAMAGE_FLASH_DURATION
	damage_flash.color = Color(1.0, 0.08, 0.12, 0.38)
	damage_flash.visible = true


func _on_coin_collected() -> void:
	coin_count += 1
	coin_label.text = "x %03d" % coin_count


func _on_special_powers_changed(wall_climb_seconds: int, fire_seconds: int) -> void:
	var active_powers: Array[String] = []
	if wall_climb_seconds > 0:
		active_powers.append("PAREDE %ds" % wall_climb_seconds)
	if fire_seconds > 0:
		active_powers.append("FOGO %ds" % fire_seconds)
	if active_powers.is_empty():
		special_power_label.text = _power_hint()
	else:
		special_power_label.text = "  ".join(active_powers)


func _on_game_over() -> void:
	timer_running = false
	mobile_controls.visible = false
	game_over_overlay.visible = true


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
