class_name CrosswordNumbering
extends RefCounted

# Numbering follows standard American crossword rules. A white cell at (r, c)
# is the start of an across word iff:
#   - The cell to its left is a block OR out-of-bounds, AND
#   - The cell to its right exists and is non-block (so the run is length >= 2).
# Similarly for down. A cell gets a number iff it starts an across or a down
# word. Numbering proceeds left-to-right, top-to-bottom starting at 1.

const ACROSS: String = "across"
const DOWN: String = "down"


static func compute_numbers(grid: CrosswordGrid) -> Array:
	var numbers: Array = _zero_grid(grid.size)
	var next_number: int = 1
	for r in range(grid.size):
		for c in range(grid.size):
			if grid.is_block(r, c):
				continue
			if _starts_across(grid, r, c) or _starts_down(grid, r, c):
				numbers[r][c] = next_number
				next_number += 1
	return numbers


static func find_word_slots(grid: CrosswordGrid) -> Array:
	var slots: Array = []
	var numbers: Array = compute_numbers(grid)
	for r in range(grid.size):
		for c in range(grid.size):
			var num: int = numbers[r][c]
			if num == 0:
				continue
			if _starts_across(grid, r, c):
				slots.append(_build_slot(grid, num, r, c, ACROSS))
			if _starts_down(grid, r, c):
				slots.append(_build_slot(grid, num, r, c, DOWN))
	return slots


static func slots_by_direction(slots: Array, direction: String) -> Array:
	var filtered: Array = []
	for slot in slots:
		if slot.get("direction", "") == direction:
			filtered.append(slot)
	return filtered


static func _starts_across(grid: CrosswordGrid, r: int, c: int) -> bool:
	var left_blocked: bool = (c == 0) or grid.is_block(r, c - 1)
	var right_open: bool = (c + 1 < grid.size) and not grid.is_block(r, c + 1)
	return left_blocked and right_open


static func _starts_down(grid: CrosswordGrid, r: int, c: int) -> bool:
	var top_blocked: bool = (r == 0) or grid.is_block(r - 1, c)
	var bottom_open: bool = (r + 1 < grid.size) and not grid.is_block(r + 1, c)
	return top_blocked and bottom_open


static func _build_slot(grid: CrosswordGrid, number: int, r: int, c: int, direction: String) -> Dictionary:
	var answer: String = ""
	if direction == ACROSS:
		var cc: int = c
		while cc < grid.size and not grid.is_block(r, cc):
			answer += grid.cell(r, cc)
			cc += 1
	else:
		var rr: int = r
		while rr < grid.size and not grid.is_block(rr, c):
			answer += grid.cell(rr, c)
			rr += 1
	return {
		"number": number,
		"direction": direction,
		"row": r,
		"col": c,
		"length": answer.length(),
		"answer": answer,
	}


static func _zero_grid(n: int) -> Array:
	var g: Array = []
	for r in range(n):
		var row: Array = []
		for c in range(n):
			row.append(0)
		g.append(row)
	return g
