extends Control

const BUTTON_BORDER := Color("#fff4d6")

var action_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_touch_controls_enabled(DisplayServer.is_touchscreen_available())


func set_touch_controls_enabled(enabled: bool) -> void:
	visible = enabled
	if not enabled or not action_buttons.is_empty():
		return

	_create_direction_button("<", "ui_left", 10.0, -155.0, 78.0, -87.0)
	_create_direction_button(">", "ui_right", 104.0, -155.0, 172.0, -87.0)
	_create_direction_button("^", "ui_up", 57.0, -223.0, 125.0, -155.0)
	_create_direction_button("v", "ui_down", 57.0, -87.0, 125.0, -19.0)

	_create_action_button("PULO", "ui_accept", -98.0, -98.0, -12.0, -12.0)
	_create_action_button("DASH", "dash", -196.0, -196.0, -102.0, -102.0)
	_create_action_button("FOGO", "cast_fire", -98.0, -196.0, -12.0, -102.0)


func _create_direction_button(
	label: String,
	action: StringName,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	_create_touch_button(
		label,
		action,
		0.0,
		1.0,
		left,
		top,
		right,
		bottom,
		20,
		Color("#087ab8")
	)


func _create_action_button(
	label: String,
	action: StringName,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	var accent := Color("#ff982c")
	if action == "dash":
		accent = Color("#9852d1")
	elif action == "cast_fire":
		accent = Color("#e84c55")

	_create_touch_button(
		label,
		action,
		1.0,
		1.0,
		left,
		top,
		right,
		bottom,
		13,
		accent
	)


func _create_touch_button(
	label: String,
	action: StringName,
	horizontal_anchor: float,
	vertical_anchor: float,
	left: float,
	top: float,
	right: float,
	bottom: float,
	font_size: int,
	accent: Color
) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var button := Button.new()
	button.name = String(action)
	button.text = label
	button.anchor_left = horizontal_anchor
	button.anchor_right = horizontal_anchor
	button.anchor_top = vertical_anchor
	button.anchor_bottom = vertical_anchor
	button.offset_left = left
	button.offset_top = top
	button.offset_right = right
	button.offset_bottom = bottom
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#fffaf0"))
	button.add_theme_color_override("font_pressed_color", Color("#111a2b"))
	button.add_theme_color_override("font_outline_color", Color("#111a2b"))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _button_style(false, accent))
	button.add_theme_stylebox_override("pressed", _button_style(true, accent))
	button.add_theme_stylebox_override("hover", _button_style(false, accent))
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	add_child(button)
	action_buttons.append(button)


func _button_style(pressed: bool, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ffd34e") if pressed else accent
	style.border_color = BUTTON_BORDER if pressed else accent.lightened(0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color("#10182acc")
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	return style


func _press_action(action: StringName) -> void:
	Input.action_press(action)


func _release_action(action: StringName) -> void:
	Input.action_release(action)
