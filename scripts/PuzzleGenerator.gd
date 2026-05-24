class_name PuzzleGenerator
extends RefCounted

# Backtracking constraint-solver for crossword grids. Given a block pattern
# (CrosswordGrid with letter cells marked "." for unknowns) and a Wordlist,
# fills every slot with a valid word — or returns null if no fill exists
# inside the backtrack budget.
#
# Algorithm:
#   1. Enumerate slots via CrosswordNumbering.find_word_slots.
#   2. Loop: pick the most-constrained unfilled slot (MRV — minimum
#      remaining values). This fails fast when a dead-end branch exists.
#   3. Try candidate words in randomized order (fixed-seed if requested).
#   4. Recurse. On failure, restore the slot and try the next candidate.
#   5. Stop when no unfilled slots remain (success) or backtrack budget is
#      exhausted (failure).

const DEFAULT_BACKTRACK_BUDGET: int = 50000

const UNKNOWN_CHAR: String = "."


static func fill(block_grid: CrosswordGrid, wordlist: Wordlist, seed: int = 0, backtrack_budget: int = DEFAULT_BACKTRACK_BUDGET) -> CrosswordGrid:
	if block_grid == null or wordlist == null:
		return null
	var slots: Array = CrosswordNumbering.find_word_slots(block_grid)
	var working: CrosswordGrid = _blank_letter_cells(block_grid)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()

	# Counter wrapped in an array so the recursion can mutate it.
	var budget: Array = [backtrack_budget]
	if _solve(working, slots, wordlist, rng, budget):
		return working
	return null


# Returns a fresh grid where every non-block cell is the UNKNOWN sentinel.
static func _blank_letter_cells(grid: CrosswordGrid) -> CrosswordGrid:
	var fresh: CrosswordGrid = CrosswordGrid.new()
	fresh.size = grid.size
	for r in range(grid.size):
		var row: Array = []
		for c in range(grid.size):
			if grid.is_block(r, c):
				row.append(CrosswordGrid.BLOCK_CHAR)
			else:
				row.append(UNKNOWN_CHAR)
		fresh.rows.append(row)
	return fresh


static func _solve(grid: CrosswordGrid, slots: Array, wordlist: Wordlist, rng: RandomNumberGenerator, budget: Array) -> bool:
	if budget[0] <= 0:
		return false

	# Find the most-constrained unfilled slot. Bail on dead-ends fast.
	# Also verify any *fully filled* slot is a real word — a crossing-word
	# can become fully determined as a side effect of filling rows/cols
	# and the resulting pattern might not be in the wordlist.
	var best_slot: Dictionary = {}
	var best_candidates: Array = []
	var best_count: int = -1
	var any_unfilled: bool = false

	for slot in slots:
		var pattern: String = _slot_pattern(slot, grid)
		if not pattern.contains(UNKNOWN_CHAR):
			if not wordlist.contains(pattern):
				return false  # filled slot is not a real word — backtrack
			continue
		any_unfilled = true
		var candidates: Array = wordlist.matches_pattern(pattern)
		if candidates.is_empty():
			return false  # dead end — no word fits
		if best_count < 0 or candidates.size() < best_count:
			best_slot = slot
			best_candidates = candidates
			best_count = candidates.size()

	if not any_unfilled:
		return true  # every slot is filled

	# Randomize order using the explicit RNG (Array.shuffle uses the global
	# RNG which would ignore the seed we were passed).
	var indices: Array = []
	for i in range(best_candidates.size()):
		indices.append(i)
	_shuffle_with_rng(indices, rng)

	for idx in indices:
		var word: String = best_candidates[idx]
		# Skip if this exact word is already used in the grid — prevents
		# repeat fills which look amateurish.
		if _word_already_used(word, slots, grid, best_slot):
			continue
		var prior: Array = _snapshot_slot(best_slot, grid)
		_write_word(best_slot, word, grid)
		if _solve(grid, slots, wordlist, rng, budget):
			return true
		_restore_slot(best_slot, prior, grid)
		budget[0] -= 1
		if budget[0] <= 0:
			return false

	return false


static func _shuffle_with_rng(arr: Array, rng: RandomNumberGenerator) -> void:
	# Fisher-Yates using the supplied RNG so the same seed always produces
	# the same fill.
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _word_already_used(word: String, slots: Array, grid: CrosswordGrid, skip_slot: Dictionary) -> bool:
	# Linear scan; fine at our slot counts. Skips the slot we're about to fill
	# (it currently holds the partial pattern, not a completed word).
	for slot in slots:
		if slot.get("row") == skip_slot.get("row") and slot.get("col") == skip_slot.get("col") and slot.get("direction") == skip_slot.get("direction"):
			continue
		var current: String = _slot_pattern(slot, grid)
		if current.contains(UNKNOWN_CHAR):
			continue
		if current == word:
			return true
	return false


static func _slot_pattern(slot: Dictionary, grid: CrosswordGrid) -> String:
	var pattern: String = ""
	var r: int = int(slot["row"])
	var c: int = int(slot["col"])
	var length: int = int(slot["length"])
	var direction: String = String(slot["direction"])
	for i in range(length):
		var cell_r: int = r if direction == CrosswordNumbering.ACROSS else r + i
		var cell_c: int = c + i if direction == CrosswordNumbering.ACROSS else c
		pattern += String(grid.cell(cell_r, cell_c))
	return pattern


static func _snapshot_slot(slot: Dictionary, grid: CrosswordGrid) -> Array:
	var snap: Array = []
	var r: int = int(slot["row"])
	var c: int = int(slot["col"])
	var length: int = int(slot["length"])
	var direction: String = String(slot["direction"])
	for i in range(length):
		var cell_r: int = r if direction == CrosswordNumbering.ACROSS else r + i
		var cell_c: int = c + i if direction == CrosswordNumbering.ACROSS else c
		snap.append(String(grid.cell(cell_r, cell_c)))
	return snap


static func _write_word(slot: Dictionary, word: String, grid: CrosswordGrid) -> void:
	var r: int = int(slot["row"])
	var c: int = int(slot["col"])
	var length: int = int(slot["length"])
	var direction: String = String(slot["direction"])
	for i in range(length):
		var cell_r: int = r if direction == CrosswordNumbering.ACROSS else r + i
		var cell_c: int = c + i if direction == CrosswordNumbering.ACROSS else c
		grid.rows[cell_r][cell_c] = word[i]


static func _restore_slot(slot: Dictionary, prior: Array, grid: CrosswordGrid) -> void:
	var r: int = int(slot["row"])
	var c: int = int(slot["col"])
	var length: int = int(slot["length"])
	var direction: String = String(slot["direction"])
	for i in range(length):
		var cell_r: int = r if direction == CrosswordNumbering.ACROSS else r + i
		var cell_c: int = c + i if direction == CrosswordNumbering.ACROSS else c
		grid.rows[cell_r][cell_c] = String(prior[i])
