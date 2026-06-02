class_name PuzzleSchedule
extends RefCounted

# Maps an in-game day (1-indexed) to a puzzle ID per difficulty tier. Each
# food-court table looks this up at interact time — solving day N at one
# difficulty doesn't affect the other tiers' day N puzzles.
#
# Schedule history:
#   Phase 10.1         — MINI 7 days, MIDI day 1, FULL day 1.
#   Phase 13a (v1.0.2) — MINI extended to 13 days (mall_day_eight … _thirteen).
#   Phase 13b (v1.0.3) — MIDI extended to 7 days (mall_midi_day_two … _seven).
#   Phase 13c (v1.0.4) — FULL extended to 7 days (mall_full_day_two … _seven).
# All three tiers now have rotation. Future content drops just extend the
# dictionaries — no code changes needed.

const DIFFICULTY_MINI: String = "mini"
const DIFFICULTY_MIDI: String = "midi"
const DIFFICULTY_FULL: String = "full"
# v1.9.0 Phase 22: rooftop puzzles are weekly (4 per season). They live
# outside the daily MINI/MIDI/FULL difficulty axis because they're
# week-indexed within a season rather than day-indexed within a schedule.
const DIFFICULTY_ROOFTOP: String = "rooftop"

const _MINI_SCHEDULE: Dictionary = {
	1: "mall_day_one",
	2: "mall_day_two",
	3: "mall_day_three",
	4: "mall_day_four",
	5: "mall_day_five",
	6: "mall_day_six",
	7: "mall_day_seven",
	8: "mall_day_eight",
	9: "mall_day_nine",
	10: "mall_day_ten",
	11: "mall_day_eleven",
	12: "mall_day_twelve",
	13: "mall_day_thirteen",
}

const _MIDI_SCHEDULE: Dictionary = {
	1: "mall_midi_day_one",
	2: "mall_midi_day_two",
	3: "mall_midi_day_three",
	4: "mall_midi_day_four",
	5: "mall_midi_day_five",
	6: "mall_midi_day_six",
	7: "mall_midi_day_seven",
}

const _FULL_SCHEDULE: Dictionary = {
	1: "mall_full_day_one",
	2: "mall_full_day_two",
	3: "mall_full_day_three",
	4: "mall_full_day_four",
	5: "mall_full_day_five",
	6: "mall_full_day_six",
	7: "mall_full_day_seven",
}

# v1.9.0 Phase 22: 4 rooftop puzzles, one per week within a season. The
# same 4 puzzles rotate across all seasons (so week 1 of season 1 and
# week 1 of season 2 are both `rooftop_week_one`). Keeping it cyclical
# means we don't have to generate fresh content every 30 in-game days
# while still giving the player a stable weekly anchor.
const _ROOFTOP_BY_WEEK: Dictionary = {
	1: "rooftop_week_one",
	2: "rooftop_week_two",
	3: "rooftop_week_three",
	4: "rooftop_week_four",
}


static func puzzle_id_for_day(day: int, difficulty: String = DIFFICULTY_MINI) -> String:
	if day <= 0:
		return ""
	return _schedule_for_difficulty(difficulty).get(day, "")


static func has_puzzle_for_day(day: int, difficulty: String = DIFFICULTY_MINI) -> bool:
	return puzzle_id_for_day(day, difficulty) != ""


static func scheduled_days(difficulty: String = DIFFICULTY_MINI) -> Array:
	var days: Array = _schedule_for_difficulty(difficulty).keys()
	days.sort()
	return days


static func last_scheduled_day(difficulty: String = DIFFICULTY_MINI) -> int:
	var days: Array = scheduled_days(difficulty)
	if days.is_empty():
		return 0
	return int(days[days.size() - 1])


static func all_difficulties() -> Array:
	# Rooftop intentionally NOT in this list. The "scheduled days across
	# all difficulties" meta-test expects daily schedules; rooftop is
	# week-indexed and doesn't fit the day-keyed lookup the test uses.
	# Use `rooftop_puzzle_for_week(...)` directly when you want the
	# weekly rooftop id.
	return [DIFFICULTY_MINI, DIFFICULTY_MIDI, DIFFICULTY_FULL]


static func rooftop_puzzle_for_week(week: int) -> String:
	# Week 1..4 lookup. Out-of-range weeks clamp to the nearest valid
	# entry so SeasonMath.week_of_season's overflow on days 29-30
	# (clamped to week 4) plays well.
	if week <= 0:
		week = 1
	elif week > _ROOFTOP_BY_WEEK.size():
		week = _ROOFTOP_BY_WEEK.size()
	return _ROOFTOP_BY_WEEK.get(week, "")


static func rooftop_puzzle_for_day(day: int) -> String:
	# Convenience: walk day -> week_of_season -> puzzle_id.
	return rooftop_puzzle_for_week(SeasonMath.week_of_season(day))


static func all_rooftop_puzzles() -> Array:
	var ids: Array = _ROOFTOP_BY_WEEK.values()
	ids.sort()
	return ids


static func _schedule_for_difficulty(difficulty: String) -> Dictionary:
	match difficulty.to_lower():
		DIFFICULTY_MIDI:
			return _MIDI_SCHEDULE
		DIFFICULTY_FULL:
			return _FULL_SCHEDULE
		_:
			return _MINI_SCHEDULE
