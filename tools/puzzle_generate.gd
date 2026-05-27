extends SceneTree

# CLI front-end for PuzzleGenerator. Loads a block pattern from one of the
# built-in presets, fills it from the bundled wordlist, and writes a puzzle
# JSON file (with placeholder clue text the author fills in afterward).
#
# Usage:
#   godot --headless -s res://tools/puzzle_generate.gd -- <pattern> <output> [seed]
#
# Patterns:
#   mini    — 5x5 with the standard block pattern matching mall_day_one
#   midi    — 9x9 with sparser blocks
#   full    — 15x15 NYT-ish pattern
#
# Exit codes:
#   0 success — file written
#   1 generation failure (no fill found within budget)
#   2 usage / file / wordlist error


func _init() -> void:
	var args: Array = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: godot --headless -s res://tools/puzzle_generate.gd -- <pattern> <output.json> [seed]")
		printerr("patterns: mini | midi | full")
		quit(2)
		return

	var pattern_name: String = String(args[0])
	var output_path: String = String(args[1])
	var seed_value: int = int(args[2]) if args.size() >= 3 else 0

	var block_grid: CrosswordGrid = _pattern_for(pattern_name)
	if block_grid == null:
		printerr("Unknown pattern: %s (expected mini, midi, or full)" % pattern_name)
		quit(2)
		return

	var wordlist: Wordlist = Wordlist.load_from_path()
	if wordlist.total_words() == 0:
		printerr("Wordlist failed to load from %s" % Wordlist.DEFAULT_PATH)
		quit(2)
		return

	# Larger grids need a larger backtrack budget — 78-slot 15x15 puzzles
	# can easily exceed the 50k default. Scale by pattern.
	#
	# FULL: kept at 500k. v1.0.4 investigation found that the FULL pattern
	# + our generator's MRV heuristic hits a hard wall on most seeds —
	# only specific lucky seeds (e.g. 1) find a fill in reasonable time;
	# bumping to 5 million didn't materially help (still 0/16 seeds in
	# a 60s timeout sweep). Generating more FULL puzzles requires either
	# (a) a smarter solver (lookahead, restart heuristics) or (b) a
	# different FULL block pattern with more flexibility — see
	# https://github.com/NickSanft/MallCross/issues for tracker.
	var budget: int = PuzzleGenerator.DEFAULT_BACKTRACK_BUDGET
	match pattern_name.to_lower():
		"full":
			budget = 500000
		"midi":
			budget = 100000

	print("Generating %s (%dx%d) with %d words in the dictionary (budget %d)..." % [
		pattern_name, block_grid.size, block_grid.size, wordlist.total_words(), budget
	])

	var filled: CrosswordGrid = PuzzleGenerator.fill(block_grid, wordlist, seed_value, budget)
	if filled == null:
		printerr("Could not generate a valid puzzle within the backtrack budget.")
		printerr("Try a different seed, a simpler pattern, or expanding the wordlist.")
		quit(1)
		return

	# Build slots + placeholder clues. Validator requires non-empty clue text,
	# so we seed it with "TODO: <answer>" — author then edits to real clues.
	var slots: Array = CrosswordNumbering.find_word_slots(filled)
	var clues: Array = []
	for slot in slots:
		clues.append({
			"number": int(slot["number"]),
			"direction": String(slot["direction"]),
			"row": int(slot["row"]),
			"col": int(slot["col"]),
			"length": int(slot["length"]),
			"text": "TODO: " + String(slot["answer"]),
		})

	var puzzle: Dictionary = CrosswordSerializer.puzzle_to_dict(
		filled, clues, "Generated " + pattern_name.to_upper(), "PuzzleGenerator", "Auto-generated draft"
	)
	var json_text: String = JSON.stringify(puzzle, "\t")
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Failed to open %s for writing." % output_path)
		quit(2)
		return
	file.store_string(json_text)
	file.close()
	print("Wrote %s — %d slots filled. Edit clue text before shipping." % [output_path, slots.size()])
	quit(0)


static func _pattern_for(name: String) -> CrosswordGrid:
	match name.to_lower():
		"mini":
			# Matches mall_day_one's block pattern so generated minis fit the
			# existing food-court UI exactly.
			return CrosswordGrid.from_strings([
				".....",
				".###.",
				".....",
				".###.",
				".....",
			])
		"midi":
			# 9x9 with a corridor of blocks through the middle creating
			# manageable 3/4/5-letter word lengths.
			return CrosswordGrid.from_strings([
				"....#....",
				"....#....",
				"....#....",
				"####.####",
				".........",
				"####.####",
				"....#....",
				"....#....",
				"....#....",
			])
		"full":
			# 15x15. Symmetric (180° rotational) heavy-block pattern. Each
			# row outside the horizontal divider has two 4-letter slots and
			# one 5-letter slot; columns get a mix of 3-7 letter slots.
			# Verified symmetric: every cell maps to its mirror (14-r, 14-c).
			return CrosswordGrid.from_strings([
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"###############",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"###############",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
				"....#.....#....",
			])
		_:
			return null
