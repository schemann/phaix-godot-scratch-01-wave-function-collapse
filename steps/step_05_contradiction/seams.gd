extends Node2D
## Frames every tile in red that breaks a rule with its right or lower neighbour.

const CELL := 64.0
const RED := Color(0.9, 0.18, 0.18)

@onready var main: Node2D = owner


func _draw() -> void:
	for cell: Vector2i in main.tiles.get_used_cells():
		var tile: String = main.tile_at(cell)
		var right: String = main.tile_at(cell + Vector2i.RIGHT)
		var below: String = main.tile_at(cell + Vector2i.DOWN)
		if right != "" and not main.fits(tile, right, main.RIGHT):
			frame(cell)
			frame(cell + Vector2i.RIGHT)
		if below != "" and not main.fits(tile, below, main.DOWN):
			frame(cell)
			frame(cell + Vector2i.DOWN)


func frame(cell: Vector2i) -> void:
	var box := Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)).grow(-4.0)
	draw_rect(box, RED, false, 4.0)
