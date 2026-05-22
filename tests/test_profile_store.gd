extends "res://addons/gut/test.gd"

# Disk-touching tests. Each one writes/deletes a unique user:// path so
# concurrent or interrupted runs can't poison subsequent tests.

const TEST_PATH_PREFIX: String = "user://test_profile_"

var _paths_to_cleanup: Array = []


func after_each() -> void:
	for path in _paths_to_cleanup:
		ProfileStore.delete_at_path(path)
	_paths_to_cleanup.clear()


func _temp_path() -> String:
	var path: String = TEST_PATH_PREFIX + str(Time.get_ticks_usec()) + ".json"
	_paths_to_cleanup.append(path)
	return path


func test_load_from_missing_file_returns_fresh_profile() -> void:
	var profile: Profile = ProfileStore.load_from_path(_temp_path())
	assert_eq(profile.woints, 0)
	assert_eq(profile.current_day, 1)


func test_save_then_load_round_trip_woints() -> void:
	var path: String = _temp_path()
	var profile: Profile = Profile.new()
	profile.add_woints(123)
	assert_true(ProfileStore.save_to_path(profile, path))
	var restored: Profile = ProfileStore.load_from_path(path)
	assert_eq(restored.woints, 123)


func test_save_then_load_round_trip_solved_set() -> void:
	var path: String = _temp_path()
	var profile: Profile = Profile.new()
	profile.current_day = 2
	profile.mark_puzzle_solved("demo_5x5")
	assert_true(ProfileStore.save_to_path(profile, path))
	var restored: Profile = ProfileStore.load_from_path(path)
	assert_true(restored.is_puzzle_solved("demo_5x5"))
	assert_eq(restored.first_solved_day("demo_5x5"), 2)


func test_save_then_load_round_trip_cached_state() -> void:
	var path: String = _temp_path()
	var profile: Profile = Profile.new()
	var grid: CrosswordGrid = CrosswordGrid.from_strings(["ABC", "DEF", "GHI"])
	var state: CrosswordState = CrosswordState.empty_for_grid(grid)
	state.set_letter(0, 0, "A")
	state.set_letter(2, 2, "I", true)
	profile.cache_state("demo_3x3", state)
	assert_true(ProfileStore.save_to_path(profile, path))

	var restored: Profile = ProfileStore.load_from_path(path)
	var restored_state: CrosswordState = restored.get_cached_state("demo_3x3")
	assert_not_null(restored_state)
	assert_eq(restored_state.entry_at(0, 0), "A")
	assert_eq(restored_state.entry_at(2, 2), "I")
	assert_true(restored_state.is_pencil(2, 2))


func test_load_returns_fresh_profile_on_garbage_json() -> void:
	var path: String = _temp_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("this is not json")
	file.close()
	var profile: Profile = ProfileStore.load_from_path(path)
	assert_eq(profile.woints, 0)


func test_load_returns_fresh_profile_on_empty_file() -> void:
	var path: String = _temp_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("")
	file.close()
	var profile: Profile = ProfileStore.load_from_path(path)
	assert_eq(profile.woints, 0)


func test_save_writes_valid_json() -> void:
	var path: String = _temp_path()
	var profile: Profile = Profile.new()
	profile.add_woints(50)
	ProfileStore.save_to_path(profile, path)
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	assert_eq(parsed["woints"], 50)


func test_save_returns_false_for_null_profile() -> void:
	assert_false(ProfileStore.save_to_path(null, _temp_path()))


func test_delete_at_path_removes_file() -> void:
	var path: String = _temp_path()
	ProfileStore.save_to_path(Profile.new(), path)
	assert_true(FileAccess.file_exists(path))
	assert_true(ProfileStore.delete_at_path(path))
	assert_false(FileAccess.file_exists(path))


func test_delete_at_path_false_when_missing() -> void:
	assert_false(ProfileStore.delete_at_path(_temp_path()))
