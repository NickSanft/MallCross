class_name PuzzleSchedule
extends RefCounted

# Maps an in-game day (1-indexed) to a puzzle ID from data/puzzles/. The
# MINI food-court table looks this up at interact time — solving day N
# unlocks the schedule's day N+1 entry on the next sleep.
#
# Phase 7.2 hardcodes the first two days. Phase 7.3+ may load this from
# data/schedule.json so puzzle packs can ship without code changes.

const _SCHEDULE: Dictionary = {
	1: "mall_day_one",
	2: "mall_day_two",
}


static func puzzle_id_for_day(day: int) -> String:
	if day <= 0:
		return ""
	return _SCHEDULE.get(day, "")


static func has_puzzle_for_day(day: int) -> bool:
	return puzzle_id_for_day(day) != ""


static func scheduled_days() -> Array:
	var days: Array = _SCHEDULE.keys()
	days.sort()
	return days


static func last_scheduled_day() -> int:
	var days: Array = scheduled_days()
	if days.is_empty():
		return 0
	return int(days[days.size() - 1])
