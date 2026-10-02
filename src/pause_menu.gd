extends Control

signal continue_requested
signal restart_requested
signal exit_requested
signal pause_requested

var menu_panel: PanelContainer
var options_panel: PanelContainer
var continue_button: Button
var fullscreen_toggle: CheckButton
var volume_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ESCAPE and event.keycode != KEY_P:
		return

	get_viewport().set_input_as_handled()
	if not visible:
		pause_requested.emit()
	elif options_panel.visible:
		_show_main_menu()
	else:
		continue_requested.emit()


func _build_menu() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.035, 0.075, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	menu_panel = _create_panel(Vector2(260, 260), Color("#ffd34e"))
	add_child(menu_panel)

	var menu_content := VBoxContainer.new()
	menu_content.add_theme_constant_override("separation", 8)
	menu_content.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_panel.add_child(menu_content)

	var title := _create_label("PAUSADO", 16, Color("#ffd34e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_content.add_child(title)

	continue_button = _create_button("CONTINUAR")
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	menu_content.add_child(continue_button)

	var restart_button := _create_button("REINICIAR")
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	menu_content.add_child(restart_button)

	var options_button := _create_button("OPCOES")
	options_button.pressed.connect(_show_options)
	menu_content.add_child(options_button)

	var exit_button := _create_button("SAIR PARA O MENU")
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	menu_content.add_child(exit_button)

	options_panel = _create_panel(Vector2(320, 190), Color("#58d8d0"))
	options_panel.visible = false
	add_child(options_panel)

	var options_content := VBoxContainer.new()
	options_content.add_theme_constant_override("separation", 14)
	options_content.alignment = BoxContainer.ALIGNMENT_CENTER
	options_panel.add_child(options_content)

	var options_title := _create_label("OPCOES", 16, Color("#58d8d0"))
	options_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_content.add_child(options_title)

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "TELA CHEIA"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	options_content.add_child(fullscreen_toggle)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 10)
	options_content.add_child(volume_row)

	var volume_label := _create_label("VOLUME", 10)
	volume_label.custom_minimum_size.x = 70
	volume_row.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value = _get_master_volume_percent()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	var back_button := _create_button("VOLTAR")
	back_button.pressed.connect(_show_main_menu)
	options_content.add_child(back_button)


func _create_panel(panel_size: Vector2, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = -panel_size * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111a2b")
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(208, 34)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 10)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#243b5a")
	normal.border_color = Color("#507093")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", normal)

	var hovered := StyleBoxFlat.new()
	hovered.bg_color = Color("#315779")
	hovered.border_color = Color("#ffd34e")
	hovered.set_border_width_all(2)
	hovered.set_corner_radius_all(0)
	button.add_theme_stylebox_override("hover", hovered)
	button.add_theme_stylebox_override("focus", hovered)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#172840")
	pressed.border_color = Color("#ffad45")
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(0)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


func _create_label(text: String, font_size: int, color := Color("#fff4d6")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _show_options() -> void:
	menu_panel.visible = false
	options_panel.visible = true
	fullscreen_toggle.grab_focus()


func _show_main_menu() -> void:
	options_panel.visible = false
	menu_panel.visible = true
	continue_button.grab_focus()


func focus_default() -> void:
	if not options_panel.visible:
		continue_button.grab_focus()


func show_main_menu() -> void:
	_show_main_menu()


func _on_fullscreen_toggled(is_toggled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if is_toggled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("O barramento de audio Master nao foi encontrado.")
		return
	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(value / 100.0) if value > 0.0 else -80.0
	)


func _get_master_volume_percent() -> float:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("O barramento de audio Master nao foi encontrado.")
		return 100.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0, 0.0, 100.0)
