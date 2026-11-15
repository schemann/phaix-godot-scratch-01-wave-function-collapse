extends Node2D

enum { UP, RIGHT, DOWN, LEFT }

const SIZE := Vector2i(20, 10)
const SOURCE := 0
## Every tile by its four corners: top left, top right, bottom right, bottom left.
## g grass, s sand, and where the tile sits in the atlas.
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
}

@export var map_seed := 1

var rules := {}
var wave: Dictionary[Vector2i, Array] = {}
var rng := RandomNumberGenerator.new()

@onready var tiles: TileMapLayer = $Map/Tiles
@onready var view: Node2D = $Map/WaveView
@onready var info: Label = $Bar/Info


func _ready() -> void:
	build_rules()
	start(map_seed)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("new_map"):
		start(map_seed + 1)


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
	tiles.clear()
	wave.clear()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			wave[Vector2i(x, y)] = TILES.keys()
	show_state()


func show_state() -> void:
	$Map/Seams.queue_redraw()
	view.queue_redraw()
	info.text = "Seed %d" % map_seed
