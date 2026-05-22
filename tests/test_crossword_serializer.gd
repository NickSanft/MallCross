extends "res://addons/gut/test.gd"


func _grid_3x3() -> CrosswordGrid:
	return CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])


func _sample_clues() -> Array:
	return [
		{"number": 1, "direction": "across", "row": 0, "col": 0, "length": 3, "answer": "ABC", "text": "First three letters"},
		{"number": 1, "direction": "down", "row": 0, "col": 0, "length": 3, "answer": "ADG", "text": "Column one"},
	]


func test_puzzle_to_dict_includes_format_version() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues())
	assert_eq(d["version"], CrosswordSerializer.PUZZLE_FORMAT_VERSION)


func test_puzzle_to_dict_includes_grid_strings() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues())
	assert_eq(d["grid"], ["ABC", "DEF", "GHI"])


func test_puzzle_to_dict_includes_size() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues())
	assert_eq(d["size"], 3)


func test_puzzle_to_dict_metadata() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues(), "Title", "Author", "Theme")
	assert_eq(d["title"], "Title")
	assert_eq(d["author"], "Author")
	assert_eq(d["theme"], "Theme")


func test_puzzle_from_dict_reconstructs_grid() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues())
	var restored: Dictionary = CrosswordSerializer.puzzle_from_dict(d)
	var grid: CrosswordGrid = restored["grid"]
	assert_eq(grid.size, 3)
	assert_eq(grid.cell(0, 0), "A")
	assert_eq(grid.cell(2, 2), "I")


func test_puzzle_from_dict_preserves_clues() -> void:
	var d: Dictionary = CrosswordSerializer.puzzle_to_dict(_grid_3x3(), _sample_clues())
	var restored: Dictionary = CrosswordSerializer.puzzle_from_dict(d)
	assert_eq(restored["clues"].size(), 2)


func test_puzzle_from_dict_defaults_when_missing() -> void:
	var restored: Dictionary = CrosswordSerializer.puzzle_from_dict({})
	var grid: CrosswordGrid = restored["grid"]
	assert_eq(grid.size, 0)
	assert_eq(restored["clues"], [])


func test_puzzle_round_trip_via_json() -> void:
	var json_text: String = CrosswordSerializer.puzzle_to_json(_grid_3x3(), _sample_clues(), "Hello", "Tester")
	var restored: Dictionary = CrosswordSerializer.puzzle_from_json(json_text)
	var grid: CrosswordGrid = restored["grid"]
	assert_eq(grid.to_strings(), ["ABC", "DEF", "GHI"])
	assert_eq(restored["title"], "Hello")
	assert_eq(restored["author"], "Tester")


func test_puzzle_from_json_handles_garbage() -> void:
	var restored: Dictionary = CrosswordSerializer.puzzle_from_json("not json at all")
	var grid: CrosswordGrid = restored["grid"]
	assert_eq(grid.size, 0)


func test_state_to_dict_round_trip_preserves_entries() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "A")
	state.set_letter(1, 1, "E", true)
	state.set_letter(2, 2, "I")
	var d: Dictionary = CrosswordSerializer.state_to_dict(state)
	var restored: CrosswordState = CrosswordSerializer.state_from_dict(d)
	assert_eq(restored.entry_at(0, 0), "A")
	assert_eq(restored.entry_at(1, 1), "E")
	assert_eq(restored.entry_at(2, 2), "I")


func test_state_to_dict_round_trip_preserves_pencil_flags() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(1, 1, "E", true)
	state.set_letter(0, 0, "A", false)
	var d: Dictionary = CrosswordSerializer.state_to_dict(state)
	var restored: CrosswordState = CrosswordSerializer.state_from_dict(d)
	assert_true(restored.is_pencil(1, 1))
	assert_false(restored.is_pencil(0, 0))


func test_state_format_version_is_recorded() -> void:
	var grid: CrosswordGrid = _grid_3x3()
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	var d: Dictionary = CrosswordSerializer.state_to_dict(state)
	assert_eq(d["version"], CrosswordSerializer.STATE_FORMAT_VERSION)


func test_state_from_dict_handles_empty() -> void:
	var restored: CrosswordState = CrosswordSerializer.state_from_dict({})
	assert_eq(restored.size, 0)


func test_puzzle_json_is_valid_parsable() -> void:
	var json_text: String = CrosswordSerializer.puzzle_to_json(_grid_3x3(), _sample_clues())
	var parsed: Variant = JSON.parse_string(json_text)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
