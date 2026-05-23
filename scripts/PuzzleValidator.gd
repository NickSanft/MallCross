class_name PuzzleValidator
extends RefCounted

# Audits a parsed puzzle (the dict shape CrosswordSerializer.puzzle_from_dict
# returns) against the crossword construction rules:
#
#   - Grid is present, non-empty, and square
#   - 180° rotational symmetry (American crossword standard)
#   - No stranded short words: every slot meets a minimum length
#   - Every slot has a clue text; no clue text is empty
#   - No duplicate (number, direction) pairs in the clue list
#   - All clue entries reference a real slot
#
# Returns an array of issue dicts: {severity, code, message}. The CLI
# wrapper (tools/puzzle_validate.gd) is a 30-line script that translates
# this into stdout + exit code.

const DEFAULT_MIN_WORD_LENGTH: int = 3
const SEVERITY_ERROR: String = "error"
const SEVERITY_WARNING: String = "warning"


static func validate(puzzle: Dictionary, min_word_length: int = DEFAULT_MIN_WORD_LENGTH) -> Array:
	var issues: Array = []

	var grid: CrosswordGrid = puzzle.get("grid")
	if grid == null:
		issues.append(_issue(SEVERITY_ERROR, "no_grid", "Puzzle has no grid."))
		return issues
	if grid.size <= 0:
		issues.append(_issue(SEVERITY_ERROR, "empty_grid", "Grid has size 0."))
		return issues
	if not grid.is_square():
		issues.append(_issue(SEVERITY_ERROR, "not_square", "Grid is not square."))

	# 180° rotational symmetry
	for asymmetry in CrosswordSymmetry.find_asymmetries(grid):
		issues.append(_issue(
			SEVERITY_ERROR, "symmetry",
			"Cell (%d,%d) is asymmetric with (%d,%d)." % [
				asymmetry["row"], asymmetry["col"],
				asymmetry["mirror_row"], asymmetry["mirror_col"],
			]
		))

	# Slot enumeration drives both length and clue-coverage checks
	var slots: Array = CrosswordNumbering.find_word_slots(grid)

	# Index clues by (number, direction) so duplicates and orphans are detectable
	var clues_by_key: Dictionary = {}
	for clue in puzzle.get("clues", []):
		var ck: String = _slot_key(int(clue.get("number", 0)), String(clue.get("direction", "")))
		if clues_by_key.has(ck):
			issues.append(_issue(SEVERITY_ERROR, "duplicate_clue", "Duplicate clue %s." % ck))
		clues_by_key[ck] = clue

	var slot_keys: Dictionary = {}
	for slot in slots:
		var sk: String = _slot_key(int(slot["number"]), String(slot["direction"]))
		slot_keys[sk] = slot
		if int(slot["length"]) < min_word_length:
			issues.append(_issue(
				SEVERITY_ERROR, "short_word",
				"Slot %s has length %d (min %d)." % [sk, slot["length"], min_word_length]
			))
		if not clues_by_key.has(sk):
			issues.append(_issue(SEVERITY_ERROR, "missing_clue", "Slot %s has no clue text." % sk))
		elif String(clues_by_key[sk].get("text", "")) == "":
			issues.append(_issue(SEVERITY_ERROR, "empty_clue_text", "Slot %s has empty clue text." % sk))

	# Orphans: clues with no corresponding slot
	for ok in clues_by_key:
		if not slot_keys.has(ok):
			issues.append(_issue(SEVERITY_WARNING, "orphan_clue", "Clue %s does not match any slot." % ok))

	return issues


static func has_errors(issues: Array) -> bool:
	for issue in issues:
		if issue.get("severity") == SEVERITY_ERROR:
			return true
	return false


static func count_by_severity(issues: Array, severity: String) -> int:
	var count: int = 0
	for issue in issues:
		if issue.get("severity") == severity:
			count += 1
	return count


static func _slot_key(number: int, direction: String) -> String:
	return str(number) + "/" + direction


static func _issue(severity: String, code: String, message: String) -> Dictionary:
	return {"severity": severity, "code": code, "message": message}
