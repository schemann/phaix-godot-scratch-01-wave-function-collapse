extends Node2D

const SIZE := Vector2i(20, 10)
const SOURCE := 0
## Every tile we use, and where it sits in the atlas.
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

var rng := RandomNumberGenerator.new()

@onready var tiles: TileMapLayer = $Map/Tiles
@onready var info: Label = $Bar/Info


func _ready() -> void:
	start(map_seed)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("new_map"):
		start(map_seed + 1)


func start(new_seed: int) -> void:
	map_seed = new_seed
	rng.seed = map_seed
	tiles.clear()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var tile: String = TILES.keys()[rng.randi_range(0, TILES.size() - 1)]
			tiles.set_cell(Vector2i(x, y), SOURCE, TILES[tile])
	show_state()


func show_state() -> void:
	info.text = "Seed %d" % map_seed
