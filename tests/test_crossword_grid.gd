extends "res://addons/gut/test.gd"


func _fixture_3x3() -> CrosswordGrid:
	return CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])


func _fixture_5x5_symmetric() -> CrosswordGrid:
	return CrosswordGrid.from_strings([
		"ABCDE",
		"F#G#H",
		"IJKLM",
		"N#O#P",
		"QRSTU",
	])


func test_from_strings_empty_yields_zero_size() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([])
	assert_eq(grid.size, 0)
	assert_eq(grid.rows.size(), 0)


func test_from_strings_sets_size_from_row_count() -> void:
	assert_eq(_fixture_3x3().size, 3)
	assert_eq(_fixture_5x5_symmetric().size, 5)


func test_from_strings_uppercases_input() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["abc", "def", "ghi"])
	assert_eq(grid.cell(0, 0), "A")
	assert_eq(grid.cell(2, 2), "I")


func test_is_square_true_for_well_formed() -> void:
	assert_true(_fixture_3x3().is_square())
	assert_true(_fixture_5x5_symmetric().is_square())


func test_is_block_returns_true_for_block_char() -> void:
	var grid: CrosswordGrid = _fixture_5x5_symmetric()
	assert_true(grid.is_block(1, 1))
	assert_true(grid.is_block(3, 3))


func test_is_block_returns_false_for_letter_cell() -> void:
	var grid: CrosswordGrid = _fixture_5x5_symmetric()
	assert_false(grid.is_block(0, 0))


func test_is_block_returns_false_for_out_of_bounds() -> void:
	var grid: CrosswordGrid = _fixture_3x3()
	assert_false(grid.is_block(-1, 0))
	assert_false(grid.is_block(0, 99))


func test_cell_returns_letter_for_white_cell() -> void:
	var grid: CrosswordGrid = _fixture_3x3()
	assert_eq(grid.cell(1, 1), "E")


func test_cell_returns_block_for_out_of_bounds() -> void:
	var grid: CrosswordGrid = _fixture_3x3()
	assert_eq(grid.cell(-1, 0), CrosswordGrid.BLOCK_CHAR)
	assert_eq(grid.cell(0, 99), CrosswordGrid.BLOCK_CHAR)


func test_to_strings_round_trips_input() -> void:
	var grid: CrosswordGrid = _fixture_5x5_symmetric()
	var dumped: Array = grid.to_strings()
	assert_eq(dumped, ["ABCDE", "F#G#H", "IJKLM", "N#O#P", "QRSTU"])


func test_block_count_for_5x5_fixture() -> void:
	assert_eq(_fixture_5x5_symmetric().block_count(), 4)


func test_block_count_zero_for_open_grid() -> void:
	assert_eq(_fixture_3x3().block_count(), 0)


func test_white_count_equals_total_minus_blocks() -> void:
	var grid: CrosswordGrid = _fixture_5x5_symmetric()
	assert_eq(grid.white_count(), 25 - 4)


func test_in_bounds_accepts_corners_rejects_outside() -> void:
	var grid: CrosswordGrid = _fixture_5x5_symmetric()
	assert_true(grid.in_bounds(0, 0))
	assert_true(grid.in_bounds(4, 4))
	assert_false(grid.in_bounds(-1, 0))
	assert_false(grid.in_bounds(0, 5))
