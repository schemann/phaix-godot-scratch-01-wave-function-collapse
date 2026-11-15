extends SceneTree
## The project's check and the source of every figure the video says: `godot --headless --path . -s tests/run_tests.gd [-- --maps=1000]`.
## Exit code 0 when everything holds. Each MEASURE line is a figure for docs/plan.md, "Measured".

var failures := 0
var maps := 1000
var started := false


## The scenes need a running tree for their @onready nodes, so the checks run on the first frame.
func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--maps="):
			maps = int(argument.get_slice("=", 1))
	check_rules("step_01_rules", 14)
	check_rules("step_05_contradiction", 39)
	check_random_fill()
	run_maps("step_04_propagate", false)
	run_maps("step_05_contradiction", true)
	run_maps("step_06_entropy", true)
	run_maps("step_07_weights", true)
	print("FAILURES %d" % failures)
	quit(1 if failures > 0 else 0)
	return false


func expect(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)


func load_main(step: String) -> Node2D:
	var main: Node2D = (load("res://steps/%s/main.tscn" % step) as PackedScene).instantiate()
	root.add_child(main)
	return main


## Every tile has a neighbour in every direction, and a rule always holds both ways.
func check_rules(step: String, count: int) -> void:
	var main := load_main(step)
	expect(main.TILES.size() == count, "%s has %d tiles, not %d" % [step, main.TILES.size(), count])
	for tile: String in main.TILES:
		for direction: int in 4:
			expect(not main.rules[tile][direction].is_empty(), "%s: %s has no neighbour in direction %d" % [step, tile, direction])
			for other: String in main.rules[tile][direction]:
				expect(main.fits(other, tile, (direction + 2) % 4), "%s: %s next to %s holds one way only" % [step, tile, other])
	main.free()


## The random map of step 1 breaks the rules: the red frames of the video are real.
func check_random_fill() -> void:
	var main := load_main("step_01_rules")
	var broken := 0
	for cell: Vector2i in main.tiles.get_used_cells():
		var right: String = main.tile_at(cell + Vector2i.RIGHT)
		if right != "" and not main.fits(main.tile_at(cell), right, main.RIGHT):
			broken += 1
	print("MEASURE step_01_rules seed 1: %d of 190 left-right pairs break a rule" % broken)
	expect(broken > 0, "the random map of step 1 breaks no rule")
	main.free()


## Runs `maps` maps from seed 1 on, each until it is finished or stuck, and checks every finished map tile by tile.
func run_maps(step: String, has_stuck: bool) -> void:
	var main := load_main(step)
	var stuck_seeds: Array[int] = []
	var stuck_at: Array[int] = []
	var grass := 0
	var cells := 0
	for map_seed: int in range(1, maps + 1):
		main.start(map_seed)
		var steps := 0
		while true:
			var before: int = open_cells(main)
			if before == 0:
				break
			main.step()
			steps += 1
			if has_stuck and main.stuck != main.NONE:
				break
			if not has_stuck and has_empty(main):
				break
		var failed: bool = (main.stuck != main.NONE) if has_stuck else has_empty(main)
		if failed:
			stuck_seeds.append(map_seed)
			stuck_at.append(steps)
			continue
		for cell: Vector2i in main.wave:
			cells += 1
			if main.wave[cell][0] == "gggg":
				grass += 1
			for direction: int in [main.RIGHT, main.DOWN]:
				var next: Vector2i = cell + main.DIRECTIONS[direction]
				if main.wave.has(next):
					expect(main.fits(main.wave[cell][0], main.wave[next][0], direction), "%s seed %d: %s breaks a rule" % [step, map_seed, cell])
	print("MEASURE %s: %d of %d maps got stuck; first stuck seeds %s after %s steps; full grass cells %.1f %%" % [
		step, stuck_seeds.size(), maps, stuck_seeds.slice(0, 12), stuck_at.slice(0, 12), 100.0 * grass / maxi(cells, 1)])
	if step != "step_05_contradiction":
		expect(stuck_seeds.is_empty(), "%s: %d maps got stuck" % [step, stuck_seeds.size()])
	else:
		expect(not stuck_seeds.is_empty(), "%s: no map got stuck, so the video has no contradiction to show" % step)
	main.free()


func open_cells(main: Node2D) -> int:
	var count := 0
	for cell: Vector2i in main.wave:
		if main.wave[cell].size() > 1:
			count += 1
	return count


func has_empty(main: Node2D) -> bool:
	for cell: Vector2i in main.wave:
		if main.wave[cell].is_empty():
			return true
	return false
