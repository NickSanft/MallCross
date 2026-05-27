extends "res://addons/gut/test.gd"


# AchievementStore: disk I/O for the unlocks dict (id -> unlock_day).
# Mirrors the SettingsManager test layout: temp paths, write/read/delete
# round-trips, defensive against malformed input.


func _temp_path() -> String:
	return "user://test_store_%d.json" % Time.get_ticks_msec()


# ----- save + load round trip -------------------------------------------

func test_save_then_load_round_trips() -> void:
	var path: String = _temp_path()
	AchievementStore.save_to_path({"first_solve": 1, "streak_7": 7}, path)
	var restored: Dictionary = AchievementStore.load_from_path(path)
	assert_eq(restored.size(), 2)
	assert_eq(restored["first_solve"], 1)
	assert_eq(restored["streak_7"], 7)
	AchievementStore.delete_at_path(path)


func test_load_missing_file_returns_empty() -> void:
	assert_eq(AchievementStore.load_from_path("user://does_not_exist.json"), {})


func test_load_malformed_json_returns_empty() -> void:
	var path: String = _temp_path()
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var restored: Dictionary = AchievementStore.load_from_path(path)
	assert_eq(restored, {})
	if FileAccess.file_exists(path):
		var dir: DirAccess = DirAccess.open(path.get_base_dir())
		dir.remove(path.get_file())


func test_load_drops_negative_days() -> void:
	var path: String = _temp_path()
	AchievementStore.save_to_path({"good": 5, "bad": -3}, path)
	var restored: Dictionary = AchievementStore.load_from_path(path)
	assert_true(restored.has("good"))
	assert_false(restored.has("bad"))
	AchievementStore.delete_at_path(path)


func test_load_drops_empty_string_ids() -> void:
	var path: String = _temp_path()
	# Hand-write because save_to_path filters these the same way.
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string('{"version": 1, "unlocks": {"": 5, "good": 10}}')
	f.close()
	var restored: Dictionary = AchievementStore.load_from_path(path)
	assert_eq(restored.size(), 1)
	assert_true(restored.has("good"))
	AchievementStore.delete_at_path(path)


func test_delete_removes_file() -> void:
	var path: String = _temp_path()
	AchievementStore.save_to_path({"a": 1}, path)
	assert_true(FileAccess.file_exists(path))
	assert_true(AchievementStore.delete_at_path(path))
	assert_false(FileAccess.file_exists(path))


func test_delete_returns_false_when_missing() -> void:
	assert_false(AchievementStore.delete_at_path(_temp_path()))


func test_save_filters_garbage_before_writing_to_disk() -> void:
	# Caller passes nonsense; on-disk file is still well-formed.
	var path: String = _temp_path()
	AchievementStore.save_to_path({"good": 3, "": 99, "neg": -1}, path)
	var restored: Dictionary = AchievementStore.load_from_path(path)
	assert_eq(restored.size(), 1)
	assert_eq(restored["good"], 3)
	AchievementStore.delete_at_path(path)
