extends Node


# ============================================================
# TIPOS DE SALA
# ============================================================

enum RoomType {
	START,
	CORRIDOR,
	ENEMY_ROOM,
	SPECIAL_ROOM,
	BOSS_ROOM
}


# ============================================================
# ALTURAS DE CONEXÃO
# ============================================================

enum ConnectionHeight {
	LOW,
	MIDDLE,
	HIGH
}


# ============================================================
# CONFIGURAÇÕES
# ============================================================

@export_category("Mapa")
@export var floor_y: int = 7
@export var dirt_depth: int = 3


@export_category("Tamanho das Salas")
@export var start_width: int = 14
@export var corridor_width: int = 20
@export var enemy_room_width: int = 30
@export var special_room_width: int = 26
@export var boss_room_width: int = 42


@export_category("Visual das Salas")
@export var wall_height: int = 6
@export var wall_width: int = 2


@export_category("Plataformas")
@export var platform_width: int = 7


@export_category("Seed")
@export var level_seed: int = 12345
@export var random_seed_on_start: bool = false


@export_category("Nova Fase")
@export var regenerate_key: Key = KEY_R


# ============================================================
# REFERÊNCIAS
# ============================================================

@onready var tile_map: TileMapLayer = $"../TileMapLayer"

@onready var seed_label: Label = get_node_or_null(
	"../CanvasLayer/SeedLabel"
)


# ============================================================
# TILES
# ============================================================

const SOURCE_ID: int = 0

const CHAO: Vector2i = Vector2i(4, 1)
const TERRA: Vector2i = Vector2i(4, 4)


# ============================================================
# RANDOM
# ============================================================

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ============================================================
# INFORMAÇÕES DO MÓDULO ATUAL
# ============================================================

var current_exit: ConnectionHeight = ConnectionHeight.LOW


# ============================================================
# INÍCIO
# ============================================================

func _ready() -> void:

	if random_seed_on_start:
		level_seed = randi()

	rng.seed = level_seed

	generate_level()


# ============================================================
# TECLA R
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == regenerate_key:

				nova_fase()


# ============================================================
# NOVA FASE
# ============================================================

func nova_fase() -> void:

	level_seed = randi()

	rng.seed = level_seed

	generate_level()


# ============================================================
# GERAR FASE
# ============================================================

func generate_level() -> void:

	tile_map.clear()

	var x: int = 0

	print("")
	print("================================")
	print("GERANDO FASE")
	print("SEED: ", level_seed)
	print("================================")


	# ========================================================
	# START
	# ========================================================

	x = gerar_modulo(
		RoomType.START,
		x
	)


	# ========================================================
	# CORREDOR
	# ========================================================

	x = gerar_modulo(
		RoomType.CORRIDOR,
		x
	)


	# ========================================================
	# ENEMY ROOM
	# ========================================================

	x = gerar_modulo(
		RoomType.ENEMY_ROOM,
		x
	)


	# ========================================================
	# CORREDOR
	# ========================================================

	x = gerar_modulo(
		RoomType.CORRIDOR,
		x
	)


	# ========================================================
	# SPECIAL ROOM
	# ========================================================

	x = gerar_modulo(
		RoomType.SPECIAL_ROOM,
		x
	)


	# ========================================================
	# CORREDOR
	# ========================================================

	x = gerar_modulo(
		RoomType.CORRIDOR,
		x
	)


	# ========================================================
	# ENEMY ROOM
	# ========================================================

	x = gerar_modulo(
		RoomType.ENEMY_ROOM,
		x
	)


	# ========================================================
	# CORREDOR FINAL
	# ========================================================

	x = gerar_modulo(
		RoomType.CORRIDOR,
		x
	)


	# ========================================================
	# BOSS
	# ========================================================

	x = gerar_modulo(
		RoomType.BOSS_ROOM,
		x
	)


	# ========================================================
	# SEED
	# ========================================================

	if seed_label != null:

		seed_label.text = "SEED: " + str(level_seed)


	print("================================")
	print("FASE PRONTA!")
	print("LARGURA: ", x)
	print("================================")


# ============================================================
# GERAR MÓDULO
# ============================================================

func gerar_modulo(
	tipo: RoomType,
	start_x: int
) -> int:

	match tipo:

		# ====================================================
		# START
		# ====================================================

		RoomType.START:

			var start_exit: ConnectionHeight = ConnectionHeight.LOW

			print(
				"START | Saída: ",
				nome_conexao(start_exit)
			)

			gerar_start_modulo(
				start_x,
				start_exit
			)

			current_exit = start_exit

			return start_x + start_width


		# ====================================================
		# CORREDOR
		# ====================================================

		RoomType.CORRIDOR:

			var corridor_variant: int = escolher_corredor_compativel()

			var corridor_exit: ConnectionHeight = obter_saida_corredor(
				corridor_variant
			)

			print(
				"CORREDOR | Variante ",
				corridor_variant,
				" | Entrada: ",
				nome_conexao(current_exit),
				" | Saída: ",
				nome_conexao(corridor_exit)
			)

			gerar_corredor_modulo(
				start_x,
				corridor_variant,
				current_exit
			)

			current_exit = corridor_exit

			return start_x + corridor_width


		# ====================================================
		# ENEMY ROOM
		# ====================================================

		RoomType.ENEMY_ROOM:

			var enemy_variant: int = escolher_enemy_compativel()

			var enemy_exit: ConnectionHeight = obter_saida_enemy(
				enemy_variant
			)

			print(
				"ENEMY ROOM | Variante ",
				enemy_variant,
				" | Entrada: ",
				nome_conexao(current_exit),
				" | Saída: ",
				nome_conexao(enemy_exit)
			)

			gerar_enemy_room_modulo(
				start_x,
				enemy_variant,
				current_exit
			)

			current_exit = enemy_exit

			return start_x + enemy_room_width


		# ====================================================
		# SPECIAL ROOM
		# ====================================================

		RoomType.SPECIAL_ROOM:

			var special_variant: int = escolher_special_compativel()

			var special_exit: ConnectionHeight = obter_saida_special(
				special_variant
			)

			print(
				"SPECIAL ROOM | Variante ",
				special_variant,
				" | Entrada: ",
				nome_conexao(current_exit),
				" | Saída: ",
				nome_conexao(special_exit)
			)

			gerar_special_room_modulo(
				start_x,
				special_variant,
				current_exit
			)

			current_exit = special_exit

			return start_x + special_room_width


		# ====================================================
		# BOSS
		# ====================================================

		RoomType.BOSS_ROOM:

			print(
				"BOSS ROOM | Entrada: ",
				nome_conexao(current_exit)
			)

			gerar_boss_room_modulo(
				start_x,
				current_exit
			)

			current_exit = ConnectionHeight.LOW

			return start_x + boss_room_width


	return start_x


# ============================================================
# ESCOLHER CORREDOR COMPATÍVEL
# ============================================================

func escolher_corredor_compativel() -> int:

	var opcoes: Array[int] = []

	# Variante 0:
	# Entrada LOW -> saída LOW

	if current_exit == ConnectionHeight.LOW:

		opcoes.append(0)
		opcoes.append(1)
		opcoes.append(2)


	# Variante 1:
	# Pode receber LOW ou MIDDLE

	elif current_exit == ConnectionHeight.MIDDLE:

		opcoes.append(1)
		opcoes.append(2)


	# HIGH
	else:

		opcoes.append(2)


	return opcoes[rng.randi_range(0, opcoes.size() - 1)]


# ============================================================
# SAÍDA DO CORREDOR
# ============================================================

func obter_saida_corredor(
	variante: int
) -> ConnectionHeight:

	match variante:

		0:
			return ConnectionHeight.LOW

		1:
			return ConnectionHeight.MIDDLE

		2:
			return ConnectionHeight.HIGH

	return ConnectionHeight.LOW


# ============================================================
# ESCOLHER ENEMY COMPATÍVEL
# ============================================================

func escolher_enemy_compativel() -> int:

	var opcoes: Array[int] = []

	if current_exit == ConnectionHeight.LOW:

		opcoes.append(0)
		opcoes.append(1)

	elif current_exit == ConnectionHeight.MIDDLE:

		opcoes.append(1)
		opcoes.append(2)

	else:

		opcoes.append(2)


	return opcoes[rng.randi_range(0, opcoes.size() - 1)]


# ============================================================
# SAÍDA ENEMY
# ============================================================

func obter_saida_enemy(
	variante: int
) -> ConnectionHeight:

	match variante:

		0:
			return ConnectionHeight.LOW

		1:
			return ConnectionHeight.MIDDLE

		2:
			return ConnectionHeight.HIGH

	return ConnectionHeight.LOW


# ============================================================
# ESCOLHER SPECIAL COMPATÍVEL
# ============================================================

func escolher_special_compativel() -> int:

	var opcoes: Array[int] = []

	if current_exit == ConnectionHeight.LOW:

		opcoes.append(0)
		opcoes.append(1)

	elif current_exit == ConnectionHeight.MIDDLE:

		opcoes.append(0)
		opcoes.append(1)

	else:

		opcoes.append(1)


	return opcoes[rng.randi_range(0, opcoes.size() - 1)]


# ============================================================
# SAÍDA SPECIAL
# ============================================================

func obter_saida_special(
	variante: int
) -> ConnectionHeight:

	match variante:

		0:
			return ConnectionHeight.MIDDLE

		1:
			return ConnectionHeight.LOW

	return ConnectionHeight.LOW


# ============================================================
# NOME DA CONEXÃO
# ============================================================

func nome_conexao(
	conexao: ConnectionHeight
) -> String:

	match conexao:

		ConnectionHeight.LOW:
			return "BAIXA"

		ConnectionHeight.MIDDLE:
			return "MEDIA"

		ConnectionHeight.HIGH:
			return "ALTA"

	return "DESCONHECIDA"


# ============================================================
# START
# ============================================================

func gerar_start_modulo(
	start_x: int,
	exit_height: ConnectionHeight
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + start_width
	):

		criar_coluna(
			tile_x,
			floor_y
		)

	criar_parede(
		start_x,
		floor_y,
		wall_height
	)

	criar_parede(
		start_x + start_width - 1,
		floor_y,
		wall_height
	)


# ============================================================
# CORREDOR
# ============================================================

func gerar_corredor_modulo(
	start_x: int,
	variante: int,
	entrada: ConnectionHeight
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + corridor_width
	):

		criar_coluna(
			tile_x,
			floor_y
		)


	# ========================================================
	# VARIANTE 0 — BAIXA
	# ========================================================

	if variante == 0:

		criar_plataforma(
			start_x + 5,
			floor_y - 2,
			6
		)


	# ========================================================
	# VARIANTE 1 — MÉDIA
	# ========================================================

	elif variante == 1:

		criar_plataforma(
			start_x + 3,
			floor_y - 2,
			5
		)

		criar_plataforma(
			start_x + 12,
			floor_y - 3,
			6
		)


	# ========================================================
	# VARIANTE 2 — ALTA
	# ========================================================

	else:

		criar_plataforma(
			start_x + 4,
			floor_y - 3,
			6
		)

		criar_plataforma(
			start_x + 13,
			floor_y - 4,
			6
		)


	# Entrada visual
	criar_entrada(
		start_x,
		entrada
	)

	# Saída visual
	criar_saida(
		start_x + corridor_width - 1,
		obter_saida_corredor(variante)
	)


# ============================================================
# ENEMY ROOM
# ============================================================

func gerar_enemy_room_modulo(
	start_x: int,
	variante: int,
	entrada: ConnectionHeight
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + enemy_room_width
	):

		criar_coluna(
			tile_x,
			floor_y
		)


	criar_parede(
		start_x,
		floor_y,
		wall_height
	)

	criar_parede(
		start_x + enemy_room_width - 1,
		floor_y,
		wall_height
	)


	# ========================================================
	# VARIANTE 0
	# ========================================================

	if variante == 0:

		criar_plataforma(
			start_x + 4,
			floor_y - 2,
			platform_width
		)

		criar_plataforma(
			start_x + enemy_room_width - 11,
			floor_y - 2,
			platform_width
		)


	# ========================================================
	# VARIANTE 1
	# ========================================================

	elif variante == 1:

		criar_plataforma(
			start_x + 5,
			floor_y - 3,
			8
		)

		criar_plataforma(
			start_x + 17,
			floor_y - 2,
			7
		)


	# ========================================================
	# VARIANTE 2
	# ========================================================

	else:

		criar_plataforma(
			start_x + 4,
			floor_y - 2,
			6
		)

		criar_plataforma(
			start_x + 12,
			floor_y - 3,
			8
		)

		criar_plataforma(
			start_x + 23,
			floor_y - 2,
			6
		)


	criar_entrada(
		start_x,
		entrada
	)

	criar_saida(
		start_x + enemy_room_width - 1,
		obter_saida_enemy(variante)
	)


# ============================================================
# SPECIAL ROOM
# ============================================================

func gerar_special_room_modulo(
	start_x: int,
	variante: int,
	entrada: ConnectionHeight
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + special_room_width
	):

		criar_coluna(
			tile_x,
			floor_y
		)


	criar_parede(
		start_x,
		floor_y,
		wall_height
	)

	criar_parede(
		start_x + special_room_width - 1,
		floor_y,
		wall_height
	)


	# ========================================================
	# VARIANTE 0
	# ========================================================

	if variante == 0:

		var center_x: int = (
			start_x + special_room_width / 2
		)

		criar_plataforma(
			center_x - 4,
			floor_y - 3,
			8
		)


	# ========================================================
	# VARIANTE 1
	# ========================================================

	else:

		criar_plataforma(
			start_x + 4,
			floor_y - 2,
			6
		)

		criar_plataforma(
			start_x + special_room_width - 10,
			floor_y - 2,
			6
		)

		criar_plataforma(
			start_x + 9,
			floor_y - 4,
			8
		)


	criar_entrada(
		start_x,
		entrada
	)

	criar_saida(
		start_x + special_room_width - 1,
		obter_saida_special(variante)
	)


# ============================================================
# BOSS ROOM
# ============================================================

func gerar_boss_room_modulo(
	start_x: int,
	entrada: ConnectionHeight
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + boss_room_width
	):

		criar_coluna(
			tile_x,
			floor_y
		)


	criar_parede(
		start_x,
		floor_y,
		wall_height
	)

	criar_parede(
		start_x + boss_room_width - 1,
		floor_y,
		wall_height
	)


	# Plataforma esquerda
	criar_plataforma(
		start_x + 5,
		floor_y - 3,
		8
	)


	# Plataforma direita
	criar_plataforma(
		start_x + boss_room_width - 13,
		floor_y - 3,
		8
	)


	# Plataforma central
	var center_x: int = (
		start_x + boss_room_width / 2
	)

	criar_plataforma(
		center_x - 5,
		floor_y - 2,
		10
	)


	criar_entrada(
		start_x,
		entrada
	)


# ============================================================
# ENTRADA VISUAL
# ============================================================

func criar_entrada(
	tile_x: int,
	altura: ConnectionHeight
) -> void:

	var y: int = floor_y

	match altura:

		ConnectionHeight.LOW:
			y = floor_y

		ConnectionHeight.MIDDLE:
			y = floor_y - 2

		ConnectionHeight.HIGH:
			y = floor_y - 4


	# Cria uma pequena plataforma de ligação
	for i: int in range(3):

		tile_map.set_cell(
			Vector2i(
				tile_x + i,
				y
			),
			SOURCE_ID,
			CHAO
		)


# ============================================================
# SAÍDA VISUAL
# ============================================================

func criar_saida(
	tile_x: int,
	altura: ConnectionHeight
) -> void:

	var y: int = floor_y

	match altura:

		ConnectionHeight.LOW:
			y = floor_y

		ConnectionHeight.MIDDLE:
			y = floor_y - 2

		ConnectionHeight.HIGH:
			y = floor_y - 4


	for i: int in range(3):

		tile_map.set_cell(
			Vector2i(
				tile_x - i,
				y
			),
			SOURCE_ID,
			CHAO
		)


# ============================================================
# CRIAR PLATAFORMA
# ============================================================

func criar_plataforma(
	start_x: int,
	y: int,
	width: int
) -> void:

	for tile_x: int in range(
		start_x,
		start_x + width
	):

		tile_map.set_cell(
			Vector2i(tile_x, y),
			SOURCE_ID,
			CHAO
		)

		for depth: int in range(1, 3):

			tile_map.set_cell(
				Vector2i(
					tile_x,
					y + depth
				),
				SOURCE_ID,
				TERRA
			)


# ============================================================
# CRIAR COLUNA
# ============================================================

func criar_coluna(
	tile_x: int,
	tile_y: int
) -> void:

	tile_map.set_cell(
		Vector2i(
			tile_x,
			tile_y
		),
		SOURCE_ID,
		CHAO
	)

	for depth: int in range(
		1,
		dirt_depth + 1
	):

		tile_map.set_cell(
			Vector2i(
				tile_x,
				tile_y + depth
			),
			SOURCE_ID,
			TERRA
		)


# ============================================================
# CRIAR PAREDE
# ============================================================

func criar_parede(
	tile_x: int,
	base_y: int,
	height: int
) -> void:

	for y: int in range(
		base_y - height,
		base_y
	):

		for offset: int in range(
			wall_width
		):

			tile_map.set_cell(
				Vector2i(
					tile_x + offset,
					y
				),
				SOURCE_ID,
				TERRA
			)
