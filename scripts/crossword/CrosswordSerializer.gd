class_name CrosswordSerializer
extends RefCounted

# JSON-friendly dict <-> object conversions for puzzles and solve state.
# Format version is bumped whenever the on-disk shape changes; loaders should
# tolerate older versions or refuse them explicitly.

const PUZZLE_FORMAT_VERSION: int = 1
const STATE_FORMAT_VERSION: int = 1


static func puzzle_to_dict(grid: CrosswordGrid, clues: Array, title: String = "", author: String = "", theme: String = "") -> Dictionary:
	return {
		"version": PUZZLE_FORMAT_VERSION,
		"title": title,
		"author": author,
		"theme": theme,
		"size": grid.size,
		"grid": grid.to_strings(),
		"clues": clues.duplicate(true),
	}


static func puzzle_from_dict(payload: Dictionary) -> Dictionary:
	# Returns {"grid": CrosswordGrid, "clues": Array, "title": String, "author": String, "theme": String, "version": int}.
	# Defensive: missing fields default to safe empties.
	var grid: CrosswordGrid = CrosswordGrid.from_strings(payload.get("grid", []))
	return {
		"version": payload.get("version", 0),
		"grid": grid,
		"clues": payload.get("clues", []),
		"title": payload.get("title", ""),
		"author": payload.get("author", ""),
		"theme": payload.get("theme", ""),
	}


static func state_to_dict(state: CrosswordState) -> Dictionary:
	var entry_lines: Array = []
	var pencil_lines: Array = []
	for r in range(state.size):
		var entry_line: String = ""
		var pencil_line: String = ""
		for c in range(state.size):
			entry_line += String(state.entries[r][c])
			pencil_line += "1" if state.pencil_flags[r][c] else "0"
		entry_lines.append(entry_line)
		pencil_lines.append(pencil_line)
	return {
		"version": STATE_FORMAT_VERSION,
		"size": state.size,
		"entries": entry_lines,
		"pencil": pencil_lines,
	}


static func state_from_dict(payload: Dictionary) -> CrosswordState:
	var state: CrosswordState = CrosswordState.new()
	state.size = int(payload.get("size", 0))
	var entry_lines: Array = payload.get("entries", [])
	var pencil_lines: Array = payload.get("pencil", [])
	for r in range(state.size):
		var entry_row: Array = []
		var pencil_row: Array = []
		var entry_line: String = String(entry_lines[r]) if r < entry_lines.size() else ""
		var pencil_line: String = String(pencil_lines[r]) if r < pencil_lines.size() else ""
		for c in range(state.size):
			var ch: String = entry_line[c] if c < entry_line.length() else CrosswordState.EMPTY_CHAR
			entry_row.append(ch)
			var is_pencil: bool = c < pencil_line.length() and pencil_line[c] == "1"
			pencil_row.append(is_pencil and ch != CrosswordState.EMPTY_CHAR)
		state.entries.append(entry_row)
		state.pencil_flags.append(pencil_row)
	return state


static func puzzle_to_json(grid: CrosswordGrid, clues: Array, title: String = "", author: String = "", theme: String = "") -> String:
	return JSON.stringify(puzzle_to_dict(grid, clues, title, author, theme), "\t")


static func puzzle_from_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return puzzle_from_dict({})
	return puzzle_from_dict(parsed)
