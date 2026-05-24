extends "res://addons/gut/test.gd"

# Generator tests use small synthetic grids to keep runtime fast.


func _tiny_wordlist() -> Wordlist:
	# Hand-crafted minimal wordlist for tests that don't need the bundled
	# data. Populates both _by_length AND _word_set (the membership cache
	# used by PuzzleGenerator's filled-slot validation).
	var words: Array = ["CAT", "ARE", "TEA", "CAR", "ATE", "BAT", "RAT", "ERA"]
	var list: Wordlist = Wordlist.new()
	list._by_length = {3: words}
	for word in words:
		list._word_set[word] = true
	return list


func _open_3x3_grid() -> CrosswordGrid:
	# 3x3 all letters — every row and every col is a 3-letter word.
	return CrosswordGrid.from_strings([
		"...",
		"...",
		"...",
	])


func test_fill_3x3_with_bundled_wordlist_succeeds() -> void:
	# Use the bundled wordlist — 350+ 3-letter words give the no-duplicate
	# constraint enough room to find a fill (only 8 words in _tiny_wordlist
	# forces repeats which the generator rejects).
	var filled: CrosswordGrid = PuzzleGenerator.fill(_open_3x3_grid(), Wordlist.load_from_path(), 1)
	assert_not_null(filled, "generator should fill a 3x3 grid with the bundled wordlist")


func test_fill_3x3_produces_words_present_in_wordlist() -> void:
	var wl: Wordlist = Wordlist.load_from_path()
	var filled: CrosswordGrid = PuzzleGenerator.fill(_open_3x3_grid(), wl, 1)
	assert_not_null(filled)
	var slots: Array = CrosswordNumbering.find_word_slots(filled)
	for slot in slots:
		var answer: String = String(slot["answer"])
		assert_has(wl.words_of_length(answer.length()), answer, "answer must come from the wordlist: %s" % answer)


func test_fill_returns_null_for_impossible_pattern() -> void:
	# Empty wordlist → no fills possible
	var empty: Wordlist = Wordlist.new()
	var filled: CrosswordGrid = PuzzleGenerator.fill(_open_3x3_grid(), empty, 1)
	assert_null(filled)


func test_fill_returns_null_for_null_inputs() -> void:
	var wl: Wordlist = _tiny_wordlist()
	assert_null(PuzzleGenerator.fill(null, wl, 1))
	assert_null(PuzzleGenerator.fill(_open_3x3_grid(), null, 1))


func test_fill_preserves_block_pattern() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		".A.",
		"###",
		"...",
	])
	# Wait — that "A" needs to be a wildcard for the generator. The generator
	# treats "." as unknown and treats any other letter as a fixed constraint.
	# Use a pure block-pattern grid where letter cells are "." sentinels.
	var input: CrosswordGrid = CrosswordGrid.from_strings([
		"...",
		"###",
		"...",
	])
	var wl: Wordlist = _tiny_wordlist()
	var filled: CrosswordGrid = PuzzleGenerator.fill(input, wl, 7)
	assert_not_null(filled)
	# Block row 1 should remain all blocks.
	for c in range(3):
		assert_true(filled.is_block(1, c), "block row must survive the fill")


func test_fill_with_explicit_seed_is_deterministic() -> void:
	# Same seed → same fill given an unchanged wordlist. Uses the bundled
	# wordlist for enough variety to actually fill 3x3.
	var grid_a: CrosswordGrid = _open_3x3_grid()
	var grid_b: CrosswordGrid = _open_3x3_grid()
	var wl: Wordlist = Wordlist.load_from_path()
	var filled_a: CrosswordGrid = PuzzleGenerator.fill(grid_a, wl, 42)
	var filled_b: CrosswordGrid = PuzzleGenerator.fill(grid_b, wl, 42)
	assert_not_null(filled_a)
	assert_not_null(filled_b)
	assert_eq(filled_a.to_strings(), filled_b.to_strings())


func test_fill_with_bundled_wordlist_on_mini_pattern() -> void:
	# Real-world acceptance test: the standard 5x5 MINI block pattern should
	# fill from the bundled wordlist in well under the backtrack budget.
	var mini: CrosswordGrid = CrosswordGrid.from_strings([
		".....",
		".###.",
		".....",
		".###.",
		".....",
	])
	var wl: Wordlist = Wordlist.load_from_path()
	var filled: CrosswordGrid = PuzzleGenerator.fill(mini, wl, 1)
	assert_not_null(filled, "bundled wordlist should fill the mini block pattern")
	# Sanity: all letter cells must be uppercase A-Z.
	for r in range(filled.size):
		for c in range(filled.size):
			if not filled.is_block(r, c):
				var ch: String = filled.cell(r, c)
				var code: int = ch.unicode_at(0)
				assert_true(code >= 65 and code <= 90, "cell (%d,%d) should be A-Z, got '%s'" % [r, c, ch])


func test_filled_grid_validates_clean() -> void:
	# A generated puzzle should pass the validator (symmetry + min length +
	# clue coverage, given we attach clues per slot).
	var mini: CrosswordGrid = CrosswordGrid.from_strings([
		".....",
		".###.",
		".....",
		".###.",
		".....",
	])
	var wl: Wordlist = Wordlist.load_from_path()
	var filled: CrosswordGrid = PuzzleGenerator.fill(mini, wl, 3)
	assert_not_null(filled)
	var slots: Array = CrosswordNumbering.find_word_slots(filled)
	var clues: Array = []
	for slot in slots:
		clues.append({
			"number": int(slot["number"]),
			"direction": String(slot["direction"]),
			"text": "TODO: " + String(slot["answer"]),
		})
	var puzzle: Dictionary = {
		"grid": filled,
		"clues": clues,
	}
	var issues: Array = PuzzleValidator.validate(puzzle)
	assert_eq(issues.size(), 0, "generated puzzle should validate clean: %s" % str(issues))


func test_fill_does_not_duplicate_words() -> void:
	var mini: CrosswordGrid = CrosswordGrid.from_strings([
		".....",
		".###.",
		".....",
		".###.",
		".....",
	])
	var wl: Wordlist = Wordlist.load_from_path()
	var filled: CrosswordGrid = PuzzleGenerator.fill(mini, wl, 9)
	assert_not_null(filled)
	var slots: Array = CrosswordNumbering.find_word_slots(filled)
	var seen: Dictionary = {}
	for slot in slots:
		var answer: String = String(slot["answer"])
		assert_false(seen.has(answer), "duplicate word in generated puzzle: %s" % answer)
		seen[answer] = true
