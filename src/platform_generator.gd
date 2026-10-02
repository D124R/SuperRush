extends Node2D

@export var platform_scene: PackedScene  # sua cena de plataforma
@export var num_platforms: int = 10       # quantidade de plataformas
@export var min_gap: int = 80            # distância mínima entre plataformas
@export var max_gap: int = 200           # distância máxima entre plataformas
@export var min_height: int = -150       # altura mínima
@export var max_height: int = -50        # altura máxima
@export var start_x: float = 200.0       # onde começa a gerar

func _ready():
	generate_platforms()

func generate_platforms():
	var current_x = start_x
	var current_y = 300.0  # altura base inicial

	for i in range(num_platforms):
		var platform = platform_scene.instantiate()

		# posição aleatória
		current_x += randi_range(min_gap, max_gap)
		current_y += randi_range(min_height, max_height)

		# limita a altura para não sair da tela
		current_y = clamp(current_y, 100.0, 400.0)

		platform.position = Vector2(current_x, current_y)
		add_child(platform)
