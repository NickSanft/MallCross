extends "res://addons/gut/test.gd"


func _grid_3x3() -> CrosswordGrid:
	return CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])


func _fill_correctly(grid: CrosswordGrid) -> CrosswordState:
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	for r in range(grid.size):
		for c in range(grid.size):
			if not grid.is_block(r, c):
				state.set_letter(r, c, grid.cell(r, c))
	return state


func test_is_cell_correct_matches_grid() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "A")
	assert_true(CrosswordValidator.is_cell_correct(grid, state, 0, 0))


func test_is_cell_correct_rejects_wrong_letter() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "Z")
	assert_false(CrosswordValidator.is_cell_correct(grid, state, 0, 0))


func test_is_cell_correct_rejects_blank() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	assert_false(CrosswordValidator.is_cell_correct(grid, state, 0, 0))


func test_is_cell_correct_blocks_always_return_true() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["A#B", "CDE", "FGH"])
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	assert_true(CrosswordValidator.is_cell_correct(grid, state, 0, 1))


func test_is_word_complete_full_correct_word() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	var slots: Array = CrosswordNumbering.find_word_slots(grid)
	for slot in slots:
		assert_true(CrosswordValidator.is_word_complete(grid, state, slot))


func test_is_word_complete_one_wrong_cell() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	state.set_letter(0, 1, "Z")  # corrupt B
	var slots: Array = CrosswordNumbering.find_word_slots(grid)
	for slot in slots:
		if slot["number"] == 1 and slot["direction"] == CrosswordNumbering.ACROSS:
			assert_false(CrosswordValidator.is_word_complete(grid, state, slot))
			return
	fail_test("Expected 1-Across slot")


func test_is_puzzle_solved_full_correct() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	assert_true(CrosswordValidator.is_puzzle_solved(grid, state))


func test_is_puzzle_solved_one_blank_cell_fails() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	state.clear_cell(1, 1)
	assert_false(CrosswordValidator.is_puzzle_solved(grid, state))


func test_is_puzzle_solved_one_wrong_cell_fails() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	state.set_letter(2, 2, "Z")
	assert_false(CrosswordValidator.is_puzzle_solved(grid, state))


func test_is_puzzle_solved_ignores_blocks() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABC", "D#E", "FGH"])
	var state: CrosswordState = _fill_correctly(grid)
	# Don't fill the block cell, but everything else is correct.
	assert_true(CrosswordValidator.is_puzzle_solved(grid, state))


func test_cells_in_word_across() -> void:
	var slot: Dictionary = {
		"row": 0,
		"col": 0,
		"length": 3,
		"direction": CrosswordNumbering.ACROSS,
	}
	var cells: Array = CrosswordValidator.cells_in_word(slot)
	assert_eq(cells.size(), 3)
	assert_eq(cells[0], {"row": 0, "col": 0})
	assert_eq(cells[1], {"row": 0, "col": 1})
	assert_eq(cells[2], {"row": 0, "col": 2})


func test_cells_in_word_down() -> void:
	var slot: Dictionary = {
		"row": 2,
		"col": 4,
		"length": 4,
		"direction": CrosswordNumbering.DOWN,
	}
	var cells: Array = CrosswordValidator.cells_in_word(slot)
	assert_eq(cells.size(), 4)
	assert_eq(cells[0], {"row": 2, "col": 4})
	assert_eq(cells[3], {"row": 5, "col": 4})


func test_correct_cell_count_starts_at_zero() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	assert_eq(CrosswordValidator.correct_cell_count(grid, state), 0)


func test_correct_cell_count_after_one_correct_letter() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "A")
	assert_eq(CrosswordValidator.correct_cell_count(grid, state), 1)


func test_correct_cell_count_full_solve() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = _fill_correctly(grid)
	assert_eq(CrosswordValidator.correct_cell_count(grid, state), 9)
