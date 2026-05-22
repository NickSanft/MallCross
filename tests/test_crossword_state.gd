extends "res://addons/gut/test.gd"


func _fresh_state() -> CrosswordState:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])
	return CrosswordState.empty_for_grid(grid)


func test_empty_for_grid_matches_grid_size() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABCDE", "FGHIJ", "KLMNO", "PQRST", "UVWXY"])
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	assert_eq(state.size, 5)
	assert_eq(state.entries.size(), 5)
	assert_eq(state.entries[0].size(), 5)


func test_empty_state_all_blank() -> void:
	var state: CrosswordState = _fresh_state()
	for r in range(state.size):
		for c in range(state.size):
			assert_true(state.is_blank(r, c))


func test_set_letter_uppercases_input() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(0, 0, "x")
	assert_eq(state.entry_at(0, 0), "X")


func test_set_letter_only_keeps_first_char() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(0, 0, "AB")
	assert_eq(state.entry_at(0, 0), "A")


func test_set_letter_empty_clears_to_empty_char() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(0, 0, "")
	assert_eq(state.entry_at(0, 0), CrosswordState.EMPTY_CHAR)


func test_pencil_flag_set_and_read() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(1, 1, "E", true)
	assert_true(state.is_pencil(1, 1))


func test_pencil_flag_default_false() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(1, 1, "E")
	assert_false(state.is_pencil(1, 1))


func test_pencil_flag_cleared_when_cell_empty() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(1, 1, "E", true)
	state.set_letter(1, 1, "")
	assert_false(state.is_pencil(1, 1))


func test_clear_cell_blanks_entry_and_pencil() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(2, 2, "I", true)
	state.clear_cell(2, 2)
	assert_true(state.is_blank(2, 2))
	assert_false(state.is_pencil(2, 2))


func test_set_letter_out_of_bounds_is_noop() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(99, 99, "Z")
	# No crash, no change
	assert_true(state.is_blank(0, 0))


func test_filled_count_counts_non_empty_cells() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(0, 0, "A")
	state.set_letter(1, 2, "F")
	state.set_letter(2, 2, "I")
	assert_eq(state.filled_count(), 3)


func test_filled_count_after_clear() -> void:
	var state: CrosswordState = _fresh_state()
	state.set_letter(0, 0, "A")
	state.clear_cell(0, 0)
	assert_eq(state.filled_count(), 0)


func test_entry_at_out_of_bounds_returns_empty_char() -> void:
	var state: CrosswordState = _fresh_state()
	assert_eq(state.entry_at(-1, 0), CrosswordState.EMPTY_CHAR)
	assert_eq(state.entry_at(0, 99), CrosswordState.EMPTY_CHAR)
