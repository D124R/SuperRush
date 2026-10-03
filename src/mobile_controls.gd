extends Control

const BUTTON_COLOR := Color(0.08, 0.14, 0.22, 0.72)
const BUTTON_BORDER := Color(0.72, 0.84, 0.95, 0.78)

var action_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_touch_controls_enabled(DisplayServer.is_touchscreen_available())


func set_touch_controls_enabled(enabled: bool) -> void:
	visible = enabled
	if not enabled or not action_buttons.is_empty():
		return

	_create_direction_button("<", "ui_left", 12.0, -116.0, 66.0, -62.0)
	_create_direction_button(">", "ui_right", 124.0, -116.0, 178.0, -62.0)
	_create_direction_button("^", "ui_up", 68.0, -172.0, 122.0, -118.0)
	_create_direction_button("v", "ui_down", 68.0, -60.0, 122.0, -6.0)

	_create_action_button("PULO", "ui_accept", -82.0, -82.0, -12.0, -12.0)
	_create_action_button("DASH", "dash", -156.0, -156.0, -86.0, -86.0)
	_create_action_button("FOGO", "cast_fire", -82.0, -156.0, -12.0, -86.0)


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
		14
	)


func _create_action_button(
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
		1.0,
		1.0,
		left,
		top,
		right,
		bottom,
		9
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
	font_size: int
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
	button.add_theme_color_override("font_color", Color("#fff4d6"))
	button.add_theme_color_override("font_pressed_color", Color("#ffd34e"))
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.add_theme_stylebox_override("hover", _button_style(false))
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	add_child(button)
	action_buttons.append(button)


func _button_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.25, 0.36, 0.88) if pressed else BUTTON_COLOR
	style.border_color = Color("#ffd34e") if pressed else BUTTON_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	return style


func _press_action(action: StringName) -> void:
	Input.action_press(action)


func _release_action(action: StringName) -> void:
	Input.action_release(action)
