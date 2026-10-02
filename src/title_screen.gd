extends Control

@onready var title_label: Label = $MenuPanel/TitleLabel
@onready var start_button: Button = $MenuPanel/Buttons/StartButton
@onready var options_button: Button = $MenuPanel/Buttons/OptionsButton
@onready var language_button: Button = $MenuPanel/Buttons/LanguageButton
@onready var quit_button: Button = $MenuPanel/Buttons/QuitButton
@onready var options_panel: Panel = $OptionsPanel
@onready var fullscreen_toggle: CheckButton = $OptionsPanel/Content/FullscreenToggle

var languages: Array[String] = ["PT-BR", "EN", "ES"]
var current_language_index: int = 0


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	language_button.pressed.connect(_on_language_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	options_panel.visible = false
	_update_language_button()
	_update_title_style()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_pressed() -> void:
	options_panel.visible = not options_panel.visible


func _on_language_pressed() -> void:
	current_language_index = (current_language_index + 1) % languages.size()
	_update_language_button()
	_update_title_style()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_toggled(is_toggled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if is_toggled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _update_language_button() -> void:
	language_button.text = "Idioma: %s" % languages[current_language_index]


func _update_title_style() -> void:
	match languages[current_language_index]:
		"PT-BR":
			title_label.text = "SUPER RUSH"
			start_button.text = "Entrar"
			options_button.text = "Opções"
			quit_button.text = "Sair"
		"EN":
			title_label.text = "SUPER RUSH"
			start_button.text = "Play"
			options_button.text = "Options"
			quit_button.text = "Quit"
		"ES":
			title_label.text = "SUPER RUSH"
			start_button.text = "Jugar"
			options_button.text = "Opciones"
			quit_button.text = "Salir"
