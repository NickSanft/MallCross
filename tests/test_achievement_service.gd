extends "res://addons/gut/test.gd"


# AchievementService unlock logic. Uses a synthetic catalog so the tests
# don't depend on the bundled data/achievements.json (lets us assert
# specific behaviors without "if the production catalog changes the count
# this test breaks" coupling).


# Catalog containing every id the service knows how to fire. Matches the
# production ids so the notify_* methods can be exercised end-to-end.
const _CATALOG: Array = [
	{"id": "first_solve", "name": "First Solve", "description": "Solve any puzzle.", "hidden": false},
	{"id": "mini_day_one", "name": "MINI Day 1", "description": "Solve MINI Day 1.", "hidden": false},
	{"id": "midi_day_one", "name": "MIDI Day 1", "description": "Solve MIDI Day 1.", "hidden": false},
	{"id": "full_day_one", "name": "FULL Day 1", "description": "Solve FULL Day 1.", "hidden": false},
	{"id": "streak_7", "name": "Streak 7", "description": "7-day streak.", "hidden": false},
	{"id": "streak_30", "name": "Streak 30", "description": "30-day streak.", "hidden": false},
	{"id": "no_checks", "name": "No Checks", "description": "Solve without checks.", "hidden": false},
	{"id": "speed_mini", "name": "Speed Demon", "description": "MINI under 60s.", "hidden": false},
	{"id": "polyglot", "name": "Polyglot", "description": "One of each tier in a day.", "hidden": false},
	{"id": "caffeinated", "name": "Caffeinated", "description": "Buy coffee.", "hidden": false},
	{"id": "bookworm", "name": "Bookworm", "description": "Buy pencil.", "hidden": false},
	{"id": "big_spender", "name": "Big Spender", "description": "Last Woint.", "hidden": false},
	{"id": "hoarder", "name": "Hoarder", "description": "1000 Woints.", "hidden": false},
	{"id": "season_pass", "name": "Season Pass", "description": "21 solves in a season.", "hidden": false},
	{"id": "rooftop_regular", "name": "Rooftop Regular", "description": "All 4 rooftop puzzles.", "hidden": false},
	{"id": "perfectionist", "name": "Perfectionist", "description": "Every scheduled puzzle in a season.", "hidden": true},
]


func _service() -> AchievementService:
	return AchievementService.new(_CATALOG, {})


# ----- primitives -------------------------------------------------------

func test_new_service_has_no_unlocks() -> void:
	var s: AchievementService = _service()
	assert_eq(s.unlocks.size(), 0)
	assert_false(s.is_unlocked("first_solve"))


func test_unlock_marks_id_unlocked() -> void:
	var s: AchievementService = _service()
	assert_true(s.unlock("first_solve", 3))
	assert_true(s.is_unlocked("first_solve"))
	assert_eq(int(s.unlocks["first_solve"]), 3)


func test_unlock_is_idempotent() -> void:
	var s: AchievementService = _service()
	assert_true(s.unlock("first_solve", 1))
	assert_false(s.unlock("first_solve", 99))
	assert_eq(int(s.unlocks["first_solve"]), 1)  # day not overwritten


func test_unlock_rejects_unknown_id() -> void:
	var s: AchievementService = _service()
	assert_false(s.unlock("no_such_id", 1))


func test_progress_string_format() -> void:
	var s: AchievementService = _service()
	s.unlock("first_solve", 1)
	s.unlock("mini_day_one", 1)
	assert_eq(s.progress_string(), "2 / %d" % _CATALOG.size())


# ----- notify_puzzle_solved --------------------------------------------

func test_notify_first_solve_fires_first_solve() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 5000, false, profile)
	assert_true(fired.has("first_solve"))


func test_notify_solving_mall_day_one_fires_mini_day_one() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 5000, false, profile)
	assert_true(fired.has("mini_day_one"))


func test_notify_solving_midi_day_one_fires_midi_day_one() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_midi_day_one", PuzzleSchedule.DIFFICULTY_MIDI, 1, 20000, false, profile)
	assert_true(fired.has("midi_day_one"))


func test_notify_with_check_letter_does_not_fire_no_checks() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 5000, true, profile)
	assert_false(fired.has("no_checks"))


func test_notify_without_check_letter_fires_no_checks() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 5000, false, profile)
	assert_true(fired.has("no_checks"))


func test_mini_under_60s_fires_speed_mini() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 45000, false, profile)
	assert_true(fired.has("speed_mini"))


func test_mini_at_60s_does_not_fire_speed_mini() -> void:
	# Strict <60s. A 60.0-second solve is over the threshold.
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_day_one", PuzzleSchedule.DIFFICULTY_MINI, 1, 60000, false, profile)
	assert_false(fired.has("speed_mini"))


func test_midi_under_60s_does_not_fire_speed_mini() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_puzzle_solved("mall_midi_day_one", PuzzleSchedule.DIFFICULTY_MIDI, 1, 30000, false, profile)
	assert_false(fired.has("speed_mini"))


func test_polyglot_fires_when_all_three_tiers_solved_on_same_day() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	profile.current_day = 1
	# Walk all three Day 1 puzzles. The third notify should fire polyglot.
	profile.mark_puzzle_solved("mall_day_one")
	profile.mark_puzzle_solved("mall_midi_day_one")
	profile.mark_puzzle_solved("mall_full_day_one")
	# notify_puzzle_solved checks the live profile, not the (puzzle_id, ...)
	# args, for the polyglot condition.
	var fired: Array = s.notify_puzzle_solved("mall_full_day_one", PuzzleSchedule.DIFFICULTY_FULL, 1, 60000, false, profile)
	assert_true(fired.has("polyglot"))


func test_polyglot_does_not_fire_when_only_two_tiers_solved() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	profile.current_day = 1
	profile.mark_puzzle_solved("mall_day_one")
	profile.mark_puzzle_solved("mall_midi_day_one")
	# FULL not solved on day 1.
	var fired: Array = s.notify_puzzle_solved("mall_midi_day_one", PuzzleSchedule.DIFFICULTY_MIDI, 1, 30000, false, profile)
	assert_false(fired.has("polyglot"))


# ----- notify_streak ----------------------------------------------------

func test_streak_at_7_fires_streak_7() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_streak(7, 7)
	assert_true(fired.has("streak_7"))
	assert_false(fired.has("streak_30"))


func test_streak_at_30_fires_both_streak_achievements() -> void:
	# A fresh service at streak 30 (e.g. loaded a save) should pick up
	# both streak_7 and streak_30 in one call.
	var s: AchievementService = _service()
	var fired: Array = s.notify_streak(30, 30)
	assert_true(fired.has("streak_7"))
	assert_true(fired.has("streak_30"))


func test_streak_below_7_fires_nothing() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_streak(6, 6)
	assert_eq(fired.size(), 0)


# ----- notify_item_purchased -------------------------------------------

func test_buying_coffee_fires_caffeinated() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_item_purchased("coffee", 50, 1)
	assert_true(fired.has("caffeinated"))


func test_buying_pencil_fires_bookworm() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_item_purchased("pencil", 50, 1)
	assert_true(fired.has("bookworm"))


func test_purchase_to_zero_woints_fires_big_spender() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_item_purchased("coffee", 0, 1)
	assert_true(fired.has("big_spender"))
	assert_true(fired.has("caffeinated"))


# ----- notify_woints ---------------------------------------------------

func test_woints_at_threshold_fires_hoarder() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_woints(1000, 1)
	assert_true(fired.has("hoarder"))


func test_woints_below_threshold_fires_nothing() -> void:
	var s: AchievementService = _service()
	var fired: Array = s.notify_woints(999, 1)
	assert_eq(fired.size(), 0)


func test_woints_idempotent_on_repeat_calls() -> void:
	var s: AchievementService = _service()
	var first: Array = s.notify_woints(1500, 1)
	var second: Array = s.notify_woints(1500, 2)
	assert_true(first.has("hoarder"))
	assert_eq(second.size(), 0)  # Already unlocked; doesn't re-fire.


# ----- all_with_state --------------------------------------------------

func test_all_with_state_includes_unlock_marker() -> void:
	var s: AchievementService = _service()
	s.unlock("first_solve", 3)
	var entries: Array = s.all_with_state()
	for entry in entries:
		if String(entry["id"]) == "first_solve":
			assert_true(bool(entry["unlocked"]))
			assert_eq(int(entry["unlock_day"]), 3)
			return
	fail_test("first_solve missing from all_with_state output")


# ----- v1.9.0 rooftop + season-progress hooks --------------------------

func test_notify_rooftop_solved_does_not_fire_until_all_four() -> void:
	# Solve three out of four; rooftop_regular should NOT fire.
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("rooftop_week_one")
	profile.mark_puzzle_solved("rooftop_week_two")
	profile.mark_puzzle_solved("rooftop_week_three")
	var fired: Array = s.notify_rooftop_solved("rooftop_week_three", 1, profile)
	assert_false(fired.has("rooftop_regular"))


func test_notify_rooftop_solved_fires_after_fourth() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	for week_id in ["rooftop_week_one", "rooftop_week_two", "rooftop_week_three", "rooftop_week_four"]:
		profile.mark_puzzle_solved(week_id)
	var fired: Array = s.notify_rooftop_solved("rooftop_week_four", 22, profile)
	assert_true(fired.has("rooftop_regular"))


func test_notify_rooftop_solved_empty_puzzle_id_no_op() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	var fired: Array = s.notify_rooftop_solved("", 1, profile)
	assert_eq(fired.size(), 0)


func test_notify_season_progress_fires_season_pass_at_21() -> void:
	# Profile has 21 first-solves in the current season.
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	profile.current_day = 25
	for i in range(21):
		profile.mark_puzzle_solved("p_" + str(i))
		profile.current_day = i + 1
	profile.current_day = 25  # current day inside season 1
	var fired: Array = s.notify_season_progress(profile)
	assert_true(fired.has("season_pass"))


func test_notify_season_progress_does_not_fire_at_20() -> void:
	var s: AchievementService = _service()
	var profile: Profile = Profile.new()
	for i in range(20):
		profile.mark_puzzle_solved("p_" + str(i))
		profile.current_day = i + 1
	profile.current_day = 25
	var fired: Array = s.notify_season_progress(profile)
	assert_false(fired.has("season_pass"))


func test_notify_season_progress_handles_null_profile() -> void:
	# Defensive: a null profile shouldn't crash the call.
	var s: AchievementService = _service()
	var fired: Array = s.notify_season_progress(null)
	assert_eq(fired.size(), 0)
