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
	# Day 14+: beyond the current MINI schedule (extended to 13 in v1.0.2).
	# Asserts the schedule has a well-defined endpoint rather than a specific
	# length so this test survives future extensions.
	var beyond: int = PuzzleSchedule.last_scheduled_day() + 1
	assert_false(PuzzleSchedule.has_puzzle_for_day(beyond))


func test_scheduled_days_returns_sorted_list() -> void:
	var days: Array = PuzzleSchedule.scheduled_days()
	# Days 1-13 in v1.0.2; will grow to 14 on the next MINI content drop.
	assert_eq(days, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])


func test_last_scheduled_day_returns_max() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(), 13)


func test_full_week_each_day_has_puzzle() -> void:
	# Originally a "first 7 days" guarantee; broadened in v1.0.2 to "every
	# scheduled day in MINI maps to a non-empty puzzle id." The original
	# property still holds — days 1-7 ARE still scheduled.
	for day in PuzzleSchedule.scheduled_days():
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


func test_midi_day_two_returns_midi_day_two_now() -> void:
	# v1.0.3 extended MIDI to 7 days. Asserts the new schedule shape and that
	# the puzzle id follows the day-number naming convention.
	assert_eq(PuzzleSchedule.puzzle_id_for_day(2, PuzzleSchedule.DIFFICULTY_MIDI), "mall_midi_day_two")


func test_midi_beyond_schedule_returns_empty() -> void:
	# Beyond the current MIDI schedule (extends to 7 days in v1.0.3).
	var beyond: int = PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_MIDI) + 1
	assert_eq(PuzzleSchedule.puzzle_id_for_day(beyond, PuzzleSchedule.DIFFICULTY_MIDI), "")


func test_midi_last_scheduled_day() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_MIDI), 7)


func test_midi_all_seven_days_distinct() -> void:
	var ids: Dictionary = {}
	for day in PuzzleSchedule.scheduled_days(PuzzleSchedule.DIFFICULTY_MIDI):
		ids[PuzzleSchedule.puzzle_id_for_day(day, PuzzleSchedule.DIFFICULTY_MIDI)] = true
	assert_eq(ids.size(), PuzzleSchedule.scheduled_days(PuzzleSchedule.DIFFICULTY_MIDI).size())


# ---- FULL ----


func test_full_day_one_has_puzzle() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, PuzzleSchedule.DIFFICULTY_FULL), "mall_full_day_one")


func test_full_day_two_returns_full_day_two_now() -> void:
	# v1.0.4 extended FULL to 7 days. Asserts the new schedule shape.
	assert_eq(PuzzleSchedule.puzzle_id_for_day(2, PuzzleSchedule.DIFFICULTY_FULL), "mall_full_day_two")


func test_full_beyond_schedule_returns_empty() -> void:
	var beyond: int = PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_FULL) + 1
	assert_eq(PuzzleSchedule.puzzle_id_for_day(beyond, PuzzleSchedule.DIFFICULTY_FULL), "")


func test_full_last_scheduled_day() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(PuzzleSchedule.DIFFICULTY_FULL), 7)


func test_full_all_seven_days_distinct() -> void:
	var ids: Dictionary = {}
	for day in PuzzleSchedule.scheduled_days(PuzzleSchedule.DIFFICULTY_FULL):
		ids[PuzzleSchedule.puzzle_id_for_day(day, PuzzleSchedule.DIFFICULTY_FULL)] = true
	assert_eq(ids.size(), PuzzleSchedule.scheduled_days(PuzzleSchedule.DIFFICULTY_FULL).size())


# ---- cross-difficulty ----


func test_unknown_difficulty_falls_back_to_mini() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "expert"), "mall_day_one")


func test_difficulty_lookup_is_case_insensitive() -> void:
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "MIDI"), "mall_midi_day_one")
	assert_eq(PuzzleSchedule.puzzle_id_for_day(1, "Full"), "mall_full_day_one")


func test_all_difficulties_returns_three() -> void:
	assert_eq(PuzzleSchedule.all_difficulties().size(), 3)


# ----- Rooftop (v1.9.0) ----------------------------------------------

func test_rooftop_puzzle_for_week_one() -> void:
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_week(1), "rooftop_week_one")


func test_rooftop_puzzle_for_week_four() -> void:
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_week(4), "rooftop_week_four")


func test_rooftop_clamps_zero_to_week_one() -> void:
	# Day 0 / week 0 sentinel from an uninitialized profile shouldn't
	# return empty string — clamp up to week 1.
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_week(0), "rooftop_week_one")


func test_rooftop_clamps_above_four_to_week_four() -> void:
	# SeasonMath.week_of_season is supposed to clamp 5+ down to 4 already,
	# but the schedule helper defends against bugs upstream too.
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_week(7), "rooftop_week_four")


func test_rooftop_puzzle_for_day_uses_week_of_season() -> void:
	# Day 1 -> week 1, day 8 -> week 2, day 22 -> week 4.
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_day(1), "rooftop_week_one")
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_day(8), "rooftop_week_two")
	assert_eq(PuzzleSchedule.rooftop_puzzle_for_day(22), "rooftop_week_four")


func test_rooftop_puzzles_have_four_distinct_ids() -> void:
	var ids: Array = PuzzleSchedule.all_rooftop_puzzles()
	assert_eq(ids.size(), 4)
	var seen: Dictionary = {}
	for id in ids:
		assert_false(seen.has(id), "Duplicate rooftop id: " + id)
		seen[id] = true


func test_rooftop_not_in_all_difficulties() -> void:
	# Rooftop puzzles are week-indexed, not day-indexed. They live outside
	# the standard daily schedule axis.
	assert_does_not_have(PuzzleSchedule.all_difficulties(), PuzzleSchedule.DIFFICULTY_ROOFTOP)


func test_every_rooftop_puzzle_file_loads() -> void:
	# Companion to test_every_scheduled_id_across_all_difficulties_loads.
	# Walks the rooftop set explicitly because it isn't in the daily
	# schedule axis the original test covers.
	for id in PuzzleSchedule.all_rooftop_puzzles():
		var puzzle: Dictionary = PuzzleLoader.load_by_id(id)
		var grid: CrosswordGrid = puzzle.get("grid")
		assert_not_null(grid, "rooftop %s should load" % id)
		assert_gt(grid.size, 0, "rooftop %s grid should be non-empty" % id)


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
