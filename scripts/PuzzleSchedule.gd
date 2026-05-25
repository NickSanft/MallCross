class_name PuzzleSchedule
extends RefCounted

# Maps an in-game day (1-indexed) to a puzzle ID per difficulty tier. Each
# food-court table looks this up at interact time — solving day N at one
# difficulty doesn't affect the other tiers' day N puzzles.
#
# Schedule history:
#   Phase 10.1 — MINI 7 days, MIDI day 1, FULL day 1.
#   Phase 13a (v1.0.2) — MINI extended to 13 days (mall_day_eight … _thirteen).
#   MIDI and FULL still day 1; extended in 13b / 13c.
# Future phases extend MIDI and FULL with more days; the data structure is
# already ready, no code changes needed.

const DIFFICULTY_MINI: String = "mini"
const DIFFICULTY_MIDI: String = "midi"
const DIFFICULTY_FULL: String = "full"

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
}

const _FULL_SCHEDULE: Dictionary = {
	1: "mall_full_day_one",
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
	return [DIFFICULTY_MINI, DIFFICULTY_MIDI, DIFFICULTY_FULL]


static func _schedule_for_difficulty(difficulty: String) -> Dictionary:
	match difficulty.to_lower():
		DIFFICULTY_MIDI:
			return _MIDI_SCHEDULE
		DIFFICULTY_FULL:
			return _FULL_SCHEDULE
		_:
			return _MINI_SCHEDULE
