extends "res://addons/gut/test.gd"


# SeasonMath is the testable layer behind the v1.9.0 season-progression
# system. Locking in the math here keeps the rest of the wiring (rooftop
# unlock, achievements, future report card) free to refactor.


# ----- season_of_day ---------------------------------------------------

func test_day_1_is_season_1() -> void:
	assert_eq(SeasonMath.season_of_day(1), 1)


func test_day_30_is_season_1() -> void:
	assert_eq(SeasonMath.season_of_day(30), 1)


func test_day_31_is_season_2() -> void:
	assert_eq(SeasonMath.season_of_day(31), 2)


func test_day_60_is_season_2() -> void:
	assert_eq(SeasonMath.season_of_day(60), 2)


func test_day_61_is_season_3() -> void:
	assert_eq(SeasonMath.season_of_day(61), 3)


func test_day_zero_clamps_to_season_1() -> void:
	# Defensive: a sentinel day 0 from an uninitialized profile shouldn't
	# return season 0.
	assert_eq(SeasonMath.season_of_day(0), 1)


func test_negative_day_clamps_to_season_1() -> void:
	assert_eq(SeasonMath.season_of_day(-5), 1)


# ----- day_of_season ---------------------------------------------------

func test_day_of_season_1_in_season_1() -> void:
	assert_eq(SeasonMath.day_of_season(1), 1)


func test_day_of_season_30_in_season_1() -> void:
	assert_eq(SeasonMath.day_of_season(30), 30)


func test_day_of_season_31_resets_to_1() -> void:
	# Day 31 wall-clock = day 1 of season 2.
	assert_eq(SeasonMath.day_of_season(31), 1)


func test_day_of_season_60_is_30_in_season_2() -> void:
	assert_eq(SeasonMath.day_of_season(60), 30)


# ----- week_of_season --------------------------------------------------

func test_week_one_covers_days_one_through_seven() -> void:
	for d in [1, 2, 3, 4, 5, 6, 7]:
		assert_eq(SeasonMath.week_of_season(d), 1, "Day %d should be week 1" % d)


func test_week_two_covers_days_eight_through_fourteen() -> void:
	for d in [8, 9, 10, 11, 12, 13, 14]:
		assert_eq(SeasonMath.week_of_season(d), 2, "Day %d should be week 2" % d)


func test_week_three_covers_days_fifteen_through_twenty_one() -> void:
	for d in [15, 18, 21]:
		assert_eq(SeasonMath.week_of_season(d), 3, "Day %d should be week 3" % d)


func test_week_four_covers_days_twenty_two_through_twenty_eight() -> void:
	for d in [22, 25, 28]:
		assert_eq(SeasonMath.week_of_season(d), 4, "Day %d should be week 4" % d)


func test_week_four_absorbs_overflow_days_29_30() -> void:
	# Days 29 and 30 are technically week 5 but we clamp to week 4 so
	# rooftop puzzle assignment stays well-defined.
	assert_eq(SeasonMath.week_of_season(29), 4)
	assert_eq(SeasonMath.week_of_season(30), 4)


func test_week_of_season_resets_across_season_boundary() -> void:
	# Day 31 is day 1 of season 2 = week 1.
	assert_eq(SeasonMath.week_of_season(31), 1)
	# Day 38 is day 8 of season 2 = week 2.
	assert_eq(SeasonMath.week_of_season(38), 2)


# ----- season_range_for_day --------------------------------------------

func test_range_for_day_1() -> void:
	var r: Dictionary = SeasonMath.season_range_for_day(1)
	assert_eq(int(r["first"]), 1)
	assert_eq(int(r["last"]), 30)


func test_range_for_day_60() -> void:
	# day 60 falls in season 2 -> 31..60.
	var r: Dictionary = SeasonMath.season_range_for_day(60)
	assert_eq(int(r["first"]), 31)
	assert_eq(int(r["last"]), 60)


# ----- is_in_same_season -----------------------------------------------

func test_is_in_same_season_true_for_same_window() -> void:
	# day 5 and day 25 both in season 1.
	assert_true(SeasonMath.is_in_same_season(25, 5))


func test_is_in_same_season_false_across_boundary() -> void:
	# day 31 (season 2) vs day 25 (season 1).
	assert_false(SeasonMath.is_in_same_season(31, 25))


func test_is_in_same_season_false_for_zero_first_solved() -> void:
	# Defensive: an unsolved puzzle has first_solved_day == 0, which
	# should NOT count as "in this season."
	assert_false(SeasonMath.is_in_same_season(15, 0))


# ----- solves_in_current_season ----------------------------------------

func _solved_dict(days: Array) -> Dictionary:
	var out: Dictionary = {}
	var idx: int = 0
	for d in days:
		out["puzzle_" + str(idx)] = {"first_solved_day": int(d)}
		idx += 1
	return out


func test_count_zero_for_empty_dict() -> void:
	assert_eq(SeasonMath.solves_in_current_season(15, {}), 0)


func test_count_includes_only_current_season() -> void:
	# 3 solves in season 1, 2 solves in season 2. Current day is 50
	# (season 2) so only the season-2 solves count.
	var dict: Dictionary = _solved_dict([5, 12, 25, 35, 45])
	assert_eq(SeasonMath.solves_in_current_season(50, dict), 2)


func test_count_ignores_zero_first_solved_day() -> void:
	# Defensive: an entry with first_solved_day == 0 doesn't count.
	var dict: Dictionary = _solved_dict([0, 5, 0, 10])
	assert_eq(SeasonMath.solves_in_current_season(15, dict), 2)


func test_count_ignores_non_dict_entries() -> void:
	# Defensive: malformed profile shouldn't crash the count.
	var dict: Dictionary = {
		"good": {"first_solved_day": 5},
		"bad": "not a dict",
	}
	assert_eq(SeasonMath.solves_in_current_season(15, dict), 1)


# ----- is_rooftop_unlocked ---------------------------------------------

func test_rooftop_locked_below_21() -> void:
	var days: Array = []
	for i in range(20):
		days.append(i + 1)
	var dict: Dictionary = _solved_dict(days)
	assert_false(SeasonMath.is_rooftop_unlocked(25, dict))


func test_rooftop_unlocks_at_exactly_21() -> void:
	var days: Array = []
	for i in range(21):
		days.append(i + 1)
	var dict: Dictionary = _solved_dict(days)
	assert_true(SeasonMath.is_rooftop_unlocked(25, dict))


func test_rooftop_lock_resets_when_season_advances() -> void:
	# Player cleared 25 in season 1, then advanced to season 2 with
	# zero solves yet. Rooftop should be locked again.
	var days: Array = []
	for i in range(25):
		days.append(i + 1)
	var dict: Dictionary = _solved_dict(days)
	assert_true(SeasonMath.is_rooftop_unlocked(25, dict))
	assert_false(SeasonMath.is_rooftop_unlocked(35, dict))


func test_rooftop_unlock_threshold_constant_is_21() -> void:
	# Pinned so any future tweak to the design forces a matching
	# CHANGELOG entry.
	assert_eq(SeasonMath.ROOFTOP_UNLOCK_THRESHOLD, 21)


func test_days_per_season_is_30() -> void:
	assert_eq(SeasonMath.DAYS_PER_SEASON, 30)


func test_weeks_per_season_is_4() -> void:
	assert_eq(SeasonMath.WEEKS_PER_SEASON, 4)
