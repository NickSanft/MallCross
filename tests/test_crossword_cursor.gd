extends "res://addons/gut/test.gd"


func _grid_3x3() -> CrosswordGrid:
	return CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])


func _grid_5x5() -> CrosswordGrid:
	return CrosswordGrid.from_strings([
		"ABCDE",
		"F#G#H",
		"IJKLM",
		"N#O#P",
		"QRSTU",
	])


func test_at_start_on_open_grid_lands_at_origin() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	assert_eq(cursor.row, 0)
	assert_eq(cursor.col, 0)
	assert_eq(cursor.direction, CrosswordCursor.ACROSS)


func test_at_start_skips_leading_block() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["#AB", "DEF", "GHI"])
	var cursor: CrosswordCursor = CrosswordCursor.at_start(grid)
	assert_eq(cursor.row, 0)
	assert_eq(cursor.col, 1)


func test_at_start_wraps_past_full_block_row() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["###", "DEF", "GHI"])
	var cursor: CrosswordCursor = CrosswordCursor.at_start(grid)
	assert_eq(cursor.row, 1)
	assert_eq(cursor.col, 0)


func test_toggle_direction_alternates() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	assert_eq(cursor.direction, CrosswordCursor.ACROSS)
	cursor.toggle_direction()
	assert_eq(cursor.direction, CrosswordCursor.DOWN)
	cursor.toggle_direction()
	assert_eq(cursor.direction, CrosswordCursor.ACROSS)


func test_move_to_valid_cell_returns_true() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	assert_true(cursor.move_to(2, 2))
	assert_eq(cursor.row, 2)
	assert_eq(cursor.col, 2)


func test_move_to_out_of_bounds_returns_false_and_no_op() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	assert_false(cursor.move_to(5, 5))
	assert_eq(cursor.row, 0)
	assert_eq(cursor.col, 0)


func test_move_to_block_cell_returns_false() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_5x5())
	assert_false(cursor.move_to(1, 1))


func test_advance_across_increments_col() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.advance()
	assert_eq(cursor.col, 1)


func test_advance_down_increments_row() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.direction = CrosswordCursor.DOWN
	cursor.advance()
	assert_eq(cursor.row, 1)


func test_advance_blocked_by_block_returns_false() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_5x5())
	cursor.move_to(1, 0)
	assert_false(cursor.advance())  # next cell (1, 1) is a block
	assert_eq(cursor.col, 0)


func test_retreat_moves_opposite_to_direction() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.move_to(0, 2)
	cursor.retreat()
	assert_eq(cursor.col, 1)


func test_direction_vector_across_is_unit_x_in_col() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	assert_eq(cursor.direction_vector(), Vector2i(0, 1))


func test_direction_vector_down_is_unit_y_in_row() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.direction = CrosswordCursor.DOWN
	assert_eq(cursor.direction_vector(), Vector2i(1, 0))


func test_current_word_cells_across_3x3() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.move_to(0, 1)
	var cells: Array = cursor.current_word_cells()
	assert_eq(cells.size(), 3)
	assert_eq(cells[0], {"row": 0, "col": 0})
	assert_eq(cells[2], {"row": 0, "col": 2})


func test_current_word_cells_down_3x3() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.direction = CrosswordCursor.DOWN
	cursor.move_to(1, 0)
	var cells: Array = cursor.current_word_cells()
	assert_eq(cells.size(), 3)
	assert_eq(cells[0], {"row": 0, "col": 0})


func test_current_word_cells_across_stops_at_block() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_5x5())
	cursor.move_to(0, 2)
	var cells: Array = cursor.current_word_cells()
	# Row 0 has no blocks, so the across word spans all 5 cells.
	assert_eq(cells.size(), 5)
	assert_eq(cells[0], {"row": 0, "col": 0})
	assert_eq(cells[4], {"row": 0, "col": 4})


func test_current_word_cells_down_full_column_through_letter_rows() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_5x5())
	cursor.direction = CrosswordCursor.DOWN
	cursor.move_to(2, 2)
	var cells: Array = cursor.current_word_cells()
	# Column 2 has no blocks (G at (1,2), O at (3,2)), so 5 cells.
	assert_eq(cells.size(), 5)


func test_current_word_start_returns_first_cell_in_run() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.at_start(_grid_3x3())
	cursor.move_to(0, 2)
	assert_eq(cursor.current_word_start(), {"row": 0, "col": 0})


func test_current_word_cells_on_block_returns_empty() -> void:
	var cursor: CrosswordCursor = CrosswordCursor.new()
	cursor.grid = _grid_5x5()
	cursor.row = 1
	cursor.col = 1  # block
	assert_eq(cursor.current_word_cells(), [])
