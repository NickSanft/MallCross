class_name CrosswordCursor
extends RefCounted

# Pure cursor model. Holds the player's current position + direction inside a
# crossword grid. No node references — fully GUT-testable.

const ACROSS: String = CrosswordNumbering.ACROSS
const DOWN: String = CrosswordNumbering.DOWN

var grid: CrosswordGrid
var row: int = 0
var col: int = 0
var direction: String = ACROSS


static func at_start(target_grid: CrosswordGrid) -> CrosswordCursor:
	# Place cursor at the top-leftmost non-block cell. Handles grids that
	# begin with a block in (0, 0). Falls back to (0, 0) if no non-block cell
	# exists (shouldn't happen on a real puzzle, but be safe).
	var cursor: CrosswordCursor = CrosswordCursor.new()
	cursor.grid = target_grid
	cursor.row = 0
	cursor.col = 0
	cursor.direction = ACROSS
	while target_grid.in_bounds(cursor.row, cursor.col) and target_grid.is_block(cursor.row, cursor.col):
		cursor.col += 1
		if cursor.col >= target_grid.size:
			cursor.col = 0
			cursor.row += 1
	if not target_grid.in_bounds(cursor.row, cursor.col):
		cursor.row = 0
		cursor.col = 0
	return cursor


func toggle_direction() -> void:
	direction = DOWN if direction == ACROSS else ACROSS


func move_to(r: int, c: int) -> bool:
	if not grid.in_bounds(r, c):
		return false
	if grid.is_block(r, c):
		return false
	row = r
	col = c
	return true


func move(d_row: int, d_col: int) -> bool:
	return move_to(row + d_row, col + d_col)


func advance() -> bool:
	# Move one cell forward in the current direction. Blocks/edges stop the cursor.
	var step: Vector2i = direction_vector()
	return move(step.x, step.y)


func retreat() -> bool:
	var step: Vector2i = direction_vector()
	return move(-step.x, -step.y)


func direction_vector() -> Vector2i:
	return Vector2i(0, 1) if direction == ACROSS else Vector2i(1, 0)


func current_word_cells() -> Array:
	# Walk backward to find the word start, then forward until a block/edge.
	var cells: Array = []
	if not grid.in_bounds(row, col) or grid.is_block(row, col):
		return cells
	var step: Vector2i = direction_vector()
	var sr: int = row
	var sc: int = col
	while grid.in_bounds(sr - step.x, sc - step.y) and not grid.is_block(sr - step.x, sc - step.y):
		sr -= step.x
		sc -= step.y
	var r: int = sr
	var c: int = sc
	while grid.in_bounds(r, c) and not grid.is_block(r, c):
		cells.append({"row": r, "col": c})
		r += step.x
		c += step.y
	return cells


func current_word_start() -> Dictionary:
	var cells: Array = current_word_cells()
	if cells.is_empty():
		return {}
	return cells[0]
