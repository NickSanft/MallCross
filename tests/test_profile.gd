extends "res://addons/gut/test.gd"


func _fresh_state_for_3x3() -> CrosswordState:
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "A")
	state.set_letter(1, 1, "E", true)
	return state


func test_new_profile_defaults() -> void:
	var profile: Profile = Profile.new()
	assert_eq(profile.woints, 0)
	assert_eq(profile.current_day, 1)
	assert_eq(profile.version, Profile.FORMAT_VERSION)


func test_add_woints_increases_balance() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(50)
	assert_eq(profile.woints, 50)


func test_add_woints_clamps_negative() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(-10)
	assert_eq(profile.woints, 0)


func test_add_woints_can_decrement_above_zero() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(100)
	profile.add_woints(-30)
	assert_eq(profile.woints, 70)


func test_mark_puzzle_solved_returns_true_first_time() -> void:
	var profile: Profile = Profile.new()
	assert_true(profile.mark_puzzle_solved("demo_5x5"))


func test_mark_puzzle_solved_returns_false_on_repeat() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("demo_5x5")
	assert_false(profile.mark_puzzle_solved("demo_5x5"))


func test_mark_puzzle_solved_records_first_day() -> void:
	var profile: Profile = Profile.new()
	profile.current_day = 4
	profile.mark_puzzle_solved("demo_5x5")
	assert_eq(profile.first_solved_day("demo_5x5"), 4)


func test_mark_puzzle_solved_ignores_empty_id() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.mark_puzzle_solved(""))
	assert_false(profile.is_puzzle_solved(""))


func test_is_puzzle_solved_false_by_default() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.is_puzzle_solved("demo_5x5"))


func test_advance_day_increments_by_one() -> void:
	var profile: Profile = Profile.new()
	profile.advance_day()
	assert_eq(profile.current_day, 2)


func test_advance_day_custom_amount() -> void:
	var profile: Profile = Profile.new()
	profile.advance_day(3)
	assert_eq(profile.current_day, 4)


func test_advance_day_clamps_at_one() -> void:
	var profile: Profile = Profile.new()
	profile.advance_day(-100)
	assert_eq(profile.current_day, 1)


func test_cache_and_restore_state_round_trip() -> void:
	var profile: Profile = Profile.new()
	var state: CrosswordState = _fresh_state_for_3x3()
	profile.cache_state("demo_5x5", state)
	var restored: CrosswordState = profile.get_cached_state("demo_5x5")
	assert_not_null(restored)
	assert_eq(restored.entry_at(0, 0), "A")
	assert_eq(restored.entry_at(1, 1), "E")
	assert_true(restored.is_pencil(1, 1))


func test_cache_state_ignores_empty_id() -> void:
	var profile: Profile = Profile.new()
	profile.cache_state("", _fresh_state_for_3x3())
	assert_null(profile.get_cached_state(""))


func test_cache_state_ignores_null_state() -> void:
	var profile: Profile = Profile.new()
	profile.cache_state("demo", null)
	assert_null(profile.get_cached_state("demo"))


func test_to_dict_emits_format_version() -> void:
	var profile: Profile = Profile.new()
	var d: Dictionary = profile.to_dict()
	assert_eq(d["version"], Profile.FORMAT_VERSION)


func test_to_dict_includes_woints_and_day() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(75)
	profile.current_day = 3
	var d: Dictionary = profile.to_dict()
	assert_eq(d["woints"], 75)
	assert_eq(d["current_day"], 3)


func test_to_dict_serializes_cached_states() -> void:
	var profile: Profile = Profile.new()
	profile.cache_state("demo_5x5", _fresh_state_for_3x3())
	var d: Dictionary = profile.to_dict()
	var states: Dictionary = d["puzzle_states"]
	assert_true(states.has("demo_5x5"))
	var state_payload: Dictionary = states["demo_5x5"]
	assert_eq(state_payload["size"], 3)


func test_from_dict_round_trips_woints() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(200)
	profile.current_day = 5
	var restored: Profile = Profile.from_dict(profile.to_dict())
	assert_eq(restored.woints, 200)
	assert_eq(restored.current_day, 5)


func test_from_dict_round_trips_solved_set_with_day() -> void:
	var profile: Profile = Profile.new()
	profile.current_day = 4
	profile.mark_puzzle_solved("demo_5x5")
	var restored: Profile = Profile.from_dict(profile.to_dict())
	assert_true(restored.is_puzzle_solved("demo_5x5"))
	assert_eq(restored.first_solved_day("demo_5x5"), 4)


func test_from_dict_round_trips_cached_states() -> void:
	var profile: Profile = Profile.new()
	profile.cache_state("demo_5x5", _fresh_state_for_3x3())
	var restored: Profile = Profile.from_dict(profile.to_dict())
	var state: CrosswordState = restored.get_cached_state("demo_5x5")
	assert_not_null(state)
	assert_eq(state.entry_at(0, 0), "A")
	assert_true(state.is_pencil(1, 1))


func test_from_dict_defaults_for_missing_fields() -> void:
	var restored: Profile = Profile.from_dict({})
	assert_eq(restored.woints, 0)
	assert_eq(restored.current_day, 1)
	assert_false(restored.is_puzzle_solved("anything"))


func test_from_dict_clamps_negative_woints() -> void:
	var restored: Profile = Profile.from_dict({"woints": -50})
	assert_eq(restored.woints, 0)


func test_from_dict_clamps_zero_day_to_one() -> void:
	var restored: Profile = Profile.from_dict({"current_day": 0})
	assert_eq(restored.current_day, 1)


# ---- inventory ----


func test_own_item_first_time_returns_true() -> void:
	var profile: Profile = Profile.new()
	assert_true(profile.own_item("coffee"))


func test_own_item_repeat_returns_false() -> void:
	var profile: Profile = Profile.new()
	profile.own_item("coffee")
	assert_false(profile.own_item("coffee"))


func test_own_item_empty_id_ignored() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.own_item(""))
	assert_false(profile.owns(""))


func test_owns_false_by_default() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.owns("coffee"))


func test_owns_true_after_own() -> void:
	var profile: Profile = Profile.new()
	profile.own_item("coffee")
	assert_true(profile.owns("coffee"))


func test_can_afford_with_sufficient_balance() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(100)
	assert_true(profile.can_afford(50))


func test_can_afford_at_exact_cost() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(50)
	assert_true(profile.can_afford(50))


func test_can_afford_false_when_short() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(20)
	assert_false(profile.can_afford(50))


func test_try_purchase_success_deducts_and_adds() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(100)
	assert_true(profile.try_purchase("coffee", 40))
	assert_eq(profile.woints, 60)
	assert_true(profile.owns("coffee"))


func test_try_purchase_fails_when_unaffordable_no_mutation() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(10)
	assert_false(profile.try_purchase("coffee", 40))
	assert_eq(profile.woints, 10)
	assert_false(profile.owns("coffee"))


func test_try_purchase_fails_when_already_owned() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(200)
	profile.try_purchase("coffee", 40)
	assert_false(profile.try_purchase("coffee", 40))
	# Second purchase should not double-deduct
	assert_eq(profile.woints, 160)


func test_try_purchase_empty_id_fails() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(100)
	assert_false(profile.try_purchase("", 40))


func test_try_purchase_negative_cost_fails() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(100)
	assert_false(profile.try_purchase("coffee", -10))


func test_inventory_round_trips_through_dict() -> void:
	var profile: Profile = Profile.new()
	profile.add_woints(200)
	profile.try_purchase("coffee", 40)
	profile.try_purchase("mall_cap", 100)
	var restored: Profile = Profile.from_dict(profile.to_dict())
	assert_true(restored.owns("coffee"))
	assert_true(restored.owns("mall_cap"))
	assert_eq(restored.woints, 60)


func test_inventory_dedupes_on_load() -> void:
	# Defensive: bad save file with duplicate ids should not result in twice-owned.
	var restored: Profile = Profile.from_dict({"owned_items": ["coffee", "coffee", "mall_cap"]})
	assert_eq(restored.owned_items.size(), 2)


func test_inventory_load_ignores_non_string_entries() -> void:
	var restored: Profile = Profile.from_dict({"owned_items": ["coffee", 42, null, "mall_cap"]})
	assert_eq(restored.owned_items, ["coffee", "mall_cap"])


# ---- streak ----


func test_streak_zero_by_default() -> void:
	var profile: Profile = Profile.new()
	assert_eq(profile.streak, 0)
	assert_eq(profile.last_solved_day, 0)


func test_first_solve_sets_streak_to_one() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")
	assert_eq(profile.streak, 1)
	assert_eq(profile.last_solved_day, 1)


func test_consecutive_day_solve_increments_streak() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")  # day 1, streak -> 1
	profile.advance_day()             # day 2
	profile.mark_puzzle_solved("b")
	assert_eq(profile.streak, 2)
	assert_eq(profile.last_solved_day, 2)


func test_streak_continues_across_multiple_days() -> void:
	var profile: Profile = Profile.new()
	for puzzle_id in ["a", "b", "c", "d"]:
		profile.mark_puzzle_solved(puzzle_id)
		profile.advance_day()
	# After 4 consecutive solves: streak = 4
	assert_eq(profile.streak, 4)


func test_same_day_second_solve_does_not_change_streak() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")
	profile.mark_puzzle_solved("b")  # same day; streak unchanged
	assert_eq(profile.streak, 1)


func test_skipped_day_resets_streak() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")  # day 1
	profile.advance_day()
	profile.advance_day()             # jump to day 3 (skipped day 2)
	profile.mark_puzzle_solved("b")
	assert_eq(profile.streak, 1)


func test_repeat_solve_attempt_does_not_change_streak() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")
	profile.advance_day()
	profile.mark_puzzle_solved("a")  # already solved; no-op
	# Streak should NOT advance because this wasn't a first-solve.
	assert_eq(profile.streak, 1)
	assert_eq(profile.last_solved_day, 1)


func test_streak_and_last_solved_day_round_trip_via_dict() -> void:
	var profile: Profile = Profile.new()
	profile.mark_puzzle_solved("a")
	profile.advance_day()
	profile.mark_puzzle_solved("b")
	# streak = 2, last_solved_day = 2
	var restored: Profile = Profile.from_dict(profile.to_dict())
	assert_eq(restored.streak, 2)
	assert_eq(restored.last_solved_day, 2)


func test_from_dict_clamps_negative_streak() -> void:
	var restored: Profile = Profile.from_dict({"streak": -5})
	assert_eq(restored.streak, 0)


func test_from_dict_clamps_negative_last_solved_day() -> void:
	var restored: Profile = Profile.from_dict({"last_solved_day": -3})
	assert_eq(restored.last_solved_day, 0)
