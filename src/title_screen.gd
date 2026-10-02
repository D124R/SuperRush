extends Control

@onready var start_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/start_btn
@onready var options_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/options_btn
@onready var language_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/language_btn
@onready var quit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/quit_btn
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var fullscreen_toggle: CheckButton = $OptionsPanel/Content/FullscreenToggle
@onready var close_options_button: Button = $OptionsPanel/Content/CloseButton

var languages: Array[String] = ["PT-BR", "EN", "ES"]
var current_language_index: int = 0


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	language_button.pressed.connect(_on_language_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	close_options_button.pressed.connect(_on_options_pressed)
	options_panel.visible = false
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_update_language()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/word_01.tscn")


func _on_options_pressed() -> void:
	options_panel.visible = not options_panel.visible


func _on_language_pressed() -> void:
	current_language_index = (current_language_index + 1) % languages.size()
	_update_language()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_toggled(is_toggled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if is_toggled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _update_language() -> void:
	language_button.text = "IDIOMA: %s" % languages[current_language_index]
	match languages[current_language_index]:
		"PT-BR":
			start_button.text = "ENTRAR"
			options_button.text = "OPCOES"
			quit_button.text = "SAIR"
			fullscreen_toggle.text = "Tela cheia"
			close_options_button.text = "Voltar"
		"EN":
			start_button.text = "PLAY"
			options_button.text = "OPTIONS"
			quit_button.text = "QUIT"
			fullscreen_toggle.text = "Fullscreen"
			close_options_button.text = "Back"
		"ES":
			start_button.text = "JUGAR"
			options_button.text = "OPCIONES"
			quit_button.text = "SALIR"
			fullscreen_toggle.text = "Pantalla completa"
			close_options_button.text = "Volver"
