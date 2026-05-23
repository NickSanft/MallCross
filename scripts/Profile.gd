class_name Profile
extends RefCounted

# Persistent player profile. Holds Woints balance, in-game day, the set of
# puzzles ever solved (with the day they were first solved on), and the
# player's mid-solve state per puzzle so re-entering a puzzle resumes.
#
# Pure model — no disk I/O. ProfileStore handles serialization.

const FORMAT_VERSION: int = 1
const DEFAULT_WOINTS: int = 0
const DEFAULT_DAY: int = 1

var version: int = FORMAT_VERSION
var woints: int = DEFAULT_WOINTS
var current_day: int = DEFAULT_DAY
# puzzle_id -> { "first_solved_day": int }
var puzzles_solved: Dictionary = {}
# Item IDs (from ItemCatalog) the player has purchased. Order = purchase order.
var owned_items: Array = []

# puzzle_id -> CrosswordState (in-memory). Serialized via CrosswordSerializer
# at to_dict() time so we keep one source of truth for the on-disk shape.
var _cached_states: Dictionary = {}


func add_woints(amount: int) -> void:
	woints = max(0, woints + amount)


func mark_puzzle_solved(puzzle_id: String) -> bool:
	# Returns true if this is the first time the puzzle has been solved (so
	# the caller knows to award Woints). Returns false on repeat solves.
	if puzzle_id == "" or puzzles_solved.has(puzzle_id):
		return false
	puzzles_solved[puzzle_id] = {"first_solved_day": current_day}
	return true


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
		"puzzles_solved": puzzles_solved.duplicate(true),
		"owned_items": owned_items.duplicate(),
		"puzzle_states": states_payload,
	}


static func from_dict(payload: Dictionary) -> Profile:
	var profile: Profile = Profile.new()
	profile.version = int(payload.get("version", 0))
	profile.woints = max(0, int(payload.get("woints", DEFAULT_WOINTS)))
	profile.current_day = max(1, int(payload.get("current_day", DEFAULT_DAY)))
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
	return profile
