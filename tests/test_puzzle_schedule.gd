extends "res://addons/gut/test.gd"


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
	assert_false(PuzzleSchedule.has_puzzle_for_day(3))


func test_scheduled_days_returns_sorted_list() -> void:
	var days: Array = PuzzleSchedule.scheduled_days()
	assert_eq(days, [1, 2])


func test_last_scheduled_day_returns_max() -> void:
	assert_eq(PuzzleSchedule.last_scheduled_day(), 2)


func test_every_scheduled_id_loads_a_real_puzzle() -> void:
	# Meta-test: anything in the schedule must point at a JSON file that
	# loads cleanly. Catches schedule/data drift.
	for day in PuzzleSchedule.scheduled_days():
		var id: String = PuzzleSchedule.puzzle_id_for_day(day)
		var puzzle: Dictionary = PuzzleLoader.load_by_id(id)
		var grid: CrosswordGrid = puzzle.get("grid")
		assert_not_null(grid, "Day %d (%s) should load a grid" % [day, id])
		assert_gt(grid.size, 0, "Day %d (%s) grid should be non-empty" % [day, id])
