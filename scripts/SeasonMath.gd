class_name SeasonMath
extends RefCounted

# Pure math for the season-progression system. The plan from the v1.0.0
# roadmap defines a "season" as a 30-in-game-day window:
#   - Season 1 = days 1..30
#   - Season 2 = days 31..60
#   - Season N = days (N-1)*30+1 .. N*30
#
# Weeks within a season are 7 days each. Season 1 weeks land on:
#   - Week 1: days 1..7
#   - Week 2: days 8..14
#   - Week 3: days 15..21
#   - Week 4: days 22..28
#   - Days 29..30 fall into "Week 4 overflow" — clamped to week 4 so the
#     rooftop puzzle for the final 2 days is the same as week 4.

const DAYS_PER_SEASON: int = 30
const DAYS_PER_WEEK: int = 7
const WEEKS_PER_SEASON: int = 4
# Number of solved-day-puzzles that unlocks the rooftop within a season.
# Matches the plan's "Season Pass" achievement threshold and the
# rooftop-table gate.
const ROOFTOP_UNLOCK_THRESHOLD: int = 21


# 1-indexed season number containing `day`. day 1..30 -> season 1,
# day 31..60 -> season 2, etc. Day 0 or below clamps to season 1 so
# a sentinel "no day yet" never produces season 0.
static func season_of_day(day: int) -> int:
	if day <= 0:
		return 1
	return ((day - 1) / DAYS_PER_SEASON) + 1


# 1-indexed day within the season (1..30). day 1 of season 1 -> 1;
# day 31 of season 2 -> 1; day 30 of season 1 -> 30.
static func day_of_season(day: int) -> int:
	if day <= 0:
		return 1
	return ((day - 1) % DAYS_PER_SEASON) + 1


# 1-indexed week within the season (1..4). Week 4 absorbs the overflow
# from days 28..30 so the rooftop puzzle stays well-defined for every day.
static func week_of_season(day: int) -> int:
	var d: int = day_of_season(day)
	var raw_week: int = ((d - 1) / DAYS_PER_WEEK) + 1
	return min(raw_week, WEEKS_PER_SEASON)


# Returns `{"first": int, "last": int}` — the inclusive day range of the
# season containing `day`. Useful for filtering profile.puzzles_solved
# entries by "first_solved_day in this season."
static func season_range_for_day(day: int) -> Dictionary:
	var n: int = season_of_day(day)
	return {
		"first": (n - 1) * DAYS_PER_SEASON + 1,
		"last": n * DAYS_PER_SEASON,
	}


# Returns true iff `first_solved_day` falls inside the same season as
# `current_day`. Convenience wrapper over season_of_day comparison.
static func is_in_same_season(current_day: int, first_solved_day: int) -> bool:
	if first_solved_day <= 0:
		return false
	return season_of_day(current_day) == season_of_day(first_solved_day)


# Counts how many entries in `puzzles_solved_dict` (Profile.puzzles_solved
# shape: { puzzle_id -> {"first_solved_day": int, ...} }) were first
# solved within the same season as `current_day`. Used by the rooftop
# unlock gate and the Season Pass achievement.
static func solves_in_current_season(current_day: int, puzzles_solved_dict: Dictionary) -> int:
	if puzzles_solved_dict == null or puzzles_solved_dict.is_empty():
		return 0
	var count: int = 0
	for puzzle_id in puzzles_solved_dict:
		var entry: Variant = puzzles_solved_dict[puzzle_id]
		if not (entry is Dictionary):
			continue
		var fsd: int = int(entry.get("first_solved_day", 0))
		if is_in_same_season(current_day, fsd):
			count += 1
	return count


# Returns true iff the rooftop access is currently unlocked. Equivalent
# to `solves_in_current_season(...) >= ROOFTOP_UNLOCK_THRESHOLD`.
static func is_rooftop_unlocked(current_day: int, puzzles_solved_dict: Dictionary) -> bool:
	return solves_in_current_season(current_day, puzzles_solved_dict) >= ROOFTOP_UNLOCK_THRESHOLD
