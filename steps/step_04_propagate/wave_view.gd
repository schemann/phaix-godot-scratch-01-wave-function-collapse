extends Node2D
## Draws the wave: every option of a cell as a tiny tile, always in the same place.

const CELL := 64.0
const DARK := Color(0.11, 0.12, 0.15)

@onready var main: Node2D = owner


func _draw() -> void:
	var source: TileSetAtlasSource = main.tiles.tile_set.get_source(main.SOURCE)
	var names: Array = main.TILES.keys()
	var cols := ceili(sqrt(names.size()))
	var size := CELL / cols
	for cell: Vector2i in main.wave:
		var options: Array = main.wave[cell]
		var corner := Vector2(cell) * CELL
		if options.size() == 1:
			continue
		draw_rect(Rect2(corner, Vector2(CELL, CELL)), DARK)
		for tile: String in options:
			var index := names.find(tile)
			var slot := Vector2(index % cols, index / float(cols)).floor() * size
			var box := Rect2(corner + slot, Vector2(size, size)).grow(-1.0)
			var region := source.get_tile_texture_region(main.TILES[tile])
			draw_texture_rect_region(source.texture, box, region)
