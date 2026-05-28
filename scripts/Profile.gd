class_name Profile
extends RefCounted

# Persistent player profile. Holds Woints balance, in-game day, the set of
# puzzles ever solved (with the day they were first solved on), and the
# player's mid-solve state per puzzle so re-entering a puzzle resumes.
#
# Pure model — no disk I/O. ProfileStore handles serialization.

const FORMAT_VERSION: int = 2  # v1.0.1: introduced best_times. Loader migrates v1 forward.
const DEFAULT_WOINTS: int = 0
const DEFAULT_DAY: int = 1

var version: int = FORMAT_VERSION
var woints: int = DEFAULT_WOINTS
var current_day: int = DEFAULT_DAY
# puzzle_id -> { "first_solved_day": int }
var puzzles_solved: Dictionary = {}
# Item IDs (from ItemCatalog) the player has purchased. Order = purchase order.
var owned_items: Array = []
# Consecutive-day solve streak. 0 = never solved; 1 = solved at least once;
# increments each time a first-solve happens on the day after the previous
# first-solve. Resets to 1 if the gap is > 1 day.
var streak: int = 0
# Day on which the most recent first-solve happened. 0 = never solved.
var last_solved_day: int = 0
# puzzle_id -> best solve time in milliseconds (the lowest seen so far).
# Introduced in FORMAT_VERSION 2; absent / non-int values are filtered out
# during load_from_dict so old v1 profiles migrate forward as an empty dict.
var best_times: Dictionary = {}

# puzzle_id -> CrosswordState (in-memory). Serialized via CrosswordSerializer
# at to_dict() time so we keep one source of truth for the on-disk shape.
var _cached_states: Dictionary = {}


func add_woints(amount: int) -> void:
	woints = max(0, woints + amount)


func mark_puzzle_solved(puzzle_id: String, update_streak: bool = true) -> bool:
	# Returns true if this is the first time the puzzle has been solved (so
	# the caller knows to award Woints). Returns false on repeat solves.
	#
	# When `update_streak` is true (the default — used for bundled
	# MINI/MIDI/FULL daily puzzles), also bumps `streak` and `last_solved_day`.
	# Community puzzles (v1.3.0+) pass false so they're recorded for
	# "already solved" tracking but don't influence the daily streak —
	# otherwise a player who drops 7 of their own puzzles in could
	# trivially run the streak counter up to 30+ without any of the
	# curated content.
	if puzzle_id == "" or puzzles_solved.has(puzzle_id):
		return false
	if update_streak:
		_update_streak_on_solve()
	puzzles_solved[puzzle_id] = {"first_solved_day": current_day}
	return true


func _update_streak_on_solve() -> void:
	# Called inside mark_puzzle_solved(), before puzzles_solved is mutated.
	# Rules:
	#   - First solve ever                 -> streak = 1
	#   - Another first-solve same day     -> streak unchanged
	#   - First-solve on day after         -> streak += 1
	#   - Gap > 1 day                      -> streak resets to 1
	if last_solved_day == 0:
		streak = 1
	elif current_day == last_solved_day:
		# Another first-solve on the same in-game day — no streak change.
		pass
	elif current_day == last_solved_day + 1:
		streak += 1
	else:
		streak = 1
	last_solved_day = current_day


func is_puzzle_solved(puzzle_id: String) -> bool:
	return puzzles_solved.has(puzzle_id)


func first_solved_day(puzzle_id: String) -> int:
	if not puzzles_solved.has(puzzle_id):
		return 0
	return int(puzzles_solved[puzzle_id].get("first_solved_day", 0))


func cache_state(puzzle_id: String, state: CrosswordState) -> void:
	if puzzle_id == "" or state == null:
		return
	_cached_states[puzzle_id] = state


func get_cached_state(puzzle_id: String) -> CrosswordState:
	return _cached_states.get(puzzle_id, null)


func advance_day(amount: int = 1) -> void:
	current_day = max(1, current_day + amount)


func record_solve_time(puzzle_id: String, elapsed_ms: int) -> bool:
	# Records `elapsed_ms` as the player's best time for this puzzle iff it
	# beats the existing best (or is the first time). Returns true if a new
	# best was recorded — callers can use that to trigger a "new record"
	# achievement or VFX later.
	#
	# Negative / zero times are ignored (can't physically solve in 0ms; also
	# guards against a bug elsewhere that submits a stale timer).
	if puzzle_id == "" or elapsed_ms <= 0:
		return false
	var prev: int = int(best_times.get(puzzle_id, 0))
	if prev != 0 and prev <= elapsed_ms:
		return false
	best_times[puzzle_id] = elapsed_ms
	return true


func best_time_ms(puzzle_id: String) -> int:
	# Returns 0 if no time has ever been recorded for this puzzle.
	return int(best_times.get(puzzle_id, 0))


static func format_time_ms(ms: int) -> String:
	# Render an elapsed-ms duration as "M:SS" (or "H:MM:SS" for the
	# pathological case of a multi-hour solve). Used by both the prompt
	# string ("(best 4:17)") and the solve banner.
	if ms <= 0:
		return "--:--"
	var total_seconds: int = int(ms / 1000)
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	return "%d:%02d" % [minutes, seconds]


func own_item(item_id: String) -> bool:
	# Returns true on first acquisition (callers can use this to gate VFX or
	# tutorial pop-ups); false on repeat. Does not deduct Woints — the
	# purchase flow does that explicitly.
	if item_id == "" or owned_items.has(item_id):
		return false
	owned_items.append(item_id)
	return true


func owns(item_id: String) -> bool:
	if item_id == "":
		return false
	return owned_items.has(item_id)


func can_afford(cost: int) -> bool:
	return woints >= cost


func try_purchase(item_id: String, cost: int) -> bool:
	# Atomic: refuses unless not-owned AND can afford. Deducts Woints and
	# adds to owned_items on success. Returns true iff purchase happened.
	if item_id == "" or cost < 0:
		return false
	if owns(item_id):
		return false
	if not can_afford(cost):
		return false
	add_woints(-cost)
	owned_items.append(item_id)
	return true


func to_dict() -> Dictionary:
	var states_payload: Dictionary = {}
	for id in _cached_states:
		var state: CrosswordState = _cached_states[id]
		if state == null:
			continue
		states_payload[id] = CrosswordSerializer.state_to_dict(state)
	return {
		"version": FORMAT_VERSION,
		"woints": woints,
		"current_day": current_day,
		"streak": streak,
		"last_solved_day": last_solved_day,
		"puzzles_solved": puzzles_solved.duplicate(true),
		"owned_items": owned_items.duplicate(),
		"puzzle_states": states_payload,
		"best_times": best_times.duplicate(),
	}


static func from_dict(payload: Dictionary) -> Profile:
	var profile: Profile = Profile.new()
	profile.version = int(payload.get("version", 0))
	profile.woints = max(0, int(payload.get("woints", DEFAULT_WOINTS)))
	profile.current_day = max(1, int(payload.get("current_day", DEFAULT_DAY)))
	profile.streak = max(0, int(payload.get("streak", 0)))
	profile.last_solved_day = max(0, int(payload.get("last_solved_day", 0)))
	profile.puzzles_solved = payload.get("puzzles_solved", {}).duplicate(true) if payload.get("puzzles_solved") is Dictionary else {}
	var raw_items: Variant = payload.get("owned_items", [])
	if raw_items is Array:
		for entry in raw_items:
			if entry is String and entry != "" and not profile.owned_items.has(entry):
				profile.owned_items.append(entry)
	var states_payload: Dictionary = payload.get("puzzle_states", {}) if payload.get("puzzle_states") is Dictionary else {}
	for id in states_payload:
		if typeof(states_payload[id]) != TYPE_DICTIONARY:
			continue
		profile._cached_states[id] = CrosswordSerializer.state_from_dict(states_payload[id])
	# best_times: v1 profiles don't have this key; v2+ stores puzzle_id -> ms.
	# Filter to int values >0 so a malformed entry can't pollute the rest.
	var raw_best: Variant = payload.get("best_times", {})
	if raw_best is Dictionary:
		for id in raw_best:
			if not (id is String) or String(id) == "":
				continue
			var ms: int = int(raw_best[id])
			if ms > 0:
				profile.best_times[id] = ms
	return profile
