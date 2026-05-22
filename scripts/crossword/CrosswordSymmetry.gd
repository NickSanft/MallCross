class_name CrosswordSymmetry
extends RefCounted

# 180° rotational symmetry — the American crossword standard. Cell (r, c)
# reflects to (size-1-r, size-1-c). A grid is symmetric iff for every cell,
# the cell and its mirror are both blocks or both non-blocks.


static func is_symmetric(grid: CrosswordGrid) -> bool:
	return find_asymmetries(grid).is_empty()


static func find_asymmetries(grid: CrosswordGrid) -> Array:
	# Returns one entry per asymmetric *pair*, not two. The entry's (row, col)
	# is the lexicographically earlier of the two mirrored cells, so callers
	# get a stable, dedup'd list.
	var violations: Array = []
	var n: int = grid.size
	for r in range(n):
		for c in range(n):
			var mr: int = n - 1 - r
			var mc: int = n - 1 - c
			if grid.is_block(r, c) == grid.is_block(mr, mc):
				continue
			if r > mr or (r == mr and c > mc):
				continue  # mirror already considered
			if r == mr and c == mc:
				continue  # impossible (center maps to itself) but be safe
			violations.append({
				"row": r,
				"col": c,
				"mirror_row": mr,
				"mirror_col": mc,
			})
	return violations


static func mirror_position(size: int, row: int, col: int) -> Vector2i:
	return Vector2i(size - 1 - row, size - 1 - col)
