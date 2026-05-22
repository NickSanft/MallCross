class_name PuzzleLoader
extends RefCounted

# Loads puzzle JSON files from res://data/puzzles/. Returns the same dict
# shape as CrosswordSerializer.puzzle_from_dict, so callers don't need to
# know whether a puzzle came from disk or memory.

const PUZZLE_DIR: String = "res://data/puzzles/"


static func load_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return CrosswordSerializer.puzzle_from_dict({})
	var content: String = FileAccess.get_file_as_string(path)
	return CrosswordSerializer.puzzle_from_json(content)


static func load_by_id(puzzle_id: String) -> Dictionary:
	return load_from_path(PUZZLE_DIR + puzzle_id + ".json")
