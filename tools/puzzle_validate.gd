extends SceneTree

# CLI wrapper around PuzzleValidator. Run with:
#   godot --headless -s res://tools/puzzle_validate.gd -- res://data/puzzles/foo.json
#
# Exit codes:
#   0 — no errors (warnings still allowed)
#   1 — one or more errors found
#   2 — usage error or file not found


func _init() -> void:
	var args: Array = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: godot --headless -s res://tools/puzzle_validate.gd -- <path-to-puzzle.json>")
		quit(2)
		return

	var has_any_error: bool = false
	for raw_path in args:
		var path: String = String(raw_path)
		if not _validate_one(path):
			has_any_error = true
	quit(1 if has_any_error else 0)


func _validate_one(path: String) -> bool:
	if not FileAccess.file_exists(path):
		printerr("File not found: %s" % path)
		return false
	var puzzle: Dictionary = PuzzleLoader.load_from_path(path)
	var issues: Array = PuzzleValidator.validate(puzzle)
	if issues.is_empty():
		print("OK  %s — no issues." % path)
		return true
	var error_count: int = PuzzleValidator.count_by_severity(issues, PuzzleValidator.SEVERITY_ERROR)
	var warning_count: int = PuzzleValidator.count_by_severity(issues, PuzzleValidator.SEVERITY_WARNING)
	var status: String = "ERR" if error_count > 0 else "WARN"
	print("%s %s — %d error(s), %d warning(s):" % [status, path, error_count, warning_count])
	for issue in issues:
		print("    [%s] %s: %s" % [issue["severity"], issue["code"], issue["message"]])
	return error_count == 0
