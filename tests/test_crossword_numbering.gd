extends "res://addons/gut/test.gd"


func _fixture_3x3() -> CrosswordGrid:
	return CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])


func _fixture_5x5() -> CrosswordGrid:
	return CrosswordGrid.from_strings([
		"ABCDE",
		"F#G#H",
		"IJKLM",
		"N#O#P",
		"QRSTU",
	])


func test_3x3_open_grid_has_five_numbered_cells() -> void:
	# (0,0) 1, (0,1) 2, (0,2) 3, (1,0) 4, (2,0) 5
	var numbers: Array = CrosswordNumbering.compute_numbers(_fixture_3x3())
	assert_eq(numbers[0][0], 1)
	assert_eq(numbers[0][1], 2)
	assert_eq(numbers[0][2], 3)
	assert_eq(numbers[1][0], 4)
	assert_eq(numbers[2][0], 5)
	assert_eq(numbers[1][1], 0)
	assert_eq(numbers[2][2], 0)


func test_5x5_with_blocks_numbers_only_word_starts() -> void:
	# Expected: 1 at (0,0), 2 at (0,2), 3 at (0,4), 4 at (2,0), 5 at (4,0).
	# Stranded length-1 segments (F, G, H, N, O, P) get no number.
	var numbers: Array = CrosswordNumbering.compute_numbers(_fixture_5x5())
	assert_eq(numbers[0][0], 1)
	assert_eq(numbers[0][2], 2)
	assert_eq(numbers[0][4], 3)
	assert_eq(numbers[2][0], 4)
	assert_eq(numbers[4][0], 5)
	# Stranded length-1 across cells must NOT be numbered:
	assert_eq(numbers[1][0], 0)
	assert_eq(numbers[1][2], 0)
	assert_eq(numbers[1][4], 0)
	assert_eq(numbers[3][0], 0)


func test_block_cells_never_get_numbered() -> void:
	var numbers: Array = CrosswordNumbering.compute_numbers(_fixture_5x5())
	assert_eq(numbers[1][1], 0)
	assert_eq(numbers[1][3], 0)
	assert_eq(numbers[3][1], 0)
	assert_eq(numbers[3][3], 0)


func test_find_word_slots_3x3_returns_six_slots() -> void:
	# 3 across (rows) + 3 down (cols)
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_3x3())
	assert_eq(slots.size(), 6)


func test_find_word_slots_3x3_across_answers() -> void:
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_3x3())
	var across: Array = CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.ACROSS)
	var answers: Array = []
	for s in across:
		answers.append(s["answer"])
	answers.sort()
	assert_eq(answers, ["ABC", "DEF", "GHI"])


func test_find_word_slots_3x3_down_answers() -> void:
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_3x3())
	var down: Array = CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.DOWN)
	var answers: Array = []
	for s in down:
		answers.append(s["answer"])
	answers.sort()
	assert_eq(answers, ["ADG", "BEH", "CFI"])


func test_find_word_slots_5x5_total_count() -> void:
	# 1-Across, 4-Across, 5-Across, 1-Down, 2-Down, 3-Down = 6 slots
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_5x5())
	assert_eq(slots.size(), 6)


func test_find_word_slots_5x5_1_down_is_five_letters() -> void:
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_5x5())
	for slot in slots:
		if slot["number"] == 1 and slot["direction"] == CrosswordNumbering.DOWN:
			assert_eq(slot["length"], 5)
			assert_eq(slot["answer"], "AFINQ")
			return
	fail_test("Expected 1-Down slot")


func test_find_word_slots_5x5_4_across_correct_answer() -> void:
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_5x5())
	for slot in slots:
		if slot["number"] == 4 and slot["direction"] == CrosswordNumbering.ACROSS:
			assert_eq(slot["answer"], "IJKLM")
			return
	fail_test("Expected 4-Across slot")


func test_slots_by_direction_filters_correctly() -> void:
	var slots: Array = CrosswordNumbering.find_word_slots(_fixture_5x5())
	var across: Array = CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.ACROSS)
	var down: Array = CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.DOWN)
	assert_eq(across.size(), 3)
	assert_eq(down.size(), 3)
