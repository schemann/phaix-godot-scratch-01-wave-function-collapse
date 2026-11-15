extends Node2D

enum { UP, RIGHT, DOWN, LEFT }

const SIZE := Vector2i(20, 10)
const SOURCE := 0
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Every tile by its four corners: top left, top right, bottom right, bottom left.
## g grass, s sand, d dirt, and where the tile sits in the atlas.
const TILES := {
	"gggg": Vector2i(4, 2),
	"ssss": Vector2i(1, 1),
	"ggsg": Vector2i(0, 0),
	"ggss": Vector2i(1, 0),
	"gggs": Vector2i(2, 0),
	"ssgs": Vector2i(3, 0),
	"sssg": Vector2i(4, 0),
	"gssg": Vector2i(0, 1),
	"sggs": Vector2i(2, 1),
	"sgss": Vector2i(3, 1),
	"gsss": Vector2i(4, 1),
	"gsgg": Vector2i(0, 2),
	"ssgg": Vector2i(1, 2),
	"sggg": Vector2i(2, 2),
	"dddd": Vector2i(6, 1),
	"ggdg": Vector2i(5, 0),
	"ggdd": Vector2i(6, 0),
	"gggd": Vector2i(7, 0),
	"ddgd": Vector2i(8, 0),
	"dddg": Vector2i(9, 0),
	"gddg": Vector2i(5, 1),
	"dggd": Vector2i(7, 1),
	"dgdd": Vector2i(8, 1),
	"gddd": Vector2i(9, 1),
	"gdgg": Vector2i(5, 2),
	"ddgg": Vector2i(6, 2),
	"dggg": Vector2i(7, 2),
	"ddsd": Vector2i(10, 0),
	"ddss": Vector2i(11, 0),
	"ddds": Vector2i(12, 0),
	"ssds": Vector2i(13, 0),
	"sssd": Vector2i(14, 0),
	"dssd": Vector2i(10, 1),
	"sdds": Vector2i(12, 1),
	"sdss": Vector2i(13, 1),
	"dsss": Vector2i(14, 1),
	"dsdd": Vector2i(10, 2),
	"ssdd": Vector2i(11, 2),
	"sddd": Vector2i(12, 2),
}
const NONE := Vector2i(-1, -1)
## How often a tile comes up. Every tile that is not in here has weight 1.
const WEIGHTS := {"gggg": 16.0, "ssss": 4.0, "dddd": 4.0}

@export var map_seed := 1
@export var step_time := 0.03

var rules := {}
var wave: Dictionary[Vector2i, Array] = {}
var rng := RandomNumberGenerator.new()
var stuck := NONE
var restarts := 0
var wait := 0.0

@onready var tiles: TileMapLayer = $Map/Tiles
@onready var view: Node2D = $Map/WaveView
@onready var info: Label = $Bar/Info


func _ready() -> void:
	build_rules()
	start(map_seed)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("new_map"):
		start(map_seed + 1)
	if Input.is_action_pressed("step"):
		wait -= delta
		if wait <= 0.0:
			step()
			wait = step_time if stuck == NONE else 1.0
	else:
		wait = 0.0


## The two corners on one side of a tile, read left to right or top to bottom.
func edge(tile: String, direction: int) -> String:
	match direction:
		UP:
			return tile[0] + tile[1]
		RIGHT:
			return tile[1] + tile[2]
		DOWN:
			return tile[3] + tile[2]
	return tile[0] + tile[3]


## rules[tile][direction]: every tile that may sit next to tile in that direction.
func build_rules() -> void:
	for tile: String in TILES:
		var sides: Array = []
		for direction: int in 4:
			var fits: Array[String] = []
			for other: String in TILES:
				if edge(tile, direction) == edge(other, (direction + 2) % 4):
					fits.append(other)
			sides.append(fits)
		rules[tile] = sides


func fits(tile: String, other: String, direction: int) -> bool:
	return rules[tile][direction].has(other)


## The tile on a cell of the TileMapLayer, "" for an empty cell.
func tile_at(cell: Vector2i) -> String:
	var tile: Variant = TILES.find_key(tiles.get_cell_atlas_coords(cell))
	return tile if tile is String else ""


func start(new_seed: int) -> void:
	map_seed = new_seed
	rng.seed = map_seed
	stuck = NONE
	tiles.clear()
	wave.clear()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			wave[Vector2i(x, y)] = TILES.keys()
	show_state()


func step() -> void:
	if stuck != NONE:
		restarts += 1
		start(map_seed + 1)
		return
	var cell := lowest_entropy()
	if cell == NONE:
		return
	collapse(cell)
	propagate(cell)
	show_state()


func collapse(cell: Vector2i) -> void:
	var options: Array = wave[cell]
	var weights := PackedFloat32Array()
	for tile: String in options:
		weights.append(WEIGHTS.get(tile, 1.0))
	place(cell, options[rng.rand_weighted(weights)])


func place(cell: Vector2i, tile: String) -> void:
	wave[cell] = [tile]
	tiles.set_cell(cell, SOURCE, TILES[tile])


## A cell lost options, so its neighbours may lose some too.
## The stack holds every cell whose options changed.
func propagate(start_cell: Vector2i) -> void:
	var stack: Array[Vector2i] = [start_cell]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		for direction: int in 4:
			var next: Vector2i = cell + DIRECTIONS[direction]
			if not wave.has(next):
				continue
			var allowed := {}
			for tile: String in wave[cell]:
				for other: String in rules[tile][direction]:
					allowed[other] = true
			var kept: Array = []
			for other: String in wave[next]:
				if allowed.has(other):
					kept.append(other)
			if kept.size() == wave[next].size():
				continue
			wave[next] = kept
			if kept.is_empty():
				stuck = next
				return
			if kept.size() == 1:
				place(next, kept[0])
			stack.append(next)


## The Shannon entropy: one likely tile among rare ones is almost certain.
func entropy(options: Array) -> float:
	var total := 0.0
	var weighted_logs := 0.0
	for tile: String in options:
		var weight: float = WEIGHTS.get(tile, 1.0)
		total += weight
		weighted_logs += weight * log(weight)
	return log(total) - weighted_logs / total


## The open cell with the lowest entropy. A tiny random number breaks ties.
func lowest_entropy() -> Vector2i:
	var best := NONE
	var lowest := INF
	for cell: Vector2i in wave:
		if wave[cell].size() < 2:
			continue
		var value := entropy(wave[cell]) + rng.randf() * 0.001
		if value < lowest:
			lowest = value
			best = cell
	return best


func show_state() -> void:
	$Map/Seams.queue_redraw()
	view.queue_redraw()
	info.text = "Seed %d    Restarts %d" % [map_seed, restarts]
