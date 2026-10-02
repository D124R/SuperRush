extends Node

enum Direction {
	RIGHT,
	LEFT,
	DOWN,
	UP,
}

class TilePattern:
	var tiles := PackedInt32Array()
	var weight := 1


const EMPTY_TILE := Vector4i(-1, -1, -1, -1)
const OPPOSITE_DIRECTION := [
	Direction.LEFT,
	Direction.RIGHT,
	Direction.UP,
	Direction.DOWN,
]

@export_category("WFC")
@export_range(2, 4, 1) var pattern_size := 2
@export_range(8, 128, 1) var generated_width := 40
@export_range(1, 20, 1) var max_attempts := 16

@export_category("Seed")
@export var level_seed := 12345
@export var regenerate_key: Key = KEY_R

@onready var tile_map: TileMap = get_node_or_null("../Level") as TileMap

var rng := RandomNumberGenerator.new()
var sample_bounds := Rect2i()
var source_bounds := Rect2i()
var sample_tiles := PackedInt32Array()
var generated_cells: Array[Vector2i] = []


func _ready() -> void:
	if tile_map == null:
		push_error("WFCGenerator precisa encontrar o TileMap ../Level.")
		return

	if pattern_size < 2:
		push_error("O tamanho dos padrões WFC precisa ser pelo menos 2.")
		return

	source_bounds = tile_map.get_used_rect()
	if source_bounds.size.x < pattern_size or source_bounds.size.y < pattern_size:
		push_error("A fase precisa ter tiles suficientes para aprender padrões WFC.")
		return

	sample_bounds = source_bounds.grow(pattern_size - 1)
	_capture_sample()
	print("WFC: aprendendo padroes da fase...")
	generate_level()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == regenerate_key:
			level_seed = randi()
			generate_level()


func generate_level() -> void:
	var patterns := _learn_patterns()
	print(
		"WFC: ", patterns.size(), " padroes | amostra: ",
		sample_bounds.size, " | mapa novo: ",
		generated_width, " x ", sample_bounds.size.y
	)
	if patterns.is_empty():
		push_error("O WFC não encontrou padrões válidos na fase atual.")
		return

	var output_height := sample_bounds.size.y
	var anchor_height := output_height - pattern_size + 1
	if anchor_height <= 0:
		push_error("A amostra da fase é baixa demais para gerar o WFC.")
		return

	var compatibility := _build_compatibility(patterns)
	var boundary_x := source_bounds.end.x
	var anchor_origin := Vector2i(
		boundary_x - (pattern_size - 1),
		sample_bounds.position.y
	)
	var width_options: Array[int] = [generated_width]
	while width_options.back() > 16:
		var reduced_width := maxi(16, floori(float(width_options.back()) * 0.75))
		if reduced_width >= width_options.back():
			break
		width_options.append(reduced_width)

	var attempt_number := 0
	for width_index in range(width_options.size()):
		var attempt_width: int = width_options[width_index]
		for _attempt in range(max_attempts):
			rng.seed = level_seed + attempt_number
			attempt_number += 1
			var wave := _create_wave(
				attempt_width * anchor_height,
				patterns.size()
			)
			var versions: Array[int] = []
			versions.resize(wave.size())
			var heap: Array[Vector3i] = []
			if not _constrain_boundary(
				wave,
				attempt_width,
				anchor_height,
				patterns,
				boundary_x
			):
				continue

			var initial_queue: Array[int] = []
			for y in range(anchor_height):
				initial_queue.append(y * attempt_width)

			if not _propagate(
				wave,
				attempt_width,
				anchor_height,
				patterns,
				compatibility,
				initial_queue,
				versions,
				heap,
				false
			):
				continue
			if not _collapse(
				wave,
				attempt_width,
				anchor_height,
				patterns,
				compatibility,
				versions
			):
				continue

			_clear_previous_extension()
			_write_extension(
				wave,
				attempt_width,
				anchor_height,
				patterns,
				anchor_origin,
				boundary_x
			)
			print(
				"WFC pronto | seed: ", level_seed,
				" | padroes: ", patterns.size(),
				" | largura: ", attempt_width,
				" tiles"
			)
			return

		if width_index + 1 < width_options.size():
			push_warning(
				"WFC: seed sem solucao em %d tiles; tentando largura menor."
				% attempt_width
			)

	push_error(
		"O WFC nao encontrou uma solucao valida nas larguras testadas. "
		+ "A extensao anterior da fase foi mantida."
	)


func _capture_sample() -> void:
	sample_tiles.resize(sample_bounds.size.x * sample_bounds.size.y * 4)
	for tile_index in range(sample_bounds.size.x * sample_bounds.size.y):
		_set_sample_tile(tile_index, EMPTY_TILE)

	for cell in tile_map.get_used_cells(0):
		if not sample_bounds.has_point(cell):
			continue
		var source_id := tile_map.get_cell_source_id(0, cell)
		var atlas := tile_map.get_cell_atlas_coords(0, cell)
		var alternative := tile_map.get_cell_alternative_tile(0, cell)
		var tile := Vector4i(source_id, atlas.x, atlas.y, alternative)
		_set_sample_tile(_sample_index(cell), tile)


func _set_sample_tile(tile_index: int, tile: Vector4i) -> void:
	var offset := tile_index * 4
	sample_tiles[offset] = tile.x
	sample_tiles[offset + 1] = tile.y
	sample_tiles[offset + 2] = tile.z
	sample_tiles[offset + 3] = tile.w


func _sample_index(cell: Vector2i) -> int:
	var x := cell.x - sample_bounds.position.x
	var y := cell.y - sample_bounds.position.y
	return y * sample_bounds.size.x + x


func _get_sample_tile(cell: Vector2i) -> Vector4i:
	var offset := _sample_index(cell) * 4
	return Vector4i(
		sample_tiles[offset],
		sample_tiles[offset + 1],
		sample_tiles[offset + 2],
		sample_tiles[offset + 3]
	)


func _learn_patterns() -> Array[TilePattern]:
	var patterns: Array[TilePattern] = []
	var pattern_lookup: Dictionary = {}

	for y in range(sample_bounds.size.y - pattern_size + 1):
		for x in range(sample_bounds.size.x - pattern_size + 1):
			var pattern := TilePattern.new()
			var key := ""

			for pattern_y in range(pattern_size):
				for pattern_x in range(pattern_size):
					var sample_cell := Vector2i(
						sample_bounds.position.x + x + pattern_x,
						sample_bounds.position.y + y + pattern_y
					)
					var tile := _get_sample_tile(sample_cell)
					_append_tile(pattern.tiles, tile)
					key += _tile_key(tile) + ";"

			if pattern_lookup.has(key):
				patterns[pattern_lookup[key]].weight += 1
			else:
				pattern_lookup[key] = patterns.size()
				patterns.append(pattern)

	return patterns


func _append_tile(target: PackedInt32Array, tile: Vector4i) -> void:
	target.append(tile.x)
	target.append(tile.y)
	target.append(tile.z)
	target.append(tile.w)


func _tile_key(tile: Vector4i) -> String:
	return "%d,%d,%d,%d" % [tile.x, tile.y, tile.z, tile.w]


func _pattern_tile(pattern: TilePattern, x: int, y: int) -> Vector4i:
	var offset := (y * pattern_size + x) * 4
	return Vector4i(
		pattern.tiles[offset],
		pattern.tiles[offset + 1],
		pattern.tiles[offset + 2],
		pattern.tiles[offset + 3]
	)


func _pattern_edge_key(pattern: TilePattern, direction: int) -> String:
	var key := ""
	match direction:
		Direction.LEFT, Direction.RIGHT:
			var start_x := 0 if direction == Direction.LEFT else 1
			for y in range(pattern_size):
				for x in range(start_x, start_x + pattern_size - 1):
					key += _tile_key(_pattern_tile(pattern, x, y)) + ";"
		Direction.UP, Direction.DOWN:
			var start_y := 0 if direction == Direction.UP else 1
			for y in range(start_y, start_y + pattern_size - 1):
				for x in range(pattern_size):
					key += _tile_key(_pattern_tile(pattern, x, y)) + ";"
	return key


func _build_compatibility(patterns: Array[TilePattern]) -> Array:
	var edge_lookup: Array[Dictionary] = []
	var edge_keys: Array = []

	for direction in range(4):
		edge_lookup.append({})
		edge_keys.append([])

	for pattern_index in range(patterns.size()):
		for direction in range(4):
			var key := _pattern_edge_key(patterns[pattern_index], direction)
			edge_keys[direction].append(key)
			if not edge_lookup[direction].has(key):
				edge_lookup[direction][key] = PackedInt32Array()
			var matching_patterns: PackedInt32Array = edge_lookup[direction][key]
			matching_patterns.append(pattern_index)
			edge_lookup[direction][key] = matching_patterns

	var compatibility: Array = []
	for direction in range(4):
		var allowed_for_direction: Array[PackedInt32Array] = []
		var neighbor_edge: int = OPPOSITE_DIRECTION[direction]
		for pattern_index in range(patterns.size()):
			var source_edge: String = edge_keys[direction][pattern_index]
			allowed_for_direction.append(
				edge_lookup[neighbor_edge].get(source_edge, PackedInt32Array())
			)
		compatibility.append(allowed_for_direction)

	return compatibility


func _create_wave(cell_count: int, pattern_count: int) -> Array[PackedByteArray]:
	var wave: Array[PackedByteArray] = []
	for cell_index in range(cell_count):
		var domain := PackedByteArray()
		domain.resize(pattern_count)
		for pattern_index in range(pattern_count):
			domain[pattern_index] = 1
		wave.append(domain)
	return wave


func _constrain_boundary(
	wave: Array[PackedByteArray],
	width: int,
	height: int,
	patterns: Array[TilePattern],
	boundary_x: int
) -> bool:
	var overlap := pattern_size - 1
	var sample_start_x := boundary_x - overlap

	for y in range(height):
		var sample_edge := ""
		for pattern_y in range(pattern_size):
			for x in range(overlap):
				var sample_cell := Vector2i(
					sample_start_x + x,
					sample_bounds.position.y + y + pattern_y
				)
				sample_edge += _tile_key(_get_sample_tile(sample_cell)) + ";"

		var domain := wave[y * width]
		var has_candidate := false
		for pattern_index in range(patterns.size()):
			if _pattern_edge_key(patterns[pattern_index], Direction.LEFT) != sample_edge:
				domain[pattern_index] = 0
			elif domain[pattern_index] != 0:
				has_candidate = true
		wave[y * width] = domain
		if not has_candidate:
			return false

	return true


func _propagate(
	wave: Array[PackedByteArray],
	width: int,
	height: int,
	patterns: Array[TilePattern],
	compatibility: Array,
	queue: Array[int],
	versions: Array[int],
	heap: Array[Vector3i],
	update_heap: bool
) -> bool:
	var queue_index := 0
	while queue_index < queue.size():
		var cell_index := queue[queue_index]
		queue_index += 1
		var cell_x := cell_index % width
		var cell_y := floori(float(cell_index) / width)

		for direction in range(4):
			var neighbor_x := cell_x
			var neighbor_y := cell_y
			match direction:
				Direction.RIGHT:
					neighbor_x += 1
				Direction.LEFT:
					neighbor_x -= 1
				Direction.DOWN:
					neighbor_y += 1
				Direction.UP:
					neighbor_y -= 1

			if neighbor_x < 0 or neighbor_x >= width or neighbor_y < 0 or neighbor_y >= height:
				continue

			var neighbor_index := neighbor_y * width + neighbor_x
			var supported := PackedByteArray()
			supported.resize(patterns.size())
			var source_domain := wave[cell_index]
			var direction_compatibility: Array = compatibility[direction]

			for pattern_index in range(patterns.size()):
				if source_domain[pattern_index] == 0:
					continue
				var compatible_patterns: PackedInt32Array = direction_compatibility[pattern_index]
				for compatible_pattern in compatible_patterns:
					supported[compatible_pattern] = 1

			var neighbor_domain := wave[neighbor_index]
			var changed := false
			var has_candidate := false
			for pattern_index in range(patterns.size()):
				if neighbor_domain[pattern_index] != 0 and supported[pattern_index] == 0:
					neighbor_domain[pattern_index] = 0
					changed = true
				elif neighbor_domain[pattern_index] != 0:
					has_candidate = true

			if not has_candidate:
				return false
			if changed:
				wave[neighbor_index] = neighbor_domain
				if update_heap:
					versions[neighbor_index] += 1
					var entropy := _domain_entropy(neighbor_domain, patterns)
					if entropy > 0.0:
						_heap_push(
							heap,
							Vector3i(
								_entropy_priority(entropy),
								neighbor_index,
								versions[neighbor_index]
							)
						)
				queue.append(neighbor_index)

	return true


func _collapse(
	wave: Array[PackedByteArray],
	width: int,
	height: int,
	patterns: Array[TilePattern],
	compatibility: Array,
	versions: Array[int]
) -> bool:
	var heap: Array[Vector3i] = []
	for cell_index in range(wave.size()):
		var entropy := _domain_entropy(wave[cell_index], patterns)
		if entropy < 0.0:
			return false
		if entropy > 0.0:
			_heap_push(
				heap,
				Vector3i(_entropy_priority(entropy), cell_index, versions[cell_index])
			)

	while not heap.is_empty():
		var entry := _heap_pop(heap)
		var selected_cell := entry.y
		if entry.z != versions[selected_cell]:
			continue

		var domain := wave[selected_cell]
		if _domain_entropy(domain, patterns) <= 0.0:
			continue

		var chosen_pattern := _choose_pattern(domain, patterns)
		for pattern_index in range(patterns.size()):
			domain[pattern_index] = 1 if pattern_index == chosen_pattern else 0
		wave[selected_cell] = domain
		versions[selected_cell] += 1

		var queue: Array[int] = [selected_cell]
		if not _propagate(
			wave,
			width,
			height,
			patterns,
			compatibility,
			queue,
			versions,
			heap,
			true
		):
			return false

	return true


func _entropy_priority(entropy: float) -> int:
	return roundi(entropy * 1000000.0) * 1000 + rng.randi_range(0, 999)


func _heap_push(heap: Array[Vector3i], entry: Vector3i) -> void:
	heap.append(entry)
	var index := heap.size() - 1
	while index > 0:
		var parent := floori(float(index - 1) / 2.0)
		if heap[parent].x <= entry.x:
			break
		heap[index] = heap[parent]
		index = parent
	heap[index] = entry


func _heap_pop(heap: Array[Vector3i]) -> Vector3i:
	var first := heap[0]
	var last: Vector3i = heap.pop_back()
	if not heap.is_empty():
		var index := 0
		while true:
			var left := index * 2 + 1
			if left >= heap.size():
				break
			var right := left + 1
			var smaller_child := left
			if right < heap.size() and heap[right].x < heap[left].x:
				smaller_child = right
			if heap[smaller_child].x >= last.x:
				break
			heap[index] = heap[smaller_child]
			index = smaller_child
		heap[index] = last
	return first


func _domain_entropy(domain: PackedByteArray, patterns: Array[TilePattern]) -> float:
	var total_weight := 0.0
	var weighted_log_weight := 0.0
	var option_count := 0

	for pattern_index in range(patterns.size()):
		if domain[pattern_index] == 0:
			continue
		var weight := float(patterns[pattern_index].weight)
		total_weight += weight
		weighted_log_weight += weight * log(weight)
		option_count += 1

	if option_count == 0:
		return -1.0
	if option_count == 1:
		return 0.0
	return log(total_weight) - weighted_log_weight / total_weight


func _choose_pattern(domain: PackedByteArray, patterns: Array[TilePattern]) -> int:
	var total_weight := 0.0
	for pattern_index in range(patterns.size()):
		if domain[pattern_index] != 0:
			total_weight += patterns[pattern_index].weight

	var choice := rng.randf() * total_weight
	for pattern_index in range(patterns.size()):
		if domain[pattern_index] == 0:
			continue
		choice -= patterns[pattern_index].weight
		if choice <= 0.0:
			return pattern_index

	return domain.find(1)


func _clear_previous_extension() -> void:
	for cell in generated_cells:
		tile_map.erase_cell(0, cell)
	generated_cells.clear()


func _write_extension(
	wave: Array[PackedByteArray],
	width: int,
	height: int,
	patterns: Array[TilePattern],
	anchor_origin: Vector2i,
	boundary_x: int
) -> void:
	var output: Dictionary = {}

	for anchor_y in range(height):
		for anchor_x in range(width):
			var chosen_pattern := _chosen_pattern(wave[anchor_y * width + anchor_x])
			var pattern: TilePattern = patterns[chosen_pattern]
			for pattern_y in range(pattern_size):
				for pattern_x in range(pattern_size):
					var cell := anchor_origin + Vector2i(
						anchor_x + pattern_x,
						anchor_y + pattern_y
					)
					if cell.x < boundary_x:
						continue
					output[cell] = _pattern_tile(pattern, pattern_x, pattern_y)

	for cell: Vector2i in output:
		var tile: Vector4i = output[cell]
		generated_cells.append(cell)
		if tile.x < 0:
			tile_map.erase_cell(0, cell)
		else:
			tile_map.set_cell(
				0,
				cell,
				tile.x,
				Vector2i(tile.y, tile.z),
				tile.w
			)


func _chosen_pattern(domain: PackedByteArray) -> int:
	for pattern_index in range(domain.size()):
		if domain[pattern_index] != 0:
			return pattern_index
	return -1
