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


func test_mark_puzzle_solved_default_updates_streak() -> void:
	# Default behavior (used by daily puzzles): mark_puzzle_solved bumps
	# both streak and last_solved_day. Documented baseline.
	var profile: Profile = Profile.new()
	profile.current_day = 1
	profile.mark_puzzle_solved("daily")
	assert_eq(profile.streak, 1)
	assert_eq(profile.last_solved_day, 1)


func test_mark_puzzle_solved_with_update_streak_false_skips_streak() -> void:
	# Community puzzles (v1.3.0+) pass update_streak=false so they're
	# recorded for "already solved" but don't influence the daily streak.
	var profile: Profile = Profile.new()
	profile.current_day = 1
	profile.mark_puzzle_solved("user://puzzles/community.json", false)
	assert_true(profile.is_puzzle_solved("user://puzzles/community.json"))
	assert_eq(profile.streak, 0)
	assert_eq(profile.last_solved_day, 0)


func test_mixed_community_and_daily_solves_preserve_streak_purity() -> void:
	# Solve a daily, then a community, then another daily. The community
	# solve in the middle must not reset or extend the streak.
	var profile: Profile = Profile.new()
	profile.current_day = 1
	profile.mark_puzzle_solved("mall_day_one")  # daily; streak -> 1
	profile.mark_puzzle_solved("user://puzzles/x.json", false)  # community; no change
	profile.advance_day()
	profile.mark_puzzle_solved("mall_day_two")  # daily; streak -> 2
	assert_eq(profile.streak, 2)
	assert_eq(profile.last_solved_day, 2)


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


# ----- best_times (introduced in FORMAT_VERSION 2) -----------------------

func test_record_solve_time_first_time_returns_true() -> void:
	var profile: Profile = Profile.new()
	assert_true(profile.record_solve_time("p", 5000))
	assert_eq(profile.best_time_ms("p"), 5000)


func test_record_solve_time_improves_on_better_time() -> void:
	var profile: Profile = Profile.new()
	profile.record_solve_time("p", 5000)
	assert_true(profile.record_solve_time("p", 3200))
	assert_eq(profile.best_time_ms("p"), 3200)


func test_record_solve_time_ignores_worse_time() -> void:
	var profile: Profile = Profile.new()
	profile.record_solve_time("p", 3200)
	assert_false(profile.record_solve_time("p", 5000))
	assert_eq(profile.best_time_ms("p"), 3200)


func test_record_solve_time_rejects_zero_or_negative() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.record_solve_time("p", 0))
	assert_false(profile.record_solve_time("p", -100))
	assert_eq(profile.best_time_ms("p"), 0)


func test_record_solve_time_rejects_empty_puzzle_id() -> void:
	var profile: Profile = Profile.new()
	assert_false(profile.record_solve_time("", 5000))


func test_best_time_ms_returns_zero_when_never_recorded() -> void:
	var profile: Profile = Profile.new()
	assert_eq(profile.best_time_ms("p"), 0)


func test_best_times_round_trip_via_dict() -> void:
	var profile: Profile = Profile.new()
	profile.record_solve_time("a", 4500)
	profile.record_solve_time("b", 12000)
	var restored: Profile = Profile.from_dict(profile.to_dict())
	assert_eq(restored.best_time_ms("a"), 4500)
	assert_eq(restored.best_time_ms("b"), 12000)


func test_v1_profile_migrates_to_v2_with_empty_best_times() -> void:
	# A v1 dict has no best_times key at all. Loading it should not crash
	# and best_times should be an empty dict.
	var v1_payload: Dictionary = {
		"version": 1,
		"woints": 100,
		"current_day": 3,
		"puzzles_solved": {"p": {"first_solved_day": 1}},
	}
	var restored: Profile = Profile.from_dict(v1_payload)
	assert_eq(restored.best_time_ms("p"), 0)
	assert_true(restored.is_puzzle_solved("p"))
	assert_eq(restored.woints, 100)


func test_from_dict_filters_malformed_best_time_entries() -> void:
	# Strings, zero, negatives — none should survive the load.
	var payload: Dictionary = {
		"best_times": {
			"good": 4000,
			"zero": 0,
			"neg": -500,
			"str_value": "5000",  # int() conversion would yield 5000; allow it
			"": 9999,             # empty puzzle id rejected
		}
	}
	var restored: Profile = Profile.from_dict(payload)
	assert_eq(restored.best_time_ms("good"), 4000)
	assert_eq(restored.best_time_ms("zero"), 0)
	assert_eq(restored.best_time_ms("neg"), 0)
	# int("5000") in GDScript == 5000, so this one DOES survive — documents
	# the lenient behavior. If we tighten that later, flip this assertion.
	assert_eq(restored.best_time_ms("str_value"), 5000)
	assert_eq(restored.best_time_ms(""), 0)


func test_format_time_ms_renders_minutes_seconds() -> void:
	assert_eq(Profile.format_time_ms(0), "--:--")
	assert_eq(Profile.format_time_ms(-1), "--:--")
	assert_eq(Profile.format_time_ms(1000), "0:01")
	assert_eq(Profile.format_time_ms(65 * 1000), "1:05")
	assert_eq(Profile.format_time_ms(257 * 1000), "4:17")
	# > 1 hour falls back to H:MM:SS so the 8-hour-solver doesn't see "120:00"
	assert_eq(Profile.format_time_ms(3661 * 1000), "1:01:01")


func test_format_version_is_current() -> void:
	# Guard against an accidental version-number revert that would break
	# the forward migrations tested above. Update the constant on every
	# schema bump; v3 added placed_furniture (v1.4.1).
	assert_eq(Profile.FORMAT_VERSION, 3)


# ----- placed_furniture (introduced in FORMAT_VERSION 3 / v1.4.1) ------

func test_place_furniture_first_time_returns_true() -> void:
	var p: Profile = Profile.new()
	assert_true(p.place_furniture("poster_geometric", Vector3(1, 2, 3), 45.0))
	assert_true(p.is_furniture_placed("poster_geometric"))


func test_place_furniture_same_pos_and_rot_returns_false() -> void:
	# Idempotent: replacing at the same transform is a no-op so the
	# GameController doesn't fire "saved" toasts on phantom updates.
	var p: Profile = Profile.new()
	p.place_furniture("poster_geometric", Vector3(1, 2, 3), 45.0)
	assert_false(p.place_furniture("poster_geometric", Vector3(1, 2, 3), 45.0))


func test_place_furniture_changed_pos_returns_true() -> void:
	var p: Profile = Profile.new()
	p.place_furniture("poster_geometric", Vector3(1, 2, 3), 0.0)
	assert_true(p.place_furniture("poster_geometric", Vector3(4, 5, 6), 0.0))
	assert_eq(p.furniture_position("poster_geometric"), Vector3(4, 5, 6))


func test_place_furniture_changed_rotation_returns_true() -> void:
	var p: Profile = Profile.new()
	p.place_furniture("poster_geometric", Vector3(1, 2, 3), 0.0)
	assert_true(p.place_furniture("poster_geometric", Vector3(1, 2, 3), 90.0))
	assert_eq(p.furniture_rotation("poster_geometric"), 90.0)


func test_place_furniture_rejects_empty_id() -> void:
	var p: Profile = Profile.new()
	assert_false(p.place_furniture("", Vector3.ZERO, 0.0))


func test_unplace_furniture_returns_false_for_missing_id() -> void:
	var p: Profile = Profile.new()
	assert_false(p.unplace_furniture("not_placed"))


func test_unplace_furniture_returns_true_after_place() -> void:
	var p: Profile = Profile.new()
	p.place_furniture("desk_lamp", Vector3.ZERO, 0.0)
	assert_true(p.unplace_furniture("desk_lamp"))
	assert_false(p.is_furniture_placed("desk_lamp"))


func test_furniture_position_zero_for_unplaced() -> void:
	var p: Profile = Profile.new()
	assert_eq(p.furniture_position("nothing"), Vector3.ZERO)


func test_placed_furniture_ids_sorted() -> void:
	var p: Profile = Profile.new()
	p.place_furniture("zeta", Vector3.ZERO, 0.0)
	p.place_furniture("alpha", Vector3.ZERO, 0.0)
	p.place_furniture("mu", Vector3.ZERO, 0.0)
	assert_eq(p.placed_furniture_ids(), ["alpha", "mu", "zeta"])


func test_placed_furniture_round_trips_via_dict() -> void:
	var p: Profile = Profile.new()
	p.place_furniture("poster_geometric", Vector3(1.5, 2.0, 3.0), 90.0)
	p.place_furniture("desk_lamp", Vector3(-1.0, 0.78, 5.0), 180.0)
	var restored: Profile = Profile.from_dict(p.to_dict())
	assert_true(restored.is_furniture_placed("poster_geometric"))
	assert_eq(restored.furniture_position("poster_geometric"), Vector3(1.5, 2.0, 3.0))
	assert_eq(restored.furniture_rotation("poster_geometric"), 90.0)
	assert_true(restored.is_furniture_placed("desk_lamp"))
	assert_eq(restored.furniture_rotation("desk_lamp"), 180.0)


func test_v2_profile_migrates_to_v3_with_empty_placed_furniture() -> void:
	# A v2 dict has no placed_furniture key. Loading shouldn't crash and
	# the dict should come back empty.
	var v2_payload: Dictionary = {
		"version": 2,
		"woints": 50,
		"current_day": 3,
		"best_times": {"mall_day_one": 1500},
	}
	var restored: Profile = Profile.from_dict(v2_payload)
	assert_eq(restored.placed_furniture_ids(), [])
	assert_eq(restored.best_time_ms("mall_day_one"), 1500)


func test_from_dict_drops_malformed_placed_entries() -> void:
	# Entries with missing position, wrong array length, or non-string id
	# are dropped. Good entries survive.
	var payload: Dictionary = {
		"placed_furniture": {
			"good": {"position": [1, 2, 3], "rotation": 45.0},
			"bad_no_pos": {"rotation": 0.0},
			"bad_pos_len": {"position": [1, 2], "rotation": 0.0},
			"": {"position": [0, 0, 0], "rotation": 0.0},
		}
	}
	var restored: Profile = Profile.from_dict(payload)
	assert_true(restored.is_furniture_placed("good"))
	assert_false(restored.is_furniture_placed("bad_no_pos"))
	assert_false(restored.is_furniture_placed("bad_pos_len"))
	assert_false(restored.is_furniture_placed(""))
