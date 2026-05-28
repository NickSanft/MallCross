extends "res://addons/gut/test.gd"


# CommunityPuzzleLoader scans user://puzzles/. Tests write fixtures to a
# unique-per-run temp subdirectory under user:// so they don't collide with
# any real community files the developer has dropped in, and clean up after
# themselves.


var _test_dir: String


func before_each() -> void:
	_test_dir = "user://test_community_%d/" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_test_dir)


func after_each() -> void:
	# Tear down. The dir is shallow (just .json files), so we can scrub
	# manually rather than a recursive helper.
	var dir: DirAccess = DirAccess.open(_test_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()
	# Remove the empty dir. DirAccess.remove on a directory path needs a
	# parent context; using remove_absolute is the portable form.
	DirAccess.remove_absolute(_test_dir.trim_suffix("/"))


func _write(filename: String, contents: String) -> String:
	var path: String = _test_dir + filename
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(contents)
	f.close()
	return path


func _valid_puzzle_json(title: String = "Test MINI") -> String:
	return '''
	{
		"version": 1,
		"title": "%s",
		"author": "TestAuthor",
		"theme": "test",
		"size": 5,
		"grid": [
			"PUTTS",
			"E###C",
			"AMIGO",
			"C###R",
			"HALVE"
		],
		"clues": [
			{"number": 1, "direction": "across", "row": 0, "col": 0, "length": 5, "text": "A"},
			{"number": 3, "direction": "across", "row": 2, "col": 0, "length": 5, "text": "B"},
			{"number": 4, "direction": "across", "row": 4, "col": 0, "length": 5, "text": "C"},
			{"number": 1, "direction": "down", "row": 0, "col": 0, "length": 5, "text": "D"},
			{"number": 2, "direction": "down", "row": 0, "col": 4, "length": 5, "text": "E"}
		]
	}
	''' % title


# ----- dir handling -----------------------------------------------------

func test_missing_directory_returns_empty_array() -> void:
	var results: Array = CommunityPuzzleLoader.scan_user_dir("user://does_not_exist_anywhere/")
	assert_eq(results, [])


func test_empty_directory_returns_empty_array() -> void:
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results, [])


func test_skips_non_json_files() -> void:
	# Drop a couple of non-JSON files. They should not appear in results.
	_write("notes.txt", "ignore me")
	_write("README.md", "# also ignored")
	_write("puzzle.json", _valid_puzzle_json())
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 1)
	assert_eq(String(results[0]["title"]), "Test MINI")


# ----- happy path -------------------------------------------------------

func test_valid_puzzle_is_marked_valid() -> void:
	_write("ok.json", _valid_puzzle_json())
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 1)
	assert_true(bool(results[0]["valid"]))
	assert_eq(String(results[0]["error"]), "")
	assert_eq(int(results[0]["size"]), 5)
	assert_eq(String(results[0]["author"]), "TestAuthor")


func test_alphabetical_sort_of_filenames() -> void:
	# DirAccess.list_dir doesn't guarantee filesystem order; the loader
	# sorts so the picker UI is stable across launches.
	_write("c.json", _valid_puzzle_json("C"))
	_write("a.json", _valid_puzzle_json("A"))
	_write("b.json", _valid_puzzle_json("B"))
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 3)
	assert_eq(String(results[0]["title"]), "A")
	assert_eq(String(results[1]["title"]), "B")
	assert_eq(String(results[2]["title"]), "C")


func test_puzzle_id_is_full_path() -> void:
	# Convention used by GameController to detect community puzzles via
	# the user:// prefix check.
	var written: String = _write("ok.json", _valid_puzzle_json())
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(String(results[0]["puzzle_id"]), written)


# ----- defensive cases --------------------------------------------------

func test_empty_file_yields_invalid_with_message() -> void:
	_write("empty.json", "")
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 1)
	assert_false(bool(results[0]["valid"]))
	assert_ne(String(results[0]["error"]), "")


func test_malformed_json_yields_invalid_with_message() -> void:
	_write("bad.json", "{this is not json")
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 1)
	assert_false(bool(results[0]["valid"]))
	assert_ne(String(results[0]["error"]), "")


func test_asymmetric_grid_is_rejected() -> void:
	# 5x5 with a block at (0,0) but no mirror at (4,4) → asymmetry error.
	# Building this minimally so we know the rejection is symmetry, not
	# something else.
	var asymmetric: String = '''
	{
		"version": 1,
		"title": "Bad",
		"author": "T",
		"theme": "t",
		"size": 5,
		"grid": [
			"#....",
			".....",
			".....",
			".....",
			"....."
		],
		"clues": []
	}
	'''
	_write("asym.json", asymmetric)
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(results.size(), 1)
	assert_false(bool(results[0]["valid"]))


func test_title_still_present_for_invalid_files() -> void:
	# Even rejected puzzles surface their (claimed) title in the picker so
	# modders can see which file the error is about.
	var malformed_but_parseable: String = '''
	{
		"version": 1,
		"title": "Almost There",
		"author": "T",
		"size": 5,
		"grid": [
			"#....",
			".....",
			".....",
			".....",
			"....."
		],
		"clues": []
	}
	'''
	_write("dummy.json", malformed_but_parseable)
	var results: Array = CommunityPuzzleLoader.scan_user_dir(_test_dir)
	assert_eq(String(results[0]["title"]), "Almost There")
