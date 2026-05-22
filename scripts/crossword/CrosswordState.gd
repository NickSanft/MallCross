class_name CrosswordState
extends RefCounted

# Mutable player state on top of an immutable CrosswordGrid. Tracks which
# letter (if any) the player has entered in each cell and whether that entry
# is in pencil (uncertain) or pen (confident) mode. Block cells are always
# stored as EMPTY_CHAR — clients should consult the grid for block-ness.

const EMPTY_CHAR: String = "."

var size: int = 0
var entries: Array  # 2D Array of single-char String (uppercase letter or EMPTY_CHAR)
var pencil_flags: Array  # 2D Array of bool


static func empty_for_grid(grid: CrosswordGrid) -> CrosswordState:
	var state: CrosswordState = CrosswordState.new()
	state.size = grid.size
	for r in range(grid.size):
		var entry_row: Array = []
		var pencil_row: Array = []
		for c in range(grid.size):
			entry_row.append(EMPTY_CHAR)
			pencil_row.append(false)
		state.entries.append(entry_row)
		state.pencil_flags.append(pencil_row)
	return state


func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < size and col >= 0 and col < size


func entry_at(row: int, col: int) -> String:
	if not in_bounds(row, col):
		return EMPTY_CHAR
	return entries[row][col]


func is_blank(row: int, col: int) -> bool:
	return entry_at(row, col) == EMPTY_CHAR


func is_pencil(row: int, col: int) -> bool:
	if not in_bounds(row, col):
		return false
	return pencil_flags[row][col]


func set_letter(row: int, col: int, letter: String, in_pencil: bool = false) -> void:
	if not in_bounds(row, col):
		return
	var normalized: String = letter.to_upper().substr(0, 1) if letter.length() > 0 else EMPTY_CHAR
	if normalized == "":
		normalized = EMPTY_CHAR
	entries[row][col] = normalized
	pencil_flags[row][col] = in_pencil and normalized != EMPTY_CHAR


func clear_cell(row: int, col: int) -> void:
	if not in_bounds(row, col):
		return
	entries[row][col] = EMPTY_CHAR
	pencil_flags[row][col] = false


func filled_count() -> int:
	var count: int = 0
	for r in range(size):
		for c in range(size):
			if entries[r][c] != EMPTY_CHAR:
				count += 1
	return count
