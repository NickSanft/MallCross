extends "res://addons/gut/test.gd"


func test_hints_for_day_one_returns_three_entries() -> void:
	var hints: Dictionary = HintRoster.hints_for_day(1)
	assert_eq(hints.size(), 3)


func test_hints_for_day_one_keys_match_roster_ids() -> void:
	var hints: Dictionary = HintRoster.hints_for_day(1)
	var roster_ids: Array = []
	for npc in NPCRoster.all_npcs():
		roster_ids.append(npc["id"])
	for npc_id in hints:
		assert_has(roster_ids, npc_id, "Hint references unknown NPC id: %s" % npc_id)


func test_hints_for_day_zero_returns_empty() -> void:
	assert_eq(HintRoster.hints_for_day(0), {})


func test_hints_for_day_negative_returns_empty() -> void:
	assert_eq(HintRoster.hints_for_day(-5), {})


func test_hints_for_day_past_schedule_returns_empty() -> void:
	assert_eq(HintRoster.hints_for_day(999), {})


func test_hint_for_known_npc_returns_string() -> void:
	var hint: String = HintRoster.hint_for("food_court_patron_a", 1)
	assert_ne(hint, "")


func test_hint_for_unknown_npc_returns_empty() -> void:
	assert_eq(HintRoster.hint_for("does_not_exist", 1), "")


func test_hint_for_empty_npc_id_returns_empty() -> void:
	assert_eq(HintRoster.hint_for("", 1), "")


func test_hint_for_day_with_no_schedule_returns_empty() -> void:
	assert_eq(HintRoster.hint_for("food_court_patron_a", 999), "")


func test_every_scheduled_day_has_hints_file() -> void:
	# Meta-test: any day in the puzzle schedule must have a matching hints
	# file with at least one entry. Catches missing data/hints/*.json.
	for day in PuzzleSchedule.scheduled_days():
		var hints: Dictionary = HintRoster.hints_for_day(day)
		assert_gt(hints.size(), 0, "Day %d (puzzle %s) has no hints file or it's empty" % [day, PuzzleSchedule.puzzle_id_for_day(day)])


func test_every_hint_references_a_known_npc_id() -> void:
	# Meta-test across all 7 scheduled days: every hint key must match an
	# NPC in NPCRoster.
	var roster_ids: Dictionary = {}
	for npc in NPCRoster.all_npcs():
		roster_ids[npc["id"]] = true
	for day in PuzzleSchedule.scheduled_days():
		var hints: Dictionary = HintRoster.hints_for_day(day)
		for npc_id in hints:
			assert_true(roster_ids.has(npc_id), "Day %d hint references unknown NPC: %s" % [day, npc_id])
