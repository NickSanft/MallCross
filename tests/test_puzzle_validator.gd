extends "res://addons/gut/test.gd"


func _good_puzzle() -> Dictionary:
	return CrosswordSerializer.puzzle_from_dict({
		"version": 1,
		"size": 5,
		"grid": ["PUTTS", "E###C", "AMIGO", "C###R", "HALVE"],
		"clues": [
			{"number": 1, "direction": "across", "row": 0, "col": 0, "length": 5, "text": "Golf strokes"},
			{"number": 3, "direction": "across", "row": 2, "col": 0, "length": 5, "text": "Pal in Spanish"},
			{"number": 4, "direction": "across", "row": 4, "col": 0, "length": 5, "text": "Cut in two"},
			{"number": 1, "direction": "down", "row": 0, "col": 0, "length": 5, "text": "Fuzzy fruit"},
			{"number": 2, "direction": "down", "row": 0, "col": 4, "length": 5, "text": "Twenty"},
		],
	})


func test_clean_puzzle_has_no_issues() -> void:
	var issues: Array = PuzzleValidator.validate(_good_puzzle())
	assert_eq(issues.size(), 0)


func test_clean_puzzle_has_no_errors_helper() -> void:
	assert_false(PuzzleValidator.has_errors(PuzzleValidator.validate(_good_puzzle())))


func test_empty_dict_reports_no_grid() -> void:
	var issues: Array = PuzzleValidator.validate({})
	assert_eq(issues.size(), 1)
	assert_eq(issues[0]["code"], "no_grid")


func test_zero_size_grid_reports_empty_grid() -> void:
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict({"size": 0, "grid": [], "clues": []})
	var issues: Array = PuzzleValidator.validate(puzzle)
	# Empty grid short-circuits with one issue.
	assert_eq(issues.size(), 1)
	assert_eq(issues[0]["code"], "empty_grid")


func test_asymmetric_grid_reports_symmetry() -> void:
	# (0,1) is a block but its mirror (2,1) is not.
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict({
		"size": 3,
		"grid": ["A#B", "CDE", "FGH"],
		"clues": [],
	})
	var issues: Array = PuzzleValidator.validate(puzzle)
	var codes: Array = _codes(issues)
	assert_has(codes, "symmetry")


func test_short_word_reported() -> void:
	# 3x3 grid all white => 3-letter words (acceptable at default min=3); use
	# min=4 to force the failure.
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict({
		"size": 3,
		"grid": ["ABC", "DEF", "GHI"],
		"clues": [
			{"number": 1, "direction": "across", "text": "x"},
			{"number": 1, "direction": "down", "text": "x"},
			{"number": 2, "direction": "down", "text": "x"},
			{"number": 3, "direction": "down", "text": "x"},
			{"number": 4, "direction": "across", "text": "x"},
			{"number": 5, "direction": "across", "text": "x"},
		],
	})
	var issues: Array = PuzzleValidator.validate(puzzle, 4)
	var codes: Array = _codes(issues)
	assert_has(codes, "short_word")


func test_missing_clue_reported() -> void:
	# Remove the 4-Across clue from the well-formed puzzle.
	var payload: Dictionary = {
		"size": 5,
		"grid": ["PUTTS", "E###C", "AMIGO", "C###R", "HALVE"],
		"clues": [
			{"number": 1, "direction": "across", "text": "a"},
			{"number": 3, "direction": "across", "text": "b"},
			{"number": 1, "direction": "down", "text": "c"},
			{"number": 2, "direction": "down", "text": "d"},
			# 4-Across deliberately missing
		],
	}
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict(payload)
	var issues: Array = PuzzleValidator.validate(puzzle)
	var codes: Array = _codes(issues)
	assert_has(codes, "missing_clue")


func test_empty_clue_text_reported() -> void:
	var payload: Dictionary = {
		"size": 5,
		"grid": ["PUTTS", "E###C", "AMIGO", "C###R", "HALVE"],
		"clues": [
			{"number": 1, "direction": "across", "text": ""},  # blank
			{"number": 3, "direction": "across", "text": "b"},
			{"number": 4, "direction": "across", "text": "c"},
			{"number": 1, "direction": "down", "text": "d"},
			{"number": 2, "direction": "down", "text": "e"},
		],
	}
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict(payload)
	var issues: Array = PuzzleValidator.validate(puzzle)
	var codes: Array = _codes(issues)
	assert_has(codes, "empty_clue_text")


func test_duplicate_clue_reported() -> void:
	var payload: Dictionary = {
		"size": 5,
		"grid": ["PUTTS", "E###C", "AMIGO", "C###R", "HALVE"],
		"clues": [
			{"number": 1, "direction": "across", "text": "a"},
			{"number": 1, "direction": "across", "text": "duplicate"},
			{"number": 3, "direction": "across", "text": "b"},
			{"number": 4, "direction": "across", "text": "c"},
			{"number": 1, "direction": "down", "text": "d"},
			{"number": 2, "direction": "down", "text": "e"},
		],
	}
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict(payload)
	var issues: Array = PuzzleValidator.validate(puzzle)
	var codes: Array = _codes(issues)
	assert_has(codes, "duplicate_clue")


func test_orphan_clue_reported_as_warning_not_error() -> void:
	var payload: Dictionary = {
		"size": 5,
		"grid": ["PUTTS", "E###C", "AMIGO", "C###R", "HALVE"],
		"clues": [
			{"number": 1, "direction": "across", "text": "a"},
			{"number": 3, "direction": "across", "text": "b"},
			{"number": 4, "direction": "across", "text": "c"},
			{"number": 1, "direction": "down", "text": "d"},
			{"number": 2, "direction": "down", "text": "e"},
			{"number": 99, "direction": "across", "text": "ghost"},  # orphan
		],
	}
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict(payload)
	var issues: Array = PuzzleValidator.validate(puzzle)
	var codes: Array = _codes(issues)
	assert_has(codes, "orphan_clue")
	assert_false(PuzzleValidator.has_errors(issues))


func test_count_by_severity() -> void:
	var puzzle: Dictionary = CrosswordSerializer.puzzle_from_dict({
		"size": 3,
		"grid": ["A#B", "CDE", "FGH"],
		"clues": [],
	})
	var issues: Array = PuzzleValidator.validate(puzzle)
	assert_gt(PuzzleValidator.count_by_severity(issues, PuzzleValidator.SEVERITY_ERROR), 0)


func test_validates_shipped_mall_day_one() -> void:
	var puzzle: Dictionary = PuzzleLoader.load_by_id("mall_day_one")
	var issues: Array = PuzzleValidator.validate(puzzle)
	# The shipped puzzle must be clean — no errors, no warnings.
	assert_eq(issues.size(), 0, "mall_day_one.json should validate cleanly")


func _codes(issues: Array) -> Array:
	var codes: Array = []
	for issue in issues:
		codes.append(issue["code"])
	return codes
