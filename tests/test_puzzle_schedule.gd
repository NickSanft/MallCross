extends "res://addons/gut/test.gd"


# ---- MINI (default) ----


func test_day_one_returns_mall_day_one() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1), "mall_day_one")


func test_day_two_returns_mall_day_two() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(2), "mall_day_two")


func test_day_beyond_schedule_returns_empty() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(999), "")


func test_day_zero_returns_empty() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(0), "")


func test_negative_day_returns_empty() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(-5), "")


func test_has_puzzle_true_for_scheduled() -> void:
	assert_true(PuzzleSchedule.has_puzzle_for_day(1))
	assert_true(PuzzleSchedule.has_puzzle_for_day(2))


func test_has_puzzle_false_for_unscheduled() -> void:
	assert_false(PuzzleSchedule.has_puzzle_for_day(8))


func test_scheduled_days_returns_sorted_list() -> void:
	var days: Array = PuzzleSchedule.scheduled_days()
	assert_eq(days, [1, 2, 3, 4, 5, 6, 7])


func test_last_scheduled_day_returns_max() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(), 7)


func test_full_week_each_day_has_puzzle() -> void:
	for day in range(1, 8):
		assert_true(PuzzleSchedule.has_puzzle_for_day(day), "Day %d should have a puzzle scheduled" % day)


func test_full_week_puzzle_ids_are_distinct() -> void:
	var ids: Array = []
	for day in PuzzleSchedule.scheduled_days():
		ids.append(PuzzleSchedule.puzzle_id_for_day(day))
	var unique: Dictionary = {}
	for id in ids:
		unique[id] = true
	assert_eq(unique.size(), ids.size(), "All scheduled days should map to distinct puzzle IDs")


# ---- MIDI ----


func test_midi_day_one_has_puzzle() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, PuzzleSchedule.DIFFICULTY_MIDI), "mall_midi_day_one")


func test_midi_day_two_returns_empty() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(2, PuzzleSchedule.DIFFICULTY_MIDI), "")


func test_midi_last_scheduled_day() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_MIDI), 1)


# ---- FULL ----


func test_full_day_one_has_puzzle() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, PuzzleSchedule.DIFFICULTY_FULL), "mall_full_day_one")


func test_full_day_two_returns_empty() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(2, PuzzleSchedule.DIFFICULTY_FULL), "")


func test_full_last_scheduled_day() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_FULL), 1)


# ---- cross-difficulty ----


func test_unknown_difficulty_falls_back_to_mini() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "expert"), "mall_day_one")


func test_difficulty_lookup_is_case_insensitive() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "MIDI"), "mall_midi_day_one")
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "Full"), "mall_full_day_one")


func test_all_difficulties_returns_three() -> void:
	assert_eq(PuzzleSchedule.all_difficulties().size(), 3)


func test_every_scheduled_id_across_all_difficulties_loads() -> void:
	# Meta-test: every difficulty's every scheduled day must point at a JSON
	# file that loads cleanly.
	for difficulty in PuzzleSchedule.all_difficulties():
		for day in PuzzleSchedule.scheduled_days(difficulty):
			var id: String = PuzzleSchedule.puzzle_id_for_day(day, difficulty)
			var puzzle: Dictionary = PuzzleLoader.load_by_id(id)
			var grid: CrosswordGrid = puzzle.get("grid")
			assert_not_null(grid, "%s day %d (%s) should load a grid" % [difficulty, day, id])
			assert_gt(grid.size, 0, "%s day %d (%s) grid should be non-empty" % [difficulty, day, id])
