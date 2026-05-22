extends "res://addons/gut/test.gd"


func test_open_grid_is_trivially_symmetric() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])
	assert_true(CrosswordSymmetry.is_symmetric(grid))


func test_symmetric_5x5_passes() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"ABCDE",
		"F#G#H",
		"IJKLM",
		"N#O#P",
		"QRSTU",
	])
	assert_true(CrosswordSymmetry.is_symmetric(grid))


func test_single_center_block_is_symmetric_for_odd_size() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"ABC",
		"D#F",
		"GHI",
	])
	assert_true(CrosswordSymmetry.is_symmetric(grid))


func test_asymmetric_grid_is_rejected() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"A#B",
		"CDE",
		"FGH",
	])
	assert_false(CrosswordSymmetry.is_symmetric(grid))


func test_find_asymmetries_returns_one_entry_per_violating_pair() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"A#B",
		"CDE",
		"FGH",
	])
	var violations: Array = CrosswordSymmetry.find_asymmetries(grid)
	# One pair: (0, 1) block but mirror (2, 1) non-block. Only one entry should report it.
	assert_eq(violations.size(), 1)
	assert_eq(violations[0]["row"], 0)
	assert_eq(violations[0]["col"], 1)
	assert_eq(violations[0]["mirror_row"], 2)
	assert_eq(violations[0]["mirror_col"], 1)


func test_find_asymmetries_empty_for_symmetric_grid() -> void:
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"ABCDE",
		"F#G#H",
		"IJKLM",
		"N#O#P",
		"QRSTU",
	])
	assert_eq(CrosswordSymmetry.find_asymmetries(grid).size(), 0)


func test_multiple_independent_asymmetries_each_reported_once() -> void:
	# Two independent asymmetric pairs: (0, 0) block but (2, 2) not; (0, 2) block but (2, 0) not.
	var grid: CrosswordGrid = CrosswordGrid.from_strings([
		"#A#",
		"BCD",
		"EFG",
	])
	var violations: Array = CrosswordSymmetry.find_asymmetries(grid)
	assert_eq(violations.size(), 2)


func test_mirror_position_for_15x15() -> void:
	var mirror: Vector2i = CrosswordSymmetry.mirror_position(15, 3, 7)
	assert_eq(mirror, Vector2i(11, 7))


func test_mirror_position_center_maps_to_itself() -> void:
	var mirror: Vector2i = CrosswordSymmetry.mirror_position(15, 7, 7)
	assert_eq(mirror, Vector2i(7, 7))
