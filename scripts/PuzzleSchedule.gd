class_name PuzzleSchedule
extends RefCounted

# Maps an in-game day (1-indexed) to a puzzle ID per difficulty tier. Each
# food-court table looks this up at interact time — solving day N at one
# difficulty doesn't affect the other tiers' day N puzzles.
#
# Phase 10.1 ships:
#   - MINI: full 7-day schedule (mall_day_one ... mall_day_seven)
#   - MIDI: day 1 only (mall_midi_day_one)
#   - FULL: day 1 only (mall_full_day_one)
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
