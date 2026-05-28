class_name CommunityPuzzleLoader
extends RefCounted

# Discovers player-authored crossword puzzles dropped into user://puzzles/.
# Each .json file in that directory is parsed via PuzzleLoader, then audited
# by PuzzleValidator. Returns an Array of result dicts — one per file —
# regardless of validity. Invalid files appear in the picker UI with their
# rejection reason so modders can see what to fix.
#
# Result shape:
#   {
#     "path":   "user://puzzles/my_custom.json",  # absolute resource path
#     "puzzle_id": "user://puzzles/my_custom.json",  # also the Profile key
#     "title":  "My Custom MINI",
#     "author": "ModderName",
#     "size":   5,
#     "valid":  true,
#     "error":  "",                              # empty when valid
#     "puzzle": <parsed dict>,                   # always present, may be {}
#   }
#
# Rescan on each call is intentional — the picker re-asks every time it
# opens so dropping a new file mid-session shows up without restarting.

const PUZZLE_DIR: String = "user://puzzles/"


static func scan_user_dir(dir_path: String = PUZZLE_DIR) -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir_path):
		# No directory yet — first run with no community puzzles. Returning
		# [] is fine; the picker shows an "empty + how to add files" hint.
		return out
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var filenames: Array = []
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".json"):
			filenames.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	# Stable ordering = alphabetical. Players who drop multiple files want
	# a predictable list order rather than filesystem-walk-order.
	filenames.sort()
	for fname in filenames:
		out.append(_inspect_file(dir_path + fname))
	return out


static func _inspect_file(path: String) -> Dictionary:
	var result: Dictionary = {
		"path": path,
		"puzzle_id": path,
		"title": path.get_file(),
		"author": "(unknown)",
		"size": 0,
		"valid": false,
		"error": "",
		"puzzle": {},
	}
	if not FileAccess.file_exists(path):
		# Possible TOCTOU between dir.list and individual reads; treat as
		# "file vanished mid-scan" which is unusual but recoverable.
		result["error"] = "File not found"
		return result
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		result["error"] = "File is empty"
		return result
	# CrosswordSerializer.puzzle_from_json wraps JSON.parse_string; it
	# returns a default-shaped dict (empty grid, no clues) on parse failure
	# rather than throwing. Detect that by checking grid size.
	var puzzle: Dictionary = PuzzleLoader.load_from_path(path)
	result["puzzle"] = puzzle
	# Hydrate display fields BEFORE running validator so even invalid
	# files show their (claimed) title in the picker for debugging.
	result["title"] = String(puzzle.get("title", path.get_file()))
	result["author"] = String(puzzle.get("author", "(unknown)"))
	var grid: CrosswordGrid = puzzle.get("grid")
	if grid != null:
		result["size"] = grid.size
	# Run the validator. Errors disqualify; warnings (orphan clues, etc.)
	# are tolerated for community content — we don't want to gate a
	# playable puzzle on cosmetic clue-list issues.
	var issues: Array = PuzzleValidator.validate(puzzle)
	if PuzzleValidator.has_errors(issues):
		result["valid"] = false
		result["error"] = _summarize_issues(issues)
	else:
		result["valid"] = true
	return result


static func _summarize_issues(issues: Array) -> String:
	# First error becomes the displayed message — the picker has limited
	# horizontal space and modders only need one fix to see what's next.
	for issue in issues:
		if issue.get("severity") == PuzzleValidator.SEVERITY_ERROR:
			return String(issue.get("message", "Validation failed"))
	return "Validation failed"
