class_name HintRoster
extends RefCounted

# Loads per-day NPC hint dialog from data/hints/<puzzle_id>.json. Each file
# maps npc_id (from NPCRoster) -> hint string. Players overhear NPCs say
# things that nudge toward one specific answer in today's puzzle.
#
# Defensive: missing file / malformed JSON / wrong shape all return {}.
# Callers should fall back to the NPC's hardcoded flavor dialog.

const HINT_DIR: String = "res://data/hints/"


static func hints_for_day(current_day: int) -> Dictionary:
	var puzzle_id: String = PuzzleSchedule.puzzle_id_for_day(current_day)
	if puzzle_id == "":
		return {}
	return load_hints_for_puzzle(puzzle_id)


static func load_hints_for_puzzle(puzzle_id: String) -> Dictionary:
	if puzzle_id == "":
		return {}
	var path: String = HINT_DIR + puzzle_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return {}
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	# Coerce all values to String so callers don't have to defend against
	# malformed entries.
	var out: Dictionary = {}
	for npc_id in parsed:
		out[String(npc_id)] = String(parsed[npc_id])
	return out


static func hint_for(npc_id: String, current_day: int) -> String:
	# Returns "" if no hint is wired for this NPC on this day. The empty
	# string is the sentinel for "use the NPC's hardcoded flavor line."
	if npc_id == "":
		return ""
	var hints: Dictionary = hints_for_day(current_day)
	return String(hints.get(npc_id, ""))
