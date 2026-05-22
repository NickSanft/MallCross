class_name CrosswordGrid
extends RefCounted

# Solution grid for a crossword puzzle. Stores the correct letters (uppercase)
# for every white cell, and a "#" sentinel for every black/block cell.
# Square only — `size` is both width and height. Size is configurable so the
# logic works for synthetic test fixtures (3x3, 5x5) as well as the production
# 15x15 puzzles.

const BLOCK_CHAR: String = "#"

var size: int = 0
var rows: Array  # Array of Array of single-char String, each row length == size


static func from_strings(string_rows: Array) -> CrosswordGrid:
	var grid: CrosswordGrid = CrosswordGrid.new()
	if string_rows.is_empty():
		return grid
	grid.size = string_rows.size()
	for raw in string_rows:
		var line: String = String(raw).to_upper()
		var row: Array = []
		for i in range(line.length()):
			row.append(line[i])
		grid.rows.append(row)
	return grid


func is_square() -> bool:
	if rows.size() != size:
		return false
	for row in rows:
		if row.size() != size:
			return false
	return true


func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < size and col >= 0 and col < size


func is_block(row: int, col: int) -> bool:
	if not in_bounds(row, col):
		return false
	return rows[row][col] == BLOCK_CHAR


func cell(row: int, col: int) -> String:
	if not in_bounds(row, col):
		return BLOCK_CHAR
	return rows[row][col]


func to_strings() -> Array:
	var out: Array = []
	for row in rows:
		var line: String = ""
		for ch in row:
			line += String(ch)
		out.append(line)
	return out


func block_count() -> int:
	var count: int = 0
	for row in rows:
		for ch in row:
			if ch == BLOCK_CHAR:
				count += 1
	return count


func white_count() -> int:
	return size * size - block_count()
