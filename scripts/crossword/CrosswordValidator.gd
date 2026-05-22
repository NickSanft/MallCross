class_name CrosswordValidator
extends RefCounted


static func is_cell_correct(grid: CrosswordGrid, state: CrosswordState, row: int, col: int) -> bool:
	if grid.is_block(row, col):
		return true  # blocks never need an entry
	return state.entry_at(row, col) == grid.cell(row, col)


static func is_word_complete(grid: CrosswordGrid, state: CrosswordState, slot: Dictionary) -> bool:
	for cell_pos in cells_in_word(slot):
		var r: int = cell_pos["row"]
		var c: int = cell_pos["col"]
		if not is_cell_correct(grid, state, r, c):
			return false
	return true


static func is_puzzle_solved(grid: CrosswordGrid, state: CrosswordState) -> bool:
	for r in range(grid.size):
		for c in range(grid.size):
			if grid.is_block(r, c):
				continue
			if not is_cell_correct(grid, state, r, c):
				return false
	return true


static func cells_in_word(slot: Dictionary) -> Array:
	var cells: Array = []
	var r: int = slot.get("row", 0)
	var c: int = slot.get("col", 0)
	var length: int = slot.get("length", 0)
	var direction: String = slot.get("direction", CrosswordNumbering.ACROSS)
	for i in range(length):
		if direction == CrosswordNumbering.ACROSS:
			cells.append({"row": r, "col": c + i})
		else:
			cells.append({"row": r + i, "col": c})
	return cells


static func correct_cell_count(grid: CrosswordGrid, state: CrosswordState) -> int:
	var count: int = 0
	for r in range(grid.size):
		for c in range(grid.size):
			if grid.is_block(r, c):
				continue
			if is_cell_correct(grid, state, r, c):
				count += 1
	return count
